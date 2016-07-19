# read configuration
_CONFIG = require "../config.js"
_ = require("underscore")
should = require('should')

# read replace AWS keys from environment
_CONFIG.aws.accessKeyId = process.env.AWS_AKI if process.env?.AWS_AKI?
_CONFIG.aws.secretAccessKey = process.env.AWS_SAK if process.env?.AWS_SAK?
_CONFIG.aws.region = process.env.AWS_REGION if process.env?.AWS_REGION?
_CONFIG.aws.tablePrefix = process.env.AWS_TABLEPREFIX if process.env?.AWS_TABLEPREFIX?


# import module to test
SimpleDynamo = require "../../lib/dynamo/"
_utils = SimpleDynamo.utils
dynDB = null
dynDBDummy = null
_tables = []

describe "----- Manager Tests -----", ->
	before ( done )->
		done()

	describe 'Initialization', ->
		it 'init manager', ( done )->
			dynDB = new SimpleDynamo( _CONFIG.aws, _CONFIG.tables )
			dynDBDummy = new SimpleDynamo( _CONFIG.aws, _CONFIG.dummyTables )
			done()
			return

		it 'pre connect', ( done )->
			dynDB.fetched.should.be.false
			dynDB.connected.should.be.false
			done()
			return

		it 'init table objects', ( done )->
			dynDB.connect ( err )->
				throw err if err
				done()
				return
			return

		it 'init table objects for dummy', ( done )->
			dynDBDummy.connect ( err )->
				throw err if err
				done()
				return
			return

		it 'post connect', ( done )->
			dynDB.fetched.should.be.true
			dynDB.connected.should.be.true
			done()
			return

		return

	describe 'Basic Methods', ->
		it "List the existing tables", ( done )->
			dynDB.list ( err, tables )->
				throw err if err

				# create expected list of tables
				tbls = []
				for tbl in Object.keys( _CONFIG.tables )
					tbls.push( tbl.toLowerCase() )
				tables.should.eql( tbls )

				done()
			return

		it "Get a table", ( done )->

			_cnf = _CONFIG.tables[ _CONFIG.test.singleCreateTableTest ]

			_tbl = dynDB.get( _CONFIG.test.singleCreateTableTest )
			_tbl.should.exist
			_tbl?.name?.should.eql( _cnf.name )

			done()
			return

		it "Try to get a not existend table", ( done )->

			_tbl = dynDB.get( "notexistend" )
			should.not.exist( _tbl )

			done()
			return

		it "has for existend table", ( done )->

			_has = dynDB.has( _CONFIG.test.singleCreateTableTest )
			_has.should.be.true

			done()
			return

		it "has for not existend table", ( done )->

			_has = dynDB.has( "notexistend" )
			_has.should.be.false

			done()
			return

		it "Get check `existend` for real table", ( done )->

			_tbl = dynDB.get( _CONFIG.test.singleCreateTableTest )
			_tbl.should.exist
			_tbl.existend.should.be.true
			done()
			return

		it "Get check `existend` for dummy table", ( done )->

			_tbl = dynDBDummy.get( "Dummy" )
			_tbl.should.exist
			_tbl.existend.should.be.false
			done()
			return

		it "generate ( existend ) table", ( done )->

			_has = dynDB.generate _CONFIG.test.singleCreateTableTest, ( err, created )->
				throw err if err 
				created.should.be.false
				done()
			return


		return

	return
