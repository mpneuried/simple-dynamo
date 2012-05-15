(function() {
  var SimpleDynamo, dynDB, dynDBDummy, should, _, _CONFIG, _ref, _ref2, _tables, _utils;
  _CONFIG = require("../config.js");
  _ = require("underscore");
  should = require('should');
  if (((_ref = process.env) != null ? _ref.AWS_AKI : void 0) != null) {
    _CONFIG.aws.accessKeyId = process.env.AWS_AKI;
  }
  if (((_ref2 = process.env) != null ? _ref2.AWS_SAK : void 0) != null) {
    _CONFIG.aws.secretAccessKey = process.env.AWS_SAK;
  }
  SimpleDynamo = require("../../lib/dynamo/");
  _utils = SimpleDynamo.utils;
  dynDB = null;
  dynDBDummy = null;
  _tables = [];
  describe("----- Manager Tests -----", function() {
    before(function(done) {
      return done();
    });
    describe('Initialization', function() {
      it('init manager', function(done) {
        dynDB = new SimpleDynamo(_CONFIG.aws, _CONFIG.tables);
        dynDBDummy = new SimpleDynamo(_CONFIG.aws, _CONFIG.dummyTables);
        done();
      });
      it('pre connect', function(done) {
        dynDB.fetched.should.be["false"];
        dynDB.connected.should.be["false"];
        done();
      });
      it('init table objects', function(done) {
        dynDB.connect(function(err) {
          if (err) {
            throw err;
          }
          done();
        });
      });
      it('init table objects for dummy', function(done) {
        dynDBDummy.connect(function(err) {
          if (err) {
            throw err;
          }
          done();
        });
      });
      it('post connect', function(done) {
        dynDB.fetched.should.be["true"];
        dynDB.connected.should.be["true"];
        done();
      });
    });
    describe('Basic Methods', function() {
      it("List the existing tables", function(done) {
        dynDB.list(function(err, tables) {
          var tbl, tbls, _i, _len, _ref3;
          if (err) {
            throw err;
          }
          tbls = [];
          _ref3 = Object.keys(_CONFIG.tables);
          for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
            tbl = _ref3[_i];
            tbls.push(tbl.toLowerCase());
          }
          tables.should.eql(tbls);
          return done();
        });
      });
      it("Get a table", function(done) {
        var _cnf, _ref3, _tbl;
        _cnf = _CONFIG.tables[_CONFIG.test.singleCreateTableTest];
        _tbl = dynDB.get(_CONFIG.test.singleCreateTableTest);
        _tbl.should.exist;
        if (_tbl != null) {
          if ((_ref3 = _tbl.name) != null) {
            _ref3.should.eql(_cnf.name);
          }
        }
        done();
      });
      it("Try to get a not existend table", function(done) {
        var _tbl;
        _tbl = dynDB.get("notexistend");
        should.not.exist(_tbl);
        done();
      });
      it("has for existend table", function(done) {
        var _has;
        _has = dynDB.has(_CONFIG.test.singleCreateTableTest);
        _has.should.be["true"];
        done();
      });
      it("has for not existend table", function(done) {
        var _has;
        _has = dynDB.has("notexistend");
        _has.should.be["false"];
        done();
      });
      it("Get check `existend` for real table", function(done) {
        var _tbl;
        _tbl = dynDB.get(_CONFIG.test.singleCreateTableTest);
        _tbl.should.exist;
        _tbl.existend.should.be["true"];
        done();
      });
      it("Get check `existend` for dummy table", function(done) {
        var _tbl;
        _tbl = dynDBDummy.get("Dummy");
        _tbl.should.exist;
        _tbl.existend.should.be["false"];
        done();
      });
      it("generate ( existend ) table", function(done) {
        var _has;
        _has = dynDB.generate(_CONFIG.test.singleCreateTableTest, function(err, created) {
          if (err) {
            throw err;
          }
          created.should.be["false"];
          return done();
        });
      });
    });
  });
}).call(this);