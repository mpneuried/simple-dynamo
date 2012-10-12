uuid = require 'node-uuid'
_ = require "underscore"
Attributes = require( "./attributes" )
attributesHelper = Attributes.helper
utils = require "./utils"

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

	get: ( args..., cb )=>
		if @_isExistend( cb )
			options = null
			switch args.length
				when 1
					[ _id ] = args
				when 2
					[ _id, options ] = args

			options = @_getOptions( options )
			
			query = @_deFixHash( _id, cb ) 
			if query instanceof Error
				@_error( cb, query )
				return

			@_get query, options, ( err, _item )=>
				if err
					@_error( cb, err )
				else
					if _item
						_obj = @_dynamoItem2JSON( _item, false )
						@emit( "get", _obj )
						cb( null, _obj )
					else
						@emit( "get-empty" )
						cb null, null
				return

		return

	mget: ( args..., cb )=>
		if @_isExistend( cb )
			options = null
			switch args.length
				when 1
					[ _ids ] = args
				when 2
					[ _ids, options ] = args

			options = @_getOptions( options )

			mQuery = []
			for _id in _ids
				query = @_deFixHash( _id, cb ) 
				if query instanceof Error
					@_error( cb, query )
					return
				else
					mQuery.push( query )

			@_mget mQuery, options, ( err, _item )=>
				if err
					@_error( cb, err )
				else
					if _item.length
						_obj = @_dynamoItem2JSON( _item, false )
						@emit( "mget", _obj )
						cb( null, _obj )
					else
						@emit( "mget-empty" )
						cb null, []
				return
			return

	set: ( args..., cb )=>
		if @_isExistend( cb )
			options = null

			switch args.length
				when 1
					_create = true
					_id = null
					[ attributes ] = args
				when 2
					if _.isString( args[ 0 ] ) or _.isNumber( args[ 0 ] ) or _.isArray( args[ 0 ] )
						_create = false
						[ _id, attributes ] = args
					else
						_create = true
						_id = null
						[ attributes, options ] = args
				when 3
					_create = false
					[ _id, attributes, options ] = args
			
			options = @_getOptions( options )

			@_attrs.validateAttributes _create, attributes, ( err, attributes )=>
				if err
					@_error( cb, err )
				else
					if _create
						@_create attributes, options, ( err, _item )=>
							if err
								@_error( cb, err )
							else
								_obj = @_dynamoItem2JSON( _item, true )
								@emit( "create", _obj )
								if options?.fields?.length
									_obj = utils.reduceObj( _obj, options?.fields )
								cb( null, _obj )
							return
					else
						@_update _id, attributes, options, ( err, item )=>
							if err
								@_error( cb,err )
							else
								# update done
								_obj = @_dynamoItem2JSON( item, true )
								
								# remove the deleted key from old to fix the mixin with new values
								
								@emit( "update", _obj )
								
								if options?.fields?.length
									_reducedItem = utils.reduceObj( _obj, options.fields )
								cb( null, _reducedItem or _obj )
							return
		return

	del: ( _id, cb )=>
		[ args..., cb ] = arguments
		[ _id, options ] = args

		options or= {}
		
		if @_isExistend( cb )
			query = @_deFixHash( _id ) 

			if query instanceof Error
				@_error( cb, query )
			else
			
				@_del query, options, ( err, success )=>
					if err
						@_error( cb, err )
					else
						@emit( "delete", success )
						cb null, success
					return

		return

	find: ( args..., cb )=>
		if @_isExistend( cb )
			# fix args if no query is passed
			options = null
			startAt = null
			query = {}
			switch args.length
				when 1
					[ query ] = args
				when 2
					[ query, _x ] = args
					if _.isString( _x ) or _.isNumber( _x )
						startAt = _x
					else
						options = _x
				when 3
					[ query, startAt, options ] = args

			options = @_getOptions( options )

			if startAt?
				startAt = @_deFixHash( startAt )
				if startAt instanceof Error
					@_error( cb, startAt )
					return


			if @isCombinedTable
				if query?[ @hashKey ]
					_op = _.first( Object.keys( query[ @hashKey ] ) )
					_val = query[ @hashKey ][ _op ]
					_val = @_deFixHash( _val )?[ @hashKey ] or _val
					if _val instanceof Error
						@_error( cb, _val )
						return
					switch _op
						when "==" then _val = _val
					
					query[ @hashKey ][ _op ] = _val

				else
					query[ @hashKey ] = { "startsWith" : @name }

			if @_isExistend( cb )
				[ _query, isScan ] = @_attrs.getQuery( @external, query, startAt, options )
				
				_fnHandle = ( err, _items )=>
					if err
						@_error( cb, err )
					else
						cb null, @_dynamoItem2JSON( _items, false )
					return
				
				if isScan
					_query.fetch _fnHandle
				else
					_fetchOpts = 
						consistent: options.consistent

					_query.fetch _fetchOpts, _fnHandle

				return

	destroy: ( cb )=>
		if @_isExistend( cb )
			@external.destroy( cb )

	_error: ( cb, err )=>
		if ERRORMAPPING[ err.name ]?
			_err = ERRORMAPPING[ err.name ]
			error = new Error
			error.name = _err.name
			error.message = _err.message
			cb( error )
		else
			cb( err )
		return

	_fixCombinedHash: ( hash )=>
		if @isCombinedTable
			_i = @name.length
			if hash[0.._i-1] is @name
				hash.slice( _i )
			else
				hash
		else
			hash

	_getOptions: ( options = {} )=>
		_defOpt =
			fields: if @_model_settings.defaultfields? then @_model_settings.defaultfields
			overwriteExistingHash: @overwriteExistingHash
			consistent: if @_model_settings.consistent? then @_model_settings.consistent else false
			forward: if @_model_settings.forward? then @_model_settings.forward else true
			conditionals: null
			
		_.extend( _defOpt, options or {} )

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

	_get: ( query, options, cb )=>
		_item = @external.get( query )
		if options?.fields?.length
			_item.get( options.fields )

		_fetchOpts = 
			consistent: options.consistent

		_item.fetch _fetchOpts, ( err, item )=>
			if err
				cb err
			else
				cb null, item
			return
		return

	_mget: ( mquery, options, cb )=>
		
		_self = @

		_batch = @mng.client.get ->
			if options?.fields?.length
				@get _self.tableName, mquery, options.fields
			else
				@get _self.tableName, mquery

		_batch.fetch ( err, items )=>
			if err
				cb err
			else
				cb null, items[ @tableName ] or []
			return

		return

	_update: ( id, attributes, options= {}, cb )=>

		_id = @_deFixHash( id ) 
		if _id instanceof Error
			@_error( cb, _id )
			return
		item = @external.get( _id )
		_upd = item.update( @_attrs.updateAttrsFn( attributes, options ) )
		_upd.returning( "ALL_NEW" )
		
		_upd = @_checkSetOptions( "update", _upd, attributes, options )

		# only save if data has changed
		if _upd.AttributeUpdates?
			_upd.save ( err, _saved )=>
				
				if err
					cb err
				else
					cb( null, _saved.Attributes or {} )
				return
		else
			cb( null, null )

		return

	_create: ( attributes = {}, options, cb )=>

		@_createId attributes, ( err, attributes )=>
			if err
				cb err
			else
				_upd = @external.put( attributes )

				_upd = @_checkSetOptions( "create", _upd, attributes, options )

				_upd.save ( err )=>
					if err
						cb err
					else
						cb( null, _upd )
					return

			return

		return

	_del: ( query, options, cb )=>
		_del = @external.get( query )

		_del.returning( "ALL_OLD" )

		_del = @_checkSetOptions( "update", _del, {}, options )

		_del.destroy ( err, item )=>
			if err
				cb err
			else
				cb null, item or null
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
		attrs

	_deFixHash: ( attrs )=>
		
		if _.isString( attrs ) or _.isNumber( attrs ) or _.isArray( attrs )
			_hName = @hashKey
			_attrs = {}
			_attrs[ _hName ] = _.clone( attrs )
		else
			_attrs = _.clone( attrs )
		
		if @hasRange
			_hType = @hashKeyType
			_rName = @rangeKey
			_rType = @rangeKeyType

			if not _.isArray( _attrs[ _hName ] )
				error = new Error
				error.name = "invalid-range-call"
				error.message = "If you try to access a hash/range item you have to pass a Array of `[hash,range]` as id."
				return error

			[ _h, _r ] = _attrs[ _hName ]
			_attrs[ _hName ] =  @_convertValue( _h, _hType )
			_attrs[ _rName ] =  @_convertValue( _r, _rType )

		_attrs

	_validateHash: ( hash )=>
		_pre = @name + @combinedHashDelimiter
		_l = _pre.length
		hash.slice( 0,_l ) is _pre

	_createId: ( attributes, cb )=>
		@_createHashKey attributes, ( attributes )=>
			# add prefix to hashKey if it's a combined table
			if @isCombinedTable
				if not @_validateHash( attributes[ @hashKey ] )
					error = new Error
					error.name = "combined-hash-invalid"
					error.message = "The hash of a combined-table has to start with the `name` of this table defined in the configuartion. Please try `#{ @name + @combinedHashDelimiter + attributes[ @hashKey ] }`"
					@_error( cb, error )
					return

			# create range attribute if defined in shema
			if @hasRange
				@_createRangeKey attributes, ( attributes )=>
					cb( null, attributes )
					return
			else
				cb( null, attributes )
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
		if @isCombinedTable
			@name + @combinedHashDelimiter + uuid.v1()
		else		
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

	_checkSetOptions: ( type, _upd, attributes, options )=>
		if type is "create" and ( not options?.overwriteExistingHash or not @overwriteExistingHash )

			_pred = {}
			_pred[ @hashKey ] = { "==": null }
			_upd.when _pred

		if type is "update"
			if not _.isEmpty( options.conditionals )
				_upd.when( options.conditionals )

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

