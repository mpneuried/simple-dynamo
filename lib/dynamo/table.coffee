uuid = require 'node-uuid'
_ = require "underscore"
Attributes = require( "./attributes" )
attributesHelper = Attributes.helper

EventEmitter = require( "events" ).EventEmitter


module.exports = class DynamoTable extends EventEmitter

	constructor: ( table, @options )->

		@mng = @options.manager
		@defaults = @options.defaults
		@external = @options.external

		@__defineGetter__ "name", =>
			@_model_settings.name

		@__defineGetter__ "tableName", =>
			@_model_settings.combineTableTo or @_model_settings.name or null

		@__defineGetter__ "isCombinedTable", =>
			@_model_settings.combineTableTo?
		
		@__defineGetter__ "combinedHashDelimiter", =>
			""

		@__defineGetter__ "hashRangeDelimiter", =>
			"::"

		@__defineGetter__ "existend", =>
			@external?

		@__defineGetter__ "hasRange", =>
			if @_model_settings?.rangeKey?.length then true else false

		@__defineGetter__ "hashKey", =>
			@_model_settings?.hashKey or null

		@__defineGetter__ "hashKeyType", =>
			if @isCombinedTable
				"S"
			else
				@_model_settings?.hashKeyType or "S"

		@__defineGetter__ "rangeKey", =>
			@_model_settings?.rangeKey or null

		@__defineGetter__ "rangeKeyType", =>
			if @hasRange
				@_model_settings?.rangeKeyType or "N"
			else
				null

		@__defineGetter__ "overwriteExistingHash", =>

			if @_model_settings?.overwriteExistingHash?
				@_model_settings.overwriteExistingHash
			else if @defaults.overwriteExistingHash?
				@defaults.overwriteExistingHash
			else
				false

		@init( table )

		return

	init: ( table )=>
		@_model_settings = table
		@_attrs = new Attributes( table.attributes, @ )

		#@external.schema( @_getShema() ) if @existend

		if @isCombinedTable
			@_regexRemCT = new RegExp( "^#{ @name }", "i" )

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
					@_error( cb,  err )
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
					@_error( cb, err )
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
				when 3
					_create = false
					[ _id, options, attributes ] = args
				
			_defOpt =
				removeMissing: if @_model_settings.removeMissing? then @_model_settings.removeMissing else true

			options = _.extend( _defOpt, options or {} )

			@_attrs.validateAttributes _create, attributes, ( err, attributes )=>
				if err
					@_error( cb, err )
				else
					if _create
						@_create attributes, ( err, _item )=>
							if err
								@_error( cb, err )
							else
								_obj = @_dynamoItem2JSON( _item, true )
								@emit( "create", _obj )
								cb( null, _obj )
							return
					else
						@_update _id, attributes, options, ( err, _curr, _old, _deletedKeys )=>
							if err
								@_error( cb,err )
							else
								if _old
									# fix hash key
									_old[ @hashKey ] = _old[ @hashKey ].replace( @_regexRemCT, "" )

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
									# fix hash key
									_curr[ @hashKey ] = _curr[ @hashKey ].replace( @_regexRemCT, "" )
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
					@_error( cb, err )
				else
					@emit( "delete", _id )
					cb null, success
				return

		return

	find: ( args..., cb )=>
		if @_isExistend( cb )
			# fix args if no query is passed
			switch args.length
				when 1
					cursor = null
					[ query ] = args
				when 2
					[ query, cursor ] = args

			if cursor?
				cursor = @_deFixHash( cursor )

			if @isCombinedTable
				if query[ @hashKey ]
					_op = _.first( Object.keys( query[ @hashKey ] ) )
					_val = query[ @hashKey ][ _op ]
					switch _op
						when "==" then _val = @name + @combinedHashDelimiter + _val
					
					query[ @hashKey ][ _op ] = _val

				else
					query[ @hashKey ] = { "startsWith" : @name }

			if @_isExistend( cb )
				_query = @_attrs.getQuery( @external, query, cursor )
				_query.fetch ( err, _items )=>
					if err
						@_error( cb, err )
					else
						cb null, @_dynamoItem2JSON( _items, false )
					return
				return

	destroy: ( cb )=>
		if @_isExistend( cb )
			@external.destroy( cb )

	_error: ( cb, err )=>
		if ERRORMAPPING[ err.name ]?
			cb( ERRORMAPPING[ err.name ] )
		else
			cb( err )
		return

	# short helper to check if the databe is existend in AWS and return a error to callback if not existend
	_isExistend: ( cb )=>
		if @existend
			true
		else 
			if _.isFunction( cb )
				# table not existend
				error = new Error
				error.name = "table-not-created"
				error.message = "Table '#{ @tableName }' not existend at AWS. please run `Table.generate()` or `Manager.generateAll()` first."
				@_error( cb, error )

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

	_update: ( id, attributes, options= {}, cb )=>

		@get id, ( err, current )=>
			if err
				cb err
			else
				item = @external.get( @_deFixHash( id ) )
				_upd = item.update( @_attrs.updateAttrsFn( current, attributes, options ) )
				_upd.returning( "UPDATED_NEW" )
				console.log "REQ",_upd
				#_upd = @_checkSetOptions( _upd, attributes )

				# only save if data has changed
				if _upd.AttributeUpdates?
					_upd.save ( err, _saved )=>
						console.log "RET",err, _saved
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
			_upd = @external.put( attributes )

			_upd = @_checkSetOptions( _upd, attributes )

			_upd.save ( err )=>
				if err
					cb err
				else
					cb( null, _upd )
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
		if _.isArray( items )
			for item, idx in items
				items[ idx ] = @_dynamoItem2JSONSingle( item, convertAttrs )
			items
		else
			@_dynamoItem2JSONSingle( items, convertAttrs )

	_dynamoItem2JSONSingle: ( item, convertAttrs = false )=>
		if convertAttrs
			_obj = attributesHelper.dyn2obj( item?.Item or item )
		else
			_obj = item

		@_fixHash( _obj )

	_fixHash: ( attrs )=>
		
		_attrs = _.clone( attrs )		
		_hName = @hashKey

		if @hasRange
			_rName = @rangeKey

			if _attrs[ _hName ]? and _attrs[ _rName ]
				_attrs[ _hName ] = _attrs[ _hName ] + @hashRangeDelimiter + _attrs[ _rName ]

		# remove prefix from hashKey if it's a combined table
		if @isCombinedTable and _attrs[ _hName ]?
			_attrs[ @hashKey ] = _attrs[ _hName ].replace( @_regexRemCT, "" )

		_attrs

	_deFixHash: ( attrs )=>
		if _.isObject( attrs )
			_attrs = _.clone( attrs )
		else
			_hName = @hashKey
			_attrs = {}
			_attrs[ _hName ] = attrs

		if @hasRange
			_hType = @hashKeyType
			_rName = @rangeKey
			_rType = @rangeKeyType

			[ _h, _r ] = _attrs[ _hName ].split( @hashRangeDelimiter )
			_attrs[ _hName ] =  @_convertValue( _h, _hType )
			_attrs[ _rName ] =  @_convertValue( _r, _rType )

		# add prefix to hashKey if it's a combined table
		if @isCombinedTable
			_attrs[ _hName ] = @name + @combinedHashDelimiter + _attrs[ _hName ]

		_attrs

	_createId: ( attributes, cb )=>
		@_createHashKey attributes, ( attributes )=>
			# add prefix to hashKey if it's a combined table
			if @isCombinedTable
				_hName = @hashKey
				attributes[ _hName ] = @name + @combinedHashDelimiter + attributes[ _hName ]

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
		_hName = @hashKey
		_hType = @hashKeyType

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
		_rName = @rangeKey
		_rType = @rangeKeyType
		
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

	_checkSetOptions: ( _upd, attributes )=>
		if not @overwriteExistingHash

			_pred = {}
			_pred[ @hashKey ] = { "==": null }
			_upd.when _pred

		_upd

	_generate: ( cb )=>

		_cr = @mng.client.add
			name: @tableName
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

		_hName = @hashKey
		_hType = @hashKeyType

		oShema[ _hName ] = if _hType is "S" then String else Number

		# define range if key is defined
		if @hasRange
			_rName = @rangeKey
			_rType = @rangeKeyType
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


ERRORMAPPING = 
	"com.amazonaws.dynamodb.v20111205#ConditionalCheckFailedException":
		name: "conditional-check-failed"
		message: "This is not a valid request. It doesnt match the conditions or you tried to insert a existing hash."

