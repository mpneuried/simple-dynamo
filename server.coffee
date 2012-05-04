root._ = require("underscore")
express = require 'express'
root.utils = require "./lib/utils"

DynamoConnector = require "./lib/dynamo"

root.argv = require('optimist')
	.default('host', "127.0.0.1")
	.default('port', "8010")
	.default('config', "LOCAL")
	.alias('config', "c")
	.argv

# get config
root._CONFIG_TYPE = argv.config
root._CONFIG_PORT = argv.port
root._CONFIG = require( "./config" )

app = express.createServer()
app.use(express.bodyParser())

# init dynamo client
dynDB = new DynamoConnector( _CONFIG.aws, _CONFIG.dynamo.region )

app.get "/", ( req, res )->
	res.send("try '/_tables'")

	return

app.get "/_tables", ( req, res )->
	dynDB.listTables ( err, tables )->
		if err
			res.json err, 500
		else
			res.json tables
		return
	return

app.get "/:table/_meta", ( req, res )->
	_t = req.params.table
	dynDB.meta _t, ( err, meta )->
		if err
			res.json err, 500
		else
			res.json meta
		return
	return


app.get "/:table/", ( req, res )->
	_t = req.params.table

	_q = {}

	dynDB.scan _t, _q, ( err, data )->

		if err
			res.json err, 500
		else
			res.json data
		return
	return

app.put "/:table/", ( req, res )->
	_t = req.params.table

	_data = req.body
	console.log _data

	dynDB.put _t, _data, ( err, success )->

		if err
			res.json err, 500
		else
			res.json success
		return
	return

app.get "/:table/:id", ( req, res )->
	_t = req.params.table
	_id = req.params.id
	dynDB.get _t, _id, ( err, success )->

		if err
			res.json err, 500
		else
			res.json success
		return
	return

app.del "/:table/:id", ( req, res )->
	_t = req.params.table
	_id = req.params.id
	dynDB.del _t, _id, ( err, success )->

		if err
			res.json err, 500
		else
			res.json success
		return
	return

app.listen(3000)