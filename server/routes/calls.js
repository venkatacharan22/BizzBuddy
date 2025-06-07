const express = require('express');
const router = express.Router();
const callsController = require('../controllers/callsController');
const auth = require('../middleware/auth');

// All routes require authentication
router.use(auth);

// Create a new call
router.post('/', callsController.createCall);

// Join an existing call
router.post('/:callId/join', callsController.joinCall);

// Leave a call
router.post('/:callId/leave', callsController.leaveCall);

// End a call (call creator or admin only)
router.post('/:callId/end', callsController.endCall);

// Get call details
router.get('/:callId', callsController.getCallDetails);

// Get user's call history
router.get('/', callsController.getUserCalls);

module.exports = router; 