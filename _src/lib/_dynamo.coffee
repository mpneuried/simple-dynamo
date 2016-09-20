# ### extends [Dynamo](_dynamo.coffee.html)
#
# ### Exports: *Class*
# 
# Basic Dynamo class for general handling of dynamo specific data 

# **npm modules**
_isEmpty = require( "lodash/isEmpty" )
AWS = require('aws-sdk')

# **internal modules**
# The [Config](../lib/config.coffee.html)
config = require( "../lib/config" )

dynamoConfig = config.get( "dynamo" )
dynamoClient = new AWS.DynamoDB( dynamoConfig )

module.exports = class Dynamo extends require( "./basic" )

	defaults: =>
		return @extend {}, super,
			tablekey: "-"

	constructor: ->
		@ready = false
		super
		
		@getter "tablename", @_getTableName
		@getter "prefix", ->@config.hashPrefix
		
		# wrap the methods with a wait for `ready`
		@_describe = @_waitUntil( @__describe )
		@_getItem = @_waitUntil( @__getItem )
		@_query = @_waitUntil( @__query )
		@_scan = @_waitUntil( @__scan )
		@_putItem = @_waitUntil( @__putItem )
		@_updateItem = @_waitUntil( @__updateItem )
		@_deleteItem = @_waitUntil( @__deleteItem )
		@_createTable = @_waitUntil( @__createTable, "inited" )

		@setClient( dynamoClient )
		return

	setClient: ( @client )=>
		@ready = true
		@emit "ready"
		return

	generate: ( cb )->
		cb( null )
		return
	
	_getTableName: ( tablekey = @config.tablekey )=>
		_tableName= dynamoConfig.tablesnames[ tablekey ]
		if not _tableName?
			@_handleError( null, "EDYNAMOMISSINGTABLE", table: @config.tablename )
			return
		return _tableName

	__describe: ( params, cb )=>
		@debug "getItem", params
		@client.describeTable params, @_processDynamoItemReturn( cb )
		return

	__getItem: ( params, cb )=>
		@debug "getItem", params
		@client.getItem params, @_processDynamoItemReturn( cb )
		return

	__query: ( [ params, options ]..., cb )=>
		@debug "query", params, options
		@client.query params, @_processDynamoQueryReturn( options, cb )
		return

	__scan: ( args..., cb )=>
		[ params, options ] = args
		@debug "scan", params, options
		@client.scan params, @_processDynamoQueryReturn( options, cb )
		return

	__putItem: ( params, cb )=>
		params.ReturnValues = "ALL_OLD"
		@debug "putItem", params
		@client.putItem params, @_processDynamoPutReturn( params, cb )
		return
		
	__updateItem: ( params, cb )=>
		params.ReturnValues = "ALL_NEW"
		@debug "updateItem", params
		@client.updateItem params, @_processDynamoUpdateReturn( params, cb )
		return

	__deleteItem: ( params, cb )=>
		@debug "deleteItem", params
		@client.deleteItem params, @_processDynamoDeleteReturn( cb )
		return

	__createTable: ( params, cb )=>
		@debug "createTable", params
		@client.createTable params, @_processDynamoCreateTable( cb )
		return

	_waitForActiveTable: ( cb )=>
		@debug "wait for active table"
		@client.waitFor "tableExists", { TableName: @config.tablename }, ( err, data )=>
			if err
				cb( err )
				return
			@debug "table ready", data
			cb( null, true )
			return
		return

	_processDynamoItemReturn: ( cb )=>
		return ( err, rawData )=>
			if err
				@_processDynamoError( cb, err )
				return

			@debug "_processDynamoItemReturn raw", rawData

			attrs = @_convertItem( rawData.Item )
			
			@debug "_processDynamoItemReturn", attrs
			
			if not attrs? or _isEmpty( attrs )
				@_handleError( cb, "ENOTFOUND" )
				return
			
			cb( null, attrs )
			return

	_processDynamoQueryReturn: ( [ options ]..., cb )=>
		return ( err, rawData )=>
			if err
				@_processDynamoError( cb, err )
				return

			@debug "_processDynamoQueryReturn raw", rawData
			
			if rawData.count <= 0
				if options?.onlyFirst
					cb( null, null )
					return
				cb( null, [] )
				return
				
			items = []
			for item in rawData.Items
				items.push @_convertItem( item )
				
			if options?.onlyFirst
				cb( null, items[ 0 ])
				return
				
			@debug "_processDynamoQueryReturn", items.length
			cb( null, items, rawData.LastEvaluatedKey )
			return

	_processDynamoPutReturn: ( params, cb )=>
		return ( err, rawData )=>
			if err
				@_processDynamoError( cb, err )
				return

			#@debug "_processDynamoPutReturn raw", 
			
			attrs = @_convertItem( params.Item )

			@debug "_processDynamoPutReturn", attrs
			cb( null, attrs )
			return
		
	_processDynamoUpdateReturn: ( params, cb )=>
		return ( err, rawData )=>
			if err
				@_processDynamoError( cb, err )
				return

			@debug "_processDynamoUpdateReturn raw", rawData
			
			attrs = @_convertItem( rawData.Attributes )

			@debug "_processDynamoUpdateReturn", attrs
			cb( null, attrs )
			return

	_processDynamoDeleteReturn: ( cb )=>
		return ( err, rawData )=>
			if err
				@_processDynamoError( cb, err )
				return

			@debug "_processDynamoItemReturn raw", rawData

			attrs = @_convertItem( rawData.Attributes )
			
			@debug "_processDynamoItemReturn", attrs
			cb( null, attrs )
			return

	_processDynamoCreateTable: ( cb )=>
		return ( err, rawData )=>
			if err and err.name isnt "ResourceInUseException"
				@_processDynamoError( cb, err )
				return

			if err?.name is "ResourceInUseException"
				cb( null, false )
				return

			@debug "_processDynamoCreateTable raw", rawData
			if rawData.TableDescription.TableStatus is "ACTIVE"
				cb( null, false )
			else
				@warning "create table", @config.tablename
				@_waitForActiveTable( cb )
			return

	_convertItem: ( raw )->
		attrs = {}
		for _k, _v of raw
			_type = Object.keys( _v )[ 0 ]
			switch _type
				when "S"
					attrs[ _k ] = _v[ _type ]
				when "SS"
					attrs[ _k ] = _v[ _type ]
				when "N"
					attrs[ _k ] = parseFloat( _v[ _type ] )
				when "BOOL"
					attrs[ _k ] = if _v[ _type ] then true else false

		return @_customConvert( attrs )

	_customConvert: ( attrs )=>
		return attrs

	_processDynamoError: ( cb, err )=>
		if err.code is "ResourceNotFoundException"
			@_handleError( cb, "EDYNAMOMISSINGTABLE", table: @config.tablename )
			return

		cb( err )
		return

	ERRORS: =>
		return @extend {}, super,
			"EDYNAMOMISSINGTABLENAME": [ 500, "The dynamo table key `<%= key %>` does not exist! Please check your code or the configuration." ]
			"EDYNAMOMISSINGTABLE": [ 400, "The dynamo table `<%= table %>` does not exist. Please generate it!" ]
			"EDYNAMOMETHODNOTDEFINED": [ 501, "The method `<%= method %>` for the table `<%= table %>` has to be implemented." ]
