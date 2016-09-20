# # NsqBasic Module
# ### extends [Basic](basic.coffee.html)
#
# a collection of shared nsq methods

# **npm modules**
_isFunction = require( "lodash/isFunction" )
_isString = require( "lodash/isString" )

# **internal modules**
Config = require "./config"

class SimpleDynamoBasic extends require( "mpbasic" )()

	constructor: ( options )->
		@connected = false

		@on "_log", @_log

		@getter "classname", ->
			return @constructor.name.toLowerCase()

		# extend the internal config
		if options instanceof Config
			@config = options
		else
			@config = new Config( options )

		# init errors
		@_initErrors()

		@initialize( options )

		@debug "loaded"
		return
		
module.exports = SimpleDynamoBasic
