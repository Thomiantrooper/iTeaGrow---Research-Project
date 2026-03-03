import React, { useState, useEffect, useRef } from 'react';
import { Server, Database, Activity, RefreshCw, CheckCircle, XCircle, AlertTriangle, Clock, ChevronLeft, ChevronRight, BookOpen, Leaf, Power, Layers, Zap, ChevronDown, ChevronUp, Wifi, WifiOff } from 'lucide-react';
import { useHealth } from '../../context/HealthContext';
import '../../css/Dashboard.css';

const SystemHealth = () => {
    const {
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
        checkAuthHealth, checkEnvIotHealth, checkSoilIotHealth, checkMarketHealth
    } = useHealth();

    // --- Sidebar State ---
    const [isDocsOpen, setIsDocsOpen] = useState(false);

    // --- UI State ---
    const [showAiSection, setShowAiSection] = useState(false);
    const [showYieldSection, setShowYieldSection] = useState(false);
    const [showMaturitySection, setShowMaturitySection] = useState(false);

    const formatUptime = (seconds) => {
        const d = Math.floor(seconds / (3600*24));
        const h = Math.floor(seconds % (3600*24) / 3600);
        const m = Math.floor(seconds % 3600 / 60);
        const s = Math.floor(seconds % 60);
        
        let result = [];
        if (d > 0) result.push(`${d}d`);
        if (h > 0) result.push(`${h}h`);
        if (m > 0) result.push(`${m}m`);
        if (s > 0) result.push(`${s}s`);
        
        return result.join(' ') || '0s';
    };

    const getStatusColor = (state) => {
        switch(state) {
            case 1: return '#2ecc71'; // Connected (Green)
            case 2: return '#f39c12'; // Connecting (Orange)
            case 3: return '#f39c12'; // Disconnecting (Orange)
            default: return '#e74c3c'; // Disconnected (Red)
        }
    };

    // --- Terminal Logic ---
    const [terminalInput, setTerminalInput] = useState('');

    const handleTerminalSubmit = async (e) => {
        if (e.key === 'Enter') {
            const command = terminalInput.trim().toLowerCase();
            const newHistory = [...terminalHistory, { type: 'input', content: command }];
            
            setTerminalInput('');

            switch (command) {
                case 'help':
                    newHistory.push({ type: 'response', content: 'Available commands:\n  help              - Show this help message\n  status            - Check internal system status\n  refresh           - Refresh all connection data\n  disease_ai_status - Check/Wake Up Disease AI\n  yield_ai_status   - Check/Wake Up Yield AI\n  maturity_ai_status - Check/Wake Up Maturity AI\n  webapp_status     - Check Main Web App\n  auth_api_status   - Check Authentication API\n  env_iot_status    - Check Environment IoT API\n  soil_iot_status   - Check Soil Monitoring IoT API\n  market_ai_status  - Check Market/Powder AI API\n  clear             - Clear terminal history\n  docs              - Open documentation sidebar' });
                    break;
                case 'status':
                    newHistory.push({ type: 'response', content: 'Checking internal system status...' });
                    setTerminalHistory(newHistory);
                    await checkHealth();
                    return; 
                case 'refresh':
                    newHistory.push({ type: 'response', content: 'Refreshing all systems...' });
                    setTerminalHistory(newHistory);
                    await checkHealth();
                    await checkAiHealth();
                    await checkYieldHealth();
                    await checkMaturityHealth();
                    await checkWebAppHealth();
                    await checkAuthHealth();
                    await checkEnvIotHealth();
                    await checkSoilIotHealth();
                    await checkMarketHealth();
                    return;
                case 'disease_ai_status':
                case 'wake_disease_ai':
                    newHistory.push({ type: 'response', content: 'Pinging Tea Leaf Disease AI Service...' });
                    setTerminalHistory(newHistory);
                    await checkAiHealth();
                    return;
                case 'yield_ai_status':
                case 'wake_yield_ai':
                    newHistory.push({ type: 'response', content: 'Pinging Tea Yield AI Service...' });
                    setTerminalHistory(newHistory);
                    await checkYieldHealth();
                    return;
                case 'maturity_ai_status':
                case 'wake_maturity_ai':
                    newHistory.push({ type: 'response', content: 'Pinging Tea Maturity AI Service...' });
                    setTerminalHistory(newHistory);
                    await checkMaturityHealth();
                    return;
                case 'webapp_status':
                case 'wake_webapp':
                    newHistory.push({ type: 'response', content: 'Pinging Main Web Application...' });
                    setTerminalHistory(newHistory);
                    await checkWebAppHealth();
                    return;
                case 'auth_api_status':
                    newHistory.push({ type: 'response', content: 'Pinging Authentication API...' });
                    setTerminalHistory(newHistory);
                    await checkAuthHealth();
                    return;
                case 'env_iot_status':
                    newHistory.push({ type: 'response', content: 'Pinging Environment IoT API...' });
                    setTerminalHistory(newHistory);
                    await checkEnvIotHealth();
                    return;
                case 'soil_iot_status':
                    newHistory.push({ type: 'response', content: 'Pinging Soil Monitoring IoT API...' });
                    setTerminalHistory(newHistory);
                    await checkSoilIotHealth();
                    return;
                case 'market_ai_status':
                    newHistory.push({ type: 'response', content: 'Pinging Tea Powder Market API...' });
                    setTerminalHistory(newHistory);
                    await checkMarketHealth();
                    return;
                case 'troubleshoot':
                case 'debug':
                case 'show_issues':
                    newHistory.push({ type: 'info', content: 'Running System Diagnostics...' });
                    const issues = [];
                    
                    // Check Web App
                    if (!webAppHealthData) {
                        issues.push('Web App is OFFLINE. Suggested: Check Railway deployment and verify backend CORS settings.');
                    } else if (webAppHealthData.status.includes('reachable')) {
                        issues.push('Web App CORS Warning: API is reachable but Restricted. Suggested: Push CORS update to production backend.');
                    }

                    // Check Internal DB
                    if (healthData?.dbStateString !== 'connected') {
                        issues.push(`Internal Database: ${healthData?.dbStateString || 'DISCONNECTED'}. Suggested: Check MongoDB URI in backend .env.`);
                    }

                    // Check Disease AI
                    if (!aiHealthData) {
                        issues.push('Disease AI: SLEEPING. Suggested: Click "Wake All Systems" or wait 60s for cold boot.');
                    }

                    // Check Yield AI
                    if (!yieldHealthData) {
                        issues.push('Yield AI: SLEEPING. Suggested: Check Yield service at Railway dashboard.');
                    }

                    // Check Maturity AI
                    if (maturityHealthData?.status !== 'healthy' && !maturityLoading) {
                        issues.push('Maturity AI: UNREACHABLE. Suggested: Verify deployment at iteagrow-tea-leaf-maturity-prod.up.railway.app.');
                    }

                    // Check Auth API
                    if (authHealthData?.status !== 'healthy' && !authLoading) {
                        issues.push('Auth API: UNREACHABLE. Suggested: Verify Railway deployment at authentication-iteagrow-api.up.railway.app.');
                    }

                    // Check Env IoT API
                    if (envIotHealthData?.status !== 'healthy' && !envIotLoading) {
                        issues.push('Env IoT API: UNREACHABLE. Suggested: Verify Railway deployment at iteagrow-environment-monitoring-iot-api.up.railway.app.');
                    }

                    // Check Soil IoT API
                    if (soilIotHealthData?.status !== 'healthy' && !soilIotLoading) {
                        issues.push('Soil IoT API: UNREACHABLE. Suggested: Verify Railway deployment at iteagrow-soil-monitoring-iot-api.up.railway.app.');
                    }

                    // Check Market AI
                    if (marketHealthData?.status !== 'healthy' && !marketLoading) {
                        issues.push('Market AI: UNREACHABLE. Suggested: Verify Railway deployment at tea-powder-classification-market-value-api.up.railway.app.');
                    }

                    if (issues.length === 0) {
                        newHistory.push({ type: 'success', content: '✓ No critical issues detected. All systems nominal.' });
                    } else {
                        newHistory.push({ type: 'error', content: `Found ${issues.length} active issues:` });
                        issues.forEach(issue => newHistory.push({ type: 'response', content: `• ${issue}` }));
                    }
                    setTerminalHistory(newHistory);
                    return;
                case 'clear':
                    setTerminalHistory([]);
                    return;
                case 'docs':
                     newHistory.push({ type: 'response', content: 'Opening documentation...' });
                     setIsDocsOpen(true);
                     break;
                case '':
                    break;
                default:
                    newHistory.push({ type: 'error', content: `Command not found: ${command}. Type "help" for commands.` });
            }
            setTerminalHistory(newHistory);
        }
    };

    return (
        <div
            className="dashboard-container"
            style={{
                position: 'relative',
                maxWidth: '100%',
                width: '100%',
                margin: 0,
                padding: '0 10px',
                boxSizing: 'border-box'
            }}
        >
            <header className="dashboard-header" style={{ marginBottom: '40px' }}>
                <div>
                    <h1 style={{ fontSize: '2.5rem', background: 'linear-gradient(90deg, #fff, #aaa)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>System Health</h1>
                    <p className="dashboard-subtitle" style={{ fontSize: '1.1rem' }}>Real-time infrastructure monitoring & status.</p>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '12px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        {/* Wake All Systems - Icon Button */}
                        <button 
                            onClick={() => { 
                                setTerminalHistory(prev => [...prev, { type: 'info', content: `[${new Date().toLocaleTimeString()}] Initiating Manual Wake-Up for All Systems...` }]);
                                refreshAll();
                            }} 
                            disabled={aiRefreshing || yieldRefreshing || maturityRefreshing || webAppRefreshing || authRefreshing || envIotRefreshing || soilIotRefreshing || marketRefreshing}
                            title="Wake All Systems"
                            style={{ 
                                background: 'rgba(255, 255, 255, 0.05)',
                                border: '1px solid rgba(46, 204, 113, 0.3)',
                                color: '#2ecc71',
                                padding: '10px',
                                borderRadius: '10px',
                                cursor: 'pointer',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                transition: 'all 0.3s ease',
                                opacity: (aiRefreshing || yieldRefreshing || maturityRefreshing || webAppRefreshing) ? 0.6 : 1
                            }}
                            onMouseEnter={(e) => {
                                if (!(aiRefreshing || yieldRefreshing || maturityRefreshing || webAppRefreshing)) {
                                    e.currentTarget.style.background = 'rgba(46, 204, 113, 0.15)';
                                    e.currentTarget.style.transform = 'translateY(-2px)';
                                    e.currentTarget.style.boxShadow = '0 4px 12px rgba(46, 204, 113, 0.3)';
                                }
                            }}
                            onMouseLeave={(e) => {
                                e.currentTarget.style.background = 'rgba(255, 255, 255, 0.05)';
                                e.currentTarget.style.transform = 'translateY(0)';
                                e.currentTarget.style.boxShadow = 'none';
                            }}
                        >
                            <Power size={20} className={(aiRefreshing || yieldRefreshing || maturityRefreshing || webAppRefreshing) ? 'spin' : ''} />
                        </button>
                        
                        {/* Refresh Status - Icon Button */}
                        <button 
                            onClick={checkHealth} 
                            disabled={refreshing}
                            title="Refresh Status"
                            style={{ 
                                background: 'rgba(46, 204, 113, 0.2)',
                                border: '1px solid rgba(46, 204, 113, 0.4)',
                                color: '#2ecc71',
                                padding: '10px',
                                borderRadius: '10px',
                                cursor: 'pointer',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                transition: 'all 0.3s ease',
                                boxShadow: refreshing ? '0 0 20px rgba(46, 204, 113, 0.4)' : 'none',
                                opacity: refreshing ? 0.8 : 1
                            }}
                            onMouseEnter={(e) => {
                                if (!refreshing) {
                                    e.currentTarget.style.background = 'rgba(46, 204, 113, 0.3)';
                                    e.currentTarget.style.transform = 'translateY(-2px)';
                                    e.currentTarget.style.boxShadow = '0 4px 12px rgba(46, 204, 113, 0.3)';
                                }
                            }}
                            onMouseLeave={(e) => {
                                e.currentTarget.style.background = 'rgba(46, 204, 113, 0.2)';
                                e.currentTarget.style.transform = 'translateY(0)';
                                e.currentTarget.style.boxShadow = 'none';
                            }}
                        >
                            <RefreshCw size={20} className={refreshing ? 'spin' : ''} />
                        </button>
                    </div>

                    {/* Live Status Indicator */}
                    {healthData && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <div className="ping-dot"></div>
                            <span style={{ color: '#aaa', fontSize: '0.85rem', fontWeight: '500' }}>
                                Live | Last update: {new Date(healthData.timestamp).toLocaleTimeString()}
                            </span>
                        </div>
                    )}
                </div>
            </header>

            {/* --- Internal Health Grid --- */}
            <div className="dashboard-grid" style={{ display: 'flex', gap: '30px', flexWrap: 'wrap' }}>
                
                {/* Unified System Status Card (App | DB | AI + IoT Services) */}
                <div className="dashboard-card stat-card modern-card" style={{ 
                    flex: '1 1 100%',
                    minWidth: '100%',
                    position: 'relative', 
                    overflow: 'hidden', 
                    display: 'flex', 
                    flexDirection: 'column', 
                    padding: 0 
                }}>
                    <div className="card-bg-glow" style={{ background: 'linear-gradient(45deg, #2ecc71, #27ae60, #16a085)' }}></div>
                    
                    {/* Top: Responsive grid of service tiles */}
                    <div
                        className="service-grid"
                        style={{
                            padding: '20px',
                            borderBottom: '1px solid rgba(255,255,255,0.05)'
                        }}
                    >
                        
                        {/* Column 0: Main Web App */}
                        <div style={{ 
                            padding: '18px', 
                            borderRadius: '12px',
                            background: 'rgba(0,0,0,0.28)',
                            display: 'flex',
                            flexDirection: 'column',
                            justifyContent: 'center'
                        }}>
                             <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
                                <div className="stat-icon-wrapper" style={{ 
                                    background: webAppHealthData ? '#2ecc7120' : 'rgba(255,255,255,0.05)',
                                    width: '32px', height: '32px', borderRadius: '8px', padding: '6px'
                                }}>
                                    <Activity size={20} color={webAppHealthData ? '#2ecc71' : '#ccc'} />
                                </div>
                                <h3 className="card-title" style={{ margin: 0, fontSize: '0.85rem', color: '#aaa', letterSpacing: '0.5px', whiteSpace: 'nowrap' }}>WEB APP</h3>
                            </div>
                            <div style={{ fontSize: '1.2rem', fontWeight: 'bold', color: webAppHealthData ? '#2ecc71' : '#e74c3c', whiteSpace: 'nowrap' }}>
                                {webAppLoading ? 'CHECKING...' : (webAppHealthData ? 'ONLINE' : 'OFFLINE')}
                            </div>
                             <div style={{ fontSize: '0.8rem', color: '#666', marginTop: '4px', whiteSpace: 'nowrap' }}>
                                {webAppHealthData ? `${webAppHealthData.latency}ms Latency` : 'Check Logs'}
                            </div>
                        </div>

                        {/* Column 1: Database (Static) */}
                        <div style={{ 
                            padding: '18px',
                            borderRadius: '12px',
                            background: 'rgba(0,0,0,0.28)',
                            display: 'flex',
                            flexDirection: 'column',
                            justifyContent: 'center'
                        }}>
                             <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
                                <div className="stat-icon-wrapper" style={{ 
                                    background: healthData ? getStatusColor(healthData.dbState) + '20' : 'rgba(255,255,255,0.05)',
                                    width: '32px', height: '32px', borderRadius: '8px', padding: '6px'
                                }}>
                                    <Database size={20} color={healthData ? getStatusColor(healthData.dbState) : '#ccc'} />
                                </div>
                                <h3 className="card-title" style={{ margin: 0, fontSize: '0.85rem', color: '#aaa', letterSpacing: '0.5px', whiteSpace: 'nowrap' }}>DATABASE</h3>
                            </div>
                            <div style={{ fontSize: '1.2rem', fontWeight: 'bold', color: healthData ? getStatusColor(healthData.dbState) : '#ccc', whiteSpace: 'nowrap' }}>
                                {loading ? 'CHECKING...' : (healthData?.dbState === 1 ? 'CONNECTED' : 'ISSUES')}
                            </div>
                             <div style={{ fontSize: '0.8rem', color: '#666', marginTop: '4px', whiteSpace: 'nowrap' }}>
                                {healthData?.dbState === 1 ? 'Operational' : 'Check Logs'}
                            </div>
                        </div>

                        {/* Column 2: Disease AI (Toggle) */}
                            <div 
                            onClick={(e) => { e.stopPropagation(); setShowAiSection(!showAiSection); }}
                            style={{ 
                                padding: '18px', 
                                borderRadius: '12px',
                                cursor: 'pointer', 
                                transition: 'background 0.3s',
                                background: showAiSection ? 'rgba(46, 204, 113, 0.14)' : 'rgba(0,0,0,0.28)',
                                display: 'flex',
                                flexDirection: 'column',
                                justifyContent: 'center'
                            }}
                        >
                             <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                    <div className="stat-icon-wrapper" style={{ background: 'rgba(46, 204, 113, 0.1)', width: '32px', height: '32px', borderRadius: '8px', padding: '6px' }}>
                                        <Server size={20} color="#2ecc71" />
                                    </div>
                                    <h3 className="card-title" style={{ margin: 0, fontSize: '0.85rem', color: '#aaa', letterSpacing: '0.5px', whiteSpace: 'nowrap' }}>DISEASE AI</h3>
                                </div>
                                 <div style={{ background: 'rgba(255,255,255,0.1)', borderRadius: '50%', width: '26px', height: '26px', display: 'flex', alignItems: 'center', justifyContent: 'center', marginLeft: '8px' }}>
                                     {showAiSection ? <ChevronUp size={14} color="rgba(255,255,255,0.7)" /> : <ChevronDown size={14} color="rgba(255,255,255,0.7)" />}
                                </div>
                            </div>
                            <div style={{ fontSize: '1.2rem', fontWeight: 'bold', color: aiHealthData ? '#2ecc71' : '#e74c3c', whiteSpace: 'nowrap' }}>
                                {aiHealthData ? 'ONLINE' : 'OFFLINE'}
                            </div>
                            <div style={{ fontSize: '0.8rem', color: '#666', marginTop: '4px', whiteSpace: 'nowrap' }}>
                                Click for details
                            </div>
                        </div>

                        {/* Column 3: Yield AI (Toggle) */}
                        <div 
                            onClick={(e) => { e.stopPropagation(); setShowYieldSection(!showYieldSection); }}
                            style={{ 
                                padding: '18px', 
                                borderRadius: '12px',
                                cursor: 'pointer', 
                                transition: 'background 0.3s',
                                background: showYieldSection ? 'rgba(46, 204, 113, 0.14)' : 'rgba(0,0,0,0.28)',
                                display: 'flex',
                                flexDirection: 'column',
                                justifyContent: 'center'
                            }}
                        >
                            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                                 <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                    <div className="stat-icon-wrapper" style={{ background: 'rgba(46, 204, 113, 0.1)', width: '32px', height: '32px', borderRadius: '8px', padding: '6px' }}>
                                        <Layers size={20} color="#2ecc71" />
                                    </div>
                                    <h3 className="card-title" style={{ margin: 0, fontSize: '0.85rem', color: '#aaa', letterSpacing: '0.5px', whiteSpace: 'nowrap' }}>YIELD AI</h3>
                                </div>
                                 <div style={{ background: 'rgba(255,255,255,0.1)', borderRadius: '50%', width: '26px', height: '26px', display: 'flex', alignItems: 'center', justifyContent: 'center', marginLeft: '8px' }}>
                                     {showYieldSection ? <ChevronUp size={14} color="rgba(255,255,255,0.7)" /> : <ChevronDown size={14} color="rgba(255,255,255,0.7)" />}
                                </div>
                            </div>
                            <div style={{ fontSize: '1.2rem', fontWeight: 'bold', color: yieldHealthData ? '#2ecc71' : '#e74c3c', whiteSpace: 'nowrap' }}>
                                {yieldHealthData ? 'ONLINE' : 'OFFLINE'}
                            </div>
                             <div style={{ fontSize: '0.8rem', color: '#666', marginTop: '4px', whiteSpace: 'nowrap' }}>
                                Click for details
                            </div>
                        </div>

                        {/* Column 4: Maturity AI (Toggle) */}
                        <div 
                            onClick={(e) => { e.stopPropagation(); setShowMaturitySection(!showMaturitySection); }}
                            style={{ 
                                padding: '18px', 
                                borderRadius: '12px',
                                cursor: 'pointer', 
                                transition: 'background 0.3s',
                                background: showMaturitySection ? 'rgba(46, 204, 113, 0.14)' : 'rgba(0,0,0,0.28)',
                                display: 'flex',
                                flexDirection: 'column',
                                justifyContent: 'center'
                            }}
                        >
                            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                                 <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                    <div className="stat-icon-wrapper" style={{ background: 'rgba(46, 204, 113, 0.1)', width: '32px', height: '32px', borderRadius: '8px', padding: '6px' }}>
                                        <Leaf size={20} color="#2ecc71" />
                                    </div>
                                    <h3 className="card-title" style={{ margin: 0, fontSize: '0.85rem', color: '#aaa', letterSpacing: '0.5px', whiteSpace: 'nowrap' }}>MATURITY AI</h3>
                                </div>
                                <div style={{ background: 'rgba(255,255,255,0.1)', borderRadius: '50%', width: '26px', height: '26px', display: 'flex', alignItems: 'center', justifyContent: 'center', marginLeft: '8px' }}>
                                     {showMaturitySection ? <ChevronUp size={14} color="rgba(255,255,255,0.7)" /> : <ChevronDown size={14} color="rgba(255,255,255,0.7)" />}
                                </div>
                            </div>
                            <div style={{ fontSize: '1.2rem', fontWeight: 'bold', color: maturityHealthData ? '#2ecc71' : '#e74c3c', whiteSpace: 'nowrap' }}>
                                {maturityHealthData ? 'ONLINE' : 'OFFLINE'}
                            </div>
                             <div style={{ fontSize: '0.8rem', color: '#666', marginTop: '4px', whiteSpace: 'nowrap' }}>
                                Click for details
                            </div>
                        </div>

                        {/* Column 5: Auth API */}
                        <div style={{ 
                            padding: '18px', 
                            borderRadius: '12px',
                            background: 'rgba(0,0,0,0.28)',
                            display: 'flex',
                            flexDirection: 'column',
                            justifyContent: 'center'
                        }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
                                <div className="stat-icon-wrapper" style={{ 
                                    background: authHealthData ? '#2ecc7120' : 'rgba(255,255,255,0.05)',
                                    width: '32px', height: '32px', borderRadius: '8px', padding: '6px'
                                }}>
                                    <Power size={20} color={authHealthData ? '#2ecc71' : '#ccc'} />
                                </div>
                                <h3 className="card-title" style={{ margin: 0, fontSize: '0.85rem', color: '#aaa', letterSpacing: '0.5px', whiteSpace: 'nowrap' }}>AUTH API</h3>
                            </div>
                            <div style={{ fontSize: '1.2rem', fontWeight: 'bold', color: authHealthData ? '#2ecc71' : '#e74c3c', whiteSpace: 'nowrap' }}>
                                {authLoading ? 'CHECKING...' : (authHealthData ? 'ONLINE' : 'OFFLINE')}
                            </div>
                            <div style={{ fontSize: '0.8rem', color: '#666', marginTop: '4px', whiteSpace: 'nowrap' }}>
                                {authHealthData ? `${authHealthData.latency}ms Latency` : 'Check Logs'}
                            </div>
                        </div>

                        {/* Column 6: Environment IoT API */}
                        <div style={{ 
                            padding: '18px', 
                            borderRadius: '12px',
                            background: 'rgba(0,0,0,0.28)',
                            display: 'flex',
                            flexDirection: 'column',
                            justifyContent: 'center'
                        }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
                                <div className="stat-icon-wrapper" style={{ 
                                    background: envIotHealthData ? '#2ecc7120' : 'rgba(255,255,255,0.05)',
                                    width: '32px', height: '32px', borderRadius: '8px', padding: '6px'
                                }}>
                                    <Wifi size={20} color={envIotHealthData ? '#2ecc71' : '#ccc'} />
                                </div>
                                <h3 className="card-title" style={{ margin: 0, fontSize: '0.85rem', color: '#aaa', letterSpacing: '0.5px', whiteSpace: 'nowrap' }}>ENV IOT</h3>
                            </div>
                            <div style={{ fontSize: '1.2rem', fontWeight: 'bold', color: envIotHealthData ? '#2ecc71' : '#e74c3c', whiteSpace: 'nowrap' }}>
                                {envIotLoading ? 'CHECKING...' : (envIotHealthData ? 'ONLINE' : 'OFFLINE')}
                            </div>
                            <div style={{ fontSize: '0.8rem', color: '#666', marginTop: '4px', whiteSpace: 'nowrap' }}>
                                {envIotHealthData ? `${envIotHealthData.latency}ms Latency` : 'Check Logs'}
                            </div>
                        </div>

                        {/* Column 7: Soil IoT API */}
                        <div style={{ 
                            padding: '18px', 
                            borderRadius: '12px',
                            background: 'rgba(0,0,0,0.28)',
                            display: 'flex',
                            flexDirection: 'column',
                            justifyContent: 'center'
                        }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
                                <div className="stat-icon-wrapper" style={{ 
                                    background: soilIotHealthData ? '#2ecc7120' : 'rgba(255,255,255,0.05)',
                                    width: '32px', height: '32px', borderRadius: '8px', padding: '6px'
                                }}>
                                    <Zap size={20} color={soilIotHealthData ? '#2ecc71' : '#ccc'} />
                                </div>
                                <h3 className="card-title" style={{ margin: 0, fontSize: '0.85rem', color: '#aaa', letterSpacing: '0.5px', whiteSpace: 'nowrap' }}>SOIL IOT</h3>
                            </div>
                            <div style={{ fontSize: '1.2rem', fontWeight: 'bold', color: soilIotHealthData ? '#2ecc71' : '#e74c3c', whiteSpace: 'nowrap' }}>
                                {soilIotLoading ? 'CHECKING...' : (soilIotHealthData ? 'ONLINE' : 'OFFLINE')}
                            </div>
                            <div style={{ fontSize: '0.8rem', color: '#666', marginTop: '4px', whiteSpace: 'nowrap' }}>
                                {soilIotHealthData ? `${soilIotHealthData.latency}ms Latency` : 'Check Logs'}
                            </div>
                        </div>

                        {/* Column 8: Market/Powder AI */}
                        <div style={{ 
                            padding: '18px', 
                            borderRadius: '12px',
                            background: 'rgba(0,0,0,0.28)',
                            display: 'flex',
                            flexDirection: 'column',
                            justifyContent: 'center'
                        }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
                                <div className="stat-icon-wrapper" style={{ 
                                    background: marketHealthData ? '#2ecc7120' : 'rgba(255,255,255,0.05)',
                                    width: '32px', height: '32px', borderRadius: '8px', padding: '6px'
                                }}>
                                    <BookOpen size={20} color={marketHealthData ? '#2ecc71' : '#ccc'} />
                                </div>
                                <h3 className="card-title" style={{ margin: 0, fontSize: '0.85rem', color: '#aaa', letterSpacing: '0.5px', whiteSpace: 'nowrap' }}>MARKET AI</h3>
                            </div>
                            <div style={{ fontSize: '1.2rem', fontWeight: 'bold', color: marketHealthData ? '#2ecc71' : '#e74c3c', whiteSpace: 'nowrap' }}>
                                {marketLoading ? 'CHECKING...' : (marketHealthData ? 'ONLINE' : 'OFFLINE')}
                            </div>
                            <div style={{ fontSize: '0.8rem', color: '#666', marginTop: '4px', whiteSpace: 'nowrap' }}>
                                {marketHealthData ? `${marketHealthData.latency}ms Latency` : 'Check Logs'}
                            </div>
                        </div>
                    </div>
                </div>

                {/* System Uptime & Comprehensive Diagnostics */}
                <div className="dashboard-card stat-card modern-card" style={{ flex: '1 1 100%', minWidth: '100%', padding: 0, overflow: 'hidden' }}>
                     <div className="card-bg-glow" style={{ background: 'linear-gradient(135deg, #9b59b6, #8e44ad, #2c3e50)' }}></div>
                     
                     <div style={{ display: 'flex', width: '100%', height: '100%', minHeight: '120px' }}>
                        
                        {/* Column 1: UPTIME */}
                        <div style={{ flex: 1, padding: '24px', display: 'flex', alignItems: 'center', gap: '20px', borderRight: '1px solid rgba(255,255,255,0.05)' }}>
                            <div className="stat-icon-wrapper" style={{ background: 'rgba(155, 89, 182, 0.1)', width: '48px', height: '48px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <Clock size={24} color="#9b59b6" />
                            </div>
                            <div className="stat-content">
                                <span className="card-title" style={{ fontSize: '0.75rem', color: '#aaa', letterSpacing: '1px', textTransform: 'uppercase' }}>UPTIME</span>
                                <div style={{ fontSize: '1.6rem', color: 'white', fontWeight: 'bold', margin: '2px 0' }}>
                                    {healthData ? formatUptime(healthData.uptime) : '...'}
                                </div>
                                <p style={{ margin: 0, fontSize: '0.75rem', color: '#666' }}>Continuous Operation</p>
                            </div>
                        </div>

                        {/* Column 2: NETWORK STATUS */}
                        <div style={{ flex: 1, padding: '24px', display: 'flex', alignItems: 'center', gap: '20px', borderRight: '1px solid rgba(255,255,255,0.05)' }}>
                            <div className="stat-icon-wrapper" style={{ background: healthData ? 'rgba(46, 204, 113, 0.1)' : 'rgba(231, 76, 60, 0.1)', width: '48px', height: '48px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                {healthData ? <Wifi size={24} color="#2ecc71" className="ping-anim" /> : <WifiOff size={24} color="#e74c3c" />}
                            </div>
                            <div className="stat-content">
                                <span className="card-title" style={{ fontSize: '0.75rem', color: '#aaa', letterSpacing: '1px', textTransform: 'uppercase' }}>NETWORK</span>
                                <div style={{ fontSize: '1.6rem', color: healthData ? '#2ecc71' : '#e74c3c', fontWeight: 'bold', margin: '2px 0' }}>
                                    {healthData ? 'UP' : 'DOWN'}
                                </div>
                                <p style={{ margin: 0, fontSize: '0.75rem', color: '#666' }}>{healthData ? 'Connected to Gateway' : 'Link Failure'}</p>
                            </div>
                        </div>

                        {/* Column 3: INTERNAL LATENCY */}
                        <div style={{ flex: 1, padding: '24px', display: 'flex', alignItems: 'center', gap: '20px', borderRight: '1px solid rgba(255,255,255,0.05)' }}>
                            <div className="stat-icon-wrapper" style={{ background: 'rgba(52, 152, 219, 0.1)', width: '48px', height: '48px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <Activity size={24} color="#3498db" />
                            </div>
                            <div className="stat-content">
                                <span className="card-title" style={{ fontSize: '0.75rem', color: '#aaa', letterSpacing: '1px', textTransform: 'uppercase' }}>LATENCY</span>
                                <div style={{ fontSize: '1.6rem', color: '#3498db', fontWeight: 'bold', margin: '2px 0' }}>
                                    {internalLatency}ms
                                </div>
                                <p style={{ margin: 0, fontSize: '0.75rem', color: '#666' }}>Backplane Response</p>
                            </div>
                        </div>

                        {/* Column 4: TCP/IP ADDRESS */}
                        <div style={{ flex: 1, padding: '24px', display: 'flex', alignItems: 'center', gap: '20px' }}>
                            <div className="stat-icon-wrapper" style={{ background: 'rgba(255, 255, 255, 0.05)', width: '48px', height: '48px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <Server size={24} color="#fff" />
                            </div>
                            <div className="stat-content">
                                <span className="card-title" style={{ fontSize: '0.75rem', color: '#aaa', letterSpacing: '1px', textTransform: 'uppercase' }}>TCP IP</span>
                                <div style={{ fontSize: '1.4rem', color: '#fff', fontWeight: '500', margin: '2px 0', fontFamily: 'monospace' }}>
                                    {healthData?.ip || '127.0.0.1'}
                                </div>
                                <p style={{ margin: 0, fontSize: '0.75rem', color: '#666' }}>Host Identifier</p>
                            </div>
                        </div>

                     </div>
                </div>
            </div>

            {/* --- AI API Section (Collapsible) --- */}
            {showAiSection && (
                <div style={{ marginTop: '50px', marginBottom: '30px', animation: 'fadeIn 0.5s ease' }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
                            <Leaf size={28} color="#2ecc71" />
                            <h2 style={{ fontSize: '1.8rem', color: '#fff', margin: 0, textShadow: '0 2px 4px rgba(0,0,0,0.5)' }}>
                                Tea Leaf Disease AI
                            </h2>
                            {aiHealthData ? (
                                <span style={{ 
                                    background: 'rgba(46, 204, 113, 0.2)', 
                                    color: '#2ecc71', 
                                    padding: '4px 12px', 
                                    borderRadius: '20px', 
                                    fontSize: '0.8rem', 
                                    border: '1px solid rgba(46, 204, 113, 0.5)',
                                    fontWeight: '700',
                                    boxShadow: '0 2px 5px rgba(0,0,0,0.3)',
                                    backdropFilter: 'blur(4px)'
                                }}>
                                    OPERATIONAL
                                </span>
                            ) : (
                                <span style={{ 
                                    background: 'rgba(231, 76, 60, 0.1)', 
                                    color: '#e74c3c', 
                                    padding: '4px 12px', 
                                    borderRadius: '20px', 
                                    fontSize: '0.8rem', 
                                    border: '1px solid rgba(231, 76, 60, 0.2)',
                                    fontWeight: '600'
                                }}>
                                    {aiLoading ? 'CONNECTING...' : 'SLEEPING / OFFLINE'}
                                </span>
                            )}
                            <button onClick={() => setShowAiSection(false)} style={{ background: 'none', border: 'none', color: '#666', cursor: 'pointer', marginLeft: '10px' }} title="Close Section">
                                <XCircle size={20} />
                            </button>
                        </div>
                    </div>

                    <div className="dashboard-grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '20px' }}>
                        
                        {/* Model Info */}
                        <div className="dashboard-card modern-card" style={{ background: 'linear-gradient(145deg, rgba(20,20,20,0.8), rgba(10,40,20,0.6))' }}>
                             <div style={{ display: 'flex', alignItems: 'center', gap: '15px', marginBottom: '20px' }}>
                                <div className="stat-icon-wrapper" style={{ background: 'rgba(46, 204, 113, 0.1)', width: '50px', height: '50px', borderRadius: '12px' }}>
                                    <Layers size={24} color="#2ecc71" />
                                </div>
                                <div>
                                    <h3 className="card-title" style={{ margin: 0, fontSize: '0.9rem' }}>AI MODEL</h3>
                                    <div style={{ fontSize: '1.2rem', fontWeight: 'bold', color: 'white' }}>
                                        {aiModelData?.model_name || 'Detecting...'}
                                    </div>
                                </div>
                            </div>
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px' }}>
                                 <div style={{ background: 'rgba(0,0,0,0.2)', padding: '10px', borderRadius: '8px' }}>
                                    <div style={{ fontSize: '0.8rem', color: '#aaa', marginBottom: '4px' }}>Version</div>
                                    <div style={{ color: '#fff', fontSize: '0.95rem' }}>{aiModelData?.model_version || '-'}</div>
                                 </div>
                                 <div style={{ background: 'rgba(0,0,0,0.2)', padding: '10px', borderRadius: '8px' }}>
                                    <div style={{ fontSize: '0.8rem', color: '#aaa', marginBottom: '4px' }}>Classes</div>
                                    <div style={{ color: '#fff', fontSize: '0.95rem' }}>{aiModelData?.classes?.length || 0} Types</div>
                                 </div>
                            </div>
                        </div>

                        {/* AI Services Status */}
                        <div className="dashboard-card modern-card">
                            <div style={{ display: 'flex', alignItems: 'center', gap: '15px', marginBottom: '20px' }}>
                                 <div className="stat-icon-wrapper" style={{ background: 'rgba(46, 204, 113, 0.1)', width: '50px', height: '50px', borderRadius: '12px' }}>
                                    <Zap size={24} color="#2ecc71" />
                                </div>
                                <h3 className="card-title" style={{ margin: 0, fontSize: '0.9rem' }}>SERVICE STATUS</h3>
                            </div>
                            
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                                {/* Inference Engine */}
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px', background: 'rgba(255,255,255,0.03)', borderRadius: '8px' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                        <div className={`status-indicator ${aiHealthData?.services?.inference === 'healthy' ? 'pulse-green' : ''}`} 
                                             style={{ background: aiHealthData?.services?.inference === 'healthy' ? '#2ecc71' : '#e74c3c' }}></div>
                                        <span style={{ color: '#eee' }}>Inference Engine</span>
                                    </div>
                                    <span style={{ 
                                        color: aiHealthData?.services?.inference === 'healthy' ? '#2ecc71' : '#e74c3c', 
                                        fontWeight: '600',
                                        fontSize: '0.85rem'
                                    }}>
                                        {aiHealthData?.services?.inference?.toUpperCase() || 'UNAVAILABLE'}
                                    </span>
                                </div>

                                {/* Database */}
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px', background: 'rgba(255,255,255,0.03)', borderRadius: '8px' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                        <div className={`status-indicator ${aiHealthData?.services?.database === 'healthy' ? 'pulse-green' : ''}`} 
                                             style={{ background: aiHealthData?.services?.database === 'healthy' ? '#2ecc71' : '#f39c12' }}></div>
                                        <span style={{ color: '#eee' }}>Detection History DB</span>
                                    </div>
                                    <span style={{ 
                                        color: aiHealthData?.services?.database === 'healthy' ? '#2ecc71' : '#f39c12', 
                                        fontWeight: '600',
                                        fontSize: '0.85rem'
                                    }}>
                                        {aiHealthData?.services?.database  ? aiHealthData.services.database.toUpperCase() : 'UNKNOWN'}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}



            {/* --- Yield AI Section (Collapsible) --- */}
            {showYieldSection && (
                <div style={{ marginTop: '50px', marginBottom: '30px', animation: 'fadeIn 0.5s ease', borderTop: '1px solid rgba(46, 204, 113, 0.2)', paddingTop: '30px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
                            <Leaf size={28} color="#2ecc71" />
                            <h2 style={{ fontSize: '1.8rem', color: '#fff', margin: 0, textShadow: '0 2px 4px rgba(0,0,0,0.5)' }}>
                                Tea Yield Predictor AI
                            </h2>
                            {yieldHealthData ? (
                                <span style={{ 
                                    background: 'rgba(46, 204, 113, 0.2)', 
                                    color: '#2ecc71', 
                                    padding: '4px 12px', 
                                    borderRadius: '20px', 
                                    fontSize: '0.8rem', 
                                    border: '1px solid rgba(46, 204, 113, 0.5)',
                                    fontWeight: '700',
                                    boxShadow: '0 2px 5px rgba(0,0,0,0.3)',
                                    backdropFilter: 'blur(4px)'
                                }}>
                                    OPERATIONAL
                                </span>
                            ) : (
                                <span style={{ 
                                    background: 'rgba(231, 76, 60, 0.1)', 
                                    color: '#e74c3c', 
                                    padding: '4px 12px', 
                                    borderRadius: '20px', 
                                    fontSize: '0.8rem', 
                                    border: '1px solid rgba(231, 76, 60, 0.2)',
                                    fontWeight: '600'
                                }}>
                                    {yieldLoading ? 'CONNECTING...' : 'SLEEPING / OFFLINE'}
                                </span>
                            )}
                            <button onClick={() => setShowYieldSection(false)} style={{ background: 'none', border: 'none', color: '#666', cursor: 'pointer', marginLeft: '10px' }} title="Close Section">
                                <XCircle size={20} />
                            </button>
                        </div>
                    </div>

                    <div className="dashboard-grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '20px' }}>
                        
                        {/* Yield AI Model Info */}
                        <div className="dashboard-card modern-card" style={{ background: 'linear-gradient(145deg, rgba(20,20,20,0.8), rgba(20,40,30,0.6))' }}>
                             <div style={{ display: 'flex', alignItems: 'center', gap: '15px', marginBottom: '20px' }}>
                                <div className="stat-icon-wrapper" style={{ background: 'rgba(46, 204, 113, 0.1)', width: '50px', height: '50px', borderRadius: '12px' }}>
                                    <Activity size={24} color="#2ecc71" />
                                </div>
                                <div>
                                    <h3 className="card-title" style={{ margin: 0, fontSize: '0.9rem' }}>YIELD PREDICTOR</h3>
                                    <div style={{ fontSize: '1.2rem', fontWeight: 'bold', color: 'white' }}>
                                        LSTM-RNN Ensemble
                                    </div>
                                </div>
                            </div>
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px' }}>
                                 <div style={{ background: 'rgba(0,0,0,0.2)', padding: '10px', borderRadius: '8px' }}>
                                    <div style={{ fontSize: '0.8rem', color: '#aaa', marginBottom: '4px' }}>Version</div>
                                    <div style={{ color: '#fff', fontSize: '0.95rem' }}>2.0.0</div>
                                 </div>
                                 <div style={{ background: 'rgba(0,0,0,0.2)', padding: '10px', borderRadius: '8px' }}>
                                    <div style={{ fontSize: '0.8rem', color: '#aaa', marginBottom: '4px' }}>Accuracy R²</div>
                                    <div style={{ color: '#fff', fontSize: '0.95rem' }}>77.3%</div>
                                 </div>
                            </div>
                        </div>

                        {/* Yield AI Services Status */}
                        <div className="dashboard-card modern-card">
                            <div style={{ display: 'flex', alignItems: 'center', gap: '15px', marginBottom: '20px' }}>
                                 <div className="stat-icon-wrapper" style={{ background: 'rgba(52, 152, 219, 0.1)', width: '50px', height: '50px', borderRadius: '12px' }}>
                                    <Zap size={24} color="#3498db" />
                                </div>
                                <h3 className="card-title" style={{ margin: 0, fontSize: '0.9rem' }}>SERVICE STATUS</h3>
                            </div>
                            
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                                {/* Inference API */}
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px', background: 'rgba(255,255,255,0.03)', borderRadius: '8px' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                        <div className={`status-indicator ${yieldHealthData?.api === 'healthy' ? 'pulse-green' : ''}`} 
                                             style={{ background: yieldHealthData?.api === 'healthy' ? '#2ecc71' : '#e74c3c' }}></div>
                                        <span style={{ color: '#eee' }}>Yield Prediction API</span>
                                    </div>
                                    <span style={{ 
                                        color: yieldHealthData?.api === 'healthy' ? '#2ecc71' : '#e74c3c', 
                                        fontWeight: '600',
                                        fontSize: '0.85rem'
                                    }}>
                                        {yieldHealthData?.api?.toUpperCase() || 'UNAVAILABLE'}
                                    </span>
                                </div>

                                {/* Predictions Database */}
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px', background: 'rgba(255,255,255,0.03)', borderRadius: '8px' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                        <div className={`status-indicator ${yieldHealthData?.database === 'connected' ? 'pulse-green' : ''}`} 
                                             style={{ background: yieldHealthData?.database === 'connected' ? '#2ecc71' : '#f39c12' }}></div>
                                        <span style={{ color: '#eee' }}>Predictions DB</span>
                                    </div>
                                    <span style={{ 
                                        color: yieldHealthData?.database === 'connected' ? '#2ecc71' : '#f39c12', 
                                        fontWeight: '600',
                                        fontSize: '0.85rem'
                                    }}>
                                        {yieldHealthData?.database?.toUpperCase() || 'DISCONNECTED'}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* --- Maturity AI Section (Collapsible) --- */}
            {showMaturitySection && (
                <div style={{ marginTop: '50px', marginBottom: '30px', animation: 'fadeIn 0.5s ease', borderTop: '1px solid rgba(46, 204, 113, 0.2)', paddingTop: '30px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
                            <Activity size={28} color="#2ecc71" />
                            <h2 style={{ fontSize: '1.8rem', color: '#fff', margin: 0, textShadow: '0 2px 4px rgba(0,0,0,0.5)' }}>
                                Tea Leaf Maturity AI
                            </h2>
                            {maturityHealthData?.status === 'healthy' ? (
                                <span style={{ 
                                    background: 'rgba(46, 204, 113, 0.2)', 
                                    color: '#2ecc71', 
                                    padding: '4px 12px', 
                                    borderRadius: '20px', 
                                    fontSize: '0.8rem', 
                                    border: '1px solid rgba(46, 204, 113, 0.5)',
                                    fontWeight: '700',
                                    boxShadow: '0 2px 5px rgba(0,0,0,0.3)',
                                    backdropFilter: 'blur(4px)'
                                }}>
                                    OPERATIONAL
                                </span>
                            ) : (
                                <span style={{ 
                                    background: 'rgba(231, 76, 60, 0.1)', 
                                    color: '#e74c3c', 
                                    padding: '4px 12px', 
                                    borderRadius: '20px', 
                                    fontSize: '0.8rem', 
                                    border: '1px solid rgba(231, 76, 60, 0.2)',
                                    fontWeight: '600'
                                }}>
                                    {maturityLoading ? 'CONNECTING...' : 'SLEEPING / OFFLINE'}
                                </span>
                            )}
                            <button onClick={() => setShowMaturitySection(false)} style={{ background: 'none', border: 'none', color: '#666', cursor: 'pointer', marginLeft: '10px' }} title="Close Section">
                                <XCircle size={20} />
                            </button>
                        </div>
                    </div>

                    <div className="dashboard-grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '20px' }}>
                        
                        {/* Maturity AI Model Info */}
                        <div className="dashboard-card modern-card" style={{ background: 'linear-gradient(145deg, rgba(20,20,20,0.8), rgba(20,40,30,0.6))' }}>
                             <div style={{ display: 'flex', alignItems: 'center', gap: '15px', marginBottom: '20px' }}>
                                <div className="stat-icon-wrapper" style={{ background: 'rgba(46, 204, 113, 0.1)', width: '50px', height: '50px', borderRadius: '12px' }}>
                                    <Layers size={24} color="#2ecc71" />
                                </div>
                                <div>
                                    <h3 className="card-title" style={{ margin: 0, fontSize: '0.9rem' }}>MATURITY CLASSIFIER</h3>
                                    <div style={{ fontSize: '1.2rem', fontWeight: 'bold', color: 'white' }}>
                                        {maturityModelData?.model_type || 'ShuffleNetV2 x1.0'}
                                    </div>
                                </div>
                            </div>
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px' }}>
                                 <div style={{ background: 'rgba(0,0,0,0.2)', padding: '10px', borderRadius: '8px' }}>
                                    <div style={{ fontSize: '0.8rem', color: '#aaa', marginBottom: '4px' }}>Version</div>
                                    <div style={{ color: '#fff', fontSize: '0.95rem' }}>{maturityModelData?.model_version || '1.0.0'}</div>
                                 </div>
                                 <div style={{ background: 'rgba(0,0,0,0.2)', padding: '10px', borderRadius: '8px' }}>
                                    <div style={{ fontSize: '0.8rem', color: '#aaa', marginBottom: '4px' }}>Input Size</div>
                                    <div style={{ color: '#fff', fontSize: '0.95rem' }}>{maturityModelData?.input_size || '224px'}</div>
                                 </div>
                            </div>
                        </div>

                        {/* Maturity AI Services Status */}
                        <div className="dashboard-card modern-card">
                            <div style={{ display: 'flex', alignItems: 'center', gap: '15px', marginBottom: '20px' }}>
                                 <div className="stat-icon-wrapper" style={{ background: 'rgba(46, 204, 113, 0.1)', width: '50px', height: '50px', borderRadius: '12px' }}>
                                    <Zap size={24} color="#2ecc71" />
                                </div>
                                <h3 className="card-title" style={{ margin: 0, fontSize: '0.9rem' }}>SERVICE STATUS</h3>
                            </div>
                            
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                                {/* Inference API */}
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px', background: 'rgba(255,255,255,0.03)', borderRadius: '8px' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                        <div className={`status-indicator ${maturityHealthData?.status === 'healthy' ? 'pulse-green' : ''}`} 
                                             style={{ background: maturityHealthData?.status === 'healthy' ? '#2ecc71' : '#e74c3c' }}></div>
                                        <span style={{ color: '#eee' }}>Inference API</span>
                                    </div>
                                    <span style={{ 
                                        color: maturityHealthData?.status === 'healthy' ? '#2ecc71' : '#e74c3c', 
                                        fontWeight: '600',
                                        fontSize: '0.85rem'
                                    }}>
                                        {maturityHealthData?.status?.toUpperCase() || 'UNAVAILABLE'}
                                    </span>
                                </div>

                                {/* Maturity Database */}
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px', background: 'rgba(255,255,255,0.03)', borderRadius: '8px' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                        <div className={`status-indicator ${maturityHealthData?.database === 'healthy' ? 'pulse-green' : ''}`} 
                                             style={{ background: (maturityHealthData?.database === 'healthy' || maturityHealthData?.database === 'connected') ? '#2ecc71' : '#f39c12' }}></div>
                                        <span style={{ color: '#eee' }}>Maturity DB</span>
                                    </div>
                                    <span style={{ 
                                        color: (maturityHealthData?.database === 'healthy' || maturityHealthData?.database === 'connected') ? '#2ecc71' : '#f39c12', 
                                        fontWeight: '600',
                                        fontSize: '0.85rem'
                                    }}>
                                        {maturityHealthData?.database?.toUpperCase() || 'UNKNOWN'}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Interactive Terminal */}
            <div className="dashboard-card" style={{ marginTop: '30px', background: '#0a0a0a', border: '1px solid #333' }}>
                <div className="card-header" style={{ borderBottom: '1px solid #333', paddingBottom: '15px', marginBottom: '0' }}>
                     <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <div style={{ display: 'flex', gap: '6px' }}>
                            <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#ff5f56' }}></div>
                            <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#ffbd2e' }}></div>
                            <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#27c93f' }}></div>
                        </div>
                        <h3 style={{ marginLeft: '10px', fontSize: '0.9rem', fontFamily: 'monospace', color: '#aaa', fontWeight: '400' }}>admin-terminal</h3>
                     </div>
                </div>
                
                <div style={{ padding: '20px', fontFamily: '"Fira Code", monospace', fontSize: '0.9rem', height: '300px', overflowY: 'auto', display: 'flex', flexDirection: 'column' }} onClick={() => document.getElementById('terminal-input').focus()}>
                    {terminalHistory.map((entry, index) => (
                        <div key={index} style={{ marginBottom: '5px', whiteSpace: 'pre-wrap' }}>
                             {entry.type === 'input' && <span style={{ color: '#2ecc71', marginRight: '8px' }}>root@iteagrow:~$</span>}
                             {entry.type === 'error' && <span style={{ color: '#e74c3c' }}>{entry.content}</span>}
                             {entry.type === 'success' && <span style={{ color: '#2ecc71' }}>{entry.content}</span>}
                             {entry.type === 'info' && <span style={{ color: '#3498db' }}>{entry.content}</span>}
                             {entry.type === 'response' && <span style={{ color: '#ccc' }}>{entry.content}</span>}
                             {entry.type === 'input' && <span style={{ color: '#fff' }}>{entry.content}</span>}
                        </div>
                    ))}
                    
                    <div style={{ display: 'flex', alignItems: 'center' }}>
                        <span style={{ color: '#2ecc71', marginRight: '8px' }}>root@iteagrow:~$</span>
                        <input 
                            id="terminal-input"
                            type="text" 
                            value={terminalInput}
                            onChange={(e) => setTerminalInput(e.target.value)}
                            onKeyDown={handleTerminalSubmit}
                            autoFocus
                            style={{ 
                                background: 'transparent', 
                                border: 'none', 
                                color: 'white', 
                                fontFamily: 'inherit', 
                                outline: 'none', 
                                flex: 1, 
                                fontSize: 'inherit'
                            }} 
                        />
                    </div>
                </div>
            </div>

            {/* Toggle Button - Fixed to screen edge for visibility */}
            <button 
                onClick={() => setIsDocsOpen(!isDocsOpen)}
                style={{
                    position: 'fixed',
                    right: isDocsOpen ? '400px' : '0',
                    top: '120px',
                    width: '40px',
                    height: '50px',
                    background: isDocsOpen ? 'rgba(20, 20, 20, 0.95)' : '#2ecc71', // Bright green when closed
                    borderTopLeftRadius: '10px',
                    borderBottomLeftRadius: '10px',
                    border: '1px solid rgba(255,255,255,0.1)',
                    borderRight: 'none',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    cursor: 'pointer',
                    color: isDocsOpen ? '#2ecc71' : '#fff', // White arrow on green
                    boxShadow: '-5px 0 15px rgba(0,0,0,0.3)',
                    zIndex: 1001, // Higher than sidebar
                    transition: 'right 0.4s cubic-bezier(0.16, 1, 0.3, 1), background 0.3s',
                }}
            >
                {isDocsOpen ? <ChevronRight size={24} /> : <ChevronLeft size={24} />}
            </button>

            {/* Collapsible Docs Sidebar */}
            <div style={{
                position: 'fixed',
                right: 0,
                top: '0',
                height: '100vh',
                width: '400px',
                background: 'rgba(15, 15, 15, 0.98)',
                backdropFilter: 'blur(20px)',
                borderLeft: '1px solid rgba(46, 204, 113, 0.2)',
                boxShadow: '-20px 0 50px rgba(0,0,0,0.7)',
                transform: isDocsOpen ? 'translateX(0)' : 'translateX(100%)',
                transition: 'transform 0.4s cubic-bezier(0.16, 1, 0.3, 1)',
                zIndex: 1000,
                padding: '25px',
                paddingTop: '100px', // Clear header space
                overflowY: 'auto'
            }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '20px', borderBottom: '1px solid rgba(255,255,255,0.1)', paddingBottom: '15px' }}>
                    <BookOpen size={20} color="#2ecc71" />
                    <h3 style={{ margin: 0, fontSize: '1.2rem', color: 'white' }}>Documentation</h3>
                </div>

                <div style={{ color: '#ccc', lineHeight: '1.6' }}>
                    <h4 style={{ color: 'white', marginTop: '0', fontSize: '1rem' }}>How to use System Health</h4>
                    <p style={{ marginBottom: '20px', fontSize: '0.9rem' }}>
                        This monitoring dashboard provides real-time insights into your application's infrastructure. 
                        The terminal above is interactive and supports basic commands to control the monitoring interface.
                    </p>
                    
                    <h4 style={{ color: '#2ecc71', fontSize: '0.95rem', marginTop: '20px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                         <span style={{ fontSize: '1.2rem' }}>›_</span> Terminal Commands
                    </h4>
                    <ul style={{ listStyle: 'none', padding: 0 }}>
                        <li style={{ marginBottom: '10px', background: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '8px' }}>
                            <code style={{ color: '#2ecc71', fontWeight: 'bold' }}>status</code> 
                            <div style={{ marginTop: '5px', fontSize: '0.85rem' }}>Forces a manual health check of the Internal Database and API.</div>
                        </li>
                        <li style={{ marginBottom: '10px', background: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '8px' }}>
                            <code style={{ color: '#2ecc71', fontWeight: 'bold' }}>webapp_status</code> 
                            <div style={{ marginTop: '5px', fontSize: '0.85rem' }}>Pings the Main Web Application site.</div>
                        </li>
                        <li style={{ marginBottom: '10px', background: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '8px' }}>
                            <code style={{ color: '#2ecc71', fontWeight: 'bold' }}>disease_ai_status</code> 
                            <div style={{ marginTop: '5px', fontSize: '0.85rem' }}>Pings the Tea Leaf Disease AI service.</div>
                        </li>
                        <li style={{ marginBottom: '10px', background: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '8px' }}>
                            <code style={{ color: '#2ecc71', fontWeight: 'bold' }}>yield_ai_status</code> 
                            <div style={{ marginTop: '5px', fontSize: '0.85rem' }}>Pings the Tea Yield AI service.</div>
                        </li>
                        <li style={{ marginBottom: '10px', background: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '8px' }}>
                            <code style={{ color: '#2ecc71', fontWeight: 'bold' }}>maturity_ai_status</code>
                            <div style={{ marginTop: '5px', fontSize: '0.85rem' }}>Pings the Tea Leaf Maturity AI service.</div>
                        </li>
                        <li style={{ marginBottom: '10px', background: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '8px' }}>
                            <code style={{ color: '#2ecc71', fontWeight: 'bold' }}>auth_api_status</code>
                            <div style={{ marginTop: '5px', fontSize: '0.85rem' }}>Pings the Authentication API.</div>
                        </li>
                        <li style={{ marginBottom: '10px', background: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '8px' }}>
                            <code style={{ color: '#2ecc71', fontWeight: 'bold' }}>env_iot_status</code>
                            <div style={{ marginTop: '5px', fontSize: '0.85rem' }}>Pings the Environment IoT API.</div>
                        </li>
                        <li style={{ marginBottom: '10px', background: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '8px' }}>
                            <code style={{ color: '#2ecc71', fontWeight: 'bold' }}>soil_iot_status</code>
                            <div style={{ marginTop: '5px', fontSize: '0.85rem' }}>Pings the Soil Monitoring IoT API.</div>
                        </li>
                        <li style={{ marginBottom: '10px', background: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '8px' }}>
                            <code style={{ color: '#2ecc71', fontWeight: 'bold' }}>market_ai_status</code>
                            <div style={{ marginTop: '5px', fontSize: '0.85rem' }}>Pings the Tea Powder Market API.</div>
                        </li>
                        <li style={{ marginBottom: '10px', background: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '8px' }}>
                            <code style={{ color: '#2ecc71', fontWeight: 'bold' }}>troubleshoot</code>
                            <div style={{ marginTop: '5px', fontSize: '0.85rem' }}>Aggregates all current issues and suggests debugging steps.</div>
                        </li>
                        <li style={{ marginBottom: '10px', background: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '8px' }}>
                            <code style={{ color: '#2ecc71', fontWeight: 'bold' }}>refresh</code> 
                            <div style={{ marginTop: '5px', fontSize: '0.85rem' }}>Update all connection data immediately.</div>
                        </li>
                        <li style={{ marginBottom: '10px', background: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '8px' }}>
                            <code style={{ color: '#2ecc71', fontWeight: 'bold' }}>clear</code> 
                            <div style={{ marginTop: '5px', fontSize: '0.85rem' }}>Clears the terminal screen history.</div>
                        </li>
                    </ul>

                    <h4 style={{ color: '#e74c3c', fontSize: '0.95rem', marginTop: '25px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <AlertTriangle size={16} /> Troubleshooting
                    </h4>
                    <div style={{ background: 'rgba(231, 76, 60, 0.1)', padding: '15px', borderRadius: '8px', border: '1px solid rgba(231, 76, 60, 0.3)' }}>
                        <strong style={{ color: '#e74c3c' }}>API Status: Sleeping?</strong> <br/>
                        <p style={{ fontSize: '0.9rem', margin: '8px 0 0 0' }}>
                            The AI Service on Railway may go to sleep after inactivity. 
                            If the status is <span style={{color: '#e74c3c'}}>OFFLINE/SLEEPING</span>, click the "Wake Up" button or type <code>disease_ai_status</code>. It may take 30-60 seconds to boot up.
                        </p>
                    </div>
                </div>
            </div>

            <style>{`
                .modern-card {
                    background: rgba(20, 20, 20, 0.6);
                    backdrop-filter: blur(20px);
                    border: 1px solid rgba(255, 255, 255, 0.05);
                    transition: transform 0.3s ease, box-shadow 0.3s ease;
                }
                .modern-card:hover {
                    transform: translateY(-5px);
                    box-shadow: 0 10px 30px rgba(0,0,0,0.5);
                    border-color: rgba(255, 255, 255, 0.1);
                }
                .card-bg-glow {
                    position: absolute;
                    top: -50%;
                    right: -50%;
                    width: 200px;
                    height: 200px;
                    border-radius: 50%;
                    opacity: 0.1;
                    filter: blur(50px);
                    pointer-events: none;
                }
                
                .spin {
                    animation: spin 1s linear infinite;
                }
                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }

                .status-indicator {
                    width: 8px;
                    height: 8px;
                    border-radius: 50%;
                    display: inline-block;
                }

                .ping-dot {
                    width: 8px;
                    height: 8px;
                    background: #2ecc71;
                    border-radius: 50%;
                    animation: pulse-green 2s infinite;
                }

                .pulse-green {
                    box-shadow: 0 0 0 0 rgba(46, 204, 113, 0.7);
                    animation: pulse-green 2s infinite;
                }
                .pulse-blue {
                    box-shadow: 0 0 0 0 rgba(52, 152, 219, 0.7);
                    animation: pulse-blue 2s infinite;
                }
                
                @keyframes pulse-green {
                    0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(46, 204, 113, 0.7); }
                    70% { transform: scale(1); box-shadow: 0 0 0 10px rgba(46, 204, 113, 0); }
                    100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(46, 204, 113, 0); }
                }
                @keyframes pulse-blue {
                    0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(52, 152, 219, 0.7); }
                    70% { transform: scale(1); box-shadow: 0 0 0 10px rgba(52, 152, 219, 0); }
                    100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(52, 152, 219, 0); }
                }

                .blinking-cursor {
                    animation: blink 1s step-end infinite;
                }
                @keyframes blink {
                    50% { opacity: 0; }
                }

                /* Responsive grid for top service tiles */
                .service-grid {
                    display: grid;
                    grid-template-columns: repeat(5, minmax(0, 1fr));
                    gap: 16px;
                    width: 100%;
                }
                @media (max-width: 1600px) {
                    .service-grid {
                        grid-template-columns: repeat(4, minmax(0, 1fr));
                    }
                }
                @media (max-width: 1300px) {
                    .service-grid {
                        grid-template-columns: repeat(3, minmax(0, 1fr));
                    }
                }
                @media (max-width: 1000px) {
                    .service-grid {
                        grid-template-columns: repeat(2, minmax(0, 1fr));
                    }
                }
                @media (max-width: 700px) {
                    .service-grid {
                        grid-template-columns: repeat(1, minmax(0, 1fr));
                    }
                }
            `}</style>
        </div>
    );
};

export default SystemHealth;
