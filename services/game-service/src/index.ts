import {server} from "./app.js";
import config from "./config/config.js";
import db from "./db/db.js";

//db(); //Fail-fast: Initialize the database connection before application starts

server.listen(config().PORT, () => {
  console.log(`Application is listening http://localhost:${config().PORT}`);
});
