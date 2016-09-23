_ = require "underscore"
utils = require "./utils"
type = require( "type-detect" )

Helper =
	val2dyn: ( value )->

		switch type( value )
			when "number" then return {N: String(value)}
			when "string" then return {S: value}
			when "object" then return {M: Helper.obj2dyn( value )}
			when "boolean" then return {BOOL: value.toString() }
			when "buffer" then return {B: value.toString('base64') }

		if value?[ 0 ]?
			switch type( value[ 0 ] )
				when "number" then return {NN: value.map(String)}
				when "string" then return {SS: value}
				else
					_vs = []
					for _v in value
						_vs.push( Helper.val2dyn( _v ) )
					return {L:_vs}

		throw new Error("Invalid key value type.")

	dyn2val: ( data )->
		name = Object.keys(data)[0]
		value = data[name]

		switch name
			when "S", "SS" then value
			when "N" then Number(value)
			when "NS" then value.map(Number)
			when "BOOL", "NULL"
				if( [ "true", "TRUE", "True", "t", "T", "1", "ok", "OK", "yes", "YES", "Yes", true, 1 ].indexOf( value ) >= 0 )
					return true
				else
					return false
			when "B" then new Buffer(value, "base64")
			when "M" then Helper.dyn2obj( value )
			when "L"
				_vs = []
				for _v in value
					_vs.push( Helper.dyn2val( _v ) )
				return _vs
			else
				throw new Error("Invalid data type: " + name)


	obj2dyn: ( attrs )->
		obj = {}
		Object.keys(attrs).forEach (key)-> obj[ key ] = Helper.val2dyn( attrs[ key ] )

		obj

	dyn2obj: (data)->
		obj = {}
		Object.keys(data).forEach (key)->
			obj[key] = Helper.dyn2val( data[ key ] )

		obj



