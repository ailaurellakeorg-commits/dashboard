# Laurel Lake Executive Dashboard

A Flutter Web skeleton for a board-level view of census, labor, and expense.

The project exposes a `DashboardRepository` boundary, a `DashboardBloc`, and an
synthetic daily demo dataset covering July 2026 through the current date. The
dashboard opens to the current month to date, and demo records and calendar
month shortcuts extend automatically as time advances. Future dates are disabled. A
vertically scrollable calendar supports preset months and custom ranges spanning
multiple months. Replace `DemoDashboardRepository` with the Microsoft 365/API
data pipeline once the Phase 1 reporting exports are available.

The Census view includes a two-dimensional day-by-bed occupancy matrix. The
Labor view includes an employee-by-day matrix with worked hours and labor cost.
Both use pinned headers and lazy two-dimensional scrolling for large ranges.

## Run locally

```bash
flutter run -d chrome
```

For the Labor directory in Flutter debug mode, the Python server must also be
running. Point the debug app at it with:

```powershell
flutter run -d chrome --dart-define=LABOR_API_BASE_URL=http://localhost:8080
```

## Host on the local network

Build and install the server task once from PowerShell in the project directory:

```powershell
winget install --id Python.Python.3.13 --exact --scope user
flutter build web --release
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\install_lan_server.ps1
```

The task uses Python's standard library and starts the static web server when
your Windows account signs in, independently of VS Code. Other devices on the
same private network can open `http://<this-machine's-LAN-IP>:8080`. If setup
reports that Windows Firewall needs administrator permission, run the displayed
`New-NetFirewallRule` command in an elevated PowerShell once.

To deploy an updated dashboard, rebuild the web bundle:

```powershell
flutter build web --release
```

The server will serve the new files immediately; restart the browser page to
load the updated app. The startup task remains installed across rebuilds.

## Labor directory data

The Python server reads `DeptMaster.csv` and `Employees.csv` from `DATA_DIR` in
the project-root `.env` file. Copy `.env.example` to `.env` and change the path
if needed; without a setting, the server uses `C:\DATA`. The setting is read
when the Labor directory is requested. The CSVs stay local and are not part of
the repository.

Employee pay subtitles use `Location_Code` as the amount, as configured for
this dashboard: `HOURLY` is shown per hour, and `SALARY`/`SALN80` as salary.
Employee-by-day cells remain blank until daily employee costs are available;
aggregate daily labor figures remain unchanged. The directory endpoint serves
employee names and these interpreted amounts to clients that can access the
server, so keep it on a trusted local network.

## Project structure

- `lib/config` — color and typography theme
- `lib/models` — dashboard view models
- `lib/repositories` — data contract plus demo data
- `lib/ui` — responsive screens, BLoC events/states, and reusable visuals
