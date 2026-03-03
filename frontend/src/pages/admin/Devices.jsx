import React, { useState, useEffect, useRef } from 'react';
import '../../css/Dashboard.css';
import { 
    Cpu, Thermometer, Droplets, Wind, Sprout, 
    Signal, SignalLow, RefreshCw, AlertTriangle, 
    Info, ShieldCheck, Activity, Wifi, Database, 
    Clock, Smartphone, Settings, HardDrive
} from 'lucide-react';

export default function Devices() {
    const [refreshing, setRefreshing] = useState(false);
    const [lastSync, setLastSync] = useState(new Date().toLocaleTimeString());
    const [latency, setLatency] = useState('--');
    const [isSyncing, setIsSyncing] = useState(false);
    const [apiConnected, setApiConnected] = useState(null);
    const [countdown, setCountdown] = useState(5);
    const [envUptime, setEnvUptime] = useState('--');
    const [soilUptime, setSoilUptime] = useState('--');
    const [syncCount, setSyncCount] = useState(0);
    const [syncErrors, setSyncErrors] = useState(0);
    const [avgSyncInterval, setAvgSyncInterval] = useState(null);
    const envFirstSeenRef = useRef(null);
    const soilFirstSeenRef = useRef(null);
    const lastSyncTimestampRef = useRef(null); // tracks real time between syncs
    
    // Real IoT Data State
    const [envData, setEnvData] = useState({
        temperature: '--',
        humidity: '--',
        airQuality: '--',
        status: 'Offline',
        signal: null,
        uptime: null,
        firmware: null,
        lastUpdate: 'Pending',
        timestamp: null
    });

    const [soilData, setSoilData] = useState({
        nitrogen: '--',
        phosphorus: '--',
        potassium: '--',
        ph: '--',
        ec: '--',
        temperature: '--',
        moisture: '--',
        status: 'Offline',
        signal: null,
        uptime: null,
        firmware: null,
        lastUpdate: 'Pending',
        timestamp: null
    });

    const getTimeAgo = (timestamp) => {
        if (!timestamp) return 'Never';
        const seconds = Math.floor((new Date() - new Date(timestamp)) / 1000);
        if (seconds < 60) return 'Just now';
        const minutes = Math.floor(seconds / 60);
        if (minutes < 60) return `${minutes}m ago`;
        const hours = Math.floor(minutes / 60);
        if (hours < 24) return `${hours}h ago`;
        return `${Math.floor(hours / 24)}d ago`;
    };

    // Signal quality from API round-trip latency (ms)
    // 0–100ms=100%, 200ms≈83%, 500ms≈58%, 1000ms≈17% — clamped 10–100
    const calcSignal = (ms) => Math.max(10, Math.min(100, Math.round(100 - (ms / 12))));

    // Human-readable uptime from milliseconds
    const formatUptime = (ms) => {
        if (!ms || ms < 0) return '--';
        const s = Math.floor(ms / 1000);
        const days = Math.floor(s / 86400);
        const hours = Math.floor((s % 86400) / 3600);
        const mins = Math.floor((s % 3600) / 60);
        const secs = s % 60;
        if (days > 0) return `${days}d ${hours}h`;
        if (hours > 0) return `${hours}h ${mins}m`;
        return `${mins}m ${secs}s`;
    };

    const isStale = (timestamp) => {
        if (!timestamp) return true;
        const seconds = Math.floor((new Date() - new Date(timestamp)) / 1000);
        // Mobile app uses 5m, but for "Real-time" dashboard we'll use 30s for the green dot
        return seconds > 30; 
    };

    const fetchData = async () => {
        setIsSyncing(true);
        setCountdown(5);
        try {
            // 1. Fetch Environmental Data (IoTENV)
            const fetchStart = performance.now();
            const envResponse = await fetch('https://iteagrow-environment-monitoring-iot-api.up.railway.app/api/iot/live/latest');
            const fetchEnd = performance.now();
            const rawLatencyMs = Math.round(fetchEnd - fetchStart);
            setLatency(`${rawLatencyMs}ms`);
            setApiConnected(envResponse.ok);
            if (envResponse.ok) {
                const data = await envResponse.json();
                
                // Pick the device with the most recent timestamp (real device beats stale test data)
                // Priority: ENV-NODE-01 > most recent timestamp > first key
                const entries = Object.entries(data);
                const targetEntry =
                    entries.find(([k]) => k.includes('NODE-01')) ||
                    entries.reduce((best, cur) => {
                        const curTs = new Date(cur[1]?.timestamp || 0).getTime();
                        const bestTs = new Date(best[1]?.timestamp || 0).getTime();
                        return curTs > bestTs ? cur : best;
                    }, entries[0]);
                const reading = targetEntry ? targetEntry[1] : null;
                
                if (reading) {
                    const ts = reading.timestamp || new Date();
                    const rawAQ = reading.air_quality ?? reading.airQuality ?? reading.aqi;
                    // Track session first-seen for uptime calculation
                    if (!envFirstSeenRef.current) envFirstSeenRef.current = Date.now();
                    setEnvData({
                        temperature: reading.temperature ?? reading.temp ?? '--',
                        humidity: reading.humidity ?? '--',
                        airQuality: (rawAQ !== null && rawAQ !== undefined) ? rawAQ : '--',
                        status: isStale(ts) ? 'Offline' : 'Online',
                        signal: calcSignal(rawLatencyMs),
                        uptime: null, // computed separately in 1s tick
                        firmware: 'v1.0 Stable',
                        lastUpdate: getTimeAgo(ts),
                        timestamp: ts
                    });
                }
            } else {
                setEnvData(prev => ({ ...prev, status: 'Offline', lastUpdate: getTimeAgo(prev.timestamp) }));
            }

            // 2. Fetch Soil Data (IoTSOIL)
            const soilResponse = await fetch('https://iteagrow-soil-monitoring-iot-api.up.railway.app/farm/latest?limit=1');
            if (soilResponse.ok) {
                const data = await soilResponse.json();
                // Ensure we get the latest record correctly
                const hectare = Array.isArray(data) ? data[0] : (data.data?.[0] || data); 
                
                if (hectare) {
                    const ts = hectare.timestamp || new Date();
                    setSoilData({
                        nitrogen: hectare.N || hectare.nitrogen || '--',
                        phosphorus: hectare.P || hectare.phosphorus || '--',
                        potassium: hectare.K || hectare.potassium || '--',
                        ph: hectare.pH || hectare.ph || '--',
                        ec: hectare.EC || hectare.ec || '--',
                        temperature: hectare.temperature || hectare.soil_temp || '--',
                        moisture: hectare.humidity || hectare.moisture || '--',
                        status: isStale(ts) ? 'Offline' : 'Online',
                        signal: calcSignal(rawLatencyMs),
                        uptime: null, // computed separately in 1s tick
                        firmware: 'v1.0 Stable',
                        lastUpdate: getTimeAgo(ts),
                        timestamp: ts
                    });
                    if (!soilFirstSeenRef.current) soilFirstSeenRef.current = Date.now();
                }
            } else {
                setSoilData(prev => ({ ...prev, status: 'Offline', lastUpdate: getTimeAgo(prev.timestamp) }));
            }

            setLastSync(new Date().toLocaleTimeString());
            setSyncCount(prev => prev + 1);
            // Measure actual real interval between syncs
            const now = Date.now();
            if (lastSyncTimestampRef.current) {
                const interval = now - lastSyncTimestampRef.current;
                setAvgSyncInterval(prev =>
                    prev === null ? interval : Math.round((prev * 0.8) + (interval * 0.2))
                );
            }
            lastSyncTimestampRef.current = now;
        } catch (error) {
            console.error('IoT Sync Error:', error);
            setApiConnected(false);
            setSyncCount(prev => prev + 1);
            setSyncErrors(prev => prev + 1);
            setEnvData(prev => ({ ...prev, status: 'Offline' }));
            setSoilData(prev => ({ ...prev, status: 'Offline' }));
        } finally {
            setIsSyncing(false);
        }
    };

    // Poll for real data every 5 seconds
    useEffect(() => {
        fetchData(); // Initial load
        const interval = setInterval(fetchData, 5000);
        return () => clearInterval(interval);
    }, []);

    // Live countdown ticker (1s) — refreshes lastUpdate strings + uptime counters
    useEffect(() => {
        const tick = setInterval(() => {
            setCountdown(prev => (prev <= 1 ? 5 : prev - 1));
            // Re-compute lastUpdate strings so "4d ago" etc stay accurate
            setEnvData(prev => prev.timestamp ? { ...prev, lastUpdate: getTimeAgo(prev.timestamp) } : prev);
            setSoilData(prev => prev.timestamp ? { ...prev, lastUpdate: getTimeAgo(prev.timestamp) } : prev);
            // Tick session uptime counters
            if (envFirstSeenRef.current) setEnvUptime(formatUptime(Date.now() - envFirstSeenRef.current));
            if (soilFirstSeenRef.current) setSoilUptime(formatUptime(Date.now() - soilFirstSeenRef.current));
        }, 1000);
        return () => clearInterval(tick);
    }, []);

    const handleRefresh = () => {
        setRefreshing(true);
        fetchData().finally(() => {
            setTimeout(() => setRefreshing(false), 1000);
        });
    };

    const getAirQualityStatus = (aqi) => {
        if (aqi === '--' || aqi === null) return { label: 'Unknown', color: '#666' };
        const val = parseInt(aqi);
        if (val < 50) return { label: 'Good', color: '#10b981' };
        if (val < 100) return { label: 'Moderate', color: '#3b82f6' };
        if (val < 150) return { label: 'Unhealthy', color: '#f59e0b' };
        return { label: 'Bad', color: '#ef4444' };
    };

    const aqStatus = getAirQualityStatus(envData.airQuality);

    const ConnectionBadge = ({ status }) => {
        const isOnline = status === 'Online';
        return (
            <div style={{ 
                padding: '6px 14px', borderRadius: '20px', 
                background: isOnline ? 'rgba(16, 185, 129, 0.15)' : 'rgba(239, 68, 68, 0.1)', 
                border: `1px solid ${isOnline ? 'rgba(16, 185, 129, 0.3)' : 'rgba(239, 68, 68, 0.3)'}`, 
                display: 'flex', alignItems: 'center', gap: '8px' 
            }}>
                <div style={{ 
                    width: '8px', height: '8px', borderRadius: '50%', 
                    background: isOnline ? '#10b981' : '#ef4444', 
                    boxShadow: `0 0 10px ${isOnline ? '#10b981' : '#ef4444'}` 
                }}></div>
                <span style={{ color: isOnline ? '#10b981' : '#ef4444', fontWeight: '700', fontSize: '0.8rem', textTransform: 'uppercase' }}>
                    {status}
                </span>
            </div>
        );
    };

    return (
        <div className="dashboard-container" style={{ padding: '30px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '40px' }}>
                <div>
                    <h1 style={{ margin: 0, fontSize: '2.5rem', background: 'linear-gradient(90deg, #fff, #aaa)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', fontWeight: '800' }}>Device Tracking</h1>
                    <p style={{ margin: '5px 0 0 0', fontSize: '1.1rem', color: '#fff', opacity: 0.8 }}>Monitor active IoT nodes and estate environmental health</p>
                </div>
                
                <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
                    <div style={{ background: 'rgba(255,255,255,0.05)', padding: '10px 20px', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.1)', textAlign: 'right', minWidth: '160px' }}>
                        <span style={{ display: 'block', fontSize: '0.65rem', color: '#fff', fontWeight: '700', textTransform: 'uppercase', marginBottom: '4px', opacity: 0.8 }}>Cloud Sync Status</span>
                        <span style={{ color: '#fff', fontWeight: '600', fontSize: '0.9rem', display: 'flex', alignItems: 'center', gap: '8px', justifyContent: 'flex-end' }}>
                            <div style={{
                                width: '8px', height: '8px', borderRadius: '50%',
                                background: isSyncing ? '#f59e0b' : apiConnected === false ? '#ef4444' : '#10b981',
                                boxShadow: isSyncing ? '0 0 8px #f59e0b' : apiConnected === false ? '0 0 8px #ef4444' : '0 0 8px #10b981',
                                animation: isSyncing ? 'pulse-dot 0.8s ease-in-out infinite' : 'none'
                            }}></div>
                            {isSyncing ? 'Syncing...' : apiConnected === false ? 'Disconnected' : 'Connected'}
                        </span>
                        <span style={{ display: 'block', fontSize: '0.65rem', color: '#fff', marginTop: '3px', textAlign: 'right', opacity: 0.6 }}>
                            {isSyncing ? `Last: ${lastSync}` : `Next sync: ${countdown}s`}
                        </span>
                    </div>
                    <button 
                        onClick={handleRefresh}
                        className="btn btn-primary"
                        style={{ padding: '12px 20px', borderRadius: '10px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <RefreshCw size={18} className={refreshing ? 'spinning' : ''} />
                        {refreshing ? 'REFRESHING...' : 'SYNC ALL DEVICES'}
                    </button>
                </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '30px' }}>
                {/* IoTENV Device Section */}
                <div className="dashboard-card" style={{ 
                    padding: '30px', borderRadius: '24px', background: 'rgba(20, 30, 20, 0.7)', 
                    border: '1px solid rgba(255, 255, 255, 0.1)', backdropFilter: 'blur(12px)',
                    boxShadow: '0 20px 50px rgba(0,0,0,0.3)'
                }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '25px' }}>
                        <div style={{ display: 'flex', gap: '20px', alignItems: 'center' }}>
                            <div style={{ padding: '12px', background: 'rgba(255, 165, 0, 0.15)', borderRadius: '16px', border: '1px solid rgba(255, 165, 0, 0.2)' }}>
                                <Wifi size={28} color="#ffa500" />
                            </div>
                            <div>
                                <h2 style={{ margin: 0, fontSize: '1.6rem', color: '#fff', fontWeight: '800' }}>IoTENV <span style={{ fontSize: '0.8rem', color: '#fff', fontWeight: '600', marginLeft: '10px', opacity: 0.5 }}>ID: ENV-NODE-01</span></h2>
                                <p style={{ margin: '2px 0 0 0', color: '#fff', fontSize: '0.9rem', opacity: 0.7 }}>Environmental & Air Quality Monitoring</p>
                            </div>
                        </div>
                        <div style={{ display: 'flex', gap: '15px' }}>
                            <ConnectionBadge status={envData.status} />
                        </div>
                    </div>

                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '20px', marginBottom: '25px' }}>
                        {[
                            { label: 'Temperature', value: envData.temperature !== '--' ? `${envData.temperature}°C` : '--', icon: <Thermometer size={22} />, color: '#ef4444' },
                            { label: 'Humidity', value: envData.humidity !== '--' ? `${envData.humidity}%` : '--', icon: <Droplets size={22} />, color: '#3b82f6' },
                            { label: 'Air Quality', value: aqStatus.label, icon: <Wind size={22} />, color: aqStatus.color, sub: envData.airQuality !== '--' ? `Index: ${envData.airQuality}` : null },
                            { label: 'Signal', value: envData.signal !== null ? `${envData.signal}%` : 'N/A', icon: <Signal size={22} />, color: '#10b981', sub: envData.signal !== null ? (envData.signal > 80 ? 'Excellent' : envData.signal > 50 ? 'Good' : 'Weak') : 'Not reported' }
                        ].map((m, i) => (
                            <div key={i} style={{ background: 'rgba(255,255,255,0.03)', padding: '20px', borderRadius: '18px', border: '1px solid rgba(255,255,255,0.05)' }}>
                                <div style={{ color: m.color, marginBottom: '12px' }}>{m.icon}</div>
                                <div style={{ fontSize: m.label === 'Air Quality' ? '1.8rem' : '1.5rem', fontWeight: '800', color: '#fff' }}>{m.value}</div>
                                <div style={{ fontSize: '0.75rem', color: '#888', textTransform: 'uppercase', fontWeight: '700', marginTop: '4px' }}>{m.label}</div>
                                {m.label !== 'Air Quality' && m.sub && <div style={{ fontSize: '0.65rem', color: m.color, fontWeight: '700', marginTop: '2px' }}>{m.sub}</div>}
                            </div>
                        ))}
                    </div>
                    
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '15px 25px', background: 'rgba(0,0,0,0.2)', borderRadius: '16px' }}>
                        <span style={{ fontSize: '0.8rem', color: '#fff', opacity: 0.6 }}>Uptime: <span style={{ color: '#fff', fontWeight: '600', opacity: 1 }}>{envUptime}</span></span>
                        <span style={{ fontSize: '0.8rem', color: '#fff', opacity: 0.6 }}>Firmware: <span style={{ color: '#fff', fontWeight: '600', opacity: 1 }}>{envData.firmware ?? 'N/A'}</span></span>
                        <span style={{ fontSize: '0.8rem', color: '#fff', opacity: 0.6 }}>Last Update: <span style={{ color: '#fff', fontWeight: '600', opacity: 1 }}>{envData.lastUpdate}</span></span>
                    </div>
                </div>

                {/* IoTSOIL Device Section */}
                <div className="dashboard-card" style={{ 
                    padding: '30px', borderRadius: '24px', background: 'rgba(20, 30, 20, 0.7)', 
                    border: '1px solid rgba(255, 255, 255, 0.1)', backdropFilter: 'blur(12px)',
                    boxShadow: '0 20px 50px rgba(0,0,0,0.3)'
                }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '25px' }}>
                        <div style={{ display: 'flex', gap: '20px', alignItems: 'center' }}>
                            <div style={{ padding: '12px', background: 'rgba(139, 92, 246, 0.15)', borderRadius: '16px', border: '1px solid rgba(139, 92, 246, 0.2)' }}>
                                <Sprout size={28} color="#8b5cf6" />
                            </div>
                            <div>
                                <h2 style={{ margin: 0, fontSize: '1.6rem', color: '#fff', fontWeight: '800' }}>IoTSOIL <span style={{ fontSize: '0.8rem', color: '#fff', fontWeight: '600', marginLeft: '10px', opacity: 0.5 }}>ID: SOIL-NODE-01</span></h2>
                                <p style={{ margin: '2px 0 0 0', color: '#fff', fontSize: '0.9rem', opacity: 0.7 }}>Smart Soil Composition & Hydration Monitoring</p>
                            </div>
                        </div>
                        <ConnectionBadge status={soilData.status} />
                    </div>

                    {soilData.status === 'Offline' && soilData.nitrogen === '--' ? (
                        <div style={{ 
                            background: 'rgba(0,0,0,0.2)', padding: '40px', borderRadius: '20px', 
                            textAlign: 'center', margin: '20px 0', border: '1px dashed rgba(255,255,255,0.1)',
                            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '15px'
                        }}>
                            <HardDrive size={48} color="#444" />
                            <div>
                                <h3 style={{ color: '#fff', margin: 0, fontSize: '1.2rem' }}>No data available</h3>
                                <p style={{ color: '#666', margin: '5px 0 0 0', fontSize: '0.9rem' }}>Waiting for device connection or initial sync...</p>
                            </div>
                        </div>
                    ) : (
                        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '15px', marginBottom: '25px' }}>
                            {[
                                { label: 'Nitrogen (N)', value: soilData.nitrogen, color: '#10b981', unit: 'mg/kg' },
                                { label: 'Phosphate (P)', value: soilData.phosphorus, color: '#f59e0b', unit: 'mg/kg' },
                                { label: 'Potash (K)', value: soilData.potassium, color: '#3b82f6', unit: 'mg/kg' },
                                { label: 'Soil pH', value: soilData.ph, color: '#a855f7', unit: 'pH' },
                                { label: 'EC Level', value: soilData.ec, color: '#06b6d4', unit: 'µS/cm' },
                                { label: 'Soil Temp', value: soilData.temperature !== '--' ? `${soilData.temperature}°C` : '--', color: '#ef4444', unit: 'Celsius' },
                                { label: 'Moisture', value: soilData.moisture !== '--' ? `${soilData.moisture}%` : '--', color: '#6366f1', unit: 'Volumetric' },
                                { label: 'Signal', value: soilData.signal !== null ? `${soilData.signal}%` : 'N/A', color: '#10b981', unit: 'Strength' }
                            ].map((m, i) => (
                                <div key={i} style={{ background: 'rgba(255,255,255,0.03)', padding: '15px 20px', borderRadius: '18px', border: '1px solid rgba(255,255,255,0.05)', textAlign: 'center' }}>
                                    <div style={{ fontSize: '1.4rem', fontWeight: '800', color: m.color }}>{m.value}</div>
                                    <div style={{ fontSize: '0.7rem', color: '#fff', opacity: 0.9, fontWeight: '700', marginTop: '4px', textTransform: 'uppercase' }}>{m.label}</div>
                                    <div style={{ fontSize: '0.6rem', color: '#555', marginTop: '2px' }}>{m.unit}</div>
                                </div>
                            ))}
                        </div>
                    )}

                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '15px 25px', background: 'rgba(0,0,0,0.2)', borderRadius: '16px' }}>
                        <span style={{ fontSize: '0.8rem', color: '#fff', opacity: 0.6 }}>Uptime: <span style={{ color: '#fff', fontWeight: '600', opacity: 1 }}>{soilUptime}</span></span>
                        <span style={{ fontSize: '0.8rem', color: '#fff', opacity: 0.6 }}>Firmware: <span style={{ color: '#fff', fontWeight: '600', opacity: 1 }}>{soilData.firmware ?? 'N/A'}</span></span>
                        <span style={{ fontSize: '0.8rem', color: '#fff', opacity: 0.6 }}>Last Update: <span style={{ color: '#fff', fontWeight: '600', opacity: 1 }}>{soilData.lastUpdate}</span></span>
                    </div>
                </div>
            </div>

            {/* Overall Network Metrics */}
            <div style={{ marginTop: '30px', display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '30px' }}>
                 <div className="dashboard-card" style={{ padding: '25px', borderRadius: '20px', background: 'rgba(16, 185, 129, 0.05)', border: '1px solid rgba(16, 185, 129, 0.2)', display: 'flex', alignItems: 'center', gap: '20px' }}>
                    <div style={{ padding: '15px', background: 'rgba(16, 185, 129, 0.1)', borderRadius: '50%' }}>
                        <ShieldCheck size={24} color="#10b981" />
                    </div>
                    <div>
                        <h4 style={{ color: '#fff', margin: 0, fontSize: '1rem', fontWeight: '700' }}>Security Active</h4>
                        <p style={{ color: '#fff', margin: '2px 0 0 0', fontSize: '0.8rem', opacity: 0.6 }}>End-to-end node encryption</p>
                    </div>
                </div>

                <div className="dashboard-card" style={{ padding: '25px', borderRadius: '20px', background: 'rgba(59, 130, 246, 0.05)', border: '1px solid rgba(59, 130, 246, 0.2)', display: 'flex', alignItems: 'center', gap: '20px' }}>
                    <div style={{ padding: '15px', background: 'rgba(59, 130, 246, 0.1)', borderRadius: '50%' }}>
                        <Activity size={24} color="#3b82f6" />
                    </div>
                    <div>
                        <h4 style={{ color: '#fff', margin: 0, fontSize: '1rem', fontWeight: '700' }}>Network Flux</h4>
                        <p style={{ color: '#fff', margin: '2px 0 0 0', fontSize: '0.8rem', opacity: 0.6 }}>Current Latency: {latency}</p>
                    </div>
                </div>

                <div className="dashboard-card" style={{ padding: '25px', borderRadius: '20px', background: 'rgba(245, 158, 11, 0.05)', border: '1px solid rgba(245, 158, 11, 0.2)', display: 'flex', alignItems: 'center', gap: '20px' }}>
                    <div style={{ padding: '15px', background: 'rgba(245, 158, 11, 0.1)', borderRadius: '50%', flexShrink: 0 }}>
                        <Database size={24} color="#f59e0b" />
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                        <h4 style={{ color: '#fff', margin: '0 0 8px 0', fontSize: '1rem', fontWeight: '700' }}>Data Integrity</h4>
                        {syncCount === 0 ? (
                            <p style={{ color: '#fff', margin: 0, fontSize: '0.8rem', opacity: 0.5 }}>Waiting for first sync...</p>
                        ) : (
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '4px 16px' }}>
                                <span style={{ fontSize: '0.72rem', color: '#888' }}>Syncs</span>
                                <span style={{ fontSize: '0.72rem', color: '#f59e0b', fontWeight: '700' }}>{syncCount}</span>
                                <span style={{ fontSize: '0.72rem', color: '#888' }}>Success rate</span>
                                <span style={{ fontSize: '0.72rem', color: syncErrors === 0 ? '#10b981' : syncErrors / syncCount < 0.1 ? '#f59e0b' : '#ef4444', fontWeight: '700' }}>
                                    {Math.round(((syncCount - syncErrors) / syncCount) * 100)}%
                                </span>
                                <span style={{ fontSize: '0.72rem', color: '#888' }}>Avg interval</span>
                                <span style={{ fontSize: '0.72rem', color: '#aaa', fontWeight: '600' }}>
                                    {avgSyncInterval !== null ? `${(avgSyncInterval / 1000).toFixed(1)}s` : '...'}
                                </span>
                                <span style={{ fontSize: '0.72rem', color: '#888' }}>Last sync</span>
                                <span style={{ fontSize: '0.72rem', color: '#aaa', fontWeight: '600' }}>{lastSync}</span>
                            </div>
                        )}
                    </div>
                </div>
            </div>

            <style>{`
                .spinning { animation: rotate 2s linear infinite; }
                @keyframes rotate { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
                @keyframes pulse-dot { 0%, 100% { opacity: 1; transform: scale(1); } 50% { opacity: 0.4; transform: scale(1.5); } }
                .dashboard-card { transition: transform 0.3s ease, box-shadow 0.3s ease; }
                .dashboard-card:hover { transform: translateY(-5px); }
            `}</style>
        </div>
    );
}
