import React, { useEffect } from 'react';
import { Sprout, BookOpen, Globe, Award, TrendingUp, Users, Map, Heart } from 'lucide-react';
import '../css/HistoryPage.css';

const HistoryPage = () => {
    useEffect(() => {
        window.scrollTo(0, 0);
    }, []);

    return (
        <div className="history-page">
            <div className="history-container heritage-staggered">
                {/* Main Header */}
                <header className="unboxed-header">
                    <div className="history-badge">
                        <BookOpen size={14} />
                        <span>Preserving a 150-Year Legacy</span>
                    </div>
                    <h1>The History of Sri Lankan Tea</h1>
                </header>

                <div className="heritage-flow">
                    {/* Node 1: Origins */}
                    <div className="history-node">
                        <div className="node-content glass-panel">
                            <div className="node-header">
                                <Sprout className="node-icon" />
                                <h2>Origins of the Ceylon Tea Industry</h2>
                            </div>
                            <p>
                                The history of Sri Lankan tea begins in the nineteenth century during British colonial rule. 
                                Before tea became the island’s defining crop, Sri Lanka, then known as Ceylon, was a major coffee producer. 
                                By the 1860s, the coffee industry collapsed due to a fungal disease known as coffee rust, 
                                scientifically identified as Hemileia vastatrix. The destruction of coffee plantations created an urgent 
                                need for an alternative commercial crop that could sustain the colonial economy.
                            </p>
                            <p>
                                In 1867, Scottish planter <strong>James Taylor</strong> introduced commercial tea cultivation at the 
                                Loolecondera Estate in Kandy. His initial plantation of nineteen acres marked the birth of the 
                                Ceylon tea industry. Taylor also developed systematic manufacturing processes, including controlled withering, 
                                rolling, fermentation, and drying. These techniques formed the foundation of Sri Lanka’s modern tea production methods.
                            </p>
                        </div>
                    </div>

                    {/* Node 2: Expansion */}
                    <div className="history-node">
                        <div className="node-content glass-panel">
                            <div className="node-header">
                                <Globe className="node-icon" />
                                <h2>Expansion Across the Highlands</h2>
                            </div>
                            <p>
                                Following early success, tea cultivation expanded rapidly across the central highlands. 
                                The island’s elevation, rainfall patterns, soil composition, and tropical climate created ideal growing conditions. 
                                Former coffee estates were gradually converted into tea plantations, transforming both the landscape 
                                and the economic structure of the hill country.
                            </p>
                            <p>
                                Infrastructure development played a critical role in this expansion. Railway networks were constructed to 
                                connect tea estates to the port of Colombo, enabling efficient export to global markets. 
                                By the end of the nineteenth century, Ceylon tea had gained international recognition 
                                for its bright liquor, brisk character, and consistent quality.
                            </p>
                        </div>
                    </div>

                    {/* Node 3: Institutional Growth */}
                    <div className="history-node">
                        <div className="node-content glass-panel">
                            <div className="node-header">
                                <Award className="node-icon" />
                                <h2>Institutional Growth and quality Regulation</h2>
                            </div>
                            <p>
                                As the industry matured, formal institutions were established to safeguard quality and ensure long term sustainability. 
                                The Tea Research Institute was founded in 1925 to advance scientific research in cultivation and processing. 
                                The Colombo Tea Auction became one of the largest and most influential tea auctions in the world, 
                                setting benchmark prices and facilitating international trade.
                            </p>
                            <p>
                                The Sri Lanka Tea Board later assumed responsibility for regulation, quality assurance, and global promotion. 
                                In 1999, the <strong>Lion Logo</strong> was introduced as a certification mark to guarantee that tea labeled as 
                                Pure Ceylon Tea is entirely grown and packed in Sri Lanka under strict standards. 
                                In 2011, Ceylon Tea received Geographical Indication protection, further reinforcing its authenticity 
                                and global identity.
                            </p>
                            <p className="legacy-statement">
                                Today, Sri Lanka’s tea industry represents more than 150 years of continuous cultivation, 
                                refinement, and international trade.
                            </p>
                        </div>
                    </div>

                    {/* Node 4: Economic Importance */}
                    <div className="history-node">
                        <div className="node-content glass-panel">
                            <div className="node-header">
                                <TrendingUp className="node-icon" />
                                <h2>The Value of Sri Lankan Tea: Economic Importance</h2>
                            </div>
                            <p>
                                Tea remains one of Sri Lanka’s most significant export commodities and a major contributor to national foreign exchange earnings. 
                                The country consistently ranks among the world’s leading exporters of black tea. 
                                Annual production generally ranges between 300,000 and 320,000 metric tons, with the majority 
                                destined for international markets in the Middle East, Europe, Russia, and Asia.
                            </p>
                            <p>
                                Revenue generated from tea exports plays a stabilizing role in the national economy, 
                                particularly during periods of financial volatility. The sector continues to be a strategic 
                                agricultural asset for the country.
                            </p>
                        </div>
                    </div>

                    {/* Node 5: Employment */}
                    <div className="history-node">
                        <div className="node-content glass-panel">
                            <div className="node-header">
                                <Users className="node-icon" />
                                <h2>Employment and Rural Development</h2>
                            </div>
                            <p>
                                The tea industry supports the livelihoods of more than one million Sri Lankans directly and indirectly. 
                                Employment extends across plantation communities, smallholder farmers, factory workers, transport operators, 
                                exporters, and packaging industries.
                            </p>
                            <p>
                                Smallholder farmers now contribute a substantial proportion of national tea production. 
                                This shift has strengthened rural entrepreneurship and increased community level economic resilience, 
                                particularly in tea growing regions.
                            </p>
                        </div>
                    </div>

                    {/* Node 6: Regional Diversity */}
                    <div className="history-node">
                        <div className="node-content glass-panel">
                            <div className="node-header">
                                <Map className="node-icon" />
                                <h2>Regional Diversity and Competitive Advantage</h2>
                            </div>
                            <p>
                                One of the defining strengths of Ceylon Tea lies in its regional diversity. 
                                Tea grown at different elevations produces distinctive flavor characteristics shaped by climate and geography.
                            </p>
                            <p>
                                High grown teas from areas such as Nuwara Eliya are known for their light color, delicate aroma, and refined taste. 
                                Mid grown teas from regions like Dimbula and Uva offer balanced body and briskness. 
                                Low grown teas from Ruhuna and Sabaragamuwa are typically stronger, darker, and full bodied.
                            </p>
                            <p>
                                This natural differentiation allows Sri Lanka to serve multiple global market segments 
                                while maintaining a premium reputation.
                            </p>
                        </div>
                    </div>

                    {/* Node 7: Cultural Significance */}
                    <div className="history-node">
                        <div className="node-content glass-panel">
                            <div className="node-header">
                                <Heart className="node-icon" />
                                <h2>Cultural and National Significance</h2>
                            </div>
                            <p>
                                Beyond economics, tea holds cultural importance within Sri Lanka. 
                                The industry has shaped the social and demographic history of the hill country and 
                                remains closely tied to the island’s national identity. 
                                Ceylon Tea is recognized internationally not only as an agricultural product but 
                                as a symbol of quality, heritage, and authenticity.
                            </p>
                            <p>
                                For more than a century, Sri Lankan tea has maintained a reputation for purity, consistency, and craftsmanship. 
                                It stands today as one of the country’s most enduring and valuable contributions to global agriculture and trade.
                            </p>
                        </div>
                    </div>
                </div>

                <footer className="history-footer-final">
                    <p>iTeaGrow Preservation Project — Crafting the Future of Heritage</p>
                </footer>
            </div>
        </div>
    );
};

export default HistoryPage;
