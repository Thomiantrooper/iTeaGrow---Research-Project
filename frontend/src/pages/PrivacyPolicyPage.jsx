import React from 'react';
import '../css/AboutPage.css'; // Reusing about page styles for formal look

const PrivacyPolicyPage = () => {
    return (
        <div className="about-page formal-research-theme">
            <div className="about-container">
                <header className="research-hero">
                    <div className="badge-container">
                        <span className="research-badge">Legal</span>
                    </div>
                    <h1>Privacy <span className="accent">Policy</span></h1>
                    <p className="hero-subtitle">
                        Your privacy is critically important to us. This policy outlines how iTeaGrow collects, uses, and protects your information.
                    </p>
                </header>

                <div className="philosophy-grid">
                    <div className="philosophy-content" style={{ gridTemplateColumns: '1fr' }}>
                        <div className="philosophy-text">
                            <h3>1. Target Audience & Age Restrictions</h3>
                            <p>
                                The iTeaGrow platform, encompassing both our Web Application and our Mobile Application (available on the Google Play Store), is specifically designed for <strong>farmers, agricultural managers, and other tea-related personnel</strong>. Services within this application are strictly intended for users who are <strong>13 years of age and older</strong>.
                            </p>

                            <h3 style={{ marginTop: '40px' }}>2. Information We Collect</h3>
                            <p>
                                We only collect information about you if we have a reason to do so—for example, to provide our Services (both Web and Mobile), to communicate with you, or to make our Services better.
                            </p>
                            <ul>
                                <li><strong>Information you provide to us:</strong> Account information, profile details, and communication data.</li>
                                <li><strong>Information we collect automatically:</strong> Log data, usage information, and location data/scans from mobile devices relevant to agricultural metrics.</li>
                            </ul>

                            <h3 style={{ marginTop: '40px' }}>3. How We Use Information</h3>
                            <p>
                                We use the information we collect to provide our Services to you, to communicate with you, to troubleshoot problems, protect against abuse, and improve our Services. Examples include optimizing yield predictions, providing real-time IoT readings, and securing your account.
                            </p>

                            <h3 style={{ marginTop: '40px' }}>4. Sharing Information</h3>
                            <p>
                                We do not sell your personal information. We may share information with vendors who need to know information about you in order to provide their services to us, or as required by legal obligations.
                            </p>
                            
                            <h3 style={{ marginTop: '40px' }}>5. User Responsibilities & Data Security</h3>
                            <p>
                                Because this application handles critical predictive data and farm metrics, we strongly advise users to <strong>handle the platform carefully</strong>. Please ensure the accuracy of your inputs (like leaf maturity scans or IoT configurations) and keep your devices secure while using the app in the tea estates.
                            </p>
                            <p>
                                While no online service is 100% secure, we work very hard to protect information about you against unauthorized access, use, alteration, or destruction.
                            </p>

                             <h3 style={{ marginTop: '40px' }}>6. Changes to this Policy</h3>
                            <p>
                                We may update this Privacy Policy from time to time. We encourage visitors to frequently check this page for any changes. Your continued use of the Web and Play Store Mobile services after any change will constitute your acceptance of such change.
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default PrivacyPolicyPage;
