#!/usr/bin/env python3
"""
极简 API 服务器 - 只提供数据读取，不处理业务逻辑
.getPort: 7891
"""

import json, pathlib, sys, threading, argparse, logging, os
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

log = logging.getLogger('server')
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(name)s] %(message)s', datefmt='%H:%M:%S')

BASE = pathlib.Path(__file__).parent
DATA = BASE / "data"
DIST = BASE / 'dist'

class SimpleAPIHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        log.info("%s %s" % (self.address_string(), format % args))

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        # 服务静态文件
        if path == '/' or path == '/index.html':
            self.serve_file(DIST / 'index.html', 'text/html')
        elif path.startswith('/assets/'):
            self.serve_file(DIST / path, None)
        # API 接口
        elif path == '/api/live-status':
            self.serve_api('live_status.json', {'tasks': [], 'syncStatus': {'ok': True}})
        elif path == '/api/agent-config':
            self.serve_api('agent_config.json', {'agents': []})
        elif path == '/api/model-change-log':
            self.serve_api('model_change_log.json', [])
        elif path == '/api/officials-stats':
            self.serve_api('officials_stats.json', {'officials': [], 'totals': {}})
        elif path == '/api/agents-status':
            self.serve_api('', {'ok': True, 'gateway': {'alive': True, 'probe': True, 'status': 'ok'}, 'agents': [], 'checkedAt': ''})
        elif path == '/api/morning-brief':
            self.serve_api('', {'date': '', 'generated_at': '', 'categories': {}})
        elif path == '/api/morning-config':
            self.serve_api('', {'categories': [], 'keywords': [], 'custom_feeds': [], 'feishu_webhook': ''})
        elif path == '/healthz':
            self.send_health()
        else:
            self.send_error(404, 'Not Found')

    def send_health(self):
        """健康检查端点"""
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(b'{"status":"ok"}')

    def serve_file(self, filepath, mime_type):
        try:
            with open(filepath, 'rb') as f:
                content = f.read()
            self.send_response(200)
            if mime_type:
                self.send_header('Content-Type', mime_type)
            elif filepath.suffix == '.js':
                self.send_header('Content-Type', 'application/javascript')
            elif filepath.suffix == '.css':
                self.send_header('Content-Type', 'text/css')
            elif filepath.suffix == '.json':
                self.send_header('Content-Type', 'application/json')
            self.send_header('Cache-Control', 'no-store')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(content)
        except FileNotFoundError:
            self.send_error(404, 'Not Found')

    def serve_api(self, filename, default_data):
        try:
            filepath = DATA / filename
            if filename and filepath.exists():
                with open(filepath, 'r', encoding='utf-8') as f:
                    data = json.load(f)
            else:
                data = default_data
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(data, ensure_ascii=False).encode('utf-8'))
        except Exception as e:
            log.error(f"API error: {e}")
            self.send_response(500)
            self.end_headers()

def run_server(port=7891):
    server = HTTPServer(('0.0.0.0', port), SimpleAPIHandler)
    log.info(f"🚀 服务器运行在 http://127.0.0.1:{port}")
    log.info(f"📊 数据目录: {DATA}")
    server.serve_forever()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=7891, help='Port to listen on')
    args = parser.parse_args()
    run_server(args.port)
