uuid = require 'node-uuid'
_ = require "underscore"
Attributes = require( "./attributes" )
attributesHelper = Attributes.helper

EventEmitter = require( "events" ).EventEmitter


module.exports = class DynamoTable extends EventEmitter

	constructor: ( table, @options )->

		@name = null
		@mng = @options.manager
		@defaults = @options.defaults
		@external = @options.external


		@__defineGetter__ "hashRangeDelimiter", =>
			"::"

		@__defineGetter__ "existend", =>
			@external?

		@__defineGetter__ "hasRange", =>
			if @_model_settings?.rangeKey?.length then true else false

		@__defineGetter__ "hashKey", =>
			@_model_settings?.hashKey or null

		@__defineGetter__ "rangeKey", =>
			@_model_settings?.rangeKey or null

		@init( table )

		return

	init: ( table )=>
		@_model_settings = table
		@_attrs = new Attributes( table.attributes, @ )

		@name = table.name

		return

	generate: ( cb )=>
		err = {}
		if not @external?
			# create table
			@_generate cb
		else
			# table already existing
			@emit( "create-status", "already-active" )
			cb( null, false )
		return

	meta: ( cb )=>
		if @_meta?
			# serve cached data
			cb( null, @_meta )
		else if @_isExistend( cb )
			# get meta data cache and serve it
			@external.fetch ( err, _meta )=>
				if err
					cb( err )
				else
					@_meta = _meta
					cb( null, _meta )
				return
		return

	get: ( _id, cb )=>
		if @_isExistend( cb )
			query = @_deFixHash( _id ) 
			
			@_get query, ( err, _item )=>
				if err
					cb( err )
				else
					if _item
						_obj = @_dynamoItem2JSON( _item, false )
						@emit( "get", _obj )
						cb( null, _obj )
					else
						@emit( "get-empty", _obj )
						cb null, null
				return

		return

	set: ( args..., cb )=>
		if @_isExistend( cb )
			switch args.length
				when 1
					_create = true
					_id = null
					[ attributes ] = args
				when 2
					_create = false
					[ _id, attributes ] = args

			@_attrs.validateAttributes attributes, ( err, attributes )=>
				if err
					cb( err )
				else
					if _create
						@_create attributes, ( err, _item )=>
							if err
								cb( err )
							else
								_obj = @_dynamoItem2JSON( _item, true )
								@emit( "create", _obj )
								cb( null, _obj )
							return
					else
						@_update _id, attributes, ( err, _curr, _old, _deletedKeys )=>
							if err
								cb( err )
							else
								if _old
									# update done
									_obj = @_dynamoItem2JSON( _curr, true )
									
									# remove the deleted key from old to fix the mixin with new values
									_oldRem = {}
									for _k, _v of _old when _k not in _deletedKeys
										_oldRem[ _k ] = _v
									_new = _.extend( _oldRem, _obj )
									@emit( "update", _new, _old )
									cb( null, _new )
								else
									# nothing changed
									@emit( "update", _curr, _curr )
									cb( null, _curr )
							return
		return

	del: ( _id, cb )=>
		if @_isExistend( cb )
			query = @_deFixHash( _id ) 
			
			@_del query, ( err, success )=>
				if err
					cb( err )
				else
					@emit( "delete", _id )
					cb null, success
				return

		return

	find: ( query = {}, cb )=>
		# fix args if no query is passed
		if arguments.length is 1 and _.isFunction( query )
			cb = query
			query = {}

		if @_isExistend( cb )
			_query = @_attrs.getQuery( @external, query )
			_query.fetch ( err, _items )=>
				if err
					cb err
				else
					cb null, @_dynamoItem2JSON( _items, false )
				return
			return


	# short helper to check if the databe is existend in AWS and return a error to callback if not existend
	_isExistend: ( cb )=>
		if @existend
			true
		else
			# table not existend
			cb
				error: "table-not-created"
				msg:"Table '#{ @name }' not existend at AWS. please run `Table.generate()` or `Manager.generateAll()` first."

			false

	_get: ( query, cb )=>
		_item = @external.get( query )
		_item.fetch ( err, item )=>
			if err
				cb err
			else
				cb null, item
			return
		return

	_update: ( id, attributes, cb )=>

		@get id, ( err, current )=>
			if err
				cb err
			else
				item = @external.get( @_deFixHash( id ) )
				_upd = item.update( @_attrs.updateAttrsFn( current, attributes ) )
				_upd.returning( "UPDATED_NEW" )

				# only save if data has changed
				if _upd.AttributeUpdates?
					_upd.save ( err, _saved )=>
						if err
							cb err
						else
							cb( null, _saved.Attributes, current, _upd._todel )
						return
				else
					cb( null, current, null )

				return

		return

	_create: ( attributes = {}, cb )=>

		@_createId attributes, ( attributes )=>
			item = @external.put( attributes )

			item.save ( err )=>
				if err
					cb err
				else
					cb( null, item )
				return

			return

		return

	_del: ( query, cb )=>
		_item = @external.get( query )

		_item.destroy ( err, success )=>
				if err
					cb err
				else
					cb null, success
				return
			return
		return

	_dynamoItem2JSON: ( items, convertAttrs = false )=>
		if _.isArray( item )
			for item, idx in items
				items[ idx ] = @_dynamoItem2JSONSingle( item, convertAttrs )
			items
		else
			@_dynamoItem2JSONSingle( items, convertAttrs )

	_dynamoItem2JSONSingle: ( item, convertAttrs = false )=>
		if convertAttrs
			_obj = attributesHelper.dyn2obj( item.Item or item )
		else
			_obj = item

		@_fixHash( _obj )

	_fixHash: ( attrs )=>

		_attrs = _.clone( attrs )		

		if @hasRange
			_hName = @_model_settings.hashKey
			_rName = @_model_settings.rangeKey

			if _attrs[ _hName ]? and _attrs[ _rName ]
				_attrs[ _hName ] = _attrs[ _hName ] + @hashRangeDelimiter + _attrs[ _rName ]

		_attrs

	_deFixHash: ( attrs )=>
		if _.isObject( attrs )
			_attrs = _.clone( attrs )
		else
			_hName = @_model_settings.hashKey
			_attrs = {}
			_attrs[ _hName ] = attrs
		
		if @hasRange
			_hType = @_model_settings.hashKeyType or "S"
			_rName = @_model_settings.rangeKey
			_rType = @_model_settings.rangeKeyType or "S"

			[ _h, _r ] = _attrs[ _hName ].split( @hashRangeDelimiter )
			_attrs[ _hName ] =  @_convertValue( _h, _hType )
			_attrs[ _rName ] =  @_convertValue( _r, _rType )

		_attrs

	_createId: ( attributes, cb )=>
		@_createHashKey attributes, ( attributes )=>
			# create range attribute if defined in shema
			if @hasRange
				@_createRangeKey attributes, ( attributes )=>
					cb( attributes )
					return
			else
				cb( attributes )
			return

		return

	_createHashKey: ( attributes, cbH )=>
		_hName = @_model_settings.hashKey
		_hType = @_model_settings.hashKeyType or "S"

		if @_model_settings.fnCreateHash and _.isFunction( @_model_settings.fnCreateHash )
			@_model_settings.fnCreateHash attributes, ( _hash )=>
				attributes[ _hName ] = @_convertValue( _hash, _hType )
				cbH( attributes )
				return

		else if attributes[ _hName ]?
			# check the type
	
			attributes[ _hName ] = @_convertValue( attributes[ _hName ], _hType )
			cbH( attributes )

		else
			# create default id as uuid if not defined by attributes
			attributes[ _hName ] = @_convertValue( @_defaultHashKey(), _hType )
			cbH( attributes )

		return

	_createRangeKey: ( attributes, cbR )=>
		_rName = @_model_settings.rangeKey
		_rType = @_model_settings.rangeKeyType or "S"
		
		if @_model_settings.fnCreateRange and _.isFunction( @_model_settings.fnCreateRange )
			@_model_settings.fnCreateRange attributes, ( __range )=>
				attributes[ _rName ] = @_convertValue( __range, _rType )
				cbR( attributes )
				return

		else if attributes[ _rName ]?
			# check the type
	
			attributes[ _rName ] = @_convertValue( attributes[ _rName ], _rType )
			cbR( attributes )

		else
			# create default range as timestamp if not defined by attributes
			attributes[ _rName ] = @_convertValue( @_defaultRangeKey(), _rType )
			cbR( attributes )

		return

	_defaultHashKey: =>
		uuid.v1()

	_defaultRangeKey: =>
		Date.now()
	
	_convertValue: ( val, type )=>
		switch type.toUpperCase()
			when "N"
				parseFloat( val, 10 )
			when "S"
				val.toString( val ) if val
			else
				val

	_generate: ( cb )=>

		_cr = @mng.client.add
			name: @_model_settings.name
			throughput: @_getThroughput()
			schema: @_getShema()

		_cr.save ( err, _table )=>
			if err
				cb( err )
			else
				@emit( "create-status", "waiting" )
				_table.watch ( err, _table )=>
					if err
						cb( err )
					else
						@emit( "create-status", "active" )
						@external = _table
						cb( null, _table )
					return
			return

		return

	_getShema: =>
		oShema = {}

		_hName = @_model_settings.hashKey
		_hType = @_model_settings.hashKeyType or "S"

		oShema[ _hName ] = if _hType is "S" then String else Number

		# define range if key is defined
		if @hasRange
			_rName = @_model_settings.rangeKey
			_rType = @_model_settings.rangeKeyType or "N"
			oShema[ _rName ] = if _rType is "S" then String else Number
		
		oShema

	_getThroughput: =>

		oRet = @defaults.throughput
		oRet.read = @options.throughput.read if @options?.throughput?.read?
		oRet.write = @options.throughput.write if @options?.throughput?.write?

		oRet

	
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



