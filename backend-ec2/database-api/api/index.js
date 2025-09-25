// database-api/api/index.js
const express = require('express');
const todoRoutes = require('./todos/todo.routes');
const router = express.Router();

// All routes defined in todo.routes.js will be prefixed with /todos
router.use('/todos', todoRoutes);

// If you add other resources (e.g., users), you would add their routers here:
// const userRoutes = require('./users/user.routes');
// router.use('/users', userRoutes);

module.exports = router;
