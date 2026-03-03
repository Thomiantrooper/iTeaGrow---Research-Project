const https = require('https');

const endpoints = [
    'https://iteagrow.up.railway.app/api/health',                                  // Main Backend
    'https://tea-leaf-disease-api-prod.up.railway.app/health',                     // Disease AI
    'https://iteagrow-tea-yield-prod.up.railway.app/health',                       // Yield AI
    'https://iteagrow-tea-leaf-maturity-prod.up.railway.app/health',               // Maturity AI
    'https://authentication-iteagrow-api.up.railway.app/api/health',               // Auth API (Railway)
    'https://tea-powder-classification-market-value-api.up.railway.app/health', // Market AI (Railway)
    'https://iteagrow-environment-monitoring-iot-api.up.railway.app/health',        // Env IoT (Railway)
    'https://iteagrow-soil-monitoring-iot-api.up.railway.app/health',              // Soil IoT (Railway)
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
