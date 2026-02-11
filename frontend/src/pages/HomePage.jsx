
import React from 'react';
import { Link } from 'react-router-dom';
import { ScanLine, Sprout, BarChart3, ChevronRight, Droplets, Sun, Activity } from 'lucide-react';
import '../css/HomePage.css';

const HomePage = () => {
    return (
        <div className="home-container">
            {/* Hero Section - Better Layout (Left Text, Right Visual) */}
            <section className="hero-section">
                <div className="hero-content">
                    <div className="hero-badge">
                        <span className="badge-dot"></span>
                        Trusted by Estates
                    </div>
                    <h1 className="hero-title">
                        Precision Agriculture for <br />
                        <span className="highlight-text">Ceylon Tea</span>
                    </h1>
                    <p className="hero-subtitle">
                        We combine explainable AI with a hybrid ready system to help tea estates increase yield, detect plant diseases at an early stage, and assess leaf maturity.
                    </p>
                    <p className="hero-subtitle">
                        Our platform also enables real-time monitoring of environmental and soil conditions, evaluating market value and grading tea powder with measurable scientific precision.
                    </p>
                    <div className="hero-actions">
                        <Link to="/about" className="btn btn-primary">
                            Explore Platform <ChevronRight size={18} />
                        </Link>
                        <Link to="/contact" className="btn btn-outline">
                            Request Demo
                        </Link>
                    </div>
                    
                    <div className="hero-stats">
                        <div className="stat-item">
                            <span className="stat-value">Best</span>
                            <span className="stat-label">Accuracy</span>
                        </div>
                        <div className="stat-separator"></div>
                        <div className="stat-item">
                            <span className="stat-value">Hybrid</span>
                            <span className="stat-label">Design</span>
                        </div>
                        <div className="stat-separator"></div>
                        <div className="stat-item">
                            <span className="stat-value">Real-time</span>
                            <span className="stat-label">Monitoring</span>
                        </div>
                    </div>
                </div>
                
                {/* Visual side removed to let background image shine, or use simple cards */}
                <div className="hero-floating-cards">
                     <div className="float-card card-glass">
                        <Activity className="icon-pulse" size={26} />
                        <div>
                            <h4>System Active</h4>
                            <span className="status-online">Operational</span>
                        </div>
                     </div>
                </div>
            </section>

            {/* Features Section - Grid Layout */}
            <section className="features-section">
                <div className="section-header">
                    <h2>Core Capabilities</h2>
                    <p>Designed for the field, powered by research.</p>
                </div>
                
                <div className="features-grid">
                    <div className="feature-card">
                        <div className="feature-main">
                            <div className="feature-icon-wrapper">
                                <ScanLine size={28} />
                            </div>
                            <h3>Disease Detection</h3>
                            <p>Real-time identification of fungal & nutrient issues using Computer Vision.</p>
                        </div>
                        <div className="feature-details">
                            <h4>Capabilities</h4>
                            <ul>
                                <li>Species (Assamica, DT1) & Maturity Analysis</li>
                                <li>Grad-CAM Heatmap Visualization</li>
                                <li>Real-time Confidence Analytics</li>
                                <li>Offline-first ML Inference</li>
                            </ul>
                        </div>
                    </div>
                    
                    <div className="feature-card">
                        <div className="feature-main">
                            <div className="feature-icon-wrapper">
                                <Sprout size={28} />
                            </div>
                            <h3>Maturity & Yield</h3>
                            <p>Automated leaf classification to predict factory-usable yield.</p>
                        </div>
                        <div className="feature-details">
                            <h4>Capabilities</h4>
                            <ul>
                                <li>Automated Leaf Classification</li>
                                <li>Factory-Usable Yield Prediction</li>
                                <li>Harvest Timing Optimization</li>
                                <li>Batch Quality Estimation</li>
                            </ul>
                        </div>
                    </div>
                    
                    <div className="feature-card">
                        <div className="feature-main">
                            <div className="feature-icon-wrapper">
                                <Sun size={28} />
                            </div>
                            <h3>Growth Analysis</h3>
                            <p>IoT-based soil monitoring (NPK, pH) with fertilization alerts.</p>
                        </div>
                        <div className="feature-details">
                            <h4>Capabilities</h4>
                            <ul>
                                <li>Real-time Soil Monitoring (NPK, pH)</li>
                                <li>TRI-Standard Fertilization Alerts</li>
                                <li>Environmental Tracking (Temp/Humidity)</li>
                                <li>Growth Stage Correlations</li>
                            </ul>
                        </div>
                    </div>

                    <div className="feature-card">
                        <div className="feature-main">
                            <div className="feature-icon-wrapper">
                                <BarChart3 size={28} />
                            </div>
                            <h3>Market Valuation</h3>
                            <p>AI-driven tea powder grading and price estimation.</p>
                        </div>
                        <div className="feature-details">
                            <h4>Capabilities</h4>
                            <ul>
                                <li>AI Powder Grading (Premium, A-C)</li>
                                <li>Quality Score Assessment (/100)</li>
                                <li>Market Value Analysis & Trends</li>
                                <li>Regional Price Tracking</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </section>

            {/* How It Works Section */}
            <section className="how-it-works-section">
                <div className="section-header center-text">
                    <h2>Simple, Powerful, Accessible</h2>
                    <p>Turn every smartphone into a precision agriculture tool.</p>
                </div>

                <div className="steps-container">
                    {/* Step 01 */}
                    <div className="step-card">
                        <div className="step-number">01</div>
                        <h3>Smart Phone & IoT</h3>
                        <p>Simply scan tea leaves with your phone or let installed IoT sensors monitor soil conditions 24/7.</p>
                    </div>

                    {/* Step 02 */}
                    <div className="step-card">
                        <div className="step-number">02</div>
                        <h3>AI Analysis</h3>
                        <p>Our advanced CNN architecture instantly analyzes visual and sensor data to identify patterns invisible to the naked eye.</p>
                    </div>

                    {/* Step 03 */}
                    <div className="step-card">
                        <div className="step-number">03</div>
                        <h3>Actionable Insights</h3>
                        <p>Receive clear, science-backed recommendations to treat diseases, optimize harvest time, and maximize market value.</p>
                    </div>
                </div>
            </section>

            {/* Mission Section - Enhanced Hook */}
            <section className="mission-section">
                <div className="mission-content-hook">
                    <h2 className="section-title">A Legacy Worth Protecting</h2>
                    <p className="hook-text">
                        For over a century, Ceylon Tea has stood as one of Sri Lanka’s most treasured legacies. 
                        Born from adversity and refined through generations, it continues to define quality, 
                        authenticity, and agricultural excellence on the global stage.
                    </p>
                    <div className="mission-actions">
                        <Link to="/history" className="btn btn-primary">Discover the History</Link>
                        <Link to="/about" className="link-secondary">Explore Our Purpose</Link>
                    </div>
                </div>
            </section>
        </div>
    );
};

export default HomePage;