class Attributes
	constructor: ( @raw, @table )->
		@prepare()
		return

	prepare: =>
		@attrs or= {}
		@_required_attrs = []

		_hKey = @table.hashKey
		_rKey = @table.rangeKey
		for _attr in @raw
			@_required_attrs.push( _attr.key ) if _attr.required

			_outE = _.clone( _attr )
			if _outE.key is _hKey
				_outE.isHash = true
			if _outE.key is _rKey
				_outE.isRange = true
			@attrs[ _outE.key ] = _outE

		if not @attrs[ _hKey ]
			@attrs[ _hKey ] =
				key: _hKey
				isHash: true
				type: @table.hashKeyType
				required: true

			#@_required_attrs.push( _hKey )

		if @table.hasRange and not @attrs[ _rKey ]
			@attrs[ _rKey ] =
				key: _rKey
				isRange: true
				type: @table.rangeKeyType
				required: true

			#@_required_attrs.push( _rKey )

		return

	get: ( key )=>
		@attrs[ key ] or null

	validateAttributes: ( isCreate, attrs, cb )=>
		if not utils.params( attrs, @_required_attrs )
			# table not existend
			error = new Error
			error.name = "validation-error"
			error.message = "Missing key. Please make sure to add all required keys ( #{ @_required_attrs } )"
			@table._error( cb, error )
		else
			for key, val of attrs
				_attr = @get( key )
				if _attr
					# check the type of the attributes
					switch _attr.type
						when "string"
							if ( not isCreate and val isnt null ) and not _.isString( val )
								error = new Error
								error.name = "validation-error"
								error.message = "Wrong type of `#{ key }`. Please pass this key as a `String`"
								@table._error( cb, error )
								return
						when "number"
							if ( not isCreate and val isnt null ) and not ( _.isNumber( val ) or val[ "$add" ]? )
								error = new Error
								error.name = "validation-error"
								error.message = "Wrong type of `#{ key }`. Please pass this key as a `Number`"
								@table._error( cb, error )
								return
						when "array"
							if isCreate
								if val is null
									delete attrs[ key ]
								else if not _.isArray( val )
									error = new Error
									error.name = "validation-error"
									error.message = "Wrong type of `#{ key }`. Please pass this key as an `Array`"
									@table._error( cb, error )
									return
								else if val.length is 0
									delete attrs[ key ]

							else
								if val isnt null and not ( val[ "$add" ]? or val[ "$rem" ]? or val[ "$reset" ]? ) and not _.isArray( val )
									error = new Error
									error.name = "validation-error"
									error.message = "Wrong type of `#{ key }`. Please pass this key as an `Array` or an Object of actions"
									@table._error( cb, error )
									return


			cb( null, attrs )
		return

	updateAttrsFn: ( _new, options = {} )=>
		self = @
		return ->
			_tbl = self.table

			# do not update the hashkey
			for _k, _v of _new when _k isnt _tbl.hashKey

				_attr = self.get( _k )

				if ( _attr?.type is "array" or ( not _attr and _v? and ( _v[ "$add" ]? or _v[ "$rem" ]? or _v[ "$reset" ]? ) ) ) and not _.isArray( _v )
					if _v is null
						@remove( _k )
					else
						if _v[ "$add" ]?
							_vA = ( if _.isArray( _v[ "$add" ] ) then _v[ "$add" ] else [ _v[ "$add" ] ] )
							@add( _k, _vA ) if _vA.length
						if _v[ "$rem" ]?
							_vA = ( if _.isArray( _v[ "$rem" ] ) then _v[ "$rem" ] else [ _v[ "$rem" ] ] )
							@remove( _k, _vA ) if _vA.length
						if _v[ "$reset" ]?
							_vA = ( if _.isArray( _v[ "$reset" ] ) then _v[ "$reset" ] else [ _v[ "$reset" ] ] )
							@put( _k, _vA ) if _vA.length

				else if ( _attr?.type is "number" and _v?[ "$add" ]? )
					@add( _k, _v[ "$add" ] ) if _v?[ "$add" ]?
				else
					if _attr?.type is "string" and _.isString( _v ) and not _v.length
						# remove attribute if type is a empty string
						@remove( _k )
					else if _v is null or ( _.isArray( _v ) and not _v.length )
						# remove attribute if null or empty array
						@remove( _k )
					else
						# update or create attribute
						@put( _k, _v )

			return
		return


	getQuery: ( table, query, startAt, options={} )=>
		[ _q, isScan ] = @fixPredicates( query )
		if isScan
			console.warn "WARNING! Dynamo-Scan on `#{ table.TableName }`. Query:", _q if @table.mng.options.scanWarning

			_q = table.scan( _q )
		else
			_q = table.query( _q )

			if not options?.forward
				_q.reverse()

		if startAt?
			_q.startAt( startAt )

		if options?.limit?
			_q.limit( options.limit )

		if options?.fields?.length
			_q.get( options?.fields )

		return [ _q, isScan ]

	fixPredicates: ( predicates = {} )=>
		_fixed = {}
		isScan = not @table.hasRange

		_predCount = Object.keys( predicates ).length
		if _predCount
			for key, predicate of predicates
				_attr = @get( key )
				# only accept defined attributes for query
				if _attr
					# check if the query has to be a scan
					if not _attr.isHash and not _attr.isRange
						isScan = true
					_fixed[ key ] = @_fixPredicate( predicate, _attr )
			# check if its a valid query. otherwise force scan
			if not isScan and not utils.params( _fixed, [ @table.hashKey, @table.rangeKey ] )
				isScan = true

		else
			isScan = true

		[ _fixed, isScan ]

	_fixPredicate: ( predicate, _attr )=>
		_ops = Object.keys( predicate )

		_arrayAcceptOps = [ "<=", ">=", "in" ]

		if _ops.length is 1
			_op = _ops[ 0 ]

			if _.isArray( predicate[ _op ] ) and _op in _arrayAcceptOps
				_a = []
				for val in predicate[ _op ]
					_v = @_fixPredicateValue( val, _attr.type )
					_a.push( _v ) if _v

				predicate[ _op ] = _a

			else if not _.isArray( predicate[ _op ] )
				_v = @_fixPredicateValue( predicate[ _op ], _attr.type )
				predicate[ _op ] = _v if _v
			else
				throw new Error( "Malformed query. Arrays only allowed for `#{ _arrayAcceptOps }" )

		else
			throw new Error( "Malformed query. Only exact one query operator will be accepted per key" )


		predicate

	_fixPredicateValue: ( value, type = "string" )->
		_vt = typeof value

		switch type
			when "string", "S"
				if value? and _vt not in [ "string", "undefined" ]
					value.toString()
				else
					value
			when "number", "N"
				if value? and _vt not in [ "number", "undefined" ]
					parseFloat( value, 10 )
				else
					value
			when "boolean", "B"
				if _vt not in [ "boolean", "undefined" ]
					Boolean( value )
				else
					value




exports = module.exports = Attributes

exports.helper = Helper
