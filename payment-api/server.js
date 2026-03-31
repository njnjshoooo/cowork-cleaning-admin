const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors({
  origin: [
    'https://homood-clean.tw',
    'http://localhost:3000',
    'http://localhost:8080',
  ],
  methods: ['GET', 'POST'],
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/create-payment', require('./routes/create-payment'));
app.use('/api/payment-callback', require('./routes/payment-callback'));

// Health check
app.get('/', (req, res) => {
  res.json({ status: 'ok', service: '戶沐淨金流 API', version: '1.0.0' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Payment API running on port ${PORT}`);
});
