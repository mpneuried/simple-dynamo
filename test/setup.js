(function() {
  var SimpleDynamo, dynDB, _CONFIG, _ref, _ref2;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  _CONFIG = require("./config.js");
  if (((_ref = process.env) != null ? _ref.AWS_AKI : void 0) != null) {
    _CONFIG.aws.accessKeyId = process.env.AWS_AKI;
  }
  if (((_ref2 = process.env) != null ? _ref2.AWS_SAK : void 0) != null) {
    _CONFIG.aws.secretAccessKey = process.env.AWS_SAK;
  }
  SimpleDynamo = require("../lib/dynamo/");
  dynDB = null;
  describe("----- SETUP -----", function() {
    before(function(done) {
      dynDB = new SimpleDynamo(_CONFIG.aws, _CONFIG.tables);
      return done();
    });
    describe("Initialization", function() {
      return it("init table objects", function(done) {
        return dynDB.connect(__bind(function(err) {
          if (err) {
            throw err;
          }
          return done();
        }, this));
      });
    });
    return describe("Create tables", function() {
      it("create a single table", function(done) {
        return dynDB.generate(_CONFIG.test.singleCreateTableTest, function(err) {
          if (err) {
            throw err;
          }
          return done();
        });
      });
      return it("create all missing tables", function(done) {
        return dynDB.generateAll(function(err) {
          if (err) {
            throw err;
          }
          return done();
        });
      });
    });
  });
}).call(this);
