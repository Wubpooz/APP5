const { Router } = require("express");
const { client } = require("../../infrastructure/database/database");

const router = Router();

router.get("/", async (req, res) => {
    const books = await client.book.findMany();
    res.status(200).json(books);
});


module.exports = router;