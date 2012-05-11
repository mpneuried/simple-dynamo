_ = require "underscore"

module.exports =

	params: ( obj, params )->
	 	if _.all( params, ( key, idx )-> obj[ key ]? )
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

		if _.isArray( ar )
			_.any( ar, _.identity )
		else
			_.identity( ar )

	# ## extend
	#
	# jquery extend method.
	#
	# **Parameters:**
	#
	# * `[ deep = false ]` ( Boolean ): Make a deep extend
	# * `baseobj` ( Object ): The base object
	# * `extendobj...` ( Object ): The Objects to extend teh base obj
	# 
	# **Returns:**
	#
	# ( Object ): the extended object
	# 
	# **Example:**
	#
	#     obj1 = { a: 1, b: { aaaa: { d: 'org' } } }
	#     obj2 = { c: 1, b: { xxxx: { d: 'org' } } }
	#     
	#     utils.extend( obj1, obj2 )
	#     # { c: 1, a: 1, b: { xxxx: { d: 'org' } } }
	#
	#     utils.extend( true, obj1, obj2 )
	#     # { c: 1, a: 1, b: { xxxx: { d: 'org' }, aaaa: { d: 'org' } } } }
	#
	extend: ->
		target = arguments[0] or {}
		i = 1
		length = arguments.length
		deep = false
		if typeof target == "boolean"
			deep = target
			target = arguments[1] or {}
			i = 2
		target = {}	if typeof target != "object" and not typeof target == "function"
		isArray = (obj) ->
			(if toString.call(copy) == "[object Array]" then true else false)
		
		isPlainObject = (obj) ->
			return false	if not obj or toString.call(obj) != "[object Object]" or obj.nodeType or obj.setInterval
			has_own_constructor = hasOwnProperty.call(obj, "constructor")
			has_is_property_of_method = hasOwnProperty.call(obj.constructor::, "isPrototypeOf")
			return false	if obj.constructor and not has_own_constructor and not has_is_property_of_method
			
			for key of obj
				last_key = key
			typeof last_key == "undefined" or hasOwnProperty.call(obj, last_key)
		
		while i < length
			if (options = arguments[i]) != null
				for name of options
					src = target[name]
					copy = options[name]
					continue	if target == copy
					if deep and copy and (isPlainObject(copy) or isArray(copy))
						clone = (if src and (isPlainObject(src) or isArray(src)) then src else (if isArray(copy) then [] else {}))
						target[name] = utils.extend(deep, clone, copy)
					else target[name] = copy	if typeof copy != "undefined"
			i++
		target