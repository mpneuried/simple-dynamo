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
					hashKey:  "_id"

					attributes: [
						key: "name", type: "string"
						key: "age", type: "number"
						key: "lastlogin", type: "timestamp"
					]


		
portOverwrite = {}
if _CONFIG_PORT
	portOverwrite =
		server:
			port: _CONFIG_PORT

module.exports = utils.extend( true, CONFIG[ "_BASIC" ], CONFIG[ _CONFIG_TYPE ] or {}, portOverwrite )
		