import React, { useState, useCallback, useMemo } from 'react';
import { Database, Download, RefreshCw, ChevronLeft, ChevronRight, Leaf, Activity, BarChart2, Wifi, X, CheckSquare, Square, FileText, FileJson, Table2, Sheet } from 'lucide-react';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';
import '../../css/DataCollection.css';

// ---------------------------------------------------------------
// Config: data sources
// ---------------------------------------------------------------
const API_BASE = import.meta.env.VITE_API_URL || '/api';

const DATA_SOURCES = [
    {
        key: 'soil',
        label: 'Soil IoT',
        subtitle: 'tea_soil_db → predictions',
        endpoint: `${API_BASE}/data/soil`,
        icon: Leaf,
        color: '#8B5E3C',
        gradient: 'linear-gradient(135deg, rgba(139,94,60,0.2), rgba(80,40,10,0.1))',
        border: 'rgba(139,94,60,0.3)',
    },
    {
        key: 'env-iot',
        label: 'Environment IoT',
        subtitle: 'iteagrow → iot_data',
        endpoint: `${API_BASE}/data/env-iot`,
        icon: Wifi,
        color: '#3498db',
        gradient: 'linear-gradient(135deg, rgba(52,152,219,0.2), rgba(20,60,100,0.1))',
        border: 'rgba(52,152,219,0.3)',
    },
    {
        key: 'yield',
        label: 'Yield Data',
        subtitle: 'tea_yield_db + iteagrow → yield collections',
        endpoint: `${API_BASE}/data/yield`,
        icon: Activity,
        color: '#2ecc71',
        gradient: 'linear-gradient(135deg, rgba(46,204,113,0.2), rgba(10,60,30,0.1))',
        border: 'rgba(46,204,113,0.3)',
    },
    {
        key: 'market',
        label: 'Market Value',
        subtitle: 'tea_powder_db → admin_market_value',
        endpoint: `${API_BASE}/data/market`,
        icon: BarChart2,
        color: '#9b59b6',
        gradient: 'linear-gradient(135deg, rgba(155,89,182,0.2), rgba(60,10,80,0.1))',
        border: 'rgba(155,89,182,0.3)',
    },
];

const PAGE_SIZE = 10;

