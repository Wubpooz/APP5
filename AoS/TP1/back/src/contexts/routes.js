const { Router } = require("express");

const router = Router();

router.use("/books", require("./book"));

module.exports = router;