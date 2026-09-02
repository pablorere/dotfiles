#!/usr/bin/env python3
import http.server
import socketserver
import urllib.parse
import os
import subprocess

PORT = 8999
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SXHKDRC_PATH = os.path.expanduser("~/.config/bspwm/config/sxhkdrc")

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>SXHKD Shortcut Editor</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #1e1e2e; color: #cdd6f4; margin: 0; padding: 20px; }
        .container { max-width: 800px; margin: 0 auto; background-color: #181825; padding: 20px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.3); }
        h1 { color: #89b4fa; text-align: center; }
        textarea { width: 100%; height: 500px; background-color: #11111b; color: #a6e3a1; border: 1px solid #313244; padding: 10px; font-family: monospace; font-size: 14px; border-radius: 5px; box-sizing: border-box; resize: vertical; }
        .btn { display: block; width: 100%; background-color: #89b4fa; color: #11111b; border: none; padding: 15px; font-size: 18px; font-weight: bold; cursor: pointer; border-radius: 5px; margin-top: 15px; }
        .btn:hover { background-color: #b4befe; }
        .alert { padding: 10px; background-color: #a6e3a1; color: #11111b; border-radius: 5px; margin-bottom: 15px; display: {alert_display}; }
    </style>
</head>
<body>
    <div class="container">
        <h1>⌨️ SXHKD Editor</h1>
        <div class="alert">{message}</div>
        <form method="POST">
            <textarea name="config">{config_content}</textarea>
            <button type="submit" class="btn">💾 Save & Reload SXHKD</button>
        </form>
    </div>
</body>
</html>
"""

class EditorHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        
        try:
            with open(SXHKDRC_PATH, "r") as f:
                content = f.read()
        except Exception as e:
            content = f"Error reading file: {e}"
            
        html = HTML_TEMPLATE.replace("{config_content}", content).replace("{message}", "").replace("{alert_display}", "none")
        self.wfile.write(html.encode('utf-8'))

    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length).decode('utf-8')
        parsed_data = urllib.parse.parse_qs(post_data)
        
        if 'config' in parsed_data:
            new_config = parsed_data['config'][0]
            # Convert Windows newlines to Unix newlines
            new_config = new_config.replace('\r\n', '\n')
            
            with open(SXHKDRC_PATH, "w") as f:
                f.write(new_config)
                
            # Reload sxhkd
            subprocess.run(["pkill", "-USR1", "-x", "sxhkd"])
            
            message = "Configuration saved successfully! SXHKD has been reloaded."
            alert_display = "block"
        else:
            message = "Error: No configuration data received."
            alert_display = "block"
            
        try:
            with open(SXHKDRC_PATH, "r") as f:
                content = f.read()
        except Exception:
            content = ""

        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        
        html = HTML_TEMPLATE.replace("{config_content}", content).replace("{message}", message).replace("{alert_display}", alert_display)
        self.wfile.write(html.encode('utf-8'))

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

if __name__ == "__main__":
    with ReusableTCPServer(("", PORT), EditorHandler) as httpd:
        print(f"Serving at http://localhost:{PORT}")
        httpd.serve_forever()
