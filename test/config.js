(function() {
  module.exports = {
    aws: {
      accessKeyId: "-",
      secretAccessKey: "-",
      region: "eu-west-1"
    },
    test: {
      deleteTablesOnEnd: true,
      singleCreateTableTest: "Employees"
    },
    tables: {
      "Employees": {
        name: "test_employees",
        hashKey: "id",
        attributes: [
          {
            key: "name",
            type: "string",
            required: true
          }, {
            key: "email",
            type: "string"
          }, {
            key: "age",
            type: "number"
          }
        ]
      },
      "Todos": {
        name: "test_todos",
        hashKey: "id",
        attributes: [
          {
            key: "title",
            type: "string",
            required: true
          }, {
            key: "done",
            type: "number"
          }
        ]
      }
    },
    dummyTables: {
      "Dummy": {
        name: "dummy",
        hashKey: "id",
        attributes: [
          {
            key: "a",
            type: "string",
            required: true
          }, {
            key: "b",
            type: "string"
          }
        ]
      }
    }
  };
}).call(this);