// ---------------------------------------------------------------
// DataTable component: renders dynamic columns from data
// ---------------------------------------------------------------
const DataTable = ({ data, page, onPage, color }) => {
    if (!data || data.length === 0) {
        return (
            <div className="dc-empty">
                <Database size={40} color="#444" />
                <p>No records found.</p>
            </div>
        );
    }

    // Derive columns from first document (exclude _id by default, show last)
    const allKeys = Object.keys(data[0]);
    const columns = ['_id', ...allKeys.filter(k => k !== '_id')];

    const totalPages = Math.ceil(data.length / PAGE_SIZE);
    const slice = data.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

    const formatCell = (val) => {
        if (val === null || val === undefined) return <span style={{ color: '#555' }}>—</span>;
        if (typeof val === 'object') return <span style={{ color: '#888', fontSize: '0.8rem' }}>{JSON.stringify(val).slice(0, 60)}…</span>;
        const str = String(val);
        return str.length > 60 ? str.slice(0, 60) + '…' : str;
    };

    return (
        <div className="dc-table-wrapper">
            <div className="dc-table-scroll">
                <table className="dc-table">
                    <thead>
                        <tr>
                            {columns.map(col => (
                                <th key={col} style={{ borderBottom: `2px solid ${color}40` }}>{col}</th>
                            ))}
                        </tr>
                    </thead>
                    <tbody>
                        {slice.map((row, i) => (
                            <tr key={i} className="dc-row">
                                {columns.map(col => (
                                    <td key={col}>{formatCell(row[col])}</td>
                                ))}
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            {/* Pagination */}
            <div className="dc-pagination">
                <span className="dc-page-info">
                    Page {page} of {totalPages} &nbsp;·&nbsp; {data.length} records
                </span>
                <div className="dc-page-btns">
                    <button onClick={() => onPage(p => Math.max(1, p - 1))} disabled={page === 1}>
                        <ChevronLeft size={16} />
                    </button>
                    <button onClick={() => onPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages}>
                        <ChevronRight size={16} />
                    </button>
                </div>
            </div>
        </div>
    );
};

// ---------------------------------------------------------------
// Market Value custom renderer
// ---------------------------------------------------------------
const GRADE_COLUMNS = ['BOPF', 'BOP', 'Pekoe', 'Fanning1', 'Dust', 'Dust1'];

const MarketTable = ({ data, color }) => {
    if (!data || data.length === 0) {
        return (
            <div className="dc-empty">
                <Database size={40} color="#444" />
                <p>No records found.</p>
            </div>
        );
    }

    const doc = data[0];
    const priceData = doc.data || {};

    // Sort entries: "default" first, then dates ascending
    const entries = Object.entries(priceData).sort(([a], [b]) => {
        if (a === 'default') return -1;
        if (b === 'default') return 1;
        return a.localeCompare(b);
    });

    // Derive grade columns from the data (union of all keys)
    const gradeSet = new Set();
    entries.forEach(([, grades]) => Object.keys(grades).forEach(g => gradeSet.add(g)));
    const grades = GRADE_COLUMNS.filter(g => gradeSet.has(g));

    return (
        <div className="dc-table-wrapper">
            {/* Metadata bar */}
            <div className="dc-market-meta">
                <div className="dc-meta-row">
                    <span className="dc-meta-label">Last Notes</span>
                    <span className="dc-meta-value">{doc.last_notes || '—'}</span>
                </div>
                <div className="dc-meta-row">
                    <span className="dc-meta-label">Source</span>
                    <span className="dc-meta-value">{doc.last_source || '—'}</span>
                </div>
                <div className="dc-meta-row">
                    <span className="dc-meta-label">Updated</span>
                    <span className="dc-meta-value">{doc.updated_at ? new Date(doc.updated_at).toLocaleString() : '—'}</span>
                </div>
            </div>

            {/* Price matrix */}
            <div className="dc-table-scroll">
                <table className="dc-table">
                    <thead>
                        <tr>
                            <th style={{ borderBottom: `2px solid ${color}40`, minWidth: 110 }}>Date / Entry</th>
                            {grades.map(g => (
                                <th key={g} style={{ borderBottom: `2px solid ${color}40`, textAlign: 'right' }}>{g}</th>
                            ))}
                        </tr>
                    </thead>
                    <tbody>
                        {entries.map(([dateKey, vals]) => (
                            <tr key={dateKey} className="dc-row">
                                <td style={{ color: dateKey === 'default' ? color : '#ccc', fontWeight: dateKey === 'default' ? 600 : 400 }}>
                                    {dateKey === 'default' ? '★ Default' : dateKey}
                                </td>
                                {grades.map(g => (
                                    <td key={g} style={{ textAlign: 'right' }}>
                                        {vals[g] != null
                                            ? <span style={{ color: '#e0e0e0' }}>Rs.&nbsp;{Number(vals[g]).toLocaleString()}</span>
                                            : <span style={{ color: '#555' }}>—</span>}
                                    </td>
                                ))}
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            <div className="dc-pagination">
                <span className="dc-page-info">{entries.length} date entries · {grades.length} grades</span>
            </div>
        </div>
    );
};

// ---------------------------------------------------------------
// Helpers to derive columns + flat rows (works for both regular & market)
// ---------------------------------------------------------------
const deriveColumnsAndRows = (source, data) => {
    if (source.key === 'market') {
        const doc = data[0];
        const priceData = doc.data || {};
        const entries = Object.entries(priceData).sort(([a], [b]) => {
            if (a === 'default') return -1;
            if (b === 'default') return 1;
            return a.localeCompare(b);
        });
        const gradeSet = new Set();
        entries.forEach(([, vals]) => Object.keys(vals).forEach(g => gradeSet.add(g)));
        const grades = GRADE_COLUMNS.filter(g => gradeSet.has(g));
        const columns = ['Date/Entry', ...grades];
        const rows = entries.map(([dateKey, vals]) => ({
            'Date/Entry': dateKey === 'default' ? '[Default]' : dateKey,
            ...Object.fromEntries(grades.map(g => [g, vals[g] != null ? vals[g] : ''])),
        }));
        return { columns, rows };
    }
    const allKeys = Object.keys(data[0]);
    const columns = ['_id', ...allKeys.filter(k => k !== '_id')];
    const rows = data.map(row => {
        const r = {};
        columns.forEach(col => { r[col] = row[col]; });
        return r;
    });
    return { columns, rows };
};

const cellStr = (val) => {
    if (val === null || val === undefined || val === '') return '';
    if (typeof val === 'object') return JSON.stringify(val);
    return String(val);
};

// ---------------------------------------------------------------
// Unified export runner
// ---------------------------------------------------------------
const runExport = (source, data, selectedCols, format) => {
    if (!data || data.length === 0) return;
    const { columns, rows } = deriveColumnsAndRows(source, data);
    const cols = selectedCols.length > 0 ? selectedCols : columns;
    const now = new Date();
    const pad = n => String(n).padStart(2, '0');
    const dateStr = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
    const timeStr = `${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}`;
    const datasetName = source.label.replace(/\s+/g, '');
    const filename = `iTeaGrow-${datasetName}-${dateStr}-${timeStr}`;

    if (format === 'pdf') {
        const isMarket = source.key === 'market';
        const accentRGB = isMarket ? [155, 89, 182] : [46, 204, 113];
        const PW = 297; // A4 landscape width mm
        const PH = 210; // A4 landscape height mm
        const HEADER_H = 28;
        const FOOTER_H = 12;
        const MARGIN = 12;
        const exportedAt = new Date().toLocaleString();
        // jsPDF built-in Helvetica only supports Latin-1 — strip non-latin glyphs
        const safeStr = (s) => String(s).replace(/→/g, '->').replace(/[^\x00-\xFF]/g, '?');

        const pdf = new jsPDF({ orientation: 'landscape', unit: 'mm', format: 'a4' });

        const drawHeader = (doc) => {
            // Background
            doc.setFillColor(14, 14, 14);
            doc.rect(0, 0, PW, HEADER_H, 'F');
            // Accent left stripe
            doc.setFillColor(...accentRGB);
            doc.rect(0, 0, 5, HEADER_H, 'F');

            // ---- Row 1 ----
            // Brand — left
            doc.setFontSize(14);
            doc.setFont('helvetica', 'bold');
            doc.setTextColor(...accentRGB);
            doc.text('iTeaGrow', MARGIN, 11);

            // Separator
            doc.setFontSize(12);
            doc.setTextColor(60, 60, 60);
            doc.text('|', MARGIN + 28, 11);

            // Title
            doc.setFontSize(11);
            doc.setFont('helvetica', 'normal');
            doc.setTextColor(210, 210, 210);
            doc.text('Data Collection Export', MARGIN + 33, 11);

            // Dataset label — right aligned
            doc.setFontSize(10);
            doc.setFont('helvetica', 'bold');
            doc.setTextColor(...accentRGB);
            doc.text(safeStr(source.label), PW - MARGIN, 11, { align: 'right' });

            // ---- Row 2 ----
            doc.setFontSize(7);
            doc.setFont('helvetica', 'normal');
            doc.setTextColor(120, 120, 120);

            // Left — collection path (max width so it never hits the right block)
            const subtitleText = `Collection: ${safeStr(source.subtitle)}`;
            doc.text(subtitleText, MARGIN, 20, { maxWidth: 160 });

            // Right block — two separate items so nothing overflows
            const rightLine1 = `Cols: ${cols.length} / ${columns.length}`;
            const rightLine2 = `Rows: ${rows.length}`;
            doc.text(rightLine1, PW - MARGIN, 17, { align: 'right' });
            doc.text(rightLine2, PW - MARGIN, 22, { align: 'right' });

            // Bottom rule
            doc.setDrawColor(...accentRGB);
            doc.setLineWidth(0.5);
            doc.line(0, HEADER_H, PW, HEADER_H);
        };

        const drawFooter = (doc, pageNum, totalPages) => {
            doc.setDrawColor(40, 40, 40);
            doc.setLineWidth(0.3);
            doc.line(0, PH - FOOTER_H, PW, PH - FOOTER_H);
            doc.setFillColor(10, 10, 10);
            doc.rect(0, PH - FOOTER_H, PW, FOOTER_H, 'F');

            doc.setFontSize(7);
            doc.setFont('helvetica', 'normal');
            // Left — timestamp
            doc.setTextColor(90, 90, 90);
            doc.text(`Exported: ${exportedAt}`, MARGIN, PH - 3.5);
            // Centre — file name (truncated)
            doc.setTextColor(65, 65, 65);
            const fnDisplay = filename.length > 50 ? filename.slice(0, 47) + '...' : filename;
            doc.text(fnDisplay, PW / 2, PH - 3.5, { align: 'center' });
            // Right — page number
            doc.setFont('helvetica', 'bold');
            doc.setTextColor(...accentRGB);
            doc.text(`Page ${pageNum} / ${totalPages}`, PW - MARGIN, PH - 3.5, { align: 'right' });
        };

        drawHeader(pdf);

        autoTable(pdf, {
            startY: HEADER_H + 2,
            margin: { top: HEADER_H + 2, bottom: FOOTER_H + 3, left: MARGIN, right: MARGIN },
            head: [cols.map(safeStr)],
            body: rows.map(r => cols.map(c => safeStr(cellStr(r[c])))),
            styles: {
                fontSize: isMarket ? 9 : 7,
                cellPadding: 2.5,
                overflow: 'linebreak',
                fillColor: [18, 18, 18],
                textColor: [210, 210, 210],
            },
            headStyles: {
                fillColor: [28, 28, 28],
                textColor: accentRGB,
                fontStyle: 'bold',
                fontSize: isMarket ? 9 : 7.5,
                cellPadding: 3,
            },
            alternateRowStyles: { fillColor: [23, 23, 23] },
            tableLineColor: [45, 45, 45],
            tableLineWidth: 0.15,
            didDrawPage: () => { drawHeader(pdf); },
        });

        // Re-draw footer on every page once total is known
        const totalPages = pdf.internal.getNumberOfPages();
        for (let i = 1; i <= totalPages; i++) {
            pdf.setPage(i);
            drawFooter(pdf, i, totalPages);
        }

        pdf.save(`${filename}.pdf`);
        return;
    }

    if (format === 'csv') {
        const escape = v => { const s = cellStr(v); return s.includes(',') || s.includes('"') || s.includes('\n') ? `"${s.replace(/"/g, '""')}"` : s; };
        const metaLines = [
            `# iTeaGrow - Data Collection Export`,
            `# Dataset  : ${source.label}`,
            `# Collection: ${source.subtitle}`,
            `# Exported : ${new Date().toLocaleString()}`,
            `# Records  : ${rows.length}   Columns: ${cols.length}`,
            `# File     : ${filename}.csv`,
            `#`,
        ];
        const dataLines = [cols.map(escape).join(','), ...rows.map(r => cols.map(c => escape(r[c])).join(','))];
        downloadBlob([...metaLines, ...dataLines].join('\r\n'), `${filename}.csv`, 'text/csv;charset=utf-8;');
        return;
    }

    if (format === 'xlsx') {
        const wb = XLSX.utils.book_new();

        // ── Meta sheet ──
        const metaRows = [
            ['iTeaGrow - Data Collection Export'],
            [],
            ['Dataset',    source.label],
            ['Collection', source.subtitle],
            ['Exported',   new Date().toLocaleString()],
            ['Records',    rows.length],
            ['Columns',    cols.length],
            ['File',       `${filename}.xlsx`],
        ];
        const metaWs = XLSX.utils.aoa_to_sheet(metaRows);
        metaWs['!cols'] = [{ wch: 16 }, { wch: 60 }];
        XLSX.utils.book_append_sheet(wb, metaWs, 'Info');

        // ── Data sheet ──
        const aoaData = [cols, ...rows.map(r => cols.map(c => r[c] != null && typeof r[c] === 'object' ? JSON.stringify(r[c]) : r[c]))];
        const ws = XLSX.utils.aoa_to_sheet(aoaData);
        ws['!autofilter'] = { ref: ws['!ref'] };
        XLSX.utils.book_append_sheet(wb, ws, source.label.slice(0, 31));

        XLSX.writeFile(wb, `${filename}.xlsx`);
        return;
    }

    if (format === 'json') {
        const filtered = rows.map(r => Object.fromEntries(cols.map(c => [c, r[c] !== undefined ? r[c] : null])));
        const output = {
            meta: {
                exported_by: 'iTeaGrow Data Collection',
                dataset: source.label,
                collection: source.subtitle,
                exported_at: new Date().toISOString(),
                total_records: rows.length,
                columns: cols.length,
                filename: `${filename}.json`,
            },
            data: filtered,
        };
        downloadBlob(JSON.stringify(output, null, 2), `${filename}.json`, 'application/json');
        return;
    }

    if (format === 'txt') {
        const colWidths = cols.map(c => Math.min(30, Math.max(c.length, ...rows.map(r => cellStr(r[c]).length))));
        const pad = (s, w) => String(s).slice(0, w).padEnd(w);
        const sep = colWidths.map(w => '-'.repeat(w + 2)).join('+');
        const totalWidth = sep.length;
        const centerLine = (s) => {
            const space = Math.max(0, totalWidth - s.length);
            return ' '.repeat(Math.floor(space / 2)) + s;
        };
        const headerBlock = [
            '='.repeat(totalWidth),
            centerLine('iTeaGrow - Data Collection Export'),
            centerLine(`Dataset   : ${source.label}`),
            centerLine(`Collection: ${source.subtitle}`),
            centerLine(`Exported  : ${new Date().toLocaleString()}`),
            centerLine(`Records   : ${rows.length}   Columns: ${cols.length}`),
            '='.repeat(totalWidth),
            '',
        ];
        const tableHead = cols.map((c, i) => ' ' + pad(c, colWidths[i]) + ' ').join('|');
        const tableRows = rows.map(r => cols.map((c, i) => ' ' + pad(cellStr(r[c]), colWidths[i]) + ' ').join('|'));
        const lines = [...headerBlock, sep, tableHead, sep, ...tableRows, sep];
        downloadBlob(lines.join('\n'), `${filename}.txt`, 'text/plain;charset=utf-8;');
        return;
    }
};

const downloadBlob = (content, filename, mime) => {
    const blob = new Blob([content], { type: mime });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = filename; a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
};

// ---------------------------------------------------------------
// Export Modal
// ---------------------------------------------------------------
const FORMATS = [
    { id: 'pdf',  label: 'PDF',  icon: FileText,  desc: 'Formatted report' },
    { id: 'csv',  label: 'CSV',  icon: Table2,    desc: 'Comma-separated' },
    { id: 'xlsx', label: 'XLSX', icon: Sheet,     desc: 'Excel workbook' },
    { id: 'json', label: 'JSON', icon: FileJson,  desc: 'Raw JSON array' },
    { id: 'txt',  label: 'TXT',  icon: FileText,  desc: 'Tab-aligned text' },
];

const ExportModal = ({ source, data, onClose }) => {
    const { columns } = useMemo(() => deriveColumnsAndRows(source, data), [source, data]);
    const [selected, setSelected] = useState(() => new Set(columns));
    const [format, setFormat] = useState('pdf');

    const toggleCol = (col) =>
        setSelected(prev => { const s = new Set(prev); s.has(col) ? s.delete(col) : s.add(col); return s; });
    const selectAll = () => setSelected(new Set(columns));
    const selectNone = () => setSelected(new Set());

    const handleExport = () => {
        runExport(source, data, columns.filter(c => selected.has(c)), format);
        onClose();
    };

    const accentColor = source.color;

    return (
        <div className="dc-modal-overlay" onClick={onClose}>
            <div className="dc-modal" onClick={e => e.stopPropagation()}>
                {/* Modal header */}
                <div className="dc-modal-header" style={{ borderBottom: `1px solid ${accentColor}30` }}>
                    <div className="dc-modal-title">
                        <Download size={18} color={accentColor} />
                        <span>Export — <span style={{ color: accentColor }}>{source.label}</span></span>
                    </div>
                    <button className="dc-modal-close" onClick={onClose}><X size={18} /></button>
                </div>

                <div className="dc-modal-body">
                    {/* Format selector */}
                    <div className="dc-modal-section">
                        <p className="dc-modal-label">Format</p>
                        <div className="dc-format-grid">
                            {FORMATS.map(f => {
                                const Icon = f.icon;
                                const active = format === f.id;
                                return (
                                    <button
                                        key={f.id}
                                        className={`dc-format-btn ${active ? 'dc-format-active' : ''}`}
                                        style={active ? { borderColor: accentColor, color: accentColor } : {}}
                                        onClick={() => setFormat(f.id)}
                                    >
                                        <Icon size={20} />
                                        <span className="dc-format-label">{f.label}</span>
                                        <span className="dc-format-desc">{f.desc}</span>
                                    </button>
                                );
                            })}
                        </div>
                    </div>

                    {/* Column selector */}
                    <div className="dc-modal-section">
                        <div className="dc-modal-label-row">
                            <p className="dc-modal-label">Columns &nbsp;<span className="dc-col-count">{selected.size} / {columns.length} selected</span></p>
                            <div className="dc-col-actions">
                                <button onClick={selectAll}>All</button>
                                <button onClick={selectNone}>None</button>
                            </div>
                        </div>
                        <div className="dc-col-grid">
                            {columns.map(col => {
                                const checked = selected.has(col);
                                return (
                                    <button
                                        key={col}
                                        className={`dc-col-chip ${checked ? 'dc-col-checked' : ''}`}
                                        style={checked ? { borderColor: `${accentColor}60`, background: `${accentColor}15`, color: accentColor } : {}}
                                        onClick={() => toggleCol(col)}
                                    >
                                        {checked ? <CheckSquare size={13} /> : <Square size={13} />}
                                        <span>{col}</span>
                                    </button>
                                );
                            })}
                        </div>
                    </div>
                </div>

                {/* Footer */}
                <div className="dc-modal-footer">
                    <button className="dc-btn" onClick={onClose}>Cancel</button>
                    <button
                        className="dc-btn dc-btn-download"
                        style={{ background: accentColor, borderColor: accentColor, color: '#fff' }}
                        disabled={selected.size === 0}
                        onClick={handleExport}
                    >
                        <Download size={15} />
                        Download {format.toUpperCase()}
                    </button>
                </div>
            </div>
        </div>
    );
};

// ---------------------------------------------------------------
// Main Page Component
// ---------------------------------------------------------------
const DataCollection = () => {
    const [activeTab, setActiveTab] = useState(DATA_SOURCES[0].key);
    const [dataMap, setDataMap] = useState({});      // key → { data, loading, error }
    const [pageMap, setPageMap] = useState({});      // key → current page number
    const [exportOpen, setExportOpen] = useState(false);

    const getState = (key) => dataMap[key] || { data: null, loading: false, error: null };

    const fetchData = useCallback(async (source) => {
        setDataMap(prev => ({ ...prev, [source.key]: { data: null, loading: true, error: null } }));
        try {
            const res = await fetch(source.endpoint);
            if (!res.ok) throw new Error(`HTTP ${res.status}`);
            const json = await res.json();
            setDataMap(prev => ({ ...prev, [source.key]: { data: json.data, loading: false, error: null } }));
            setPageMap(prev => ({ ...prev, [source.key]: 1 }));
        } catch (err) {
            setDataMap(prev => ({ ...prev, [source.key]: { data: null, loading: false, error: err.message } }));
        }
    }, []);

    const handleTabClick = (source) => {
        setActiveTab(source.key);
        // Auto-fetch if not loaded yet
        if (!dataMap[source.key]) {
            fetchData(source);
        }
    };

    const activeSource = DATA_SOURCES.find(s => s.key === activeTab);
    const activeState = getState(activeTab);
    const activePage = pageMap[activeTab] || 1;

    return (
        <div className="dc-container">
            {/* Header */}
            <header className="dc-header">
                <div>
                    <h1 className="dc-title">Data Collection</h1>
                    <p className="dc-subtitle">Browse and export live data from all iTeaGrow databases.</p>
                </div>
                <div className="dc-header-actions">
                    <button
                        className="dc-btn dc-btn-refresh"
                        onClick={() => fetchData(activeSource)}
                        disabled={activeState.loading}
                        title="Refresh data"
                    >
                        <RefreshCw size={16} className={activeState.loading ? 'spin' : ''} />
                        Refresh
                    </button>
                    <button
                        className="dc-btn dc-btn-download"
                        onClick={() => setExportOpen(true)}
                        disabled={!activeState.data || activeState.data.length === 0}
                        title="Export data"
                    >
                        <Download size={16} />
                        Export
                    </button>
                </div>
            </header>

            {/* Source Cards (Tab Bar) */}
            <div className="dc-tabs">
                {DATA_SOURCES.map(source => {
                    const Icon = source.icon;
                    const state = getState(source.key);
                    const isActive = activeTab === source.key;
                    return (
                        <button
                            key={source.key}
                            className={`dc-tab ${isActive ? 'dc-tab-active' : ''}`}
                            style={isActive ? {
                                background: `rgba(45, 50, 56, 0.90)`,
                                borderColor: source.color,
                                borderWidth: '1.5px',
                                boxShadow: `0 4px 20px ${source.color}50, 0 2px 10px rgba(0,0,0,0.5)`,
                            } : {}}
                            onClick={() => handleTabClick(source)}
                        >
                            <div className="dc-tab-icon" style={{ color: isActive ? source.color : '#fff' }}>
                                <Icon size={20} />
                            </div>
                            <div className="dc-tab-info">
                                <span className="dc-tab-label" style={{ color: isActive ? source.color : '#fff' }}>
                                    {source.label}
                                </span>
                                <span className="dc-tab-sub">{source.subtitle}</span>
                                {state.data && (
                                    <span className="dc-tab-count" style={{ color: source.color }}>
                                        {state.data.length} records
                                    </span>
                                )}
                            </div>
                        </button>
                    );
                })}
            </div>

            {/* Data Panel */}
            <div className="dc-panel" style={{ borderColor: activeSource.border }}>
                <div className="dc-panel-header" style={{ borderBottom: `1px solid ${activeSource.border}` }}>
                    <div className="dc-panel-title">
                        {React.createElement(activeSource.icon, { size: 18, color: activeSource.color })}
                        <span style={{ color: activeSource.color }}>{activeSource.label}</span>
                        <code className="dc-collection-badge">{activeSource.subtitle}</code>
                    </div>
                </div>

                <div className="dc-panel-body">
                    {/* Not yet loaded */}
                    {!activeState.data && !activeState.loading && !activeState.error && (
                        <div className="dc-placeholder">
                            <Database size={48} color="#333" />
                            <p>Click <strong>Refresh</strong> to load data from this collection.</p>
                        </div>
                    )}

                    {/* Loading */}
                    {activeState.loading && (
                        <div className="dc-loading">
                            <RefreshCw size={32} color={activeSource.color} className="spin" />
                            <p style={{ color: activeSource.color }}>Fetching from {activeSource.subtitle}…</p>
                        </div>
                    )}

                    {/* Error */}
                    {activeState.error && (
                        <div className="dc-error">
                            <p>⚠ Failed to load: {activeState.error}</p>
                            <button className="dc-btn dc-btn-refresh" onClick={() => fetchData(activeSource)}>
                                <RefreshCw size={14} /> Retry
                            </button>
                        </div>
                    )}

                    {/* Data Table / Market Table */}
                    {activeState.data && !activeState.loading && (
                        activeTab === 'market'
                            ? <MarketTable data={activeState.data} color={activeSource.color} />
                            : <DataTable
                                data={activeState.data}
                                page={activePage}
                                onPage={(fn) => setPageMap(prev => ({ ...prev, [activeTab]: fn(prev[activeTab] || 1) }))}
                                color={activeSource.color}
                            />
                    )}
                </div>
            </div>

            {/* Export Modal */}
            {exportOpen && activeState.data && (
                <ExportModal
                    source={activeSource}
                    data={activeState.data}
                    onClose={() => setExportOpen(false)}
                />
            )}

            <style>{`
                .spin { animation: spin 1s linear infinite; }
                @keyframes spin { 0%{transform:rotate(0deg)} 100%{transform:rotate(360deg)} }
            `}</style>
        </div>
    );
};

export default DataCollection;
