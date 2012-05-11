_ = require "underscore"

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

		for _attr in @raw
			_outE = _.clone( _attr )
			if _outE.key is @table.hashKey
				_outE.isHash = true
			if _outE.key is @table.rangeKey
				_outE.isRange = true
			@attrs[ _outE.key ] = _outE

		return

	get: ( key )=>
		@attrs[ key ] or null

	validateAttributes: ( attrs, cb )=>
		# TODO implement validation
		cb( null, attrs )

	updateAttrsFn: ( _current, _new )=>
		self = @
		return ->
			_tbl = self.table
			_kc = _.without( Object.keys( _current ), _tbl.hashKey, _tbl.rangeKey )
			_kn = _.without( Object.keys( _new ), _tbl.hashKey, _tbl.rangeKey )
			@_todel = _.difference( _kc, _kn )
			# do not update the hashkey
			for _k, _v of _new when _k isnt _tbl.hashKey
				if _current[ _k ]? and _current[ _k ] isnt _v
					# existend and not changed
					@put( _k, _v )
				else if not _current[ _k ]? 
					# new attribute
					@put( _k, _v )

			@remove( _k ) for _k in @_todel

			return


	getQuery: ( table, query )=>
		[ _q, isScan ] = @fixPredicates( query )
		if isScan
			console.warn "WARNING! Dynamo-Scan on `#{ table.TableName }`. Query:", _q
			table.scan( _q )
		else
			table.query( _q )

	fixPredicates: ( predicates )=>
		_fixed = {}
		isScan = false
		for key, predicate of predicates
			_attr = @get( key )

			# only accept defined attributes for query
			if _attr
				# check if the query has to be a scan
				if not isScan or ( not _attr.isHash and not _attr.isRange )
					isScan = true
				_fixed[ key ] = @_fixPredicate( predicate, _attr )

		[ _fixed, true ]

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
					Boolean( 10 )
				else
					value




exports = module.exports = Attributes

exports.helper = Helper

