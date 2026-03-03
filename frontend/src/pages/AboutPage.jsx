
import React, { useEffect } from 'react';
import { Cpu, Wifi, Globe, Activity, Users, Award, ShieldCheck, Microscope, Linkedin, Github, ExternalLink, GraduationCap } from 'lucide-react';
import '../css/AboutPage.css';

const AboutPage = () => {
    useEffect(() => {
        window.scrollTo(0, 0);
    }, []);

    return (
        <div className="about-page formal-research-theme">
            <div className="about-container">
                {/* Formal Hero Section */}
                <header className="research-hero">
                    <div className="badge-container">
                        <span className="research-badge">Official Research Platform</span>
                    </div>
                    <h1>Intelligence Meets <span className="accent">Heritage</span></h1>
                    <p className="hero-subtitle">
                        An integrated AI-IoT framework spearheading precision agriculture 
                        for the Sri Lankan tea value chain.
                    </p>
                </header>

                {/* Core Philosophy Section */}
                <section className="research-section philosophy-grid">
                    <div className="section-header centered">
                        <Award className="section-icon" />
                        <h2>Our Research Core</h2>
                        <div className="rule-line"></div>
                    </div>
                    
                    <div className="philosophy-content">
                        <div className="philosophy-text glass-panel">
                            <h3>Bridging the Modernity Gap</h3>
                            <p>
                                iTeaGrow serves as a bridge between traditional manual estate management and 
                                next-generation data science. Our mission is to preserve the century-old 
                                expertise of Ceylon tea while empowering it with <strong>Explainable AI (XAI)</strong>.
                            </p>
                            <p>
                                We believe that technology should not replace the human touch, but rather 
                                illuminate it with actionable, data-driven insights.
                            </p>
                        </div>
                        <div className="philosophy-stats glass-panel">
                            <div className="stat-row">
                                <Microscope size={24} />
                                <div>
                                    <h4>Scientific Validation</h4>
                                    <p>Models calibrated against TRI standards.</p>
                                </div>
                            </div>
                            <div className="stat-row">
                                <ShieldCheck size={24} />
                                <div>
                                    <h4>Data Integrity</h4>
                                    <p>Encrypted, sovereign data ownership.</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>

                {/* Technical Stack - Symmetrical Cards */}
                <section className="research-section">
                    <div className="section-header centered">
                        <h2>Infrastructure Pillars</h2>
                        <p>The technological foundation of the iTeaGrow ecosystem.</p>
                    </div>

                    <div className="tech-stack-grid">
                        <div className="tech-card glass-panel">
                            <div className="tech-icon-box">
                                <Cpu size={32} />
                            </div>
                            <h3>Explainable AI</h3>
                            <p>Deploying advanced CNN architectures with Grad-CAM visualizations to ensure ML transparency in disease detection and leaf grading.</p>
                        </div>

                        <div className="tech-card glass-panel">
                            <div className="tech-icon-box">
                                <Wifi size={32} />
                            </div>
                            <h3>Hybrid IoT</h3>
                            <p>Custom-engineered low-power wide-area networks (LPWAN) designed to transmit sensor data through challenging mountainous terrain.</p>
                        </div>

                        <div className="tech-card glass-panel">
                            <div className="tech-icon-box">
                                <Globe size={32} />
                            </div>
                            <h3>Edge Intelligence</h3>
                            <p>Mobile-first inference ensures that complex ML models run locally on field devices, providing zero-latency support in remote estates.</p>
                        </div>
                    </div>
                </section>


                {/* Research Supervision Section */}
                <section className="research-section team-research">
                    <div className="section-header centered">
                        <GraduationCap className="section-icon" />
                        <h2>Research Supervision</h2>
                    </div>

                    <div className="formal-team-grid">
                        <div className="member-row glass-panel supervisor-card">
                            <div className="member-info">
                                <span className="supervisor-tag">Research Supervisor</span>
                                <h3>Ms. Shashika Lokuliyana</h3>
                                <span className="member-role">Senior Lecturer, Sri Lanka Institute of Information Technology</span>
                                <div className="member-socials">
                                    <a href="https://www.sliit.lk/faculty-of-computing/staff/shashika.l/" target="_blank" rel="noopener noreferrer">
                                        <ExternalLink size={18} />
                                    </a>
                                </div>
                            </div>
                        </div>
                        <div className="member-row glass-panel supervisor-card">
                            <div className="member-info">
                                <span className="supervisor-tag co-supervisor-tag">Research Co-Supervisor</span>
                                <h3>Mr. Uditha Dharmakeerthi</h3>
                                <span className="member-role">Academic Fellow / Lecturer, Sri Lanka Institute of Information Technology</span>
                                <div className="member-socials">
                                    <a href="https://www.sliit.lk/faculty-of-computing/staff/uditha.d/" target="_blank" rel="noopener noreferrer">
                                        <ExternalLink size={18} />
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>

                {/* Formal Team Section */}
                <section className="research-section team-research">
                    <div className="section-header centered">
                        <Users className="section-icon" />
                        <h2>Innovators & Researchers</h2>
                    </div>
                    
                    <div className="formal-team-grid">
                        <div className="member-row glass-panel">
                            <div className="member-info">
                                <h3>Kajanthan Kirubakaran</h3>
                                <span className="member-role">Research Team Lead, System Architect, AI/ML, Full Stack Developer</span>
                                <p className="member-contribution">Developed Tea Leaf Disease Identification & Environmental Monitoring System (IoT).</p>
                                <div className="member-socials">
                                    <a href="https://www.linkedin.com/in/kajanthan-kirubakaran-37049b290/" target="_blank" rel="noopener noreferrer"><Linkedin size={18} /></a>
                                    <a href="https://github.com/Thomiantrooper" target="_blank" rel="noopener noreferrer"><Github size={18} /></a>
                                </div>
                            </div>
                        </div>
                        <div className="member-row glass-panel">
                            <div className="member-info">
                                <h3>Kanzurrizk Rihan</h3>
                                <span className="member-role">AI/ML & Full Stack Developer</span>
                                <p className="member-contribution">Developed Tea Leaf Maturity & Yield Predictive Analytics for the iTeaGrow ecosystem.</p>
                                <div className="member-socials">
                                    <a href="https://www.linkedin.com/in/kanzurrizk/" target="_blank" rel="noopener noreferrer"><Linkedin size={18} /></a>
                                    <a href="https://github.com/kanzur" target="_blank" rel="noopener noreferrer"><Github size={18} /></a>
                                </div>
                            </div>
                        </div>
                        <div className="member-row glass-panel">
                            <div className="member-info">
                                <h3>Ashwin Visvanathan</h3>
                                <span className="member-role">IoT Systems & Full Stack Developer</span>
                                <p className="member-contribution">Developed Soil Monitoring System (IoT) and Fertilizer Recommendation System.</p>
                                <div className="member-socials">
                                    <a href="https://www.linkedin.com/in/ashwin-visvanathan-3b1601309/" target="_blank" rel="noopener noreferrer"><Linkedin size={18} /></a>
                                    <a href="https://github.com/Ashwinvisva" target="_blank" rel="noopener noreferrer"><Github size={18} /></a>
                                </div>
                            </div>
                        </div>
                        <div className="member-row glass-panel">
                            <div className="member-info">
                                <h3>Thisuri Peiris</h3>
                                <span className="member-role">AI/ML & Full Stack Developer</span>
                                <p className="member-contribution">Developed Tea Powder Grading and Tea Market Value Analysis system.</p>
                                <div className="member-socials">
                                    <a href="https://www.linkedin.com/in/thisuripeiris/" target="_blank" rel="noopener noreferrer"><Linkedin size={18} /></a>
                                    <a href="https://github.com/thisuripeiris" target="_blank" rel="noopener noreferrer"><Github size={18} /></a>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>

                <footer className="research-footer">
                    <div className="footer-line"></div>
                </footer>
            </div>
        </div>
    );
};

export default AboutPage;
