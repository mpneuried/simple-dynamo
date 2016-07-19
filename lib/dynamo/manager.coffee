dynamo = require "mp-dynamo"

EventEmitter = require( "events" ).EventEmitter
Table = require "./table"
utils = require "./utils"
_ = require "underscore"


module.exports = class DynamoManager extends EventEmitter

	_connected: false
	_fetched: false

	defaults:
		throughput:
			read: 3
			write: 3
		overwriteExistingHash: false

	constructor: ( @options, @tableSettings )->
		@options.scanWarning or= true
		@options.tablePrefix or= ""

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
			error = new Error
			error.name = "missing-option"
			error.message = "Missing options vars. required options are: '#{ neededParams.join( ', ' ) }'"

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
					
				if @options.tablePrefix?.length
					if table.combineTableTo?.length
						if table.combineTableTo.indexOf( @options.tablePrefix ) < 0
							table.combineTableTo = @options.tablePrefix + table.combineTableTo
						else
							
					else
						if table.name.indexOf( @options.tablePrefix ) < 0
							table.name = @options.tablePrefix + table.name
				
				
				# generate a Table Object for each table-element out of @tableSettings
				_ext = if table.combineTableTo?.length then @client.tables[ table.combineTableTo ] else @client.tables[ table.name ]
				_opt = _.extend {},
					manager: @
					defaults: @defaults
					external: _ext

				@_tables[ tableName ] = new Table( table, _opt )
				@emit( "new-table", tableName, @_tables[ tableName ] )

			@_connected = true
			cb( null )

		else
			error = new Error
			error.name = "no-tables-fetched"
			error.message = "Currently not tables fetched. Please run `Manager.connect()` first."
			cb( error )

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

	_getTablesToGenerate: =>
		_ret = {}
		for _n, tbl of @_tables
			if not _ret[ tbl.tableName ]?
				_ret[ tbl.tableName ] = 
					name: _n
					tableName: tbl.tableName

		_ret

	generateAll: ( cb )=>
		aCreate = []
		for _n, table of @_getTablesToGenerate()
			aCreate.push _.bind( ( tableName, cba )->
				
				@generate tableName, ( err, generated )=>
					cba( err, generated )
					return
				
				return
				
			, @, table.name )

		utils.runSeries aCreate, ( err, _generated )=>
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
			error = new Error
			error.name = "table-not-found"
			error.message = "Table `#{ tableName }` not found."
			cb( error )
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
