const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const axios = require('axios');

const app = express();
const PORT = 3000;

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'views', 'index.html'));
});

app.post('/submit-form', async (req, res) => {
    try {
        const { name, email, message } = req.body;

        const backendUrl = process.env.BACKEND_URL || 'http://localhost:5000/submit';

        const response = await axios.post(backendUrl, new URLSearchParams({
            name,
            email,
            message
        }), {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        });

        res.send(`<h1>Success!</h1><p>${response.data.message}</p><a href="/">Go back</a>`);
    } catch (error) {
        console.error('Error submitting to backend:', error.message);
        res.status(500).send(`<h1>Error</h1><p>Failed to submit form to backend.</p><p>${error.message}</p><a href="/">Go back</a>`);
    }
});

app.listen(PORT, () => {
    console.log(`Frontend server running on http://localhost:${PORT}`);
});
