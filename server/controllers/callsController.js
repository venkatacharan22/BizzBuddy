const Call = require('../models/Call');
const { v4: uuidv4 } = require('uuid');

// Create a new call
exports.createCall = async (req, res) => {
  try {
    const userId = req.userId;
    
    // Generate a unique callId if not provided
    const callId = req.body.callId || uuidv4();
    
    // Create a call with Stream Video API
    const call = await req.streamClient.video.createCall({
      id: callId,
      type: 'default',
      data: {
        created_by: userId,
        members: [userId]
      }
    });
    
    // Create entry in our database
    const newCall = new Call({
      callId,
      createdBy: userId,
      participants: [{ userId }],
      status: 'created'
    });
    
    await newCall.save();
    
    // Get call token
    const token = req.streamClient.createToken(userId);
    
    res.status(201).json({
      callId,
      token,
      createdBy: userId,
      startedAt: newCall.startedAt
    });
  } catch (error) {
    console.error('Create call error:', error);
    res.status(500).json({ message: 'Server error creating call' });
  }
};

// Join an existing call
exports.joinCall = async (req, res) => {
  try {
    const { callId } = req.params;
    const userId = req.userId;
    
    // Find the call
    const call = await Call.findOne({ callId });
    
    if (!call) {
      return res.status(404).json({ message: 'Call not found' });
    }
    
    if (call.status === 'ended') {
      return res.status(400).json({ message: 'This call has ended' });
    }
    
    // Check if user is already a participant
    const existingParticipant = call.participants.find(p => 
      p.userId === userId && !p.leftAt
    );
    
    if (!existingParticipant) {
      // Add participant
      call.participants.push({ userId });
      
      // Update call status to active if it was just created
      if (call.status === 'created') {
        call.status = 'active';
      }
      
      await call.save();
    }
    
    // Get call token
    const token = req.streamClient.createToken(userId);
    
    res.json({
      callId,
      token,
      startedAt: call.startedAt
    });
  } catch (error) {
    console.error('Join call error:', error);
    res.status(500).json({ message: 'Server error joining call' });
  }
};

// Leave a call
exports.leaveCall = async (req, res) => {
  try {
    const { callId } = req.params;
    const userId = req.userId;
    
    // Find the call
    const call = await Call.findOne({ callId });
    
    if (!call) {
      return res.status(404).json({ message: 'Call not found' });
    }
    
    // Update participant status
    const participantIndex = call.participants.findIndex(p => 
      p.userId === userId && !p.leftAt
    );
    
    if (participantIndex !== -1) {
      call.participants[participantIndex].leftAt = new Date();
      
      // Check if all participants have left
      const anyActiveParticipants = call.participants.some(p => !p.leftAt);
      
      if (!anyActiveParticipants) {
        // End call if all participants have left
        call.status = 'ended';
        call.endedAt = new Date();
      }
      
      await call.save();
    }
    
    res.json({ message: 'Successfully left the call' });
  } catch (error) {
    console.error('Leave call error:', error);
    res.status(500).json({ message: 'Server error leaving call' });
  }
};

// End a call (only call creator or admin)
exports.endCall = async (req, res) => {
  try {
    const { callId } = req.params;
    const userId = req.userId;
    
    // Find the call
    const call = await Call.findOne({ callId });
    
    if (!call) {
      return res.status(404).json({ message: 'Call not found' });
    }
    
    // Check if user is the creator or an admin
    if (call.createdBy !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized to end this call' });
    }
    
    if (call.status === 'ended') {
      return res.status(400).json({ message: 'Call is already ended' });
    }
    
    // End the call
    call.status = 'ended';
    call.endedAt = new Date();
    
    // Mark all active participants as having left
    call.participants.forEach(participant => {
      if (!participant.leftAt) {
        participant.leftAt = new Date();
      }
    });
    
    await call.save();
    
    // End call in Stream API
    await req.streamClient.video.endCall(callId);
    
    res.json({
      callId,
      status: 'ended',
      duration: call.duration
    });
  } catch (error) {
    console.error('End call error:', error);
    res.status(500).json({ message: 'Server error ending call' });
  }
};

// Get call details
exports.getCallDetails = async (req, res) => {
  try {
    const { callId } = req.params;
    
    // Find the call
    const call = await Call.findOne({ callId });
    
    if (!call) {
      return res.status(404).json({ message: 'Call not found' });
    }
    
    res.json({
      callId: call.callId,
      createdBy: call.createdBy,
      startedAt: call.startedAt,
      endedAt: call.endedAt,
      status: call.status,
      duration: call.duration,
      participants: call.participants
    });
  } catch (error) {
    console.error('Get call details error:', error);
    res.status(500).json({ message: 'Server error retrieving call details' });
  }
};

// Get user's call history
exports.getUserCalls = async (req, res) => {
  try {
    const userId = req.userId;
    
    // Find calls where user is a participant
    const calls = await Call.find({
      'participants.userId': userId
    }).sort({ startedAt: -1 });
    
    res.json(calls.map(call => ({
      callId: call.callId,
      createdBy: call.createdBy,
      startedAt: call.startedAt,
      endedAt: call.endedAt,
      status: call.status,
      duration: call.duration
    })));
  } catch (error) {
    console.error('Get user calls error:', error);
    res.status(500).json({ message: 'Server error retrieving user calls' });
  }
}; 