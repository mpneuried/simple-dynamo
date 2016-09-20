_all = require( "lodash/all" )
_isArray = require( "lodash/isArray" )
_any = require( "lodash/any" )
_identity = require( "lodash/identity" )


module.exports =

	params: ( obj, params )->
		if _all( params, ( key, idx )-> obj[ key ]? )
			true
		else
			false

	# simple serial flow controll
	runSeries: (fns, callback) ->
		return callback()	if fns.length is 0
		completed = 0
		data = []
		iterate = ->
			fns[completed] (results) ->
				data[completed] = results
				if ++completed is fns.length
					callback data	if callback
				else
					iterate()

		iterate()

	# simple parallel flow controll
	runParallel: (fns, callback) ->
		return callback() if fns.length is 0
		started = 0
		completed = 0
		data = []
		iterate = ->
			fns[started] ((i) ->
				(results) ->
					data[i] = results
					if ++completed is fns.length
						callback data if callback
						return
			)(started)
			iterate() unless ++started is fns.length

		iterate()

	# check for a single `true` element in an array
	checkArray: ( ar )->

		if _isArray( ar )
			_any( ar, _identity )
		else
			_identity( ar )

	# *reduce the keys of an object to the keys listed in the `keys array*  
	# **obj:** { Object } *object to reduce*  
	# **keys:** { Array } *Array of valid keys*  
	reduceObj: ( obj, keys )->
		ret = {}
		ret[ key ] = val for key, val of obj when keys.indexOf( key ) >= 0
		ret
