// backend/api/root.controller.js
const path = require('path'); // Importer le module 'path' de Node.js

// 'process.cwd()' retourne le répertoire de travail courant où le processus Node a été lancé.
// Dans un conteneur Docker avec WORKDIR /usr/src/app, ce sera /usr/src/app.
const packageJsonPath = path.join(process.cwd(), 'package.json');
const { name, version } = require(packageJsonPath);


// Ce contrôleur gère la requête pour la racine de l'API
exports.getApiRoot = (req, res) => {
    const currentLogger = req.log || (req.app && req.app.locals && req.app.locals.logger) || console;
    
    currentLogger.info("Backend API: Request received for API root path [/api/]"); // Corrigé le chemin pour la clarté du log

    res.status(200).json({
        success: true,
        message: "Welcome to the Backend API!",
        service: name, // Le nom du service depuis package.json
        version: version, // La version depuis package.json
        status: "UP"
    });
};
