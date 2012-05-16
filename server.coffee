root._ = require("underscore")
express = require 'express'
root.utils = require "./lib/utils"

DynamoManager = require "./lib/dynamo/"

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

_CONFIG.aws.accessKeyId = process.env.AWS_AKI if process.env?.AWS_AKI?
_CONFIG.aws.secretAccessKey = process.env.AWS_SAK if process.env?.AWS_SAK?

app = express.createServer()
app.use(express.bodyParser())

_dynamoOpt = _.extend( _CONFIG.aws, region: _CONFIG.dynamo.region )
# init dynamo client
dynDB = new DynamoManager( _dynamoOpt, _CONFIG.dynamo.tables )
dynDB.connect ( err )=>
	if err
		console.error err

# listen to events
dynDB
	.on "new-table", ( table )=>
		console.log "new-table", table.name
		table.on "create-status", ( status )=>
			console.log "create-status", table.name, status
			return
		return
	.on "all-tables-generated", ( generated )=>
		console.log "all-tables-generated", generated
		return
	.on "table-generated", =>
		console.log "table-generated"
		return

app.post "/redpill/:method", ( req, res )->
	_m = req.params.method
	_data = req.body

	_fn = _.bind( dynDB.client[ _m ], dynDB.client )

	_fn _data, ( err, result )->
		if err
			res.json err, 500
		else
			res.json result
		return
	return

app.get "/", ( req, res )->
	res.send("try '/_tables'")

	return

app.get "/_tables", ( req, res )->
	dynDB.list ( err, tables )->
		if err
			res.json err, 500
		else
			res.json tables
		return
	return

app.get "/createTables", ( req, res )->
	dynDB.generateAll ( err, created )->
		if err
			res.json err, 500
		else
			res.json created or true
		return
	return

app.get "/:table/_meta", ( req, res )->
	_t = req.params.table
	_tbl = dynDB.get( _t )
	if not _tbl
		res.json "table '#{ _t }' not found", 404
		return
	_tbl.meta ( err, meta )->
		if err
			res.json err, 500
		else
			res.json meta
		return
	return

app.get "/:table/", ( req, res )->
	_t = req.params.table

	if 0
		_regexQuery = /\w+(\^|\*|!|<|>)$/i
		_regexQueryType = /(\^|\*|!|<|>)$/i
		_q = {}
		for key, val of req.query or {}
			if _regexQuery.test( key )
				_key = key.replace( _regexQueryType, '' )
				switch _.last( key.split('') )
					when "^"
						_q[ _key ] = { "startsWith": val }
					when "*"
						_q[ _key ] = { "contains": val }
					when "<"
						_q[ _key ] = { "<": val }
					when ">"
						_q[ _key ] = { ">": val }
			else
				_q[ key ] = { "==": val }
	else
		_q = JSON.parse( req.query?.q  or "{}" )

	_tbl = dynDB.get( _t )
	if not _tbl
		res.json "table '#{ _t }' not found", 404
		return

	_tbl.find _q, ( err, data )->

		if err
			res.json err, 500
		else
			res.json data
		return
	return

app.put "/:table/", ( req, res )->
	_t = req.params.table
	_data = req.body

	_tbl = dynDB.get( _t )
	if not _tbl
		res.json "table '#{ _t }' not found", 404
		return

	_tbl.set _data, ( err, success )->
		if err
			res.json err, 500
		else
			res.json success
		return
	return

app.get "/:table/:id", ( req, res )->
	_t = req.params.table
	_id = req.params.id

	_tbl = dynDB.get( _t )
	if not _tbl
		res.json "table '#{ _t }' not found", 404
		return

	_tbl.get _id, ( err, success )->

		if err
			res.json err, 500
		else
			res.json success
		return
	return

app.post "/:table/:id", ( req, res )->
	_t = req.params.table
	_id = req.params.id
	_data = req.body

	_tbl = dynDB.get( _t )
	if not _tbl
		res.json "table '#{ _t }' not found", 404
		return

	_tbl.set _id, _data, ( err, success )->
		if err
			res.json err, 500
		else
			res.json success
		return
	return

app.del "/:table/:id", ( req, res )->
	_t = req.params.table
	_id = req.params.id

	_tbl = dynDB.get( _t )
	if not _tbl
		res.json "table '#{ _t }' not found", 404
		return

	_tbl.del _id, ( err, success )->

		if err
			res.json err, 500
		else
			res.json success
		return
	return

app.listen(3000)