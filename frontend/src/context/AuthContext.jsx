
import React, { createContext, useState, useContext, useEffect } from 'react';

const AUTH_API = import.meta.env.VITE_AUTH_API_URL || 'https://authentication-iteagrow-api.up.railway.app';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Strict Session: No persistence on refresh.
        // If the user refreshes, 'user' state resets to null, effectively logging them out.
        setLoading(false);

        // Handle Browser Back Button (bfcache) & Tab Restoration
        const handlePageAccess = (event) => {
            // Check if we have a valid session flag in storage
            // This flag is CLEARED on logout. If it's missing, even if React state is restored, we must logout.
            const isSessionActive = sessionStorage.getItem('iteagrow_session_active');

            if (!isSessionActive) {
                // If no session flag, but we have a user in state (restored from cache), kill it.
                if (user) {
                   setUser(null);
                   window.location.href = '/login'; 
                } else if (window.location.pathname.startsWith('/admin')) {
                    // If we are on an admin page and no session flag, force login
                    window.location.href = '/login';
                }
            } else {
                 // If session is active, but event tells us usage of bfcache, reload to be safe and ensure logic runs
                 if (event && (event.persisted || (performance.getEntriesByType("navigation")[0] && performance.getEntriesByType("navigation")[0].type === "back_forward"))) {
                    window.location.reload();
                 }
            }
        };

        window.addEventListener('pageshow', handlePageAccess);
        // Also check on visibility change (switching tabs)
        document.addEventListener('visibilitychange', () => {
             if (document.visibilityState === 'visible') {
                 handlePageAccess();
             }
        });

        // initial check
        handlePageAccess();

        return () => {
            window.removeEventListener('pageshow', handlePageAccess);
            document.removeEventListener('visibilitychange', handlePageAccess);
        };
    }, [user]);

    // ... (Inactivity Timer Code - Unchanged) ...
    // Note: ensure you keep the inactivity timer useEffect here

    const login = async (email, password) => {
        try {
            const response = await fetch('/api/auth/login', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ email, password }),
            });

            const data = await response.json();

            if (response.ok) {
                setUser(data);
                // STRICT SECURITY: Do NOT save user data to localStorage.
                // WE ONLY save a simple flag to sessionStorage to validate the "Session" exists for this tab.
                // This flag does NOT contain data, just "I am logged in".
                sessionStorage.setItem('iteagrow_session_active', 'true');
                return { success: true, user: data };
            } else {
                return { success: false, message: data.message || 'Invalid credentials' };
            }
        } catch (error) {
            console.error('Login Error:', error);
            return { success: false, message: 'Server error. Please try again later.' };
        }
    };

    const googleLogin = async (idToken) => {
        try {
            const response = await fetch(`${AUTH_API}/api/users/google-login`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ id_token: idToken }),
            });

            const data = await response.json();

            if (response.ok) {
                // Auth API returns { access_token, user: { id, username, full_name, email, role, ... } }
                // Normalize to match the regular login shape used across the app (user.name, user._id)
                const userData = {
                    ...data.user,
                    _id: data.user.id,
                    name: data.user.full_name,          // Google gives full_name → map to name
                    username: data.user.username,       // auto-generated from email prefix
                    token: data.access_token,
                };
                setUser(userData);
                sessionStorage.setItem('iteagrow_session_active', 'true');
                return { success: true, user: userData };
            } else {
                return { success: false, message: data.detail || 'Google login failed' };
            }
        } catch (error) {
            console.error('Google Login Error:', error);
            return { success: false, message: 'Unable to connect. Please try again.' };
        }
    };

    const updateProfile = async (profileData) => {
        try {
            const response = await fetch('/api/auth/profile', {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${user.token}`
                },
                body: JSON.stringify(profileData),
            });

            const data = await response.json();

            if (response.ok) {
                setUser(data);
                return { success: true };
            } else {
                return { success: false, message: data.message || 'Update failed' };
            }
        } catch (error) {
            console.error('Update Error:', error);
            return { success: false, message: 'Server error. Please try again later.' };
        }
    };

    const logout = () => {
        // Clear local state
        setUser(null);
        // Clear session storage
        sessionStorage.removeItem('iteagrow_session_active'); 
        // Force a hard refresh and redirect to homepage
        window.location.href = '/';
    };

    return (
        <AuthContext.Provider value={{ user, login, googleLogin, logout, updateProfile, loading, isAuthenticated: !!user }}>
            {!loading && children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => useContext(AuthContext);
