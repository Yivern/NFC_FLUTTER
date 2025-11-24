const express = require('express');
const app = express();
const config = require('./config.json');
const ProductController = require('./controllers/ProductController.js')

const logResponse = (statusCode, message) => {
  console.log(`HTTP/1.1 ${statusCode} ${message} ${Date()}`);
};

require('./connection').mongoConnect().then(async () => {
  app.use(express.text())

  app.post('/product', async (req, res) => {
    const body = req.body
    const data = JSON.parse(body)
    const { result, code, message } = await ProductController.find(data.id)
    logResponse(code, message)
    return res.status(code).send(result)
  });

  app.post('/create', async (req, res) => {
    const body = req.body;
    const data = JSON.parse(body)
    const { result, code, message } = await ProductController.create(data)
    logResponse(code, message)
    return res.status(code).send(result)
  });

  app.post('/update', async (req, res) => {
    const body = req.body;
    const data = JSON.parse(body)
    const { result, code, message } = await ProductController.update(data)
    logResponse(code, message)
    return res.status(code).send(result)
  });

  app.listen(config.port, () =>
    console.log(`Servicio escuchando en el puerto ${config.port}...`)
  )
})
