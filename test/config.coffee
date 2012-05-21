module.exports  =
	aws:
		accessKeyId: "-"
		secretAccessKey: "-"
		region: "eu-west-1"
		scanWarning: false

	test:
		deleteTablesOnEnd: false
		singleCreateTableTest: "Employees"

	tables: 
		"Employees":
			name: "test_employees"
			hashKey:  "id"

			attributes: [
				{ key: "name", type: "string", required: true }
				{ key: "email", type: "string" }
				{ key: "age", type: "number" }
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

			fnCreateHash: ( attributes, cb )=>
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

			fnCreateHash: ( attributes, cb )=>
				cb( attributes.user )
				return

			attributes: [
				{ key: "user", type: "string", required: true }
				{ key: "title", type: "string" }
			]

		"C_Employees":
			name: "employees"
			combineTableTo: "test_combined"

			hashKey:  "id"

			attributes: [
				{ key: "name", type: "string", required: true }
				{ key: "email", type: "string" }
				{ key: "age", type: "number" }
			]

		"C_Rooms":
			name: "test_rooms"
			combineTableTo: "test_combined"

			hashKey:  "id"

			attributes: [
				{ key: "name", type: "string" }
				{ key: "users", type: "array" }
			]

		"C_Todos":
			name: "todos"
			combineTableTo: "test_combined"

			hashKey:  "id"
			hashKeyType: "S"

			overwriteExistingHash: false

			attributes: [
				{ key: "title", type: "string", required: true }
				{ key: "done", type: "number" }
			]

		"C_Logs1":
			name: "test_log1"
			combineTableTo: "test_rangecombined"

			hashKey:  "id"
			hashKeyType: "S"

			rangeKey: "t"
			rangeKeyType: "N"

			fnCreateHash: ( attributes, cb )=>
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

			fnCreateHash: ( attributes, cb )=>
				cb( attributes.user )
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