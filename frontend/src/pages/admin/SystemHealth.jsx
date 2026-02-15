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
        terminalHistory, setTerminalHistory,
        refreshAll, checkHealth, checkAiHealth, checkYieldHealth, checkMaturityHealth, checkWebAppHealth
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
                    newHistory.push({ type: 'response', content: 'Available commands:\n  help              - Show this help message\n  status            - Check internal system status\n  refresh           - Refresh all connection data\n  disease_ai_status - Check/Wake Up Disease AI\n  yield_ai_status   - Check/Wake Up Yield AI\n  clear             - Clear terminal history\n  docs              - Open documentation sidebar' });
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
        <div className="dashboard-container" style={{ position: 'relative' }}>
            <header className="dashboard-header" style={{ marginBottom: '40px' }}>
                <div>
                    <h1 style={{ fontSize: '2.5rem', background: 'linear-gradient(90deg, #fff, #aaa)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>System Health</h1>
                    <p className="dashboard-subtitle" style={{ fontSize: '1.1rem' }}>Real-time infrastructure monitoring & status.</p>
                </div>
                <div className="header-actions">
                    <div style={{ display: 'flex', gap: '10px' }}>
                        {/* Wake Disease AI Button */}
                        {/* Unified Wake AI Button */}
                        <button 
                            onClick={() => { 
                                setTerminalHistory(prev => [...prev, { type: 'info', content: `[${new Date().toLocaleTimeString()}] Initiating Manual Wake-Up for All Systems...` }]);
                                refreshAll();
                            }} 
                            className="btn"
                            disabled={aiRefreshing || yieldRefreshing || maturityRefreshing || webAppRefreshing}
                            style={{ 
                                display: 'flex', 
                                alignItems: 'center', 
                                gap: '6px', 
                                padding: '10px 16px', 
                                fontSize: '0.85rem',
                                background: 'rgba(46, 204, 113, 0.1)',
                                color: (aiRefreshing || yieldRefreshing || maturityRefreshing || webAppRefreshing) ? '#2ecc71' : '#ccc',
                                border: '1px solid rgba(46, 204, 113, 0.2)',
                                borderRadius: '8px',
                                transition: 'all 0.3s',
                                cursor: 'pointer'
                            }}
                        >
                            <Power size={16} className={(aiRefreshing || yieldRefreshing || maturityRefreshing || webAppRefreshing) ? 'spin' : ''} />
                            {(aiRefreshing || yieldRefreshing || maturityRefreshing || webAppRefreshing) ? 'Waking Systems...' : 'Wake All Systems'}
                        </button>
                        
                        {/* Main Refresh Button */}
                        <button 
                            onClick={checkHealth} 
                            className="btn btn-primary"
                            disabled={refreshing}
                            style={{ 
                                display: 'flex', 
                                alignItems: 'center', 
                                gap: '10px', 
                                padding: '12px 24px', 
                                fontSize: '1rem',
                                boxShadow: '0 0 20px rgba(46, 204, 113, 0.4)',
                                transition: 'all 0.3s'
                            }}
                        >
                            <RefreshCw size={20} className={refreshing ? 'spin' : ''} />
                            {refreshing ? 'Refreshing...' : 'Refresh Status'}
                        </button>
                    </div>

                    {healthData && (
                        <div style={{ textAlign: 'right', marginTop: '8px', display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: '6px' }}>
                            <div className="ping-dot"></div>
                            <span className="last-updated" style={{ background: 'transparent', padding: 0, color: '#aaa', fontSize: '0.85rem' }}>
                                Live | Last update: {new Date(healthData.timestamp).toLocaleTimeString()}
                            </span>
                        </div>
                    )}
                </div>
            </header>

            {/* --- Internal Health Grid --- */}
            <div className="dashboard-grid" style={{ display: 'flex', gap: '30px', flexWrap: 'wrap' }}>
                
                {/* Unified System Status Card (App | DB | AI Services) */}
                <div className="dashboard-card stat-card modern-card" style={{ 
                    flex: '5', 
                    minWidth: '1000px', // Increased min-width for 5 columns
                    position: 'relative', 
                    overflow: 'hidden', 
                    display: 'flex', 
                    flexDirection: 'column', 
                    padding: 0 
                }}>
                    <div className="card-bg-glow" style={{ background: 'linear-gradient(45deg, #2ecc71, #27ae60, #16a085)' }}></div>
                    
                    {/* Top Row: The 5 Columns */}
                    <div style={{ display: 'flex', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                        
                        {/* Column 0: Main Web App */}
                        <div style={{ 
                            flex: 1, 
                            padding: '24px', 
                            borderRight: '1px solid rgba(255,255,255,0.1)',
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
                            flex: 1, 
                            padding: '24px', // Increased padding
                            borderRight: '1px solid rgba(255,255,255,0.1)',
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
                                flex: 1, 
                                padding: '24px', 
                                borderRight: '1px solid rgba(255,255,255,0.1)',
                                cursor: 'pointer', 
                                transition: 'background 0.3s',
                                background: showAiSection ? 'rgba(46, 204, 113, 0.1)' : 'transparent',
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
                                flex: 1, 
                                padding: '24px', 
                                cursor: 'pointer', 
                                transition: 'background 0.3s',
                                background: showYieldSection ? 'rgba(46, 204, 113, 0.1)' : 'transparent',
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
                                flex: 1, 
                                padding: '24px', 
                                cursor: 'pointer', 
                                transition: 'background 0.3s',
                                background: showMaturitySection ? 'rgba(46, 204, 113, 0.1)' : 'transparent',
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
                    </div>
                </div>

                {/* System Uptime & Comprehensive Diagnostics */}
                <div className="dashboard-card stat-card modern-card" style={{ flex: '1', minWidth: '1000px', padding: 0, overflow: 'hidden' }}>
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
            `}</style>
        </div>
    );
};

export default SystemHealth;
