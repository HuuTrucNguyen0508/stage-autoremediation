// database-api/db/index.js
const mongoose = require("mongoose");

exports.connect = (app) => {
  const options = {
    autoIndex: process.env.NODE_ENV !== 'production',
    maxPoolSize: 10,
  };

  const connectWithRetry = () => {
    mongoose.Promise = global.Promise;
    console.log("Database API: MongoDB connection with retry using URI:", process.env.MONGODB_URI);
    mongoose
      .connect(process.env.MONGODB_URI, options)
      .then(() => {
        console.log("Database API: MongoDB is connected");
        if (app && typeof app.emit === 'function') {
          app.emit("ready");
        }
      })
      .catch((err) => {
        console.error("Database API: MongoDB connection unsuccessful, retry after 2 seconds.", err.message); // Log only err.message
        setTimeout(connectWithRetry, 2000);
      });
  };
  connectWithRetry();
};
