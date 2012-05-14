dynamo = require "dynamo"

EventEmitter = require( "events" ).EventEmitter
Table = require "./table"
utils = require "./utils"
_ = require "underscore"


module.exports = class DynamoManager extends EventEmitter

	_connected: false
	_fetched: false

	defaults:
		throughput:
			read: 10
			write: 5
		overwriteDoubleHash: true

	constructor: ( @options, @tableSettings )->

		@options.scanWarning or= true

		@_tables = {}

		@__defineGetter__ "fetched", =>
			return @_fetched

		@__defineGetter__ "connected", =>
			return @_connected

		return

	connect: ( cb )=>
		# create the dynamo client
		@_createClient ( err )=>
			if err
				cb err
			else 
				# fetch the existing tables
				@_fetchTables ( err )=>
					if err
						cb err
					else
						# init the defined tables
						@_initTables( undefined, cb )
					return
			return
		return

	_createClient: ( cb )=>
		@client or= null
		
		# check for existend required params
		neededParams = [ "accessKeyId", "secretAccessKey", "region" ]
		if utils.params( @options, neededParams )
			
			# create and configure the dynamo client
			_client = dynamo.createClient
				accessKeyId: @options.accessKeyId
				secretAccessKey: @options.secretAccessKey

			@client = _client.get @options.region

			cb( null )
		else
			cb 
				error: "missing-option"
				msg: "Missing options vars. required options are: '#{ neededParams.join( ', ' ) }'"

		return

	_fetchTables: ( cb )=>
		# allways fetch tables on a call
		@client.fetch ( err )=>
			if err
				cb( err )
			else
				@_fetched = true
				cb( null, true )
			return
		return

	_initTables: ( tables = @tableSettings, cb )=>
		if @fetched

			for tableName, table of tables
				tableName = tableName.toLowerCase()
				# destroy existing table
				if @_tables[ tableName ]?
					delete @_tables[ tableName ]
				
				# generate a Table Object for each table-element out of @tableSettings
				_opt = _.extend {},
					manager: @
					defaults: @defaults
					external: @client.tables[ table.name ]

				@_tables[ tableName ] = new Table( table, _opt )
				@emit( "new-table", @_tables[ tableName ] )

			@_connected = true
			cb( null )

		else
			cb 
				error: "no-tables-fetched"
				msg: "Currently not tables fetched. Please run `Manager.connect()` first."

		return



	list: ( cb )=>
		@_fetchTables ( err )=>
			if err
				cb err
			else
				cb null, Object.keys( @_tables )
			return
		return

	get: ( tableName )=>
		tableName = tableName.toLowerCase()
		if @has( tableName )
			@_tables[ tableName ]
		else
			null

	has: ( tableName )=>
		tableName = tableName.toLowerCase()
		@_tables[ tableName ]?

	generateAll: ( cb )=>
		aCreate = []

		for tableName of @_tables
			aCreate.push _.bind( ( tableName, cba )->
				
				@generate tableName, ( err, generated )=>
					cba( err, generated )
					return
				
				return
				
			, @, tableName )

		utils.runParallel aCreate, ( err, _generated )=>
			if utils.checkArray( err )
				cb err
			else
				@emit( "all-tables-generated" )
				cb null
			return

		return

	generate: ( tableName, cb )=>
		tbl = @get tableName

		if not tbl
			cb 
				error: "table-not-found"
				msg: "Table `#{ tableName }` not found."
		else

			tbl.generate ( err, generated )=>
				if err
					cb err
					return 

				@emit( "table-generated", generated )

				cb( null, generated )

				return
			return
		return