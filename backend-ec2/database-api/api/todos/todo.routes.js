// database-api/api/todos/todo.routes.js
const express = require('express');
const todoController = require('./todo.controller');
const router = express.Router();

router.post('/', todoController.createTodo);
router.get('/', todoController.getAllTodos);
router.get('/:id', todoController.getTodoById); // Example for getting by ID

module.exports = router;
