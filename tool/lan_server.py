import csv
import json
import os
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

PORT = 8080
PROJECT_ROOT = Path(__file__).resolve().parents[1]


def _load_data_directory():
    env_path = PROJECT_ROOT / ".env"
    file_settings = {}
    if env_path.is_file():
        for line in env_path.read_text(encoding="utf-8-sig").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            value = value.strip().strip("\"'")
            file_settings[key.strip()] = value

    return Path(os.environ.get("DATA_DIR", file_settings.get("DATA_DIR", r"C:\DATA"))).expanduser()


def _read_csv(path, required_columns):
    with path.open("r", encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source)
        missing = set(required_columns) - set(reader.fieldnames or ())
        if missing:
            raise ValueError(f"{path.name} is missing columns: {', '.join(sorted(missing))}")
        return [
            {key: (value or "").strip() for key, value in row.items() if key is not None}
            for row in reader
        ]


def load_labor_directory(data_dir):
    data_dir = Path(data_dir)
    departments = _read_csv(
        data_dir / "DeptMaster.csv",
        ("Department_Code", "Description", "CodeType"),
    )
    employees = _read_csv(
        data_dir / "Employees.csv",
        (
            "Employee_Code",
            "Employee_Last_Name",
            "Employee_First_Name",
            "Department_Code",
            "Wage_Type",
            "Location_Code",
            "Pay_Rule",
        ),
    )

    employee_department_codes = {row["Department_Code"] for row in employees}
    department_names = {
        row["Department_Code"]: row["Description"]
        for row in departments
        if row["CodeType"].upper() == "E"
        and row["Department_Code"] in employee_department_codes
    }

    grouped_employees = {code: [] for code in department_names}
    for row in employees:
        department_code = row["Department_Code"]
        if department_code not in grouped_employees:
            department_names[department_code] = f"Department {department_code}"
            grouped_employees[department_code] = []

        pay_rule = row["Pay_Rule"].upper()
        if pay_rule == "HOURLY":
            rate_type = "hourly"
        elif pay_rule in {"SALARY", "SALN80"}:
            rate_type = "salary"
        else:
            rate_type = None

        try:
            rate_amount = float(row["Location_Code"]) if rate_type else None
        except ValueError:
            rate_amount = None

        grouped_employees[department_code].append(
            {
                "code": row["Employee_Code"],
                "name": " ".join(
                    part
                    for part in (
                        row["Employee_First_Name"],
                        row["Employee_Initial"],
                        row["Employee_Last_Name"],
                    )
                    if part
                ),
                "rateType": rate_type if rate_amount is not None else None,
                "rateAmount": rate_amount,
                "payRule": row["Pay_Rule"],
            }
        )

    return [
        {
            "code": code,
            "name": department_names[code],
            "employees": sorted(group, key=lambda employee: employee["name"].casefold()),
        }
        for code, group in sorted(
            grouped_employees.items(),
            key=lambda entry: (department_names[entry[0]].casefold(), entry[0]),
        )
    ]


class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        if urlsplit(self.path).path.startswith("/api/"):
            origin = self.headers.get("Origin")
            if origin and urlsplit(origin).hostname in {"localhost", "127.0.0.1", "::1"}:
                self.send_header("Access-Control-Allow-Origin", origin)
                self.send_header("Vary", "Origin")
                self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        super().end_headers()

    def do_OPTIONS(self):
        if not urlsplit(self.path).path.startswith("/api/"):
            self.send_error(405)
            return
        self.send_response(204)
        self.end_headers()

    def do_GET(self):
        if urlsplit(self.path).path == "/api/labor-directory":
            try:
                data_dir = _load_data_directory()
                payload = load_labor_directory(data_dir)
            except (OSError, ValueError) as error:
                payload = {"error": str(error)}
                self._send_json(payload, status=500)
                return
            self._send_json(payload)
            return
        super().do_GET()

    def _send_json(self, payload, status=200):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main():
    web_root = PROJECT_ROOT / "build" / "web"
    if not (web_root / "index.html").is_file():
        raise SystemExit(f"Web build not found at {web_root}. Run flutter build web --release.")

    handler = partial(NoCacheHandler, directory=str(web_root))
    server = ThreadingHTTPServer(("0.0.0.0", PORT), handler)
    print(f"Serving {web_root} on http://0.0.0.0:{PORT}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()