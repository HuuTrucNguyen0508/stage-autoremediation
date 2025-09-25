// backend/api/index.js
const express = require('express');
const todoRoutes = require('./todos/todo.routes');
const rootRoutes = require('./root.routes');

const router = express.Router();

// On ne monte que les routes qui existent réellement
router.use('/', rootRoutes);
router.use('/todos', todoRoutes);
// const notificationRoutes = require('./notifications/notification.routes'); // <<< SUPPRIMER ou COMMENTER
// router.use('/notifications', notificationRoutes); // <<< SUPPRIMER ou COMMENTER

module.exports = router;
