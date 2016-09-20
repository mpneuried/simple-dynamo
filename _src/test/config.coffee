_CONFIG.aws.accessKeyId = process.env.AWS_AKI if process.env?.AWS_AKI?
_CONFIG.aws.secretAccessKey = process.env.AWS_SAK if process.env?.AWS_SAK?
_CONFIG.aws.region = process.env.AWS_REGION if process.env?.AWS_REGION?
_CONFIG.aws.tablePrefix = process.env.AWS_TABLEPREFIX if process.env?.AWS_TABLEPREFIX?


module.exports  =
	aws:
		accessKeyId: process.env.AWS_AKI or "-"
		secretAccessKey: process.env.AWS_SAK or "-"
		region: "eu-west-1"
		scanWarning: false

	test:
		deleteTablesOnEnd: true
		singleCreateTableTest: "Employees"

	tables:
		"Employees":
			name: "test_employees"
			hashKey:  "id"

			attributes: [
				{ key: "name", type: "string", required: true }
				{ key: "email", type: "string" }
				{ key: "age", type: "number" }
				{ key: "additional", type: "string" }
			]

		"Rooms":
			name: "test_rooms"
			hashKey:  "id"
			hashKeyType: "S"

			attributes: [
				{ key: "name", type: "string" }
				{ key: "users", type: "array" }
			]

		"Todos":
			name: "test_todos"
			hashKey:  "id"
			hashKeyType: "S"

			overwriteExistingHash: false

			defaultfields: [ "title", "id" ]

			attributes: [
				{ key: "title", type: "string" }
				{ key: "done", type: "number" }
			]

		"Logs1":
			name: "test_log1"
			hashKey:  "id"
			hashKeyType: "S"

			rangeKey: "t"
			rangeKeyType: "N"

			overwriteExistingHash: true

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

			overwriteExistingHash: true

			fnCreateHash: ( attributes, cb )->
				cb( attributes.user )
				return

			attributes: [
				{ key: "user", type: "string", required: true }
				{ key: "title", type: "string" }
			]

		"C_Employees":
			name: "emp"
			combineTableTo: "test_combined"

			hashKey:  "id"

			attributes: [
				{ key: "name", type: "string", required: true }
				{ key: "email", type: "string" }
				{ key: "age", type: "number" }
				{ key: "additional", type: "string" }
			]

		"C_Rooms":
			name: "roo"
			combineTableTo: "test_combined"

			hashKey:  "id"

			attributes: [
				{ key: "name", type: "string" }
				{ key: "users", type: "array" }
			]

		"C_Todos":
			name: "tds"
			combineTableTo: "test_combined"

			hashKey:  "id"
			hashKeyType: "S"

			overwriteExistingHash: false

			defaultfields: [ "title", "id" ]

			attributes: [
				{ key: "title", type: "string", required: true }
				{ key: "done", type: "number" }
			]

		"C_Logs1":
			name: "lg1"
			combineTableTo: "test_rangecombined"

			hashKey:  "id"
			hashKeyType: "S"

			rangeKey: "t"
			rangeKeyType: "N"

			fnCreateHash: ( attributes, cb )->
				cb( "lg1" + attributes.user )
				return

			attributes: [
				{ key: "user", type: "string", required: true }
				{ key: "title", type: "string" }
			]

		"C_Logs2":
			name: "lg2"
			combineTableTo: "test_rangecombined"
			
			hashKey:  "id"
			hashKeyType: "S"

			rangeKey: "t"
			rangeKeyType: "N"

			fnCreateHash: ( attributes, cb )->
				cb( "lg2" + attributes.user )
				return

			attributes: [
				{ key: "user", type: "string", required: true }
				{ key: "title", type: "string" }
			]


	dummyTables:
		"Dummy":
			name: "dummy"
			hashKey:  "id"

			attributes: [
				{ key: "a", type: "string", required: true }
				{ key: "b", type: "string" }
			]
