// database-api/models/Todo.model.js
const mongoose = require('mongoose');

const TodoSchema = new mongoose.Schema({
    text : {
        type: String,
        trim: true,
        required: [true, "Todo text is required"],
        minlength: 1
    },
    completed: {
      type: Boolean,
      default: false,
    },
    completedAt: {
      type: Number,
      default: null,
    },
}, { timestamps: true }); // Adds createdAt and updatedAt automatically

const Todo = mongoose.model('Todo', TodoSchema);

module.exports = { Todo };
