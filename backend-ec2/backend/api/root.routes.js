// backend/api/root.routes.js
const express = require('express');
const rootController = require('./root.controller');
const router = express.Router();

// Associe la méthode GET sur la racine de ce routeur à la fonction du contrôleur
router.get('/', rootController.getApiRoot);

module.exports = router;
