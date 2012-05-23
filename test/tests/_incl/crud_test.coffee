module.exports = ( testTitle, _basicTable, _overwriteTable, _logTable1, _logTable2, _setTable )->

	# read configuration
	_CONFIG = require "../../config.js"
	_ = require("underscore")
	should = require('should')

	# read replace AWS keys from environment
	_CONFIG.aws.accessKeyId = process.env.AWS_ACCESS_KEY_ID if process.env?.AWS_ACCESS_KEY_ID?
	_CONFIG.aws.secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY if process.env?.AWS_SECRET_ACCESS_KEY?

	# import module to test
	SimpleDynamo = require "../../../lib/dynamo/"
	_utils = SimpleDynamo.utils


	_DATA = require "../../testdata.js"

	dynDB = null
	tableG = null

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

					tableG = dynDB.get( _basicTable )
					tableG.should.exist

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
				
				tableG.find ( err, items )->
					throw err if err
					items.should.an.instanceof( Array )
					_ItemCount = items.length
					console.log _ItemCount, "Items found"
					done()
					return
				return

			it "create an item", ( done )->
				tableG.set _.clone( _D[ "insert1" ] ), ( err, item )->
					throw err if err
					item.id.should.exist
					item.name.should.exist
					item.email.should.exist
					item.age.should.exist

					item.id.should.equal( _D[ "insert1" ].id )
					item.name.should.equal( _D[ "insert1" ].name )
					item.email.should.equal( _D[ "insert1" ].email )
					item.age.should.equal( _D[ "insert1" ].age )

					_ItemCount++
					_G[ "insert1" ] = item

					done()
					return
				return

			it "try to get the item and check the content", ( done )->
				
				tableG.get _G[ "insert1" ][ _C.hashKey ], ( err, item )->
					throw err if err

					item.id.should.exist
					item.name.should.exist
					item.email.should.exist
					item.age.should.exist

					item.id.should.equal( _D[ "insert1" ].id )
					item.name.should.equal( _D[ "insert1" ].name )
					item.email.should.equal( _D[ "insert1" ].email )
					item.age.should.equal( _D[ "insert1" ].age )

					done()
					return
				return

			it "create a second item", ( done )->
				
				tableG.set _.clone( _D[ "insert2" ] ), ( err, item )->
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
				
				tableG.set _.clone( _D[ "insert3" ] ), ( err, item )->
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
				
				tableG.find ( err, items )->
					throw err if err

					items.should.an.instanceof( Array )
					items.length.should.equal( _ItemCount )
					done()
					return
				return

			it "delete the first inserted item", ( done )->
				
				tableG.del _G[ "insert1" ][ _C.hashKey ], ( err )->
					throw err if err
					_ItemCount--
					done()
					return
				return

			it "try to get deleted item", ( done )->
				tableG.get _G[ "insert1" ][ _C.hashKey ], ( err, item )->
					throw err if err

					should.not.exist( item )

					done()
					return
				return

			it "update second item", ( done )->
				tableG.set _G[ "insert2" ][ _C.hashKey ], _D[ "update2" ], ( err, item )->
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
				
				tableG.del _G[ "insert2" ][ _C.hashKey ], ( err )->
					throw err if err
					_ItemCount--
					done()
					return
				return

			it "delete the third inserted item", ( done )->
				
				tableG.del _G[ "insert3" ][ _C.hashKey ], ( err )->
					throw err if err
					_ItemCount--
					done()
					return
				return

			it "check item count after update(s) and delete(s)", ( done )->
				
				tableG.find ( err, items )->
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

			table1 = null
			table2 = null
			_D1 = _DATA[ _logTable1 ]
			_D2 = _DATA[ _logTable2 ]
			_G1 = []
			_G2 = []
			_ItemCount1 = 0
			_ItemCount2 = 0
			
			it "get table 1", ( done )->
				table1 = dynDB.get( _logTable1 )
				should.exist( table1 )
				done()
				return

			it "get table 2", ( done )->
				table2 = dynDB.get( _logTable2 )
				should.exist( table2 )
				done()
				return

			it "insert #{ _D1.inserts.length } items to range list of table 1", ( done )->
				aFns = []
				for insert in _D1.inserts
					_throtteldSet = _.throttle( table1.set, 250 )
					aFns.push _.bind( ( insert, cba )->
						_throtteldSet _.clone( insert ), ( err, item )->
							throw err if err

							item.id.should.equal( insert.user + "::" + insert.t )
							item.user.should.equal( insert.user )
							item.title.should.equal( insert.title )
							_ItemCount1++
							_G1.push( item )
							cba( item )

					, table1, insert ) 

				_utils.runSeries aFns, ( err )->
					done()

			it "insert #{ _D2.inserts.length } items to range list of table 2", ( done )->
				aFns = []
				for insert in _D2.inserts
					_throtteldSet = _.throttle( table2.set, 250 )
					aFns.push _.bind( ( insert, cba )->
						_throtteldSet _.clone( insert ), ( err, item )->
							throw err if err

							item.id.should.equal( insert.user + "::" + insert.t )
							item.user.should.equal( insert.user )
							item.title.should.equal( insert.title )
							_ItemCount2++
							_G2.push( item )
							cba( item )

					, table2, insert ) 

				_utils.runSeries aFns, ( err )->
					done()

			it "get a range of table 1", ( done )->
				_q = 
					id: { "==": "A" }
					t: { ">=": 5 }

				table1.find _q, ( err, items )->
					throw err if err

					items.length.should.equal( 3 )
					done()

			it "get a range of table 2", ( done )->
				_q = 
					id: { "==": "D" }
					t: { ">=": 3 }

				table2.find _q, ( err, items )->
					throw err if err

					items.length.should.equal( 1 )
					done()

			it "get a single item of table 1", ( done )->
				_item = _G1[ 4 ]

				table1.get _item.id, ( err, item )->
					throw err if err

					item.should.eql( _item )
					done()

			it "delete whole data from table 1", ( done )->
				aFns = []
				for item in _G1
					_throtteldDel = _.throttle( table1.del, 250 )
					aFns.push _.bind( ( item, cba )->
						_throtteldDel item.id, ( err )->
							throw err if err
							_ItemCount1--
							cba()
					, table1, item )

				_utils.runSeries aFns, ( err )->
					done()

			it "delete whole data from table 2", ( done )->
				aFns = []
				for item in _G2
					_throtteldDel = _.throttle( table2.del, 250 )
					aFns.push _.bind( ( item, cba )->
						_throtteldDel item.id, ( err )->
							throw err if err
							_ItemCount2--
							cba()
					, table2, item )

				_utils.runSeries aFns, ( err )->
					done()

			it "check for empty table 1", ( done )->
				_q = {}

				table1.find _q, ( err, items )->
					throw err if err

					items.length.should.equal( _ItemCount1 )
					done()

			it "check for empty table 2", ( done )->
				_q = {}

				table2.find _q, ( err, items )->
					throw err if err

					items.length.should.equal( _ItemCount2 )
					done()
		
		describe "#{ testTitle } Set Tests", ->		
			

			_C = _CONFIG.tables[ _setTable ]
			_D = _DATA[ _setTable ]
			_G = {}
			_ItemCount = 0
			table = null

			it "get table", ( done )->
				table = dynDB.get( _setTable )
				should.exist( table )
				done()
				return

			it "create the test item", ( done )->
				
				table.set _.clone( _D[ "insert1" ] ), ( err, item )->
					throw err if err

					item.id.should.exist
					item.name.should.exist
					item.users.should.exist

					item.name.should.equal( _D[ "insert1" ].name )
					item.users.should.eql( [ "a" ] )

					_ItemCount++
					_G[ "insert1" ] = item

					done()
					return
				return

			it "test raw reset", ( done )->
				
				table.set _G[ "insert1" ].id, _.clone( _D[ "update1" ] ), ( err, item )->
					throw err if err
					item.id.should.exist
					item.name.should.exist
					item.users.should.exist

					item.name.should.equal( _D[ "insert1" ].name )
					item.users.should.eql( [ "a", "b" ] )

					_G[ "insert1" ] = item

					done()
					return
				return

			it "test $add action", ( done )->
				
				table.set _G[ "insert1" ].id, _.clone( _D[ "update2" ] ), ( err, item )->
					throw err if err

					item.id.should.exist
					item.name.should.exist
					item.users.should.exist

					item.name.should.equal( _D[ "insert1" ].name )
					item.users.should.eql( [ "a", "b", "c" ] )

					_G[ "insert1" ] = item

					done()
					return
				return

			it "test $rem action", ( done )->
				table.set _G[ "insert1" ].id, _.clone( _D[ "update3" ] ), ( err, item )->
					throw err if err

					item.id.should.exist
					item.name.should.exist
					item.users.should.exist

					item.name.should.equal( _D[ "insert1" ].name )
					item.users.should.eql( [ "b", "c" ] )

					_G[ "insert1" ] = item

					done()
					return
				return

			it "test $reset action", ( done )->
				
				table.set _G[ "insert1" ].id, _.clone( _D[ "update4" ] ), ( err, item )->
					throw err if err

					item.id.should.exist
					item.name.should.exist
					item.users.should.exist

					item.name.should.equal( _D[ "insert1" ].name )
					item.users.should.eql( [ "x", "y" ] )

					_G[ "insert1" ] = item

					done()
					return
				return

			it "delete test item", ( done )->
				
				table.del _G[ "insert1" ].id, ( err )->
					throw err if err
					_ItemCount--
					done()
					return
				return

		return			
