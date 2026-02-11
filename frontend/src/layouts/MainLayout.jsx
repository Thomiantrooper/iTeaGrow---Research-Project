
import React from 'react';
import { Outlet } from 'react-router-dom';
import Navbar from '../components/Navbar';
import TeaBackground from '../components/TeaBackground';
import Footer from '../components/Footer';
import '../css/index.css'; // Ensure global styles are applied

const MainLayout = () => {
    return (
        <div className="app-wrapper">
            <TeaBackground />
            <Navbar />
            <div className="main-content-container">
                <Outlet />
            </div>
            <Footer />
        </div>
    );
};

export default MainLayout;
