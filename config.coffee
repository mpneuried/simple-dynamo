CONFIG = 
	"_BASIC":
		server:
			port: 8010
			host: null

		aws:
			accessKeyId: "-"
			secretAccessKey: "-"

		dynamo:
			region: "eu-west-1"

			tables: 
				"Users":
					name: "users"
					combineTableTo: "combined"

					hashKey:  "_id"

					overwriteDoubleHash: false
					# overwriteExisting

					attributes: [
						{ key: "name", type: "string", required: true }
						{ key: "age", type: "number" }
						{ key: "lastlogin", type: "number" }
					]

				"Rooms":
					name: "rooms"
					combineTableTo: "combined"

					hashKey:  "_id"

					overwriteDoubleHash: false

					attributes: [
						{ key: "name", type: "string", required: true }
						{ key: "age", type: "number" }
						{ key: "lastlogin", type: "number" }
					]

				"Messages":
					name: "messages"
					hashKey:  "_id"
					rangeKey:  "_t"
					rangeKeyType:  "N"

					fnCreateHash: ( attributes, cb )=>
						cb( attributes.user_id )
						return

					attributes: [
						key: "_t", type: "number", required: true
					,	key: "user_id", type: "string", required: true
					,	key: "lastlogin", type: "number"
					]


		
portOverwrite = {}
if _CONFIG_PORT
	portOverwrite =
		server:
			port: _CONFIG_PORT

module.exports = utils.extend( true, CONFIG[ "_BASIC" ], CONFIG[ _CONFIG_TYPE ] or {}, portOverwrite )
		