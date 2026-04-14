#!/bin/bash
# Serve game with cache disabled (for development)
PORT=${1:-8081}
echo "Serving on http://localhost:$PORT (no-cache)"
python3 -c "
from http.server import HTTPServer, SimpleHTTPRequestHandler
import os
os.chdir('build/html5')
class H(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        super().end_headers()
HTTPServer(('', $PORT), H).serve_forever()
"
