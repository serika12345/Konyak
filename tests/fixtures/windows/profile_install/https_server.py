#!/usr/bin/env python3
"""Fixed localhost HTTPS server used only by the profile-install smoke."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import ssl
import threading


class FixtureRequestHandler(SimpleHTTPRequestHandler):
    request_log: Path
    request_log_lock = threading.Lock()

    def log_request(self, code: int | str = "-", size: int | str = "-") -> None:
        if self.path == "/health":
            return
        record = json.dumps(
            {
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "method": self.command,
                "path": self.path,
                "code": int(code),
            },
            sort_keys=True,
            separators=(",", ":"),
        )
        with self.request_log_lock:
            with self.request_log.open("a", encoding="utf-8") as output:
                output.write(record + "\n")

    def do_GET(self) -> None:  # noqa: N802 - stdlib handler contract
        if self.path == "/health":
            payload = b"ok\n"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return
        super().do_GET()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", required=True, type=Path)
    parser.add_argument("--certificate", required=True)
    parser.add_argument("--key", required=True)
    parser.add_argument("--request-log", required=True, type=Path)
    parser.add_argument("--port", type=int, default=18443)
    arguments = parser.parse_args()

    arguments.request_log.parent.mkdir(parents=True, exist_ok=True)
    arguments.request_log.write_text("", encoding="utf-8")
    handler = lambda *args, **kwargs: FixtureRequestHandler(  # noqa: E731
        *args, directory=str(arguments.directory), **kwargs
    )
    FixtureRequestHandler.request_log = arguments.request_log
    server = ThreadingHTTPServer(("127.0.0.1", arguments.port), handler)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(arguments.certificate, arguments.key)
    server.socket = context.wrap_socket(server.socket, server_side=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
