import React from 'react';
import '../css/TeaBackground.css';

const TeaBackground = () => {
  return (
    <div className="tea-background">
      <div className="leaf-layer layer-1"></div>
      <div className="leaf-layer layer-2"></div>
      <div className="gradient-overlay"></div>
    </div>
  );
};

export default TeaBackground;
