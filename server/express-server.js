const express = require('express');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const cors = require('cors');
const { StreamChat } = require('stream-chat');
require('dotenv').config();

// Initialize Express app
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/bizzybuddy', {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => {
    console.log('Connected to MongoDB');
}).catch((error) => {
    console.error('MongoDB connection error:', error);
});

// Stream Chat client
const streamClient = StreamChat.getInstance(
    process.env.STREAM_API_KEY,
    process.env.STREAM_API_SECRET
);

// Models
const User = require('./models/User');
const Room = require('./models/Room');
const Call = require('./models/Call');

// Authentication middleware
const authenticateToken = async (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];
        
        if (!token) {
            return res.status(401).json({ message: 'Access token is required' });
        }
        
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.userId);

        if (!user) {
            return res.status(401).json({ message: 'Invalid token' });
        }

        req.user = user;
        next();
    } catch (error) {
        console.error('Auth error:', error);
        return res.status(401).json({ message: 'Invalid token' });
    }
};

// Authentication routes
app.post('/api/auth/register', async (req, res) => {
    try {
        const { name, email, password } = req.body;
        
        // Check if user exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ message: 'User already exists' });
        }
        
        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Create Stream user token
        const streamToken = streamClient.createToken(email);
        
        // Create user
        const user = new User({
            name,
            email,
            password: hashedPassword,
            role: 'user',
            streamToken
        });
        
        await user.save();
        
        // Generate JWT token
        const token = jwt.sign(
            { userId: user._id },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.status(201).json({
            userId: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            token,
            streamToken
        });
    } catch (error) {
        console.error('Register error:', error);
        res.status(500).json({ message: 'Error registering user' });
    }
});

app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        
        // Find user
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Check password
        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Generate Stream token
        const streamToken = streamClient.createToken(email);

        // Update user's Stream token
        user.streamToken = streamToken;
        await user.save();
        
        // Generate JWT token
        const token = jwt.sign(
            { userId: user._id },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.json({
            userId: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            token,
            streamToken
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Error logging in' });
    }
});

app.post('/api/auth/validate', authenticateToken, (req, res) => {
    res.json({ valid: true });
});

app.get('/api/auth/user', authenticateToken, async (req, res) => {
    try {
        const user = await User.findById(req.user._id).select('-password');
        res.json(user);
    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({ message: 'Error fetching user' });
    }
});

// Audio Room routes
app.post('/api/audio-rooms', authenticateToken, async (req, res) => {
    try {
        const { roomName, settings } = req.body;
        
        // Create room
        const room = new Room({
            roomName: roomName || `Room-${Date.now()}`,
            host: req.user._id,
            participants: [req.user._id],
            settings: settings || { audio: true, video: false }
        });
        
        await room.save();
        
        // Create Stream call
        const streamCall = await streamClient.createCall({
            id: room._id.toString(),
            type: 'audio_room',
            members: [req.user._id.toString()]
        });

        // Update room with Stream call ID
        room.streamCallId = streamCall.id;
        await room.save();
        
        res.status(201).json(room);
    } catch (error) {
        console.error('Create room error:', error);
        res.status(500).json({ message: 'Error creating room' });
    }
});

app.get('/api/audio-rooms', authenticateToken, async (req, res) => {
    try {
        const rooms = await Room.find({
            $or: [
                { host: req.user._id },
                { participants: req.user._id }
            ]
        }).populate('host', 'name email')
          .populate('participants', 'name email');
        
        res.json(rooms);
    } catch (error) {
        console.error('Get rooms error:', error);
        res.status(500).json({ message: 'Error fetching rooms' });
    }
});

app.post('/api/audio-rooms/:roomId/join', authenticateToken, async (req, res) => {
    try {
        const room = await Room.findById(req.params.roomId);
        
        if (!room) {
            return res.status(404).json({ message: 'Room not found' });
        }
        
        // Add user to participants if not already there
        if (!room.participants.includes(req.user._id)) {
            room.participants.push(req.user._id);
            await room.save();
        }
        
        res.json(room);
    } catch (error) {
        console.error('Join room error:', error);
        res.status(500).json({ message: 'Error joining room' });
    }
});

