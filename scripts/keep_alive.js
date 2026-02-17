const https = require('https');

const endpoints = [
    'https://tea-leaf-disease-api-prod.up.railway.app/health',
    'https://iteagrow-tea-yield-prod.up.railway.app/health',
    'https://iteagrow-tea-leaf-maturity-prod.up.railway.app/health',
    'https://iteagrow.up.railway.app/api/health'
];

function ping(url) {
    return new Promise((resolve, reject) => {
        const req = https.get(url, (res) => {
            console.log(`[${new Date().toISOString()}] Pinged ${url} - Status: ${res.statusCode}`);
            resolve(res.statusCode);
        });

        req.on('error', (e) => {
            console.error(`[${new Date().toISOString()}] Error pinging ${url}: ${e.message}`);
            resolve(null); // Resolve to keep going
        });
    });
}

async function run() {
    console.log('Starting Keep-Alive Check...');
    for (const url of endpoints) {
        await ping(url);
    }
    console.log('Check complete.\n');
}

// Run immediately
run();

// Then run every 5 minutes (300000 ms)
setInterval(run, 5 * 60 * 1000);
