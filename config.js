(function() {
  var CONFIG, portOverwrite;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  CONFIG = {
    "_BASIC": {
      server: {
        port: 3000,
        host: null
      },
      aws: {
        accessKeyId: "-",
        secretAccessKey: "-"
      },
      dynamo: {
        region: "eu-west-1",
        tables: {
          "Users": {
            name: "users",
            combineTableTo: "combined",
            hashKey: "_id",
            overwriteExistingHash: false,
            attributes: [
              {
                key: "name",
                type: "string",
                required: true
              }, {
                key: "age",
                type: "number"
              }, {
                key: "lastlogin",
                type: "number"
              }
            ]
          },
          "Rooms": {
            name: "rooms",
            combineTableTo: "combined",
            hashKey: "_id",
            overwriteExistingHash: false,
            attributes: [
              {
                key: "name",
                type: "string",
                required: true
              }, {
                key: "age",
                type: "number"
              }, {
                key: "lastlogin",
                type: "number"
              }
            ]
          },
          "Messages": {
            name: "messages",
            hashKey: "_id",
            rangeKey: "_t",
            rangeKeyType: "N",
            fnCreateHash: __bind(function(attributes, cb) {
              cb(attributes.user_id);
            }, this),
            attributes: [
              {
                key: "_t",
                type: "number",
                required: true
              }, {
                key: "user_id",
                type: "string",
                required: true,
                key: "lastlogin",
                type: "number"
              }
            ]
          },
          "mt": {
            name: "many",
            hashKey: "id",
            hashKeyType: "S",
            rangeKey: "t",
            rangeKeyType: "N",
            fnCreateHash: __bind(function(attributes, cb) {
              cb(attributes.user);
            }, this),
            attributes: [
              {
                key: "user",
                type: "string",
                required: true
              }, {
                key: "title",
                type: "string"
              }
            ]
          },
          "Logs1": {
            name: "test_log1",
            hashKey: "id",
            hashKeyType: "S",
            rangeKey: "t",
            rangeKeyType: "N",
            fnCreateHash: __bind(function(attributes, cb) {
              cb(attributes.user);
            }, this),
            attributes: [
              {
                key: "user",
                type: "string",
                required: true
              }, {
                key: "title",
                type: "string"
              }
            ]
          },
          "Logs2": {
            name: "test_log2",
            hashKey: "id",
            hashKeyType: "S",
            rangeKey: "t",
            rangeKeyType: "N",
            fnCreateHash: __bind(function(attributes, cb) {
              cb(attributes.user);
            }, this),
            attributes: [
              {
                key: "user",
                type: "string",
                required: true
              }, {
                key: "title",
                type: "string"
              }
            ]
          },
          "C_Logs1": {
            name: "test_log1",
            combineTableTo: "test_rangecombined",
            hashKey: "id",
            hashKeyType: "S",
            rangeKey: "t",
            rangeKeyType: "N",
            fnCreateHash: __bind(function(attributes, cb) {
              cb(attributes.user);
            }, this),
            attributes: [
              {
                key: "user",
                type: "string",
                required: true
              }, {
                key: "title",
                type: "string"
              }
            ]
          },
          "C_Logs2": {
            name: "test_log2",
            combineTableTo: "test_rangecombined",
            hashKey: "id",
            hashKeyType: "S",
            rangeKey: "t",
            rangeKeyType: "N",
            fnCreateHash: __bind(function(attributes, cb) {
              cb(attributes.user);
            }, this),
            attributes: [
              {
                key: "user",
                type: "string",
                required: true
              }, {
                key: "title",
                type: "string"
              }
            ]
          },
          "c_mt": {
            name: "cmt",
            hashKey: "id",
            hashKeyType: "S",
            combineTableTo: "test_rangecombined",
            rangeKey: "t",
            rangeKeyType: "N",
            fnCreateHash: __bind(function(attributes, cb) {
              cb(attributes.user);
            }, this),
            attributes: [
              {
                key: "user",
                type: "string",
                required: true
              }, {
                key: "title",
                type: "string"
              }
            ]
          }
        }
      }
    }
  };
  portOverwrite = {};
  if (_CONFIG_PORT) {
    portOverwrite = {
      server: {
        port: _CONFIG_PORT
      }
    };
  }
  module.exports = utils.extend(true, CONFIG["_BASIC"], CONFIG[_CONFIG_TYPE] || {}, portOverwrite);
}).call(this);
