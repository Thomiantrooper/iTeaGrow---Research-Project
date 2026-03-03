import React, { useState, useEffect } from 'react';
import '../../css/Dashboard.css';
import { 
    Calendar, Save, AlertCircle, Droplets, DollarSign, CloudRain, 
    RefreshCw, TrendingUp, TrendingDown, Info, MessageSquare, 
    ExternalLink, ChevronDown, ChevronUp, History, FileDown, Filter, X, ShieldCheck
} from 'lucide-react';
import { jsPDF } from "jspdf";
import autoTable from 'jspdf-autotable';

const API_BASE = "https://tea-powder-classification-market-value-api.up.railway.app";

const initialGrades = [
    { name: 'BOPF', default: 1300, prev: 1135, tag: 'Premium', color: '#10b981', desc: 'Broken Orange Pekoe Fannings' },
    { name: 'BOP', default: 1580, prev: 1085, tag: 'Orthodox', color: '#3b82f6', desc: 'Broken Orange Pekoe' },
    { name: 'Pekoe', default: 1010, prev: 1015, tag: 'Specialty', color: '#8b5cf6', desc: 'Curled whole leaf tea' },
    { name: 'Fanning1', default: 970, prev: 975, tag: 'Fannings', color: '#f59e0b', desc: 'High-quality small leaf particles' },
    { name: 'Dust', default: 940, prev: 945, tag: 'Dust', color: '#64748b', desc: 'Fine tea particles' },
    { name: 'Dust1', default: 910, prev: 915, tag: 'Low', color: '#94a3b8', desc: 'Lowest grade tea particles' }
];

