const mongoose = require('mongoose');

const roomSchema = new mongoose.Schema({
    roomName: {
        type: String,
        required: true
    },
    host: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    participants: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }],
    streamCallId: {
        type: String
    },
    settings: {
        audio: {
            type: Boolean,
            default: true
        },
        video: {
            type: Boolean,
            default: false
        }
    }
}, { timestamps: true });

const Room = mongoose.model('Room', roomSchema);
module.exports = Room;
