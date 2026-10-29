"""Local loopback-only VIN simulation provider. No inventory writes or manufacturer data."""
import json
import re
from datetime import date
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlsplit


def response_for(path):
    path = urlsplit(path).path
    if not path.startswith('/decode/'):
        return 404, {"error": "NOT_FOUND", "simulation": True}
    vin = path.removeprefix('/decode/')
    if not re.fullmatch(r'[A-HJ-NPR-Z0-9]{17}', vin):
        return 400, {"error": "INVALID_VIN_FORMAT", "simulation": True}
    return 200, {"vin": vin, "make": "Aurelia", "model": "Fictional Sedan", "year": date.today().year,
                 "bodyStyle": "Sedan", "simulation": True}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        status, payload = response_for(self.path)
        data = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)


if __name__ == '__main__':
    HTTPServer(('127.0.0.1', 8080), Handler).serve_forever()
