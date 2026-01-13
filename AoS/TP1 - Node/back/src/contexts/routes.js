const { Router } = require("express");

const router = Router();

router.use("/books", require("./book"));
router.use("/authors", require("./authors"));

module.exports = router;