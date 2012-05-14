# read configuration
_CONFIG = require "./config.js"

# read replace AWS keys from environment
_CONFIG.aws.accessKeyId = process.env.AWS_AKI if process.env?.AWS_AKI?
_CONFIG.aws.secretAccessKey = process.env.AWS_SAK if process.env?.AWS_SAK?

# import module to test
SimpleDynamo = require "../lib/dynamo/"
dynDB = null

describe "----- SETUP -----", ->
	before ( done )->
		dynDB = new SimpleDynamo( _CONFIG.aws, _CONFIG.tables )
		done()

	describe "Initialization", ->
		it "init table objects", ( done )->
			dynDB.connect ( err )=>
				throw err if err
				done()

	describe "Create tables", ->
		it "create a single table", ( done )->
			dynDB.generate _CONFIG.test.singleCreateTableTest, ( err )->
				throw err if err
				done()

		it "create all missing tables", ( done )->
			dynDB.generateAll ( err )->
				throw err if err
				done()


