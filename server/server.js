// server/server.js
const { WebSocketServer } = require('ws');
const readline = require('readline');

// Explicitly bind to the IPv4 loopback address
const wss = new WebSocketServer({ 
    port: 8055,
    host: '127.0.0.1' 
});


// 1. Start WebSocket Server for the Browser
let browserClient = null;

wss.on('connection', (ws) => {
    browserClient = ws;
    
    // Listen for messages from the Browser and forward to Neovim
    ws.on('message', (message) => {
        const data = JSON.parse(message);
        // Print to stdout: Neovim reads this!
        console.log(JSON.stringify({ source: 'browser', data }));
    });
});

// 2. Read stdin from Neovim
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false
});

rl.on('line', (line) => {
    try {
        const payload = JSON.parse(line);
        // Forward Neovim data straight to the browser if connected
        if (browserClient && browserClient.readyState === 1) {
            browserClient.send(JSON.stringify(payload));
        }
    } catch (e) {
        // Suppress or log errors safely
    }
});
