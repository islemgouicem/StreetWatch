const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const reportRoutes = require('./routes/reportRoutes');

const app = express();
const server = http.createServer(app);

// Initialize Socket.io with permissive CORS for local development
const io = socketIo(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// Create uploads folder if it doesn't exist
const uploadsDir = path.join(__dirname, 'public/uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(uploadsDir));

// Attach Socket.io instance to app for controller access
app.set('socketio', io);

// Database Connection
const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/streetwatch';
mongoose.connect(mongoURI)
  .then(() => console.log('✅ Connected to MongoDB successfully'))
  .catch(err => {
    console.error('❌ MongoDB Connection Error:', err);
    process.exit(1);
  });

// Routes
app.use('/api/reports', reportRoutes);

// Socket.io Connection Logic
io.on('connection', (socket) => {
  console.log(`🔌 Client connected to Real-Time socket: ${socket.id}`);
  socket.on('disconnect', () => {
    console.log(`🔌 Client disconnected from socket: ${socket.id}`);
  });
});

// Start Server
const PORT = process.env.PORT || 5050;
server.listen(PORT, () => {
  console.log(`🚀 StreetWatch Backend server active on port ${PORT}`);
});
