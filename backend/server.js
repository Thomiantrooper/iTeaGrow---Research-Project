
const path = require('path');
const express = require('express');
const dotenv = require('dotenv');
const connectDB = require('./config/db');

dotenv.config({ path: path.resolve(__dirname, '.env') });

connectDB();

const app = express();
const cors = require('cors');
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

const contactRoutes = require('./routes/contact.routes');
const authRoutes = require('./routes/auth.routes');
const alertRoutes = require('./routes/alert.routes');
const { notFound, errorHandler } = require('./middleware/errorMiddleware');
app.use('/api/contact', contactRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/users', require('./routes/user.routes'));
app.use('/api/admin', alertRoutes);

// Health Check Endpoint
app.use('/api/health', async (req, res) => {
  const mongoose = require('mongoose');
  const os = require('os');
  const states = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting',
  };
  const state = mongoose.connection.readyState;
  
  // Get local IP address
  const networkInterfaces = os.networkInterfaces();
  const addresses = [];
  for (const interfaceName in networkInterfaces) {
    for (const iface of networkInterfaces[interfaceName]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        addresses.push(iface.address);
      }
    }
  }

  let dbStatus = 'unknown';
  try {
    if (state === 1) {
      await mongoose.connection.db.admin().ping();
      dbStatus = 'active';
    }
  } catch (err) {
    dbStatus = 'error';
    console.error('Health Check DB Ping Failed:', err);
  }

  res.status(200).json({
    status: 'success',
    dbState: state,
    dbStateString: states[state],
    dbPing: dbStatus,
    timestamp: new Date(),
    uptime: process.uptime(),
    ip: addresses[0] || '127.0.0.1'
  });
});

// Serve static assets if in production
if (process.env.NODE_ENV === 'production') {
  // Set static folder
  app.use(express.static(path.join(__dirname, '../frontend/dist')));

  app.get('*', (req, res) => {
    res.sendFile(path.resolve(__dirname, '../', 'frontend', 'dist', 'index.html'));
  });
} else {
  app.get('/', (req, res) => {
    res.send('API is running...');
  });
}

app.use(notFound);
app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
