import express from "express";
import puppeteer from 'puppeteer';
import asyncHandler from 'express-async-handler';
import jwt from 'jsonwebtoken';

const app = express();
const port = 3000;


app.get('/:id', asyncHandler(async (req, res, next) => {
    var id = req.params["id"];
    const browser = await puppeteer.launch({args: ['--no-sandbox', '--ignore-certificate-errors']});
    const page = await browser.newPage();
    // Navigate the page to a URL.
    await page.goto('https://app1.tiweb.tp.ubik.academy/');
    const secretKey = process.env.JWT_SECRET; // Replace with your own secret key
    const options = {
        expiresIn: '1m', // Token expiration time
    };

    const token = jwt.sign({'sub': 'username:admin_user', 'role': 'Admin'}, secretKey, options);
    await page.evaluate(
        (token) => {
            localStorage.setItem('access_token', token);
        },
        token
    )
    await page.goto(`https://app1.tiweb.tp.ubik.academy/pizza/${id}`);
    res.send('Welcome to my server!');
}));

app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});