export default function MarketAuction() {
    const [gradesData, setGradesData] = useState(initialGrades);
    const [history, setHistory] = useState([]);
    const [isSaving, setIsSaving] = useState(false);
    const [statusIndicator, setStatusIndicator] = useState({ text: 'Verifying DB...', type: 'warning' });
    const [marketNotes, setMarketNotes] = useState('BOPF appreciated by Rs.20-40/kg. Active buying from Russia and Middle East.');
    const [marketSource, setMarketSource] = useState('Colombo Tea Auction');
    const [refreshing, setRefreshing] = useState(false);
    const [autoData, setAutoData] = useState({ rainfall: '...', exchange: '...', season: '...' });
    const [toast, setToast] = useState({ show: false, message: '', isError: false });
    const [showHistory, setShowHistory] = useState(false);
    
    // Filtering State
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');

    // UI state for user inputs
    const [userInputs, setUserInputs] = useState({});
    const [userNotes, setUserNotes] = useState('');
    const [userSource, setUserSource] = useState('');

    const getAuctionWeekString = () => {
        const now = new Date();
        const diff = now.getDate() - now.getDay() + (now.getDay() === 0 ? -6 : 1);
        const monday = new Date(now.setDate(diff));
        return monday.toISOString().split('T')[0];
    };

    const showToast = (message, isError = false) => {
        setToast({ show: true, message, isError });
        setTimeout(() => setToast({ show: false, message: '', isError: false }), 4000);
    };

    const fetchMarketMetadata = async () => {
        try {
            const res = await fetch(`${API_BASE}/api/v1/market-metadata`);
            if (res.ok) {
                const data = await res.json();
                setAutoData({
                    rainfall: data.rainfall_mm.toFixed(1),
                    exchange: data.exchange_rate.toFixed(2),
                    season: data.season
                });
            }
        } catch (err) {
            console.error("Failed fetching metadata", err);
        }
    };

    const fetchMarketPrices = async (isAuto = false) => {
        if (!isAuto) setRefreshing(true);
        try {
            const res = await fetch(`${API_BASE}/api/v1/market-price`);
            if (res.ok) {
                const dictData = await res.json();
                const allData = dictData.market_prices;
                const thisWeekStr = getAuctionWeekString();
                
                if (allData) {
                    let updatedGrades = [...initialGrades];
                    if (allData[thisWeekStr]) {
                        updatedGrades = updatedGrades.map(g => ({
                            ...g,
                            default: allData[thisWeekStr][g.name] || g.default
                        }));
                        setMarketNotes(allData[thisWeekStr].notes || marketNotes);
                        setMarketSource(allData[thisWeekStr].source || marketSource);
                        if (!isAuto) setStatusIndicator({ text: 'Verified in Database', type: 'success' });
                    } else {
                        if (!isAuto) setStatusIndicator({ text: 'Weekly Update Pending', type: 'warning' });
                        const dates = Object.keys(allData).filter(k => k !== "default").sort().reverse();
                        if (dates.length > 0) {
                            updatedGrades = updatedGrades.map(g => ({
                                ...g,
                                default: allData[dates[0]][g.name] || g.default
                            }));
                            setMarketNotes(allData[dates[0]].notes || marketNotes);
                            setMarketSource(allData[dates[0]].source || marketSource);
                        }
                    }
                    setGradesData(updatedGrades);
                    
                    const historyKeys = Object.keys(allData).filter(k => k !== "default").sort().reverse();
                    setHistory(historyKeys.map(k => ({ week: k, data: allData[k] })));
                }
            }
        } catch (err) {
            console.error("Failed fetching live market", err);
        } finally {
            if (!isAuto) setRefreshing(false);
        }
    };

    useEffect(() => {
        fetchMarketPrices(false);
        fetchMarketMetadata();
        const metadataInterval = setInterval(fetchMarketMetadata, 5000); 
        const priceInterval = setInterval(() => fetchMarketPrices(true), 15000); 
        return () => {
            clearInterval(metadataInterval);
            clearInterval(priceInterval);
        };
    }, []);

    const handlePriceChange = (index, value) => {
        if (value === '' || (/^\d*\.?\d{0,2}$/.test(value) && parseFloat(value) >= 0)) {
            setUserInputs(prev => ({ ...prev, [index]: value }));
        }
    };

    const handleSave = async () => {
        setIsSaving(true);
        const prices = {};
        gradesData.forEach((g, idx) => { 
            const val = userInputs[idx] !== undefined && userInputs[idx] !== '' 
                ? parseFloat(userInputs[idx]) 
                : g.default;
            prices[g.name] = val; 
        });
        
        const finalNotes = userNotes.trim() !== '' ? userNotes : marketNotes;
        const finalSource = userSource.trim() !== '' ? userSource : marketSource;

        try {
            const res = await fetch(`${API_BASE}/api/v1/market-price`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    auction_week: getAuctionWeekString(),
                    prices,
                    notes: finalNotes,
                    source: finalSource
                })
            });
            if (res.ok) {
                showToast('Prices synced to AI Model & App');
                setStatusIndicator({ text: 'Sync Complete', type: 'success' });
                setUserInputs({});
                setUserNotes('');
                setUserSource('');
                fetchMarketPrices(true);
            } else {
                showToast('Database Sync Failed', true);
            }
        } catch (err) {
            showToast(err.message, true);
        } finally {
            setIsSaving(false);
        }
    };

    // Filtered History Data
    const getFilteredHistory = () => {
        if (!startDate && !endDate) return history;
        return history.filter(item => {
            const date = new Date(item.week);
            const startLimit = startDate ? new Date(startDate) : null;
            const endLimit = endDate ? new Date(endDate) : null;
            
            if (startLimit && date < startLimit) return false;
            if (endLimit && date > endLimit) return false;
            return true;
        });
    };

    const generatePDF = () => {
        const filteredData = getFilteredHistory();
        if (filteredData.length === 0) {
            showToast('No data available for the selected range', true);
            return;
        }

        const doc = new jsPDF();
        const teaGreen = [26, 46, 32]; // #1a2e20
        const accentGold = [184, 158, 123]; // #b89e7b
        
        // 1. BRANDED HEADER
        doc.setFillColor(...teaGreen);
        doc.rect(0, 0, 210, 50, 'F');
        
        doc.setTextColor(255, 255, 255);
        doc.setFontSize(28);
        doc.setFont("helvetica", "bold");
        doc.text("iTeaGrow", 20, 30);
        
        doc.setTextColor(accentGold[0], accentGold[1], accentGold[2]);
        doc.setFontSize(10);
        doc.setFont("helvetica", "bold");
        doc.text("INTELLIGENCE REPORT • MARKET ANALYSIS", 22, 38);
        
        doc.setTextColor(200, 200, 200);
        doc.setFontSize(9);
        doc.setFont("helvetica", "normal");
        const reportDate = new Date().toLocaleDateString('en-US', { day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' });
        doc.text(`Official Document ID: ITG-MAR-${Date.now().toString().slice(-6)}`, 140, 20);
        doc.text(`Generated: ${reportDate}`, 140, 26);

        let yPos = 65;

        // 2. EXECUTIVE SUMMARY
        doc.setTextColor(...teaGreen);
        doc.setFontSize(14);
        doc.setFont("helvetica", "bold");
        doc.text("Executive Market Overview", 20, yPos);
        
        yPos += 8;
        doc.setFillColor( accentGold[0], accentGold[1], accentGold[2]);
        doc.rect(20, yPos, 170, 0.5, 'F');
        
        yPos += 12;
        doc.setTextColor(50, 50, 50);
        doc.setFontSize(10);
        doc.setFont("helvetica", "bold");
        doc.text(`Primary Source: ${marketSource || "Colombo Tea Auction"}`, 20, yPos);
        
        yPos += 6;
        doc.setFont("helvetica", "normal");
        const splitNotes = doc.splitTextToSize(`Key Observations: ${marketNotes || "No specific observations recorded for this period."}`, 170);
        doc.text(splitNotes, 20, yPos);
        yPos += (splitNotes.length * 5) + 10;

        // 3. MARKET DYNAMICS (Stats)
        doc.setTextColor(...teaGreen);
        doc.setFontSize(14);
        doc.setFont("helvetica", "bold");
        doc.text("Environmental & Macro Dynamics", 20, yPos);
        
        yPos += 8;
        doc.setFillColor(accentGold[0], accentGold[1], accentGold[2]);
        doc.rect(20, yPos, 170, 0.5, 'F');
        
        yPos += 12;
        // Draw Stat Boxes
        const drawStatBox = (x, y, label, value, unit) => {
            doc.setFillColor(245, 248, 245);
            doc.rect(x, y, 50, 20, 'F');
            doc.setDrawColor(230, 230, 230);
            doc.rect(x, y, 50, 20, 'D');
            doc.setTextColor(100, 100, 100);
            doc.setFontSize(8);
            doc.text(label.toUpperCase(), x + 5, y + 7);
            doc.setTextColor(...teaGreen);
            doc.setFontSize(11);
            doc.setFont("helvetica", "bold");
            doc.text(`${value} ${unit}`, x + 5, y + 15);
            doc.setFont("helvetica", "normal");
        };

        drawStatBox(20, yPos, "Avg Rainfall", autoData.rainfall, "mm");
        drawStatBox(80, yPos, "Currency Rate", autoData.exchange, "LKR/USD");
        drawStatBox(140, yPos, "Growth Season", autoData.season, "");
        
        yPos += 35;

        // 4. PRICE HISTORY ANALYSIS
        doc.setTextColor(...teaGreen);
        doc.setFontSize(14);
        doc.setFont("helvetica", "bold");
        doc.text("Detailed Valuation Matrix", 20, yPos);
        
        yPos += 8;
        doc.setFillColor(accentGold[0], accentGold[1], accentGold[2]);
        doc.rect(20, yPos, 170, 0.5, 'F');
        
        yPos += 10;
        doc.setTextColor(100, 100, 100);
        doc.setFontSize(9);
        const filterStr = startDate && endDate ? `Date Range: ${startDate} to ${endDate}` : "Full dataset visualization";
        doc.text(`Showing ${filteredData.length} records. ${filterStr}`, 20, yPos);

        const tableColumn = ["Auction Week", ...initialGrades.map(g => g.name)];
        const tableRows = filteredData.map(item => [
            item.week,
            ...initialGrades.map(g => item.data[g.name] ? `Rs. ${item.data[g.name].toFixed(2)}` : '-')
        ]);

        autoTable(doc, {
            head: [tableColumn],
            body: tableRows,
            startY: yPos + 5,
            theme: 'grid',
            headStyles: { 
                fillColor: teaGreen, 
                textColor: [255, 255, 255],
                fontSize: 9,
                fontStyle: 'bold',
                halign: 'center'
            },
            bodyStyles: { 
                fontSize: 8,
                textColor: [50, 50, 50],
                halign: 'center'
            },
            columnStyles: {
                0: { halign: 'left', fontStyle: 'bold' }
            },
            alternateRowStyles: {
                fillColor: [250, 252, 250]
            },
            margin: { left: 20, right: 20 }
        });

        // 5. GRADE DEFINITIONS & DISCLOSURE
        yPos = doc.lastAutoTable.finalY + 15;
        
        if (yPos > 240) { doc.addPage(); yPos = 30; }

        doc.setTextColor(...teaGreen);
        doc.setFontSize(12);
        doc.setFont("helvetica", "bold");
        doc.text("Grade Classifications of Tea Powder", 20, yPos);
        
        yPos += 6;
        doc.setFontSize(8);
        doc.setFont("helvetica", "normal");
        doc.setTextColor(100, 100, 100);
        
        initialGrades.forEach((g, idx) => {
            const line = `${g.name} (${g.tag}): ${g.desc}`;
            doc.text(`• ${line}`, 20, yPos + (idx * 5));
        });

        yPos += 40;
        
        // 6. APPROVAL SECTION
        doc.setDrawColor(200, 200, 200);
        doc.line(20, yPos, 70, yPos);
        doc.line(120, yPos, 170, yPos);
        
        doc.setFontSize(8);
        doc.text("Market Analyst Signature", 20, yPos + 5);
        doc.text("Manager/ Asst. Manager Approval", 120, yPos + 5);

        // Footer
        const pageCount = doc.internal.getNumberOfPages();
        for (let i = 1; i <= pageCount; i++) {
            doc.setPage(i);
            doc.setFillColor(...teaGreen);
            doc.rect(0, 287, 210, 10, 'F');
            doc.setTextColor(255, 255, 255);
            doc.setFontSize(7);
            doc.text(`© ${new Date().getFullYear()} iTeaGrow Intelligence • This document is confidential and intended for authorized stakeholders only.`, 20, 293);
            doc.text(`Page ${i} of ${pageCount}`, 180, 293);
        }

        doc.save(`iTeaGrow_Market_Report_${getAuctionWeekString()}.pdf`);
        showToast('PDF Report Generated');
    };

    return (
        <div className="dashboard-container" style={{ position: 'relative', width: '100%', maxWidth: '100%', margin: '0', padding: '30px' }}>
            {/* Custom Toast */}
            {toast.show && (
                <div style={{ position: 'fixed', bottom: '30px', right: '30px', zIndex: 9999, animation: 'slideRight 0.3s ease-out' }}>
                    <div style={{ background: toast.isError ? '#e74c3c' : '#2ecc71', color: 'white', padding: '12px 24px', borderRadius: '12px', display: 'flex', alignItems: 'center', gap: '10px', boxShadow: '0 8px 24px rgba(0,0,0,0.3)' }}>
                        {toast.isError ? <AlertCircle size={20} /> : <div style={{ fontSize: '1.2rem' }}>✓</div>}
                        <span style={{ fontWeight: '600' }}>{toast.message}</span>
                    </div>
                </div>
            )}

            {/* Header & Stats Row */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '30px', flexWrap: 'wrap', gap: '25px' }}>
                <header className="dashboard-header" style={{ margin: 0, display: 'flex', alignItems: 'center', gap: '15px' }}>
                    <div>
                        <h1 style={{ margin: 0, fontSize: '2.5rem', background: 'linear-gradient(90deg, #fff, #aaa)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', fontWeight: '800' }}>Market Auction</h1>
                        <p className="dashboard-subtitle" style={{ margin: '2px 0 0 0', fontSize: '1.1rem', color: '#fff', opacity: 0.8 }}>Enter & manage weekly market valuations</p>
                    </div>
                </header>

                <div className="dashboard-card stat-row-unified" style={{ 
                    display: 'flex', padding: 0, borderRadius: '12px', 
                    background: 'rgba(20, 30, 20, 0.7)', border: '1px solid rgba(255, 255, 255, 0.1)',
                    overflow: 'hidden', backdropFilter: 'blur(8px)'
                }}>
                    {[
                        { label: 'Rainfall', value: autoData.rainfall, unit: 'mm', icon: <Droplets size={18} color="#4facfe" />, bg: 'rgba(79, 172, 254, 0.1)' },
                        { label: 'Exchange', value: autoData.exchange, unit: 'LKR', icon: <DollarSign size={18} color="#2ecc71" />, bg: 'rgba(46, 204, 113, 0.1)' },
                        { label: 'Season', value: autoData.season, unit: '', icon: <CloudRain size={18} color="#9b59b6" />, bg: 'rgba(155, 89, 182, 0.1)' }
                    ].map((stat, i) => (
                        <div key={i} style={{ 
                            padding: '12px 20px', borderRight: i < 2 ? '1px solid rgba(255, 255, 255, 0.1)' : 'none',
                            display: 'flex', alignItems: 'center', gap: '12px', minWidth: '150px'
                        }}>
                             <div className="stat-icon-wrapper" style={{ padding: '8px', background: stat.bg, borderRadius: '8px' }}>{stat.icon}</div>
                             <div>
                                <span style={{ fontSize: '0.65rem', color: '#ddd', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>{stat.label}</span>
                                <div style={{ fontSize: '1.1rem', color: 'white', fontWeight: 'bold' }}>{stat.value} <small style={{ fontWeight: 'normal', color: '#ccc', fontSize: '0.75rem' }}>{stat.unit}</small></div>
                             </div>
                        </div>
                    ))}
                </div>
            </div>

            {/* Active Valuations Section */}
            <div style={{ marginBottom: '30px' }}>
                 <div style={{ 
                    display: 'flex', alignItems: 'center', justifyContent: 'space-between', 
                    padding: '20px 24px', background: 'rgba(255, 255, 255, 0.05)', 
                    borderRadius: '12px 12px 0 0', border: '1px solid rgba(255, 255, 255, 0.1)',
                    borderBottom: 'none'
                }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#2ecc71', boxShadow: '0 0 10px #2ecc71' }}></div>
                        <h2 style={{ fontSize: '0.9rem', color: '#ddd', fontWeight: '600', margin: 0, textTransform: 'uppercase', letterSpacing: '1px' }}>Active Valuations</h2>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                         <span style={{ color: '#2ecc71', fontSize: '0.85rem', fontWeight: '700', display: 'flex', alignItems: 'center', gap: '6px' }}>
                            Verified in Database
                         </span>
                         <button 
                            onClick={() => { fetchMarketPrices(); fetchMarketMetadata(); }}
                            className="refresh-btn"
                            style={{ padding: '6px', borderRadius: '6px' }}>
                            <RefreshCw size={14} className={refreshing ? 'spinning' : ''} />
                        </button>
                    </div>
                </div>

                <div style={{ 
                    display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '20px', 
                    marginTop: '20px' 
                }}>
                    {gradesData.map((grade, index) => {
                        const diff = grade.default - grade.prev;
                        const isUp = diff >= 0;
                        return (
                            <div key={grade.name} className="dashboard-card" style={{
                                padding: '15px', background: 'rgba(20, 30, 20, 0.7)',
                                border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px',
                                transition: 'all 0.2s ease', backdropFilter: 'blur(8px)'
                            }}>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                        <div style={{ width: '28px', height: '28px', borderRadius: '50%', background: 'rgba(255,255,255,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#eee', fontWeight: '600', fontSize: '0.8rem' }}>
                                            {grade.name.charAt(0)}
                                        </div>
                                        <span style={{ fontSize: '1rem', fontWeight: '700', color: '#fff' }}>{grade.name}</span>
                                    </div>
                                    <span style={{ fontSize: '0.65rem', color: '#fff', fontWeight: '600', background: 'rgba(255,255,255,0.1)', padding: '2px 6px', borderRadius: '4px', border: '1px solid rgba(255,255,255,0.1)' }}>{grade.tag}</span>
                                </div>

                                <div className="price-input-container" style={{ background: 'rgba(255, 255, 255, 0.05)', padding: '8px 12px', borderRadius: '6px', marginBottom: '12px', border: '1px solid rgba(255, 255, 255, 0.1)' }}>
                                    <div style={{ display: 'flex', alignItems: 'center' }}>
                                        <span style={{ fontSize: '0.85rem', color: '#aaa', fontWeight: '500', marginRight: '4px' }}>Rs.</span>
                                        <input 
                                            type="number" 
                                            placeholder={grade.default.toFixed(2)}
                                            value={userInputs[index] || ''}
                                            onChange={(e) => handlePriceChange(index, e.target.value)}
                                            className="valuation-input"
                                            min="0"
                                            step="0.01"
                                            style={{ background: 'transparent', border: 'none', color: '#fff', fontSize: '1.25rem', fontWeight: '800', width: '100%', outline: 'none' }}
                                        />
                                    </div>
                                </div>

                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                        <div style={{ width: '5px', height: '5px', borderRadius: '50%', background: isUp ? '#2ecc71' : '#e74c3c' }}></div>
                                        <span style={{ color: isUp ? '#2ecc71' : '#e74c3c', fontWeight: '700', fontSize: '0.85rem' }}>
                                            {isUp ? '+' : ''}{diff.toFixed(2)}
                                        </span>
                                        <span style={{ color: '#aaa', fontSize: '0.75rem' }}>vs past</span>
                                    </div>
                                    <Info size={14} color="#aaa" style={{ cursor: 'pointer', opacity: 0.7 }} />
                                </div>
                            </div>
                        );
                    })}
                </div>
            </div>

            {/* Unified Notes, Source & Publish Action Bar */}
            <div className="dashboard-card" style={{ padding: '20px', borderRadius: '12px', background: 'rgba(20, 30, 20, 0.7)', border: '1px solid rgba(255, 255, 255, 0.1)', backdropFilter: 'blur(8px)', width: '100%', marginBottom: '30px', overflow: 'hidden' }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'minmax(250px, 2.2fr) minmax(200px, 1.2fr) minmax(140px, 0.8fr)', gap: '20px', alignItems: 'stretch' }}>
                    {/* Observations Column */}
                    <div style={{ display: 'flex', flexDirection: 'column' }}>
                         <label style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#ddd', fontSize: '0.75rem', fontWeight: '600', marginBottom: '12px' }}>
                            <MessageSquare size={14} /> AUCTION OBSERVATIONS
                         </label>
                         <textarea 
                            placeholder={marketNotes}
                            value={userNotes}
                            onChange={(e) => setUserNotes(e.target.value)}
                            className="form-input global-placeholder"
                            rows="4"
                            style={{ width: '100%', resize: 'none', flex: 1, fontSize: '0.9rem' }}
                         />
                    </div>

                    {/* Source & Date Column */}
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '25px' }}>
                        <div>
                             <label style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#ddd', fontSize: '0.85rem', fontWeight: '600', marginBottom: '18px' }}>
                                <ExternalLink size={16} /> MARKET SOURCE
                             </label>
                             <input 
                                placeholder={marketSource}
                                value={userSource}
                                onChange={(e) => setUserSource(e.target.value)}
                                className="form-input global-placeholder"
                                style={{ width: '100%', fontSize: '0.9rem' }}
                             />
                        </div>
                         
                          <div style={{ marginTop: 'auto', padding: '12px', background: 'rgba(255,255,255,0.03)', borderRadius: '10px', display: 'flex', alignItems: 'center', gap: '12px', border: '1px solid rgba(255,255,255,0.05)' }}>
                             <Calendar size={18} color="#2ecc71" />
                             <div>
                                 <span style={{ block: 'block', fontSize: '0.65rem', color: '#888', textTransform: 'uppercase', fontWeight: '700', letterSpacing: '0.5px' }}>Active Period: </span>
                                 <span style={{ color: '#fff', fontSize: '0.95rem', fontWeight: '600' }}>{getAuctionWeekString()}</span>
                             </div>
                          </div>
                    </div>

                    {/* Unified Publish Action */}
                    <div style={{ display: 'flex', width: '100%' }}>
                            <button 
                                onClick={handleSave}
                                disabled={isSaving}
                                className="btn btn-primary"
                                style={{
                                    width: '100%', height: '100%', borderRadius: '8px', 
                                    display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                                    gap: '8px', padding: '12px', fontWeight: '800', fontSize: '0.9rem',
                                    transition: 'all 0.3s ease', boxSizing: 'border-box'
                                }}>
                                {isSaving ? <RefreshCw className="spinning" size={20} /> : <Save size={20} />}
                                <span style={{ letterSpacing: '0.5px', marginTop: '4px' }}>{isSaving ? "SYNCING..." : "PUBLISH PRICES"}</span>
                            </button>
                    </div>
                </div>
            </div>

            {/* Collapsible History Section */}
            <div className="dashboard-card" style={{ 
                padding: 0, borderRadius: '12px', background: 'rgba(20, 30, 20, 0.7)', 
                border: '1px solid rgba(255, 255, 255, 0.1)', backdropFilter: 'blur(8px)', 
                width: '100%', overflow: 'hidden' 
            }}>
                <button 
                    onClick={() => setShowHistory(!showHistory)}
                    style={{ 
                        width: '100%', padding: '20px 30px', background: 'transparent', 
                        border: 'none', display: 'flex', justifyContent: 'space-between', 
                        alignItems: 'center', cursor: 'pointer', transition: 'background 0.2s' 
                    }}
                    onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(255,255,255,0.02)'}
                    onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <History size={20} color="#aaa" />
                        <span style={{ color: '#fff', fontSize: '1rem', fontWeight: '700', letterSpacing: '0.5px' }}>PRICE HISTORY</span>
                        <span style={{ fontSize: '0.7rem', color: '#888', background: 'rgba(255,255,255,0.05)', padding: '2px 8px', borderRadius: '4px' }}>
                            {getFilteredHistory().length} records visible
                        </span>
                    </div>
                    {showHistory ? <ChevronUp color="#aaa" /> : <ChevronDown color="#aaa" />}
                </button>

                {showHistory && (
                    <div style={{ padding: '0 30px 30px 30px', animation: 'fadeIn 0.3s ease-out' }}>
                        {/* Filter & Export Row */}
                        <div style={{ 
                            display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', 
                            marginBottom: '20px', padding: '20px', background: 'rgba(255,255,255,0.03)', 
                            borderRadius: '12px', border: '1px solid rgba(255,255,255,0.05)', flexWrap: 'wrap', gap: '20px'
                        }}>
                            <div style={{ display: 'flex', gap: '20px', flexWrap: 'wrap' }}>
                                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                                    <label style={{ fontSize: '0.65rem', color: '#888', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '1px' }}>Start Date</label>
                                    <div style={{ position: 'relative' }}>
                                        <input 
                                            type="date" 
                                            value={startDate}
                                            onChange={(e) => setStartDate(e.target.value)}
                                            className="date-input-custom"
                                            style={{ padding: '10px 15px', borderRadius: '8px', background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(255,255,255,0.1)', color: '#fff', outline: 'none' }}
                                        />
                                    </div>
                                </div>
                                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                                    <label style={{ fontSize: '0.65rem', color: '#888', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '1px' }}>End Date</label>
                                    <div style={{ position: 'relative' }}>
                                        <input 
                                            type="date" 
                                            value={endDate}
                                            onChange={(e) => setEndDate(e.target.value)}
                                            className="date-input-custom"
                                            style={{ padding: '10px 15px', borderRadius: '8px', background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(255,255,255,0.1)', color: '#fff', outline: 'none' }}
                                        />
                                    </div>
                                </div>
                                {(startDate || endDate) && (
                                    <button 
                                        onClick={() => { setStartDate(''); setEndDate(''); }}
                                        style={{ alignSelf: 'flex-end', padding: '10px', borderRadius: '8px', background: 'rgba(231, 76, 60, 0.1)', border: '1px solid rgba(231, 76, 60, 0.2)', color: '#e74c3c', display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}
                                    >
                                        <X size={16} /> Reset
                                    </button>
                                )}
                            </div>

                            <button 
                                onClick={generatePDF}
                                style={{ 
                                    padding: '12px 25px', borderRadius: '8px', background: '#2ecc71', 
                                    border: 'none', color: '#fff', fontWeight: '700', 
                                    display: 'flex', alignItems: 'center', gap: '10px', 
                                    cursor: 'pointer', transition: 'all 0.2s',
                                    boxShadow: '0 4px 15px rgba(46, 204, 113, 0.2)'
                                }}
                                onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-2px)'}
                                onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
                            >
                                <FileDown size={20} /> DOWNLOAD PDF REPORT
                            </button>
                        </div>

                        <div style={{ overflowX: 'auto', borderRadius: '8px', border: '1px solid rgba(255,255,255,0.05)' }}>
                            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                                <thead>
                                    <tr style={{ background: 'rgba(255,255,255,0.05)' }}>
                                        <th style={{ padding: '15px 20px', color: '#aaa', fontSize: '0.75rem', fontWeight: '700', textTransform: 'uppercase' }}>Week</th>
                                        {initialGrades.map(g => (
                                            <th key={g.name} style={{ padding: '15px 20px', color: '#aaa', fontSize: '0.75rem', fontWeight: '700', textTransform: 'uppercase' }}>{g.name}</th>
                                        ))}
                                    </tr>
                                </thead>
                                <tbody>
                                    {getFilteredHistory().map((item, idx) => (
                                        <tr key={idx} style={{ borderBottom: idx === getFilteredHistory().length - 1 ? 'none' : '1px solid rgba(255,255,255,0.05)' }}>
                                            <td style={{ padding: '15px 20px', color: '#fff', fontSize: '0.9rem', fontWeight: '600' }}>{item.week}</td>
                                            {initialGrades.map(g => (
                                                <td key={g.name} style={{ padding: '15px 20px', color: '#ddd', fontSize: '0.9rem' }}>
                                                    {item.data[g.name] ? `Rs. ${item.data[g.name].toFixed(2)}` : '-'}
                                                </td>
                                            ))}
                                        </tr>
                                    ))}
                                    {getFilteredHistory().length === 0 && (
                                        <tr>
                                            <td colSpan={7} style={{ padding: '40px', textAlign: 'center', color: '#666', fontStyle: 'italic' }}>
                                                No records found for the selected period.
                                            </td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </div>
                )}
            </div>

            <style>{`
                .spinning { animation: rotate 2s linear infinite; }
                @keyframes rotate { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
                @keyframes slideRight { from { transform: translateX(30px); opacity: 0; } to { transform: translateX(0); opacity: 1; } }
                @keyframes fadeIn { from { opacity: 0; transform: translateY(-10px); } to { opacity: 1; transform: translateY(0); } }

                .valuation-input::placeholder,
                .global-placeholder::placeholder {
                    color: #fff !important;
                    opacity: 0.3 !important;
                }

                .btn-primary:active { transform: scale(0.97); }
                .btn-primary:hover { box-shadow: 0 0 20px rgba(46, 204, 113, 0.3); }

                .date-input-custom::-webkit-calendar-picker-indicator {
                    filter: invert(1);
                    cursor: pointer;
                }

                @media (max-width: 1200px) {
                    div[style*="gridTemplateColumns: minmax(400px"] {
                        grid-template-columns: 1fr !important;
                        gap: 25px !important;
                    }
                }

                @media (max-width: 1100px) {
                    div[style*="gridTemplateColumns: repeat(3, 1fr)"] {
                        grid-template-columns: repeat(2, 1fr) !important;
                    }
                }
                @media (max-width: 700px) {
                    div[style*="gridTemplateColumns: repeat(3, 1fr)"] {
                        grid-template-columns: 1fr !important;
                    }
                }

                input::-webkit-outer-spin-button,
                input::-webkit-inner-spin-button { -webkit-appearance: none; margin: 0; }
            `}</style>
        </div>
    );
}
