import React, { createContext, useContext, useState, useEffect, useRef } from 'react';

export const HealthContext = createContext();

export const useHealth = () => useContext(HealthContext);

export const HealthProvider = ({ children }) => {
    // --- Internal System Health State ---
    const [healthData, setHealthData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [refreshing, setRefreshing] = useState(false);
    const [error, setError] = useState(null);
    const [internalLatency, setInternalLatency] = useState(0);
    
    // --- External AI API State ---
    const [aiHealthData, setAiHealthData] = useState(null);
    const [aiModelData, setAiModelData] = useState(null);
    const [aiLoading, setAiLoading] = useState(true);
    const [aiRefreshing, setAiRefreshing] = useState(false);

    // --- Tea Yield AI State ---
    const [yieldHealthData, setYieldHealthData] = useState(null);
    const [yieldDbStats, setYieldDbStats] = useState(null);
    const [yieldLoading, setYieldLoading] = useState(true);
    const [yieldRefreshing, setYieldRefreshing] = useState(false);

    // --- Tea Maturity AI State ---
    const [maturityHealthData, setMaturityHealthData] = useState(null);
    const [maturityModelData, setMaturityModelData] = useState(null);
    const [maturityLoading, setMaturityLoading] = useState(true);
    const [maturityRefreshing, setMaturityRefreshing] = useState(false);

    // --- Main Web App State ---
    const [webAppHealthData, setWebAppHealthData] = useState(null);
    const [webAppLoading, setWebAppLoading] = useState(true);
    const [webAppRefreshing, setWebAppRefreshing] = useState(false);

    // --- Auth API State ---
    const [authHealthData, setAuthHealthData] = useState(null);
    const [authLoading, setAuthLoading] = useState(true);
    const [authRefreshing, setAuthRefreshing] = useState(false);

    // --- Environment IoT API State ---
    const [envIotHealthData, setEnvIotHealthData] = useState(null);
    const [envIotLoading, setEnvIotLoading] = useState(true);
    const [envIotRefreshing, setEnvIotRefreshing] = useState(false);

    // --- Soil IoT API State ---
    const [soilIotHealthData, setSoilIotHealthData] = useState(null);
    const [soilIotLoading, setSoilIotLoading] = useState(true);
    const [soilIotRefreshing, setSoilIotRefreshing] = useState(false);

    // --- Market/Powder API State ---
    const [marketHealthData, setMarketHealthData] = useState(null);
    const [marketLoading, setMarketLoading] = useState(true);
    const [marketRefreshing, setMarketRefreshing] = useState(false);

    // --- Terminal History State ---
    const [terminalHistory, setTerminalHistory] = useState([
        { type: 'info', content: 'System Health Monitor v1.0.0' },
        { type: 'info', content: 'Type "help" for a list of commands.' }
    ]);

    // --- Alert Cooldown State ---
    const lastAlertTime = useRef({
        db: 0,
        disease: 0,
        yield: 0,
        maturity: 0,
        webapp: 0
    });

    const triggerAlert = async (system, issues) => {
        const now = Date.now();
        const COOLDOWN = 5 * 60 * 1000; // 5 Minutes

        if (now - lastAlertTime.current[system] < COOLDOWN) return;

        try {
            await fetch('/api/admin/system-alert', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ systemName: system, issues })
            });
            lastAlertTime.current[system] = now;
            setTerminalHistory(prev => [...prev, { type: 'info', content: `[${new Date().toLocaleTimeString()}] 📧 Admin Alert Sent: ${system} failure.` }]);
        } catch (err) {
            console.error("Failed to send alert:", err);
        }
    };

    // --- Internal Health Check ---
    const checkHealth = async () => {
        setRefreshing(true);
        if (!healthData) setLoading(true);
        try {
            const start = Date.now();
            const response = await fetch('/api/health');
            const end = Date.now();
            if (!response.ok) throw new Error('Failed to fetch health status');
            const data = await response.json();
            setHealthData(data);
            setInternalLatency(end - start);
            setError(null);
        } catch (err) {
            console.error(err);
            setError('Could not connect to server');
            setHealthData({ status: 'error', dbState: 0, dbStateString: 'disconnected', timestamp: new Date(), uptime: 0 });
            triggerAlert('Internal Database', ['Server connection lost or MongoDB is down.']);
        } finally {
            setLoading(false);
            setRefreshing(false);
        }
    };

    // --- Disease AI Check ---
    const checkAiHealth = async () => {
        setAiRefreshing(true);
        if (!aiHealthData) setAiLoading(true);
        const baseUrl = 'https://tea-leaf-disease-api-prod.up.railway.app';
        try {
            const healthRes = await fetch(`${baseUrl}/health`);
            const healthData = await healthRes.json();
            let modelData = null;
            try {
                const modelRes = await fetch(`${baseUrl}/api/v1/inference/model-info`);
                if (modelRes.ok) modelData = await modelRes.json();
            } catch (e) { console.warn('Failed to display model info:', e); }
            setAiHealthData(healthData);
            setAiModelData(modelData);
        } catch (err) {
            console.error("AI API Error:", err);
            setAiHealthData(null);
            triggerAlert('Disease AI', ['Railway service is SLEEPING or UNREACHABLE.', 'Suggested: Manual wake-up required.']);
        } finally {
            setAiLoading(false);
            setAiRefreshing(false);
        }
    };

    // --- Yield AI Check ---
    const checkYieldHealth = async () => {
        setYieldRefreshing(true);
        if (!yieldHealthData) setYieldLoading(true);
        const baseUrl = 'https://iteagrow-tea-yield-prod.up.railway.app';
        try {
            const [rootRes, modelRes, dbRes] = await Promise.allSettled([
                fetch(`${baseUrl}/`),
                fetch(`${baseUrl}/health`),
                fetch(`${baseUrl}/database/status`)
            ]);
            const isRootOk = rootRes.status === 'fulfilled' && rootRes.value.ok;
            const isModelOk = modelRes.status === 'fulfilled' && modelRes.value.ok;
            let dbData = null;
            if (dbRes.status === 'fulfilled' && dbRes.value.ok) dbData = await dbRes.value.json();
            if (isRootOk || isModelOk) {
                setYieldHealthData({
                    status: 'operational',
                    api: isRootOk ? 'healthy' : 'degraded',
                    model: isModelOk ? 'healthy' : 'degraded',
                    database: dbData?.connected ? 'connected' : 'disconnected'
                });
                setYieldDbStats(dbData);
            } else { throw new Error('Yield Service Unreachable'); }
        } catch (err) {
            console.error("Yield API Error:", err);
            setYieldHealthData(null);
            setYieldDbStats(null);
            triggerAlert('Yield AI', ['Yield Predictor AI service is SLEEPING or UNREACHABLE.']);
        } finally {
            setYieldLoading(false);
            setYieldRefreshing(false);
        }
    };

    // --- Maturity AI Check ---
    const checkMaturityHealth = async () => {
        setMaturityRefreshing(true);
        if (!maturityHealthData) setMaturityLoading(true);
        const baseUrl = 'https://iteagrow-tea-leaf-maturity-prod.up.railway.app';
        try {
            const healthRes = await fetch(`${baseUrl}/health`);
            const healthData = await healthRes.json();
            let modelData = null;
            try {
                const modelRes = await fetch(`${baseUrl}/api/v1/model/info`);
                if (modelRes.ok) modelData = await modelRes.json();
            } catch (e) { console.warn('Failed to display maturity model info:', e); }
            setMaturityHealthData(healthData);
            setMaturityModelData(modelData);
        } catch (err) {
            console.error("Maturity API Error:", err);
            setMaturityHealthData(null);
            triggerAlert('Maturity AI', ['Maturity Classifier AI is UNREACHABLE.']);
        } finally {
            setMaturityLoading(false);
            setMaturityRefreshing(false);
        }
    };

    // --- Auth API Check ---
    const checkAuthHealth = async () => {
        setAuthRefreshing(true);
        if (!authHealthData) setAuthLoading(true);
        const baseUrl = 'https://authentication-iteagrow-api.up.railway.app';
        try {
            const start = Date.now();
            const res = await fetch(`${baseUrl}/health`);
            const end = Date.now();
            if (res.ok) {
                const data = await res.json();
                setAuthHealthData({ status: 'online', latency: end - start, ...data });
            } else throw new Error('Auth API not OK');
        } catch (err) {
            console.error('Auth API Error:', err);
            setAuthHealthData(null);
            triggerAlert('Auth API', ['Authentication service is UNREACHABLE.']);
        } finally {
            setAuthLoading(false);
            setAuthRefreshing(false);
        }
    };

    // --- Environment IoT API Check ---
    const checkEnvIotHealth = async () => {
        setEnvIotRefreshing(true);
        if (!envIotHealthData) setEnvIotLoading(true);
        const baseUrl = 'https://iteagrow-environment-monitoring-iot-api.up.railway.app';
        try {
            const start = Date.now();
            const res = await fetch(`${baseUrl}/health`);
            const end = Date.now();
            if (res.ok) {
                const data = await res.json();
                setEnvIotHealthData({ status: 'online', latency: end - start, ...data });
            } else throw new Error('Env IoT API not OK');
        } catch (err) {
            console.error('Env IoT API Error:', err);
            setEnvIotHealthData(null);
            triggerAlert('Environment IoT', ['Environment IoT API is UNREACHABLE.']);
        } finally {
            setEnvIotLoading(false);
            setEnvIotRefreshing(false);
        }
    };

    // --- Soil IoT API Check ---
    const checkSoilIotHealth = async () => {
        setSoilIotRefreshing(true);
        if (!soilIotHealthData) setSoilIotLoading(true);
        const baseUrl = 'https://iteagrow-soil-monitoring-iot-api.up.railway.app';
        try {
            const start = Date.now();
            const res = await fetch(`${baseUrl}/health`);
            const end = Date.now();
            if (res.ok) {
                const data = await res.json();
                setSoilIotHealthData({ status: 'online', latency: end - start, ...data });
            } else throw new Error('Soil IoT API not OK');
        } catch (err) {
            console.error('Soil IoT API Error:', err);
            setSoilIotHealthData(null);
            triggerAlert('Soil IoT', ['Soil Monitoring IoT API is UNREACHABLE.']);
        } finally {
            setSoilIotLoading(false);
            setSoilIotRefreshing(false);
        }
    };

    // --- Market/Powder API Check ---
    const checkMarketHealth = async () => {
        setMarketRefreshing(true);
        if (!marketHealthData) setMarketLoading(true);
        const baseUrl = 'https://tea-powder-classification-market-value-api.up.railway.app';
        try {
            const start = Date.now();
            const res = await fetch(`${baseUrl}/health`);
            const end = Date.now();
            if (res.ok) {
                const data = await res.json();
                setMarketHealthData({ status: 'online', latency: end - start, ...data });
            } else throw new Error('Market API not OK');
        } catch (err) {
            console.error('Market API Error:', err);
            setMarketHealthData(null);
            triggerAlert('Market API', ['Tea Powder Market API is UNREACHABLE.']);
        } finally {
            setMarketLoading(false);
            setMarketRefreshing(false);
        }
    };

    // --- Web App Check ---
    const checkWebAppHealth = async () => {
        setWebAppRefreshing(true);
        if (!webAppHealthData) setWebAppLoading(true);
        const baseUrl = 'https://iteagrow.up.railway.app';
        try {
            const start = Date.now();
            const res = await fetch(`${baseUrl}/api/health`, { mode: 'cors', headers: { 'Accept': 'application/json' } });
            const end = Date.now();
            if (res.ok) {
                const data = await res.json();
                setWebAppHealthData({ status: 'online', latency: end - start, timestamp: new Date().toISOString(), dbState: data.dbState });
            } else {
                const rootRes = await fetch(`${baseUrl}/`, { mode: 'no-cors' });
                setWebAppHealthData({ status: 'online (reachable)', latency: Date.now() - start, timestamp: new Date().toISOString() });
            }
        } catch (err) {
            console.error("Web App Health Check Failed:", err);
            setWebAppHealthData(null);
            triggerAlert('Main Web App', ['iTeaGrow Main Web App is OFFLINE.', 'Suggested: Check CORS and Railway deployment.']);
        } finally {
            setWebAppLoading(false);
            setWebAppRefreshing(false);
        }
    };

    const refreshAll = () => {
        checkHealth();
        checkAiHealth();
        checkYieldHealth();
        checkMaturityHealth();
        checkWebAppHealth();
        checkAuthHealth();
        checkEnvIotHealth();
        checkSoilIotHealth();
        checkMarketHealth();
    };

    useEffect(() => {
        refreshAll();
        const interval = setInterval(refreshAll, 30000);
        return () => clearInterval(interval);
    }, []);

    // --- Logging Effects (Build history in background) ---
    useEffect(() => {
        if (healthData && !loading) {
             setTerminalHistory(prev => [
                ...prev, 
                { type: 'success', content: `[${new Date().toLocaleTimeString()}] Internal Health Check: ${healthData.dbStateString?.toUpperCase() || 'UNKNOWN'}` }
            ]);
        }
    }, [healthData, loading]);

    useEffect(() => {
        if (!aiLoading) {
             const status = aiHealthData ? 'ONLINE' : 'OFFLINE/SLEEPING';
             const type = aiHealthData ? 'success' : 'error';
             setTerminalHistory(prev => [...prev, { type, content: `[${new Date().toLocaleTimeString()}] Disease AI Check: ${status}` }]);
        }
    }, [aiHealthData, aiLoading]);

    useEffect(() => {
        if (!yieldLoading) {
             const status = yieldHealthData ? 'ONLINE' : 'OFFLINE/SLEEPING';
             const type = yieldHealthData ? 'success' : 'error';
             setTerminalHistory(prev => [...prev, { type, content: `[${new Date().toLocaleTimeString()}] Yield AI Check: ${status}` }]);
        }
    }, [yieldHealthData, yieldLoading]);

    useEffect(() => {
        if (!maturityLoading) {
             const status = maturityHealthData ? 'ONLINE' : 'OFFLINE/SLEEPING';
             const type = maturityHealthData ? 'success' : 'error';
             setTerminalHistory(prev => [...prev, { type, content: `[${new Date().toLocaleTimeString()}] Maturity AI Check: ${status}` }]);
        }
    }, [maturityHealthData, maturityLoading]);

    useEffect(() => {
        if (!webAppLoading) {
             const status = webAppHealthData ? 'ONLINE' : 'OFFLINE/SLEEPING';
             const type = webAppHealthData ? 'success' : 'error';
             setTerminalHistory(prev => [...prev, { type, content: `[${new Date().toLocaleTimeString()}] Main Web App Check: ${status}` }]);
        }
    }, [webAppHealthData, webAppLoading]);

    useEffect(() => {
        if (!authLoading) {
            const status = authHealthData ? 'ONLINE' : 'OFFLINE';
            const type = authHealthData ? 'success' : 'error';
            setTerminalHistory(prev => [...prev, { type, content: `[${new Date().toLocaleTimeString()}] Auth API Check: ${status}` }]);
        }
    }, [authHealthData, authLoading]);

    useEffect(() => {
        if (!envIotLoading) {
            const status = envIotHealthData ? 'ONLINE' : 'OFFLINE';
            const type = envIotHealthData ? 'success' : 'error';
            setTerminalHistory(prev => [...prev, { type, content: `[${new Date().toLocaleTimeString()}] Environment IoT API Check: ${status}` }]);
        }
    }, [envIotHealthData, envIotLoading]);

    useEffect(() => {
        if (!soilIotLoading) {
            const status = soilIotHealthData ? 'ONLINE' : 'OFFLINE';
            const type = soilIotHealthData ? 'success' : 'error';
            setTerminalHistory(prev => [...prev, { type, content: `[${new Date().toLocaleTimeString()}] Soil IoT API Check: ${status}` }]);
        }
    }, [soilIotHealthData, soilIotLoading]);

    useEffect(() => {
        if (!marketLoading) {
            const status = marketHealthData ? 'ONLINE' : 'OFFLINE';
            const type = marketHealthData ? 'success' : 'error';
            setTerminalHistory(prev => [...prev, { type, content: `[${new Date().toLocaleTimeString()}] Market API Check: ${status}` }]);
        }
    }, [marketHealthData, marketLoading]);

    const value = {
        healthData, loading, refreshing, error, internalLatency,
        aiHealthData, aiModelData, aiLoading, aiRefreshing,
        yieldHealthData, yieldDbStats, yieldLoading, yieldRefreshing,
        maturityHealthData, maturityModelData, maturityLoading, maturityRefreshing,
        webAppHealthData, webAppLoading, webAppRefreshing,
        authHealthData, authLoading, authRefreshing,
        envIotHealthData, envIotLoading, envIotRefreshing,
        soilIotHealthData, soilIotLoading, soilIotRefreshing,
        marketHealthData, marketLoading, marketRefreshing,
        terminalHistory, setTerminalHistory,
        refreshAll, checkHealth, checkAiHealth, checkYieldHealth, checkMaturityHealth, checkWebAppHealth,
        checkAuthHealth, checkEnvIotHealth, checkSoilIotHealth, checkMarketHealth, triggerAlert
    };

    return <HealthContext.Provider value={value}>{children}</HealthContext.Provider>;
};
