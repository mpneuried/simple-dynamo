dynamo = require "dynamo"
uuid = require 'node-uuid'

module.exports = class DynamoConnector
	constructor: ( aws, region )->

		@client = dynamo.createClient aws
		@db = @client.get region

		return

	fetchTable: ( table, cb )=>
		if Object.keys( @db.tables ).length
			cb( null, @db.get( table ) )
		else
			@db.fetch ( err )=>
				if err
					cb err
				else
					if table is null
						cb( null, true )
					else if @db.tables[ table ]
						cb( null, @db.get( table ) )
					else
						cb error: "table not found"
				return
		return

	listTables: ( cb )=>
		@fetchTable null, ( err, success )=>
			if err
				cb err
			else
				cb null, Object.keys( @db.tables )
			return
		return
			
	meta: ( _table, cb )=>
		@fetchTable _table, ( err, table )=>
			table.fetch ( err, meta )=>
				if err
					cb err
				else
					cb null, meta
				return
			return
		return

	scan: ( _table, query, cb )=>
		@fetchTable _table, ( err, table )=>
			scan = table.scan( query )
			scan.fetch ( err, data )=>
				if err
					cb err
				else
					cb null, data
				return
			return
		return

	put: ( _table, data = {}, cb )=>
		@fetchTable _table, ( err, table )=>
			if not data._id?
				data._id = uuid.v1()

			if not data._t?
				data._t = Date.now()

			item = table.put( data )
			item.save ( err )=>
				if err
					cb err
				else
					cb null, item
				return
			return
		return

	get: ( _table, _id, cb )=>
		@fetchTable _table, ( err, table )=>
			
			item = table.get( @_idQuery( _id ) )
			item.fetch ( err, data )=>
				if err
					cb err
				else
					cb null, data
				return
			return
		return

	del: ( _table, _id, cb )=>
		@fetchTable _table, ( err, table )=>

			item = table.get( @_idQuery( _id ) )
			item.destroy ( err, success )=>
				if err
					cb err
				else
					cb null, success
				return
			return
		return


	_idQuery: ( _id, idKey = "_id", rageKey = "_t" )=>
		_q = {}
		if ":" in _id
			_aId = _id.split( ":" )
			if _aId.length == 2
				_q[ idKey ] = _aId[ 0 ]
				_q[ rageKey ] = parseInt( _aId[ 1 ], 10 )
			else
				cb error: "Wrong id format. Please use '[hash-key:range-key]'"
				return

		else
			_q[ idKey ] = _id

		_q




