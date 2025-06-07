const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

const app = express();
const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'bizzybuddy-super-secret-key';

// Middleware
app.use(cors());
app.use(bodyParser.json());

// In-memory database (replace with MongoDB in production)
const users = [];
const calls = [];

// Middleware to verify JWT token
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN format
  
  if (!token) {
    return res.status(401).json({ message: 'Access token is required' });
  }
  
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ message: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Health check route
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'BizzyBuddy API server is running'
  });
});

// Auth routes
app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    
    // Validate input
    if (!name || !email || !password) {
      return res.status(400).json({ 
        message: 'Name, email and password are required' 
      });
    }
    
    // Check if user exists
    if (users.some(user => user.email === email)) {
      return res.status(400).json({ 
        message: 'User already exists with this email' 
      });
    }
    
    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    
    // Create user
    const userId = `user-${Date.now()}`;
    const newUser = {
      userId,
      name,
      email,
      password: hashedPassword,
      role: 'user',
      createdAt: new Date()
    };
    
    users.push(newUser);
    
    // Generate JWT token
    const token = jwt.sign(
      { userId, email, role: 'user' }, 
      JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    // Generate mock Stream token (replace with actual Stream token generation)
    const streamToken = `mock-stream-token-${userId}`;
    
    // Return response without password
    res.status(201).json({
      userId,
      name,
      email,
      role: 'user',
      token,
      streamToken
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Server error during registration' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Validate input
    if (!email || !password) {
      return res.status(400).json({ 
        message: 'Email and password are required' 
      });
    }
    
    // Find user
    const user = users.find(u => u.email === email);
    
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    
    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    
    // Generate JWT token
    const token = jwt.sign(
      { userId: user.userId, email, role: user.role }, 
      JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    // Generate mock Stream token (replace with actual Stream token generation)
    const streamToken = `mock-stream-token-${user.userId}`;
    
    // Return response without password
    res.status(200).json({
      userId: user.userId,
      name: user.name,
      email: user.email,
      role: user.role,
      token,
      streamToken
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Server error during login' });
  }
});

// Token validation endpoint
app.post('/api/auth/validate', authenticateToken, (req, res) => {
  res.status(200).json({ 
    valid: true, 
    user: {
      userId: req.user.userId,
      email: req.user.email,
      role: req.user.role
    }
  });
});

// User data endpoint
app.get('/api/auth/user', authenticateToken, (req, res) => {
  try {
    const user = users.find(u => u.userId === req.user.userId);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Generate a Stream token for the user
    const streamToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidGVzdF91c2VyX2ZpeGVkIn0.lN44-voKI7Tn3hK6EiG7VtsvpJy7fprC5QJqQI-akwM';
    
    res.status(200).json({
      userId: user.userId,
      name: user.name,
      email: user.email,
      role: user.role,
      streamToken
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ message: 'Server error fetching user data' });
  }
});

// Call routes (protected by JWT)
app.post('/api/calls', authenticateToken, (req, res) => {
  try {
    const callId = `call-${Date.now()}`;
    const { userId } = req.user;
    
    // Create new call
    const newCall = {
      callId,
      createdBy: userId,
      participants: [{ userId, joinedAt: new Date() }],
      startedAt: new Date(),
      status: 'created'
    };
    
    calls.push(newCall);
    
    // Return response
    res.status(201).json({
      callId,
      token: `mock-token-for-call-${callId}`,
      createdBy: userId,
      startedAt: newCall.startedAt
    });
  } catch (error) {
    console.error('Create call error:', error);
    res.status(500).json({ message: 'Server error creating call' });
  }
});

// Join existing call route
app.post('/api/calls/:callId/join', authenticateToken, (req, res) => {
  try {
    const { callId } = req.params;
    const { userId } = req.user;
    
    // Find call
    const call = calls.find(c => c.callId === callId);
    
    if (!call) {
      return res.status(404).json({ message: 'Call not found' });
    }
    
    // Check if call is still active
    if (call.status === 'ended') {
      return res.status(400).json({ message: 'Call has already ended' });
    }
    
    // Check if user is already in the call
    if (!call.participants.some(p => p.userId === userId)) {
      call.participants.push({
        userId,
        joinedAt: new Date()
      });
    }
    
    res.status(200).json({
      callId,
      status: call.status
    });
  } catch (error) {
    console.error('Join call error:', error);
    res.status(500).json({ message: 'Server error joining call' });
  }
});

// Leave call route
app.post('/api/calls/:callId/leave', authenticateToken, (req, res) => {
  try {
    const { callId } = req.params;
    const { userId } = req.user;
    
    // Find call
    const call = calls.find(c => c.callId === callId);
    
    if (!call) {
      return res.status(404).json({ message: 'Call not found' });
    }
    
    // Update participant status
    const participantIndex = call.participants.findIndex(p => p.userId === userId);
    
    if (participantIndex !== -1) {
      call.participants[participantIndex].leftAt = new Date();
    }
    
    res.status(200).json({
      callId,
      status: 'left'
    });
  } catch (error) {
    console.error('Leave call error:', error);
    res.status(500).json({ message: 'Server error leaving call' });
  }
});

// End call route (only creator or admin can end)
app.post('/api/calls/:callId/end', authenticateToken, (req, res) => {
  try {
    const { callId } = req.params;
    const { userId, role } = req.user;
    
    // Find call
    const call = calls.find(c => c.callId === callId);
    
    if (!call) {
      return res.status(404).json({ message: 'Call not found' });
    }
    
    // Check if user is authorized to end call
    if (call.createdBy !== userId && role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized to end this call' });
    }
    
    // End the call
    call.status = 'ended';
    call.endedAt = new Date();
    
    res.status(200).json({
      callId,
      status: 'ended'
    });
  } catch (error) {
    console.error('End call error:', error);
    res.status(500).json({ message: 'Server error ending call' });
  }
});

app.get('/api/calls', authenticateToken, (req, res) => {
  try {
    const { userId } = req.user;
    
    // Filter calls by user
    const userCalls = calls.filter(call => 
      call.createdBy === userId || 
      call.participants.some(p => p.userId === userId)
    );
    
    // Return response
    res.status(200).json(userCalls.map(call => ({
      callId: call.callId,
      createdBy: call.createdBy,
      startedAt: call.startedAt,
      endedAt: call.endedAt,
      status: call.status,
      duration: call.endedAt ? 
        Math.floor((call.endedAt - call.startedAt) / 1000) : 0
    })));
  } catch (error) {
    console.error('Get calls error:', error);
    res.status(500).json({ message: 'Server error retrieving calls' });
  }
});

// Root route for info
app.get('/', (req, res) => {
  res.status(200).json({
    name: 'BizzyBuddy API',
    version: '1.0.0',
    description: 'Backend API for BizzyBuddy Flutter application',
    endpoints: [
      {
        path: '/api/auth/register',
        method: 'POST',
        description: 'Register a new user'
      },
      {
        path: '/api/auth/login',
        method: 'POST',
        description: 'Login a user'
      },
      {
        path: '/api/calls',
        method: 'POST',
        description: 'Create a new call (authenticated)'
      },
      {
        path: '/api/calls',
        method: 'GET',
        description: 'Get call history (authenticated)'
      }
    ]
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`BizzyBuddy API server running on port ${PORT}`);
  console.log(`Server started at ${new Date().toISOString()}`);
}); 