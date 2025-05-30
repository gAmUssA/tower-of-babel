import express from 'express';
import http from 'http';
import { Server } from 'socket.io';
import path from 'path';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Create Express app
const app = express();
const server = http.createServer(app);
const io = new Server(server);

// Set port
const PORT = process.env.PORT || 9300;

// Middleware
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Routes
app.get('/', (req, res) => {
  res.send('Analytics API is running');
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.get('/analytics/dashboard', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

app.get('/api/messages/recent', (req, res) => {
  // In a real app, this would fetch from a database
  res.json({
    messages: []
  });
});

// Socket.io for real-time updates
io.on('connection', (socket) => {
  console.log('A client connected');
  
  socket.on('disconnect', () => {
    console.log('A client disconnected');
  });
});

// Start server
server.listen(PORT, () => {
  console.log(`Analytics API running on http://localhost:${PORT}`);
  console.log(`Dashboard available at http://localhost:${PORT}/analytics/dashboard`);
});
