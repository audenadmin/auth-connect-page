/**
 * Local Development Server for Auden Auth Page
 *
 * This server simulates both auth.auden.app and connect.auden.app
 * for local development and testing.
 *
 * Usage:
 *   node dev-server.js
 *
 * Then visit:
 *   http://localhost:3333/magic?token=test-token-12345678901234567890
 *   http://localhost:3333/oauth/google?code=test-code&state=test-state
 *   http://localhost:3333/calendar/google?code=test-code&state=test-state
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3333;
const HOST = process.env.HOST || 'localhost';

// Read the HTML file
const htmlPath = path.join(__dirname, 'index.html');

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${HOST}:${PORT}`);

  console.log(`[${new Date().toISOString()}] ${req.method} ${url.pathname}${url.search}`);

  // Serve favicon
  if (url.pathname === '/favicon.ico') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Serve the HTML file for all routes (SPA behavior)
  fs.readFile(htmlPath, 'utf8', (err, html) => {
    if (err) {
      console.error('Error reading HTML file:', err);
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('Internal Server Error');
      return;
    }

    res.writeHead(200, {
      'Content-Type': 'text/html',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'X-Frame-Options': 'DENY',
      'X-Content-Type-Options': 'nosniff',
    });
    res.end(html);
  });
});

server.listen(PORT, HOST, () => {
  console.log(`
╔═══════════════════════════════════════════════════════════════╗
║           Auden Auth Page - Development Server                ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  Server running at: http://${HOST}:${PORT}                       ║
║                                                               ║
║  Test URLs:                                                   ║
║                                                               ║
║  Magic Link:                                                  ║
║    http://localhost:${PORT}/magic?token=test123456789012345678901234567890
║                                                               ║
║  Login OAuth (Google):                                        ║
║    http://localhost:${PORT}/oauth/google?code=testcode&state=teststate123456
║                                                               ║
║  Login OAuth (Microsoft):                                     ║
║    http://localhost:${PORT}/oauth/microsoft?code=testcode&state=teststate123456
║                                                               ║
║  Calendar OAuth (Google):                                     ║
║    http://localhost:${PORT}/calendar/google?code=testcode&state=teststate123456
║                                                               ║
║  Calendar OAuth (Microsoft):                                  ║
║    http://localhost:${PORT}/calendar/microsoft?code=testcode&state=teststate123456
║                                                               ║
║  OAuth Error:                                                 ║
║    http://localhost:${PORT}/oauth/google?error=access_denied
║                                                               ║
║  Invalid Token:                                               ║
║    http://localhost:${PORT}/magic?token=short
║                                                               ║
║  Missing Token:                                               ║
║    http://localhost:${PORT}/magic
║                                                               ║
║  404 Page:                                                    ║
║    http://localhost:${PORT}/unknown-route
║                                                               ║
║  Landing Page:                                                ║
║    http://localhost:${PORT}/
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
  `);
});

// Handle server errors
server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`Port ${PORT} is already in use. Try a different port with PORT=XXXX node dev-server.js`);
  } else {
    console.error('Server error:', err);
  }
  process.exit(1);
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\nShutting down server...');
  server.close(() => {
    console.log('Server stopped.');
    process.exit(0);
  });
});
