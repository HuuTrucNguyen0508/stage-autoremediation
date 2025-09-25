// backend/api/todos/todo.routes.js
const express = require('express');
const todoController = require('./todo.controller'); // Points to the new controller
const router = express.Router();

router.post('/', todoController.createTodo);
router.get('/', todoController.getAllTodos);

module.exports = router;
