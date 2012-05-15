(function() {
  module.exports = function(testTitle, _basicTable, _overwriteTable, _logTable1, _logTable2) {
    var SimpleDynamo, dynDB, should, table, _, _CONFIG, _DATA, _ref, _ref2, _utils;
    _CONFIG = require("../../config.js");
    _ = require("underscore");
    should = require('should');
    if (((_ref = process.env) != null ? _ref.AWS_AKI : void 0) != null) {
      _CONFIG.aws.accessKeyId = process.env.AWS_AKI;
    }
    if (((_ref2 = process.env) != null ? _ref2.AWS_SAK : void 0) != null) {
      _CONFIG.aws.secretAccessKey = process.env.AWS_SAK;
    }
    SimpleDynamo = require("../../../lib/dynamo/");
    _utils = SimpleDynamo.utils;
    _DATA = require("../../testdata.js");
    dynDB = null;
    table = null;
    return describe("----- " + testTitle + " TESTS -----", function() {
      before(function(done) {
        return done();
      });
      describe('Initialization', function() {
        it('init manager', function(done) {
          dynDB = new SimpleDynamo(_CONFIG.aws, _CONFIG.tables);
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
            table = dynDB.get(_basicTable);
            table.should.exist;
            done();
          });
        });
        it('post connect', function(done) {
          dynDB.fetched.should.be["true"];
          done();
        });
      });
      describe("" + testTitle + " CRUD Tests", function() {
        var _C, _D, _G, _ItemCount;
        _C = _CONFIG.tables[_basicTable];
        _D = _DATA[_basicTable];
        _G = {};
        _ItemCount = 0;
        it("list existing items", function(done) {
          table.find(function(err, items) {
            if (err) {
              throw err;
            }
            items.should.an["instanceof"](Array);
            _ItemCount = items.length;
            console.log(_ItemCount, "Items found");
            done();
          });
        });
        it("create an item", function(done) {
          table.set(_.clone(_D["insert1"]), function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.email.should.exist;
            item.age.should.exist;
            item.name.should.equal(_D["insert1"].name);
            item.email.should.equal(_D["insert1"].email);
            item.age.should.equal(_D["insert1"].age);
            _ItemCount++;
            _G["insert1"] = item;
            done();
          });
        });
        it("create a second item", function(done) {
          table.set(_.clone(_D["insert2"]), function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.email.should.exist;
            item.age.should.exist;
            item.additional.should.exist;
            item.name.should.equal(_D["insert2"].name);
            item.email.should.equal(_D["insert2"].email);
            item.age.should.equal(_D["insert2"].age);
            item.additional.should.equal(_D["insert2"].additional);
            _ItemCount++;
            _G["insert2"] = item;
            done();
          });
        });
        it("create a third item", function(done) {
          table.set(_.clone(_D["insert3"]), function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.email.should.exist;
            item.age.should.exist;
            item.name.should.equal(_D["insert3"].name);
            item.email.should.equal(_D["insert3"].email);
            item.age.should.equal(_D["insert3"].age);
            _ItemCount++;
            _G["insert3"] = item;
            done();
          });
        });
        it("list existing items after insert(s)", function(done) {
          table.find(function(err, items) {
            if (err) {
              throw err;
            }
            items.should.an["instanceof"](Array);
            items.length.should.equal(_ItemCount);
            done();
          });
        });
        it("delete the first inserted item", function(done) {
          table.del(_G["insert1"][_C.hashKey], function(err) {
            if (err) {
              throw err;
            }
            _ItemCount--;
            done();
          });
        });
        it("try to get deleted item", function(done) {
          table.get(_G["insert1"][_C.hashKey], function(err, item) {
            if (err) {
              throw err;
            }
            should.not.exist(item);
            done();
          });
        });
        it("update second item", function(done) {
          table.set(_G["insert2"][_C.hashKey], _D["update2"], function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.email.should.exist;
            item.age.should.exist;
            should.not.exist(item.additional);
            item.id.should.equal(_G["insert2"].id);
            item.name.should.equal(_D["update2"].name);
            item.email.should.equal(_G["insert2"].email);
            item.age.should.equal(_D["update2"].age);
            _G["insert2"] = item;
            done();
          });
        });
        it("delete the second inserted item", function(done) {
          table.del(_G["insert2"][_C.hashKey], function(err) {
            if (err) {
              throw err;
            }
            _ItemCount--;
            done();
          });
        });
        it("delete the third inserted item", function(done) {
          table.del(_G["insert3"][_C.hashKey], function(err) {
            if (err) {
              throw err;
            }
            _ItemCount--;
            done();
          });
        });
        it("check item count after update(s) and delete(s)", function(done) {
          table.find(function(err, items) {
            if (err) {
              throw err;
            }
            items.should.an["instanceof"](Array);
            items.length.should.equal(_ItemCount);
            done();
          });
        });
      });
      describe("" + testTitle + " Overwrite Tests", function() {
        var _C, _D, _G, _ItemCount;
        table = null;
        _C = _CONFIG.tables[_overwriteTable];
        _D = _DATA[_overwriteTable];
        _G = {};
        _ItemCount = 0;
        it("get table", function(done) {
          table = dynDB.get(_overwriteTable);
          should.exist(table);
          done();
        });
        it("create item", function(done) {
          table.set(_.clone(_D["insert1"]), function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.title.should.exist;
            item.done.should.exist;
            item.id.should.equal(_D["insert1"].id);
            item.title.should.equal(_D["insert1"].title);
            item.done.should.equal(_D["insert1"].done);
            _ItemCount++;
            _G["insert1"] = item;
            done();
          });
        });
        it("try second insert with the same hash", function(done) {
          table.set(_D["insert2"], function(err, item) {
            err.should.exist;
            err.name.should.equal("conditional-check-failed");
            should.not.exist(item);
            done();
          });
        });
        it("list items", function(done) {
          table.find(function(err, items) {
            if (err) {
              throw err;
            }
            console.log(items);
            items.should.an["instanceof"](Array);
            items.length.should.equal(_ItemCount);
            done();
          });
        });
        return it("delete the first inserted item", function(done) {
          table.del(_G["insert1"][_C.hashKey], function(err) {
            if (err) {
              throw err;
            }
            _ItemCount--;
            done();
          });
        });
      });
      describe("" + testTitle + " Range Tests", function() {
        var _D, _ItemCount;
        table = null;
        _D = _DATA[_logTable1];
        _ItemCount = 0;
        it("get table", function(done) {
          table = dynDB.get(_logTable1);
          should.exist(table);
          done();
        });
        return it("insert " + _D.inserts.length + " items to range list", function(done) {
          var aFns, insert, _i, _len, _ref3, _throtteldSet;
          aFns = [];
          _ref3 = _D.inserts;
          for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
            insert = _ref3[_i];
            _throtteldSet = _.throttle(table.set, 250);
            aFns.push(_.bind(function(insert, cba) {
              return _throtteldSet(_.clone(insert), function(err, item) {
                if (err) {
                  throw err;
                }
                item.id.should.equal(insert.user + "::" + insert.t);
                item.user.should.equal(insert.user);
                item.title.should.equal(insert.title);
                _ItemCount++;
                return cba(insert);
              });
            }, table, insert));
          }
          return _utils.runSeries(aFns, function(err) {
            return done();
          });
        });
      });
    });
  };
}).call(this);
