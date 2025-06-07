const mongoose = require('mongoose');

const callSchema = new mongoose.Schema({
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  participants: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    joinedAt: {
      type: Date,
      default: Date.now
    },
    leftAt: {
      type: Date
    }
  }],
  status: {
    type: String,
    enum: ['created', 'active', 'ended'],
    default: 'created'
  },
  streamCallId: {
    type: String
  },
  startedAt: {
    type: Date,
    default: Date.now
  },
  endedAt: {
    type: Date
  }
}, { timestamps: true });

// Virtual for calculating call duration when ended
callSchema.virtual('callDuration').get(function() {
  if (this.endedAt && this.startedAt) {
    return (this.endedAt - this.startedAt) / 1000; // duration in seconds
  }
  return 0;
});

// Update duration field when ending a call
callSchema.pre('save', function(next) {
  if (this.isModified('endedAt') && this.endedAt) {
    this.duration = (this.endedAt - this.startedAt) / 1000;
  }
  next();
});

const Call = mongoose.model('Call', callSchema);

module.exports = Call; 