const { Router } = require("express");
const { client } = require("../../infrastructure/database/database");

const router = Router();

// Get all authors
router.get("/", async (req, res) => {
    const authors = await client.author.findMany({
        include: {
            books: {
                include: {
                    book: true
                }
            }
        }
    });
    res.status(200).json(authors);
});

// Get author by id
router.get("/:id", async (req, res) => {
    const { id } = req.params;
    const author = await client.author.findUnique({
        where: { id: id },
        include: {
            books: {
                include: {
                    book: true
                }
            }
        }
    });
    if (author) {
        res.status(200).json(author);
    } else {
        res.status(404).json({ message: "Author not found" });
    }
});

// Create author
router.post("/", async (req, res) => {
    const { name } = req.body;
    const newAuthor = await client.author.create({
        data: { name }
    });
    res.status(201).json(newAuthor);
});

// Update author
router.patch("/:id", async (req, res) => {
    const { id } = req.params;
    const { name } = req.body;
    const updatedAuthor = await client.author.update({
        where: { id: id },
        data: { name }
    });
    res.status(200).json(updatedAuthor);
});

// Delete author
router.delete("/:id", async (req, res) => {
    const { id } = req.params;
    await client.author.delete({
        where: { id: id }
    });
    res.status(204).end();
});

module.exports = router;