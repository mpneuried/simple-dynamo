# # Simpledynamo

# ### extends [NPM:MPBasic](https://cdn.rawgit.com/mpneuried/mpbaisc/master/_docs/index.coffee.html)

#
# ### Exports: *Class*
#
# Main Module
#

class Simpledynamo extends require( "mpbasic" )()

	# ## defaults
	defaults: =>
		@extend super,
			# **Simpledynamo.foo** *Number* This is a example default option
			foo: 23
			# **Simpledynamo.bar** *String* This is a example default option
			bar: "Buzz"

	###
	## constructor
	###
	constructor: ( options ) ->
		super
		

		@start()

		return

	start: =>
		@debug( "START" )
		return

#export this class
module.exports = Simpledynamo