app.post('/api/audio-rooms/:roomId/leave', authenticateToken, async (req, res) => {
    try {
        const room = await Room.findById(req.params.roomId);
        
        if (!room) {
            return res.status(404).json({ message: 'Room not found' });
        }
        
        // Remove user from participants
        room.participants = room.participants.filter(
            participant => participant.toString() !== req.user._id.toString()
        );
        
        // If host leaves and there are other participants, assign new host
        if (room.host.toString() === req.user._id.toString() && room.participants.length > 0) {
            room.host = room.participants[0];
        }
        
        // If room is empty, delete it
        if (room.participants.length === 0) {
            await Room.findByIdAndDelete(req.params.roomId);
            return res.json({ message: 'Room closed' });
        }
        
        await room.save();
        res.json(room);
    } catch (error) {
        console.error('Leave room error:', error);
        res.status(500).json({ message: 'Error leaving room' });
    }
});

// Video Call routes
app.post('/api/calls', authenticateToken, async (req, res) => {
    try {
        const call = new Call({
            createdBy: req.user._id,
            participants: [{
                userId: req.user._id,
                joinedAt: new Date()
            }],
            status: 'active',
            startedAt: new Date()
        });

        await call.save();

        // Create Stream call
        const streamCall = await streamClient.createCall({
            id: call._id.toString(),
            type: 'video_call',
            members: [req.user._id.toString()]
        });

        // Update call with Stream call ID
        call.streamCallId = streamCall.id;
        await call.save();

        res.status(201).json(call);
    } catch (error) {
        console.error('Create call error:', error);
        res.status(500).json({ message: 'Error creating call' });
    }
});

app.post('/api/calls/:callId/join', authenticateToken, async (req, res) => {
    try {
        const call = await Call.findById(req.params.callId);
        
        if (!call) {
            return res.status(404).json({ message: 'Call not found' });
        }

        if (call.status === 'ended') {
            return res.status(400).json({ message: 'Call has ended' });
        }

        // Add participant if not already in call
        const existingParticipant = call.participants.find(
            p => p.userId.toString() === req.user._id.toString()
        );

        if (!existingParticipant) {
            call.participants.push({
                userId: req.user._id,
                joinedAt: new Date()
            });
            await call.save();
        }

        res.json(call);
    } catch (error) {
        console.error('Join call error:', error);
        res.status(500).json({ message: 'Error joining call' });
    }
});

app.post('/api/calls/:callId/leave', authenticateToken, async (req, res) => {
    try {
        const call = await Call.findById(req.params.callId);
        
        if (!call) {
            return res.status(404).json({ message: 'Call not found' });
        }

        // Remove participant
        call.participants = call.participants.filter(
            p => p.userId.toString() !== req.user._id.toString()
        );

        // If creator leaves and there are other participants, assign new creator
        if (call.createdBy.toString() === req.user._id.toString() && call.participants.length > 0) {
            call.createdBy = call.participants[0].userId;
        }

        // If call is empty, end it
        if (call.participants.length === 0) {
            call.status = 'ended';
            call.endedAt = new Date();
        }

        await call.save();
        res.json(call);
    } catch (error) {
        console.error('Leave call error:', error);
        res.status(500).json({ message: 'Error leaving call' });
    }
});

app.post('/api/calls/:callId/end', authenticateToken, async (req, res) => {
    try {
        const call = await Call.findById(req.params.callId);
        
        if (!call) {
            return res.status(404).json({ message: 'Call not found' });
        }

        // Only creator or admin can end call
        if (call.createdBy.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
            return res.status(403).json({ message: 'Not authorized to end call' });
        }

        call.status = 'ended';
        call.endedAt = new Date();
        await call.save();

        res.json(call);
    } catch (error) {
        console.error('End call error:', error);
        res.status(500).json({ message: 'Error ending call' });
    }
});

app.get('/api/calls', authenticateToken, async (req, res) => {
    try {
        const calls = await Call.find({
            $or: [
                { createdBy: req.user._id },
                { 'participants.userId': req.user._id }
            ]
        }).sort({ startedAt: -1 });

        res.json(calls);
    } catch (error) {
        console.error('Get calls error:', error);
        res.status(500).json({ message: 'Error fetching calls' });
    }
});

// Stream token route
app.post('/api/stream/token', authenticateToken, async (req, res) => {
    try {
        const streamToken = streamClient.createToken(req.user._id.toString());
        res.json({ token: streamToken });
    } catch (error) {
        console.error('Stream token error:', error);
        res.status(500).json({ message: 'Error generating Stream token' });
    }
});

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
}); 