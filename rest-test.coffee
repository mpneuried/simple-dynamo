root._ = require("underscore")
express = require 'express'
root.utils = require "./lib/utils"

DynamoManager = require "./lib/dynamo/"

root.argv = require('optimist')
	.default('host', "127.0.0.1")
	.default('port')
	.default('config', "LOCAL")
	.alias('config', "c")
	.argv

# get config
root._CONFIG_TYPE = argv.config
root._CONFIG_PORT = argv.port
root._CONFIG = require( "./config" )

_CONFIG.aws.accessKeyId = process.env.AWS_ACCESS_KEY_ID if process.env?.AWS_ACCESS_KEY_ID?
_CONFIG.aws.secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY if process.env?.AWS_SECRET_ACCESS_KEY?

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
	.on "new-table", ( name, table )=>
		console.log "new-table", name, table.name
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

app.get "/many/:table", ( req, res )->
	_t = req.params.table
	_i = 0
	_tbl = dynDB.get( _t )
	if not _tbl
		res.json "table '#{ _t }' not found", 404
		return

	users = [ "A", "B", "C", "D" ]

	_fnInsert = ( cb )->
		_item = { message: randomString( 10 ), user_id: users[ _randrange( 0,3 ) ], _t: Date.now() }
		_tbl.set _item, ( err, item )->
			if err
				console.log "ERROR", err
				cb( false )
			else
				_i++
				console.log "INSERT: ( #{ _i } )", item.id
				cb( true )
			return
	fnInsert = _.throttle( _fnInsert, 250 )

	fnOnSucess = ( success )->
		if success
			fnInsert( fnOnSucess )
		return
	fnInsert( fnOnSucess )

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

app.get "/:table/_create", ( req, res )->
	_t = req.params.table
	_tbl = dynDB.get( _t )
	if not _tbl
		res.json "table '#{ _t }' not found", 404
		return
	_tbl.generate ( err, result )->
		if err
			res.json err, 500
		else
			res.json result
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

	_o = JSON.parse( req.query?.o  or "{}" )

	_tbl = dynDB.get( _t )
	if not _tbl
		res.json "table '#{ _t }' not found", 404
		return

	_tbl.find _q, req.query?.c, _o, ( err, data )->

		if err
			res.json err, 500
		else
			console.log "LEN", data?.length
			res.json data
		return
	return

app.put "/:table/", ( req, res )->
	_t = req.params.table
	_data = req.body

	_o = JSON.parse( req.query?.o  or "{}" )

	_tbl = dynDB.get( _t )
	if not _tbl
		res.json "table '#{ _t }' not found", 404
		return

	_tbl.set _data, _o, ( err, success )->
		if err
			res.json err, 500
		else
			res.json success
		return
	return

app.get "/mget/:table/:ids", ( req, res )->
	_t = req.params.table
	try
		_ids = JSON.parse( req.params.ids )
	catch _err
		_ids = req.params.ids

	_tbl = dynDB.get( _t )
	if not _tbl
		res.json "table '#{ _t }' not found", 404
		return

	_o = JSON.parse( req.query?.o or "{}" )


	if _.isString( _ids )
		_ids = _ids.split( "," )

	_tbl.mget _ids, _o, ( err, success )->

		if err
			res.json err, 500
		else
			res.json success
		return
	return

app.get "/:table/:id", ( req, res )->
	_t = req.params.table
	try
		_id = JSON.parse( req.params.id )
	catch _err
		_id = req.params.id

	_tbl = dynDB.get( _t )
	if not _tbl
		res.json "table '#{ _t }' not found", 404
		return

	_o = JSON.parse( req.query?.o or "{}" )

	_tbl.get _id, _o, ( err, success )->

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

	try
		_id = JSON.parse( req.params.id )
	catch _err
		_id = req.params.id

	_o = JSON.parse( req.query?.o or "{}" )

	_tbl = dynDB.get( _t )
	if not _tbl
		res.json "table '#{ _t }' not found", 404
		return

	_tbl.set _id, _data, _o, ( err, success )->
		if err
			res.json err, 500
		else
			res.json success
		return
	return

app.del "/:table/:id", ( req, res )->
	_t = req.params.table
	_id = req.params.id

	try
		_id = JSON.parse( req.params.id )
	catch _err
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

# test helper
randomString = ( length, withnumbers = true ) ->
	chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	chars += "0123456789" if withnumbers

	string_length = length or 5
	randomstring = ""
	i = 0
	
	while i < string_length
		rnum = Math.floor(Math.random() * chars.length)
		randomstring += chars.substring(rnum, rnum + 1)
		i++
	randomstring

_randrange = ( lowVal, highVal )->
	Math.floor( Math.random()*(highVal-lowVal+1 ))+lowVal



app.listen(_CONFIG.server.port)
console.log "Server started on #{ _CONFIG.server.port }"