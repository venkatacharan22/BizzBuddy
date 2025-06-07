10// Simple HTTP server without external dependencies
const http = require('http');

const PORT = 5000;

// Simple in-memory database
const users = [];
const calls = [];

// Create HTTP server
const server = http.createServer((req, res) => {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Parse URL
  const url = new URL(req.url, `http://${req.headers.host}`);
  const path = url.pathname;
  
  // Set content type
  res.setHeader('Content-Type', 'application/json');
  
  // Basic routing
  try {
    // Health check endpoint
    if (path === '/health' && req.method === 'GET') {
      res.writeHead(200);
      res.end(JSON.stringify({ status: 'OK', message: 'Simple server is running' }));
      return;
    }
    
    // Auth routes
    if (path === '/api/auth/register' && req.method === 'POST') {
      handleRegister(req, res);
      return;
    }
    
    if (path === '/api/auth/login' && req.method === 'POST') {
      handleLogin(req, res);
      return;
    }
    
    // Call routes
    if (path === '/api/calls' && req.method === 'POST') {
      handleCreateCall(req, res);
      return;
    }
    
    if (path === '/api/calls' && req.method === 'GET') {
      handleGetCalls(req, res);
      return;
    }
    
    // Not found
    res.writeHead(404);
    res.end(JSON.stringify({ message: 'Not found' }));
  } catch (error) {
    console.error('Server error:', error);
    res.writeHead(500);
    res.end(JSON.stringify({ message: 'Internal server error' }));
  }
});

// Start server
server.listen(PORT, () => {
  console.log(`Simple server running on port ${PORT}`);
  console.log(`Test the server by opening http://localhost:${PORT}/health in your browser`);
});

// Helper to read request body
const getRequestBody = (req) => {
  return new Promise((resolve, reject) => {
    const bodyChunks = [];
    req.on('data', (chunk) => {
      bodyChunks.push(chunk);
    });
    req.on('end', () => {
      try {
        const body = Buffer.concat(bodyChunks).toString();
        const data = body ? JSON.parse(body) : {};
        resolve(data);
      } catch (error) {
        reject(error);
      }
    });
  });
};

// Auth handlers
async function handleRegister(req, res) {
  try {
    const data = await getRequestBody(req);
    const { name, email, password } = data;
    
    if (!name || !email || !password) {
      res.writeHead(400);
      res.end(JSON.stringify({ message: 'Name, email and password are required' }));
      return;
    }
    
    // Check if user exists
    if (users.some(user => user.email === email)) {
      res.writeHead(400);
      res.end(JSON.stringify({ message: 'User already exists with this email' }));
      return;
    }
    
    // Create user
    const userId = `user-${Date.now()}`;
    const newUser = {
      userId,
      name,
      email,
      password, // In a real app, password would be hashed
      role: 'user',
      createdAt: new Date()
    };
    
    users.push(newUser);
    
    // Create mock token
    const token = `mock-token-${userId}`;
    const streamToken = `mock-stream-token-${userId}`;
    
    // Return response
    res.writeHead(201);
    res.end(JSON.stringify({
      userId,
      name,
      email,
      role: 'user',
      token,
      streamToken
    }));
  } catch (error) {
    console.error('Registration error:', error);
    res.writeHead(500);
    res.end(JSON.stringify({ message: 'Server error during registration' }));
  }
}

async function handleLogin(req, res) {
  try {
    const data = await getRequestBody(req);
    const { email, password } = data;
    
    if (!email || !password) {
      res.writeHead(400);
      res.end(JSON.stringify({ message: 'Email and password are required' }));
      return;
    }
    
    // Find user
    const user = users.find(u => u.email === email && u.password === password);
    
    if (!user) {
      res.writeHead(401);
      res.end(JSON.stringify({ message: 'Invalid email or password' }));
      return;
    }
    
    // Create mock token
    const token = `mock-token-${user.userId}`;
    const streamToken = `mock-stream-token-${user.userId}`;
    
    // Return response
    res.writeHead(200);
    res.end(JSON.stringify({
      userId: user.userId,
      name: user.name,
      email: user.email,
      role: user.role,
      token,
      streamToken
    }));
  } catch (error) {
    console.error('Login error:', error);
    res.writeHead(500);
    res.end(JSON.stringify({ message: 'Server error during login' }));
  }
}

// Call handlers
async function handleCreateCall(req, res) {
  try {
    const callId = `call-${Date.now()}`;
    
    // Create new call
    const newCall = {
      callId,
      createdBy: 'demo-user',
      participants: [{ userId: 'demo-user', joinedAt: new Date() }],
      startedAt: new Date(),
      status: 'created'
    };
    
    calls.push(newCall);
    
    // Return response
    res.writeHead(201);
    res.end(JSON.stringify({
      callId,
      token: `mock-token-for-call-${callId}`,
      createdBy: 'demo-user',
      startedAt: newCall.startedAt
    }));
  } catch (error) {
    console.error('Create call error:', error);
    res.writeHead(500);
    res.end(JSON.stringify({ message: 'Server error creating call' }));
  }
}

async function handleGetCalls(req, res) {
  try {
    // Return response
    res.writeHead(200);
    res.end(JSON.stringify(calls.map(call => ({
      callId: call.callId,
      createdBy: call.createdBy,
      startedAt: call.startedAt,
      endedAt: call.endedAt,
      status: call.status,
      duration: 0
    }))));
  } catch (error) {
    console.error('Get calls error:', error);
    res.writeHead(500);
    res.end(JSON.stringify({ message: 'Server error retrieving calls' }));
  }
} 