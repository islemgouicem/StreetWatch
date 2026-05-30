const axios = require('axios');

const BACKEND_URL = 'http://localhost:5050/api/reports';

const images = [
  'https://images.unsplash.com/photo-1515162305285-0293e4767cc2?w=800',
  'https://images.unsplash.com/photo-1599740831114-171888939c0f?w=800',
  'https://images.unsplash.com/photo-1621293954908-907141401da8?w=800',
  'https://images.unsplash.com/photo-1584824486509-112e4181ff6b?w=800',
  'https://images.unsplash.com/photo-1542362567-b07eac790931?w=800'
];

const titles = [
  'Deep Pothole',
  'Faded Crosswalk Line',
  'Blocked Storm Drain',
  'Illegal Trash Dumping',
  'Broken Speed Limit Sign'
];

const descriptions = [
  'This pothole is located in the middle lane and is causing cars to swerve dangerously.',
  'The pedestrian crosswalk paint has completely worn away, making it dangerous for walkers.',
  'Leaves and plastic bottles are completely blocking the drain, leading to street flooding.',
  'Multiple bags of household garbage and furniture have been left on the sidewalk.',
  'The sign is bent and pointing away from oncoming traffic, making it impossible to read.'
];

function getRandomCoord(center, range) {
  return center + (Math.random() - 0.5) * range;
}

async function sendReport() {
  const index = Math.floor(Math.random() * images.length);
  const report = {
    title: `${titles[index]} #${Math.floor(Math.random() * 1000)}`,
    description: descriptions[index],
    latitude: getRandomCoord(36.7538, 0.08),
    longitude: getRandomCoord(3.0588, 0.08),
    imageUrl: images[index],
    points: Math.floor(Math.random() * 50) + 15,
    status: 'Pending'
  };

  try {
    const res = await axios.post(BACKEND_URL, report);
    console.log(`[Success] Sent simulated report: "${report.title}" -> XP: ${report.points} -> ID: ${res.data._id}`);
  } catch (error) {
    console.error('[Error] Failed to send simulated report:', error.message);
  }
}

async function seed() {
  console.log('🌱 Starting database seeding with initial reports...');
  for (let i = 0; i < 5; i++) {
    await sendReport();
    await new Promise(r => setTimeout(r, 800));
  }
  
  console.log('🚀 Simulation active: sending a new report every 5 seconds. Press Ctrl+C to stop.');
  setInterval(sendReport, 5000);
}

seed();
