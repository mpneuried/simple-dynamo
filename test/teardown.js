(function() {
  var SimpleDynamo, dynDB, _, _CONFIG, _ref, _ref2, _tables, _utils;
  _CONFIG = require("./config.js");
  _ = require("underscore");
  if (((_ref = process.env) != null ? _ref.AWS_AKI : void 0) != null) {
    _CONFIG.aws.accessKeyId = process.env.AWS_AKI;
  }
  if (((_ref2 = process.env) != null ? _ref2.AWS_SAK : void 0) != null) {
    _CONFIG.aws.secretAccessKey = process.env.AWS_SAK;
  }
  SimpleDynamo = require("../lib/dynamo/");
  dynDB = null;
  _tables = [];
  _utils = SimpleDynamo.utils;
  describe("----- TEARDOWN -----", function() {
    before(function(done) {
      dynDB = new SimpleDynamo(_CONFIG.aws, _CONFIG.tables);
      dynDB.connect(function(err) {
        if (err) {
          throw err;
        }
        dynDB.list(function(err, tables) {
          if (err) {
            throw err;
          }
          _tables = tables;
          return done();
        });
      });
    });
    return it("DESTROY test tables", function(done) {
      var aFn, tableName, _i, _len, _tbl;
      if (!_CONFIG.test.deleteTablesOnEnd) {
        done();
        console.log("DESTROY deactivated");
        return;
      }
      aFn = [];
      for (_i = 0, _len = _tables.length; _i < _len; _i++) {
        tableName = _tables[_i];
        _tbl = dynDB.get(tableName);
        if (_tbl) {
          aFn.push(_.bind(function(cba) {
            return this.destroy(function(err) {
              console.log("" + tableName + " deleted");
              if (err) {
                throw err;
              }
              _.delay(cba, 2000, err);
            });
          }, _tbl));
        }
      }
      _utils.runSeries(aFn, function(err) {
        if (_utils.checkArray(err)) {
          throw _.first(err);
        }
        done();
      });
    });
  });
}).call(this);
