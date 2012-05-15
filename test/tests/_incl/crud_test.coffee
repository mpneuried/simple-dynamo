module.exports = ( testTitle, _basicTable, _overwriteTable, _logTable1, _logTable2 )->

	# read configuration
	_CONFIG = require "../../config.js"
	_ = require("underscore")
	should = require('should')

	# read replace AWS keys from environment
	_CONFIG.aws.accessKeyId = process.env.AWS_AKI if process.env?.AWS_AKI?
	_CONFIG.aws.secretAccessKey = process.env.AWS_SAK if process.env?.AWS_SAK?

	# import module to test
	SimpleDynamo = require "../../../lib/dynamo/"
	_utils = SimpleDynamo.utils


	_DATA = require "../../testdata.js"

	dynDB = null
	table = null

	describe "----- #{ testTitle } TESTS -----", ->
		before ( done )->
			done()

		describe 'Initialization', ->
			it 'init manager', ( done )->
				dynDB = new SimpleDynamo( _CONFIG.aws, _CONFIG.tables )
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

					table = dynDB.get( _basicTable )
					table.should.exist

					done()
					return
				return

			it 'post connect', ( done )->
				dynDB.fetched.should.be.true
				done()
				return

			return

		describe "#{ testTitle } CRUD Tests", ->

			_C = _CONFIG.tables[ _basicTable ]
			_D = _DATA[ _basicTable ]
			_G = {}
			_ItemCount = 0

			it "list existing items", ( done )->
				
				table.find ( err, items )->
					throw err if err
					items.should.an.instanceof( Array )
					_ItemCount = items.length
					console.log _ItemCount, "Items found"
					done()
					return
				return

			it "create an item", ( done )->
				
				table.set _.clone( _D[ "insert1" ] ), ( err, item )->
					throw err if err

					item.id.should.exist
					item.name.should.exist
					item.email.should.exist
					item.age.should.exist

					item.name.should.equal( _D[ "insert1" ].name )
					item.email.should.equal( _D[ "insert1" ].email )
					item.age.should.equal( _D[ "insert1" ].age )

					_ItemCount++
					_G[ "insert1" ] = item

					done()
					return
				return

			it "create a second item", ( done )->
				
				table.set _.clone( _D[ "insert2" ] ), ( err, item )->
					throw err if err

					item.id.should.exist
					item.name.should.exist
					item.email.should.exist
					item.age.should.exist
					item.additional.should.exist

					item.name.should.equal( _D[ "insert2" ].name )
					item.email.should.equal( _D[ "insert2" ].email )
					item.age.should.equal( _D[ "insert2" ].age )
					item.additional.should.equal( _D[ "insert2" ].additional )

					_ItemCount++
					_G[ "insert2" ] = item

					done()
					return
				return

			it "create a third item", ( done )->
				
				table.set _.clone( _D[ "insert3" ] ), ( err, item )->
					throw err if err

					item.id.should.exist
					item.name.should.exist
					item.email.should.exist
					item.age.should.exist

					item.name.should.equal( _D[ "insert3" ].name )
					item.email.should.equal( _D[ "insert3" ].email )
					item.age.should.equal( _D[ "insert3" ].age )

					_ItemCount++
					_G[ "insert3" ] = item

					done()
					return
				return

			it "list existing items after insert(s)", ( done )->
				
				table.find ( err, items )->
					throw err if err

					items.should.an.instanceof( Array )
					items.length.should.equal( _ItemCount )
					done()
					return
				return

			it "delete the first inserted item", ( done )->
				
				table.del _G[ "insert1" ][ _C.hashKey ], ( err )->
					throw err if err
					_ItemCount--
					done()
					return
				return

			it "try to get deleted item", ( done )->
				table.get _G[ "insert1" ][ _C.hashKey ], ( err, item )->
					throw err if err

					should.not.exist( item )

					done()
					return
				return

			it "update second item", ( done )->
				table.set _G[ "insert2" ][ _C.hashKey ], _D[ "update2" ], ( err, item )->
					throw err if err

					item.id.should.exist
					item.name.should.exist
					item.email.should.exist
					item.age.should.exist
					should.not.exist( item.additional )

					item.id.should.equal( _G[ "insert2" ].id )
					item.name.should.equal( _D[ "update2" ].name )
					item.email.should.equal( _G[ "insert2" ].email )
					item.age.should.equal( _D[ "update2" ].age )

					_G[ "insert2" ] = item

					done()
					return
				return

			it "delete the second inserted item", ( done )->
				
				table.del _G[ "insert2" ][ _C.hashKey ], ( err )->
					throw err if err
					_ItemCount--
					done()
					return
				return

			it "delete the third inserted item", ( done )->
				
				table.del _G[ "insert3" ][ _C.hashKey ], ( err )->
					throw err if err
					_ItemCount--
					done()
					return
				return

			it "check item count after update(s) and delete(s)", ( done )->
				
				table.find ( err, items )->
					throw err if err

					items.should.an.instanceof( Array )
					items.length.should.equal( _ItemCount )
					done()
					return
				return

			return

		describe "#{ testTitle } Overwrite Tests", ->

			table = null

			_C = _CONFIG.tables[ _overwriteTable ]
			_D = _DATA[ _overwriteTable ]
			_G = {}
			_ItemCount = 0

			it "get table", ( done )->
				table = dynDB.get( _overwriteTable )
				should.exist( table )
				done()
				return

			it "create item", ( done )->
				
				table.set _.clone( _D[ "insert1" ] ), ( err, item )->
					throw err if err

					item.id.should.exist
					item.title.should.exist
					item.done.should.exist

					item.id.should.equal( _D[ "insert1" ].id )
					item.title.should.equal( _D[ "insert1" ].title )
					item.done.should.equal( _D[ "insert1" ].done )

					_ItemCount++
					_G[ "insert1" ] = item

					done()
					return
				return

			it "try second insert with the same hash", ( done )->
				
				table.set _D[ "insert2" ], ( err, item )->

					err.should.exist
					err.name.should.equal( "conditional-check-failed" )

					should.not.exist( item )

					done()
					return
				return

			it "list items", ( done )->
				table.find ( err, items )->
					throw err if err
					console.log items
					items.should.an.instanceof( Array )
					items.length.should.equal( _ItemCount )
					done()
					return
				return

			it "delete the first inserted item", ( done )->
				
				table.del _G[ "insert1" ][ _C.hashKey ], ( err )->
					throw err if err
					_ItemCount--
					done()
					return
				return


		describe "#{ testTitle } Range Tests", ->

			table = null
			_D = _DATA[ _logTable1 ]
			_ItemCount = 0
			
			it "get table", ( done )->
				table = dynDB.get( _logTable1 )
				should.exist( table )
				done()
				return

			it "insert #{ _D.inserts.length } items to range list", ( done )->
				aFns = []
				for insert in _D.inserts
					_throtteldSet = _.throttle( table.set, 250 )
					aFns.push _.bind( ( insert, cba )->
						_throtteldSet _.clone( insert ), ( err, item )->
							throw err if err

							item.id.should.equal( insert.user + "::" + insert.t )
							item.user.should.equal( insert.user )
							item.title.should.equal( insert.title )
							_ItemCount++
							cba( insert )

					, table, insert ) 

				_utils.runSeries aFns, ( err )->
					done()


		return			
