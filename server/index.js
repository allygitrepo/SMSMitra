const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const http = require('http');
const { Server } = require('socket.io');
require('dotenv').config();

const { connectDB, sequelize } = require('./config/db');
const routes = require('./routes/index');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

app.set('io', io);

io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  socket.on('join', (userId) => {
    socket.join(userId.toString());
    console.log(`User ${userId} joined room`);
  });
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

// Middlewares
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Routes
app.use('/smsmitra/v1', routes);

// Error Handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send({ message: 'Something went wrong!' });
});

const PORT = process.env.PORT;

const startServer = async () => {
  await connectDB();

  // Sync Database
  // Use { force: false } in production
  await sequelize.sync({ alter: true });
  console.log('Database synced.');

  server.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
};

startServer();
