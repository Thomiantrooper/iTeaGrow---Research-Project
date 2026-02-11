
import React from 'react';

import '../css/TeaBackground.css';

const TeaBackground = () => {
    return (
        <div className="tea-background">
            <div 
                className="bg-image"
                style={{ backgroundImage: `url("/tea_hero.png?v=1")` }}
            ></div>
            <div className="bg-overlay"></div>
        </div>
    );
};

export default TeaBackground;
