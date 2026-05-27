const mongoose = require('mongoose');

const ReportSchema = new mongoose.Schema({
  title: { 
    type: String, 
    required: true, 
    trim: true 
  },
  description: { 
    type: String, 
    required: true, 
    trim: true 
  },
  imageUrl: { 
    type: String, 
    required: true 
  },
  coordinates: {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true }
  },
  timestamp: { 
    type: Date, 
    default: Date.now 
  },
  points: { 
    type: Number, 
    default: 0 
  },
  status: { 
    type: String, 
    enum: ['Pending', 'Verified', 'Resolved', 'Rejected'], 
    default: 'Pending' 
  }
});

module.exports = mongoose.model('Report', ReportSchema);
