# read configuration
_CONFIG = require "./config.js"

# read replace AWS keys from environment
_CONFIG.aws.accessKeyId = process.env.AWS_ACCESS_KEY_ID if process.env?.AWS_ACCESS_KEY_ID?
_CONFIG.aws.secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY if process.env?.AWS_SECRET_ACCESS_KEY?

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


