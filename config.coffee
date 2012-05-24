CONFIG = 
	"_BASIC":
		server:
			port: 3000
			host: null

		aws:
			accessKeyId: "-"
			secretAccessKey: "-"

		dynamo:
			region: "eu-west-1"

			tables: 
				"User":
					name: "users"
					hashKey:  "_id"

					overwriteExistingHash: false
					# overwriteExisting

					attributes: [
						{ key: "name", type: "string", required: true }
						{ key: "age", type: "number" }
						{ key: "lastlogin", type: "number" }
					]

				"Users":
					name: "u"
					combineTableTo: "combined"

					hashKey:  "_id"

					overwriteExistingHash: false
					# overwriteExisting

					attributes: [
						{ key: "name", type: "string", required: true }
						{ key: "age", type: "number" }
						{ key: "lastlogin", type: "number" }
					]

				"Rooms":
					name: "r"
					combineTableTo: "combined"

					hashKey:  "_id"

					overwriteExistingHash: false

					attributes: [
						{ key: "name", type: "string", required: true }
						{ key: "users", type: "array" }
						{ key: "foo", type: "array" }
					]

				"Messages":
					name: "messages"
					hashKey:  "_id"
					rangeKey:  "_t"
					rangeKeyType:  "N"

					fnCreateHash: ( attributes, cb )->
						cb( attributes.user_id )
						return

					attributes: [
						{ key: "_t", type: "number", required: true }
					,	{ key: "user_id", type: "string", required: true }
					,	{ key: "lastlogin", type: "number" }
					]


				"mt":
					name: "many"
					hashKey:  "id"
					hashKeyType: "S"

					rangeKey: "t"
					rangeKeyType: "N"

					fnCreateHash: ( attributes, cb )->
						cb( attributes.user )
						return

					attributes: [
						{ key: "user", type: "string", required: true }
						{ key: "title", type: "string" }
					]

				"Logs1":
					name: "test_log1"
					hashKey:  "id"
					hashKeyType: "S"

					rangeKey: "t"
					rangeKeyType: "N"

					fnCreateHash: ( attributes, cb )->
						cb( attributes.user )
						return

					attributes: [
						{ key: "user", type: "string", required: true }
						{ key: "title", type: "string" }
					]

				"Logs2":
					name: "test_log2"
					hashKey:  "id"
					hashKeyType: "S"

					rangeKey: "t"
					rangeKeyType: "N"

					fnCreateHash: ( attributes, cb )->
						cb( attributes.user )
						return

					attributes: [
						{ key: "user", type: "string", required: true }
						{ key: "title", type: "string" }
					]

				
				"C_Logs1":
					name: "test_log1"
					combineTableTo: "test_rangecombined"

					hashKey:  "id"
					hashKeyType: "S"

					rangeKey: "t"
					rangeKeyType: "N"

					fnCreateHash: ( attributes, cb )->
						cb( attributes.user )
						return

					attributes: [
						{ key: "user", type: "string", required: true }
						{ key: "title", type: "string" }
					]

				"C_Logs2":
					name: "test_log2"
					combineTableTo: "test_rangecombined"
					
					hashKey:  "id"
					hashKeyType: "S"

					rangeKey: "t"
					rangeKeyType: "N"

					fnCreateHash: ( attributes, cb )->
						cb( attributes.user )
						return

					attributes: [
						{ key: "user", type: "string", required: true }
						{ key: "title", type: "string" }
					]

				"c_mt":
					name: "cmt"
					hashKey:  "id"
					hashKeyType: "S"

					combineTableTo: "test_rangecombined"

					rangeKey: "t"
					rangeKeyType: "N"

					fnCreateHash: ( attributes, cb )->
						cb( "cmt" + attributes.user )
						return

					attributes: [
						{ key: "user", type: "string", required: true }
						{ key: "title", type: "string" }
					]


		
portOverwrite = {}
if _CONFIG_PORT
	portOverwrite =
		server:
			port: _CONFIG_PORT

module.exports = utils.extend( true, CONFIG[ "_BASIC" ], CONFIG[ _CONFIG_TYPE ] or {}, portOverwrite )
		