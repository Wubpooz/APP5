const { Router } = require("express");
const { client } = require("../../infrastructure/database/database");

const router = Router();

router.get("/", async (req, res) => {
  const { page = 1, limit = 10 } = req.query; // Default values if not provided
  const offset = (page - 1) * limit;
  const books = await client.book.findMany({
    include: {
      authors: {
        include: {
          author: true
        }
      }
    },
    skip: parseInt(offset),
    take: parseInt(limit),
  });
  res.status(200).json(books);
});

router.get("/:id", async (req, res) => {
    const { id } = req.params;
    const book = await client.book.findUnique({
        where: { id: id },
        include: {
            authors: {
                include: {
                    author: true
                }
            }
        }
    });
    if (book) {
        res.status(200).json(book);
    } else {
        res.status(404).json({ message: "Book not found" });
    }
});

router.post("/", async (req, res) => {
    const { title, description } = req.body;
    const newBook = await client.book.create({
        data: {
            title,
            description
        },
    });
    res.status(201).json(newBook);
});

router.patch("/:id", async (req, res) => {
    const { id } = req.params;
    const { title, description } = req.body;
    const updatedBook = await client.book.update({
        where: { id: id },
        data: {
            title,
            description
        },
    });
    res.status(200).json(updatedBook);
});

router.delete("/:id", async (req, res) => {
    const { id } = req.params;
    await client.book.delete({
        where: { id: id },
    });
    res.status(204).end();
});

// Add author to book
router.post("/:id/authors/:authorId", async (req, res) => {
    const { id, authorId } = req.params;
    const bookAuthor = await client.bookAuthor.create({
        data: {
            bookId: id,
            authorId: authorId
        }
    });
    res.status(201).json(bookAuthor);
});

// Remove author from book
router.delete("/:id/authors/:authorId", async (req, res) => {
    const { id, authorId } = req.params;
    await client.bookAuthor.delete({
        where: {
            bookId_authorId: {
                bookId: id,
                authorId: authorId
            }
        }
    });
    res.status(204).end();
});


module.exports = router;