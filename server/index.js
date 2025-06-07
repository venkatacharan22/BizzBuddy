require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const { StreamChat } = require('stream-chat');

// Import routes
const authRoutes = require('./routes/auth');
const callRoutes = require('./routes/calls');

// Initialize Express app
const app = express();

// Initialize Stream Chat client
const streamClient = StreamChat.getInstance(
  process.env.STREAM_API_KEY,
  process.env.STREAM_API_SECRET
);

// Middleware
app.use(cors());
app.use(express.json());

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('Failed to connect to MongoDB:', err));

// Make Stream client available to routes
app.use((req, res, next) => {
  req.streamClient = streamClient;
  next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/calls', callRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
}); 