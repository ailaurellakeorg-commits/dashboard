from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PORT = 8080


class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


def main():
    web_root = Path(__file__).resolve().parents[1] / "build" / "web"
    if not (web_root / "index.html").is_file():
        raise SystemExit(f"Web build not found at {web_root}. Run flutter build web --release.")

    handler = partial(NoCacheHandler, directory=str(web_root))
    server = ThreadingHTTPServer(("0.0.0.0", PORT), handler)
    print(f"Serving {web_root} on http://0.0.0.0:{PORT}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()