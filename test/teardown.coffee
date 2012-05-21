# read configuration
_CONFIG = require "./config.js"
_ = require("underscore")


# read replace AWS keys from environment
_CONFIG.aws.accessKeyId = process.env.AWS_ACCESS_KEY_ID if process.env?.AWS_ACCESS_KEY_ID?
_CONFIG.aws.secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY if process.env?.AWS_SECRET_ACCESS_KEY?

# import module to test
SimpleDynamo = require "../lib/dynamo/"
dynDB = null
_tables = []

_utils = SimpleDynamo.utils

describe "----- TEARDOWN -----", ->
	before ( done )->
		dynDB = new SimpleDynamo( _CONFIG.aws, _CONFIG.tables )
		dynDB.connect ( err )->
			throw err if err
			dynDB.list ( err, tables )->
				throw err if err
				_tables = tables
				done()
			return
		return


	it "DESTROY test tables", ( done )->
		# Only run destroy 
		if not _CONFIG.test.deleteTablesOnEnd
			done()
			console.log "DESTROY deactivated"
			return

		aFn = []
		for tableName in _tables
			_tbl = dynDB.get( tableName )
			if _tbl
				aFn.push _.bind( ( cba )->
					tableName = @name
					@destroy ( err )->
						console.log "#{ tableName } deleted"
						throw err if err
						
						# delay each destroy to throttle control plane requests
						_.delay( cba, 2000, err )
						return


				, _tbl )

		_utils.runSeries aFn, ( err )->
			throw _.first( err ) if _utils.checkArray( err )
			done()
			return
		return