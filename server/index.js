const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

const { connectDB, sequelize } = require('./config/db');
const routes = require('./routes/index');

const app = express();

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

const PORT = process.env.PORT || 3000;

const startServer = async () => {
  await connectDB();
  
  // Sync Database
  // Use { force: false } in production
  await sequelize.sync({ alter: true });
  console.log('Database synced.');

  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
};

startServer();
