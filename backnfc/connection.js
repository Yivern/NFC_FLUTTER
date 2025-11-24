const mongoose = require('mongoose')
const config = require('./config.json')

exports.mongoConnect = async function mongoConnect() {
	console.info('Conectando base de datos...')
	await mongoose.connect(config.database, {}).then(() => {
		console.info('Base de datos conectada.')
	}).catch((err) => {
		console.error('Error al conectar la base de datos...', err.message)
		process.exit()
	})
}