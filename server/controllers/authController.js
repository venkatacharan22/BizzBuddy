const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { v4: uuidv4 } = require('uuid');

// Generate JWT token
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

// Generate Stream token
const generateStreamToken = (userId, streamClient) => {
  return streamClient.createToken(userId);
};

// Register a new user
exports.register = async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    // Check if user already exists
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: 'User already exists with this email' });
    }

    // Generate a unique userId
    const userId = uuidv4();
    
    // Create new user
    user = new User({
      userId,
      name,
      email,
      password,
      role: role || 'user'
    });

    // Save user to database
    await user.save();

    // Generate tokens
    const token = generateToken(userId);
    const streamToken = generateStreamToken(userId, req.streamClient);

    res.status(201).json({
      userId,
      name,
      email,
      role: user.role,
      token,
      streamToken
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Server error during registration' });
  }
};

// Login user
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Generate tokens
    const token = generateToken(user.userId);
    const streamToken = generateStreamToken(user.userId, req.streamClient);

    res.json({
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
};

// Get current user
exports.getCurrentUser = async (req, res) => {
  try {
    const user = await User.findOne({ userId: req.userId }).select('-password');
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Generate Stream token
    const streamToken = generateStreamToken(user.userId, req.streamClient);
    
    res.json({
      userId: user.userId,
      name: user.name,
      email: user.email,
      role: user.role,
      streamToken
    });
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({ message: 'Server error' });
  }
}; 