const Report = require('../models/Report');

// Fetch all reports sorted by newest first
exports.getAllReports = async (req, res) => {
  try {
    const reports = await Report.find().sort({ timestamp: -1 });
    return res.status(200).json(reports);
  } catch (error) {
    return res.status(500).json({ 
      success: false, 
      message: 'Failed to retrieve reports', 
      error: error.message 
    });
  }
};

// Create a report (handles files and mock data URLs)
exports.createReport = async (req, res) => {
  try {
    const { title, description, latitude, longitude, imageUrl, points, status } = req.body;
    
    // Determine the image location (either upload file path or test web URL)
    let finalImageUrl = imageUrl;
    if (req.file) {
      finalImageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
    }

    if (!finalImageUrl) {
      return res.status(400).json({ success: false, message: 'An image URL or file upload is required.' });
    }

    const calculatedPoints = points ? parseInt(points, 10) : Math.floor(Math.random() * 50) + 15;

    const newReport = new Report({
      title,
      description,
      imageUrl: finalImageUrl,
      coordinates: {
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude)
      },
      points: calculatedPoints,
      status: status || 'Pending',
      timestamp: new Date()
    });

    const savedReport = await newReport.save();

    // Broadcast the new report to all listening React dashboards instantly
    const io = req.app.get('socketio');
    if (io) {
      io.emit('new_report', savedReport);
      console.log(`📡 Broadcasted new report via Socket.io: "${savedReport.title}"`);
    } else {
      console.warn('⚠️ Socket.io instance not found on app, skipping broadcast.');
    }

    return res.status(201).json(savedReport);
  } catch (error) {
    console.error('Create report error:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Failed to create report', 
      error: error.message 
    });
  }
};
