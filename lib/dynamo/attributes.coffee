_ = require "underscore"
utils = require "./utils"

Helper = 
	val2dyn: ( value )->

		switch typeof value
			when "number" then return {N: String(value)}
			when "string" then return {S: value}

		if value
			switch typeof value[0]
				when "number" then return {NN: value.map(String)}
				when "string" then return {SS: value}

		throw new Error("Invalid key value type.")

	dyn2val: ( data )->
		name = Object.keys(data)[0]
		value = data[name]

		switch name
			when "S", "SS" then value
			when "N" then Number(value)
			when "NS" then value.map(Number)
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
							if not _.isString( val )
								error = new Error
								error.name = "validation-error"
								error.message = "Wrong type of `#{ key }`. Please pass this key as a `String`"
								@table._error( cb, error )
								return
						when "number"
							if not _.isNumber( val )
								error = new Error
								error.name = "validation-error"
								error.message = "Wrong type of `#{ key }`. Please pass this key as a `Number`"
								@table._error( cb, error )
								return
						when "array"
							if isCreate
								if not _.isArray( val )
									error = new Error
									error.name = "validation-error"
									error.message = "Wrong type of `#{ key }`. Please pass this key as an `Array`"
									@table._error( cb, error )
									return
							else
								if not ( val[ "$add" ]? or val[ "$rem" ]? or val[ "$reset" ]? ) and not _.isArray( val )
									error = new Error
									error.name = "validation-error"
									error.message = "Wrong type of `#{ key }`. Please pass this key as an `Array` or an Object of actions"
									@table._error( cb, error )
									return


			cb( null, attrs )
		return

	updateAttrsFn: ( _current, _new, options = {} )=>
		self = @
		return ->
			_tbl = self.table
			_kc = _.without( Object.keys( _current ), _tbl.hashKey, _tbl.rangeKey )
			_kn = _.without( Object.keys( _new ), _tbl.hashKey, _tbl.rangeKey )
			if options.removeMissing
				@_todel = _.difference( _kc, _kn )
			else
				@_todel = []
			# do not update the hashkey
			for _k, _v of _new when _k isnt _tbl.hashKey

				_attr = self.get( _k )

				if _attr?.type is "array" and not _.isArray( _new[ _k ] )
					val = _new[ _k ]
					if val[ "$add" ]?
						@add( _k, val[ "$add" ] )
					if val[ "$rem" ]?
						@remove( _k, val[ "$rem" ] )
					if val[ "$reset" ]?
						@put( _k, val[ "$reset" ] )

				else 
					if _current[ _k ]? and _current[ _k ] isnt _v
						# existend and not changed
						@put( _k, _v )
					else if not _current[ _k ]? 
						# new attribute
						@put( _k, _v )

			if @_todel.length
				@remove( _k ) for _k in @_todel

			return


	getQuery: ( table, query, startAt, options={} )=>
		[ _q, isScan ] = @fixPredicates( query )
		if isScan
			console.warn "WARNING! Dynamo-Scan on `#{ table.TableName }`. Query:", _q if @table.mng.options.scanWarning

			_q = table.scan( _q )
		else
			_q = table.query( _q )

		if startAt?
			_q.startAt( startAt )

		if options?.limit?
			_q.limit( options.limit )

		if options?.fields?.length
			_q.get( options?.fields )

		_q

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

	_fixPredicateValue: ( value, type = "string" )=>
		_vt = typeof value

		switch type
			when "string"
				if _vt not in [ "string", "undefined" ]
					value.toString()
				else
					value
			when "number"
				if _vt not in [ "number", "undefined" ]
					parseFloat( value, 10 )
				else
					value
			when "boolean"
				if _vt not in [ "boolean", "undefined" ]
					Boolean( value )
				else
					value




exports = module.exports = Attributes

exports.helper = Helper

