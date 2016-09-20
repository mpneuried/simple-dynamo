# read configuration
_CONFIG = require "./config"
async = require "async"
_delay = require("lodash/delay")


# read replace AWS keys from environment
_CONFIG.aws.accessKeyId = process.env.AWS_AKI if process.env?.AWS_AKI?
_CONFIG.aws.secretAccessKey = process.env.AWS_SAK if process.env?.AWS_SAK?
_CONFIG.aws.region = process.env.AWS_REGION if process.env?.AWS_REGION?
_CONFIG.aws.tablePrefix = process.env.AWS_TABLEPREFIX if process.env?.AWS_TABLEPREFIX?

# import module to test
SimpleDynamo = require "../."
dynDB = null
_tables = []

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
		
		fnDel = ( tbl )->
			return ( cba )->
				tableName = @name
				tbl.destroy ( err )->
					console.log "#{ tableName } deleted"

					console.log err if err
					
					# delay each destroy to throttle control plane requests
					_delay( cba, 2000, err )
					return
				return
		
		aFn = []
		for tableName in _tables
			_tbl = dynDB.get( tableName )
			if _tbl
				aFn.push fnDel( _tbl )

		asnyc.series aFn, ( err )->
			done()
			return
		return
