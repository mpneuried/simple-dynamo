// Generated by CoffeeScript 1.3.3
(function() {

  module.exports = function(testTitle, _basicTable, _overwriteTable, _logTable1, _logTable2, _setTable) {
    var SimpleDynamo, dynDB, should, tableG, _, _CONFIG, _DATA, _ref, _ref1, _utils;
    _CONFIG = require("../../config.js");
    _ = require("underscore");
    should = require('should');
    if (((_ref = process.env) != null ? _ref.AWS_ACCESS_KEY_ID : void 0) != null) {
      _CONFIG.aws.accessKeyId = process.env.AWS_ACCESS_KEY_ID;
    }
    if (((_ref1 = process.env) != null ? _ref1.AWS_SECRET_ACCESS_KEY : void 0) != null) {
      _CONFIG.aws.secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY;
    }
    SimpleDynamo = require("../../../lib/dynamo/");
    _utils = SimpleDynamo.utils;
    _DATA = require("../../testdata.js");
    dynDB = null;
    tableG = null;
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
            tableG = dynDB.get(_basicTable);
            tableG.should.exist;
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
          tableG.find(function(err, items) {
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
          tableG.set(_.clone(_D["insert1"]), function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.email.should.exist;
            item.age.should.exist;
            item.id.should.equal(_D["insert1"].id);
            item.name.should.equal(_D["insert1"].name);
            item.email.should.equal(_D["insert1"].email);
            item.age.should.equal(_D["insert1"].age);
            _ItemCount++;
            _G["insert1"] = item;
            done();
          });
        });
        it("try to get the item and check the content", function(done) {
          tableG.get(_G["insert1"][_C.hashKey], function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.email.should.exist;
            item.age.should.exist;
            item.id.should.equal(_D["insert1"].id);
            item.name.should.equal(_D["insert1"].name);
            item.email.should.equal(_D["insert1"].email);
            item.age.should.equal(_D["insert1"].age);
            done();
          });
        });
        it("create a second item", function(done) {
          tableG.set(_.clone(_D["insert2"]), function(err, item) {
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
          tableG.set(_.clone(_D["insert3"]), function(err, item) {
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
        if (_basicTable.slice(0, 2) === "C_") {
          it("insert a invalid item to combined table", function(done) {
            tableG.set(_.clone(_D["insert4"]), function(err, item) {
              err.should.exist;
              err.name.should.equal("combined-hash-invalid");
              should.not.exist(item);
              done();
            });
          });
        }
        it("list existing items after insert(s)", function(done) {
          tableG.find(function(err, items) {
            if (err) {
              throw err;
            }
            items.should.an["instanceof"](Array);
            items.length.should.equal(_ItemCount);
            done();
          });
        });
        it("try to get two items at once (mget)", function(done) {
          tableG.mget([_G["insert1"][_C.hashKey], _G["insert2"][_C.hashKey]], function(err, items) {
            var aPred, item, _i, _len;
            if (err) {
              throw err;
            }
            items.should.have.length(2);
            aPred = [_G["insert1"], _G["insert2"]];
            for (_i = 0, _len = items.length; _i < _len; _i++) {
              item = items[_i];
              aPred.should.includeEql(item);
            }
            done();
          });
        });
        it("try to get two items plus a unkown at once (mget)", function(done) {
          tableG.mget([_G["insert1"][_C.hashKey], _G["insert2"][_C.hashKey], "xxxxxx"], function(err, items) {
            var aPred, item, _i, _len;
            if (err) {
              throw err;
            }
            items.should.have.length(2);
            aPred = [_G["insert1"], _G["insert2"]];
            for (_i = 0, _len = items.length; _i < _len; _i++) {
              item = items[_i];
              aPred.should.includeEql(item);
            }
            done();
          });
        });
        it("delete the first inserted item", function(done) {
          tableG.del(_G["insert1"][_C.hashKey], function(err) {
            if (err) {
              throw err;
            }
            _ItemCount--;
            done();
          });
        });
        it("try to get deleted item", function(done) {
          tableG.get(_G["insert1"][_C.hashKey], function(err, item) {
            if (err) {
              throw err;
            }
            should.not.exist(item);
            done();
          });
        });
        it("update second item", function(done) {
          tableG.set(_G["insert2"][_C.hashKey], _D["update2"], {
            fields: ["id", "name", "age"]
          }, function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.age.should.exist;
            should.not.exist(item.email);
            should.not.exist(item.additional);
            item.id.should.equal(_G["insert2"].id);
            item.name.should.equal(_D["update2"].name);
            item.age.should.equal(_D["update2"].age);
            _G["insert2"] = item;
            done();
          });
        });
        it("update third item with successfull conditonal", function(done) {
          var _opt;
          _opt = {
            fields: ["id", "name", "age"],
            conditionals: {
              "age": {
                "==": 78
              }
            }
          };
          tableG.set(_G["insert3"][_C.hashKey], _D["update3"], _opt, function(err, item) {
            console.log("UPDATE THRId", err, item);
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.age.should.exist;
            should.not.exist(item.email);
            should.not.exist(item.additional);
            item.id.should.equal(_G["insert3"].id);
            item.name.should.equal(_D["update3"].name);
            item.age.should.equal(_D["update3"].age);
            _G["insert3"] = item;
            done();
          });
        });
        it("update third item with failing conditonal", function(done) {
          var _opt;
          _opt = {
            fields: ["id", "name", "age"],
            conditionals: {
              "age": {
                "==": 123
              }
            }
          };
          tableG.set(_G["insert3"][_C.hashKey], _D["update3"], _opt, function(err, item) {
            err.should.exist;
            err.name.should.equal("conditional-check-failed");
            done();
          });
        });
        it("delete the second inserted item", function(done) {
          tableG.del(_G["insert2"][_C.hashKey], function(err) {
            if (err) {
              throw err;
            }
            _ItemCount--;
            done();
          });
        });
        it("delete the third inserted item", function(done) {
          tableG.del(_G["insert3"][_C.hashKey], function(err) {
            if (err) {
              throw err;
            }
            _ItemCount--;
            done();
          });
        });
        it("check item count after update(s) and delete(s)", function(done) {
          tableG.find(function(err, items) {
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
        var table, _C, _D, _G, _ItemCount;
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
        var last, pre_last, table1, table2, _C1, _C2, _D1, _D2, _G1, _G2, _ItemCount1, _ItemCount2;
        table1 = null;
        table2 = null;
        _D1 = _DATA[_logTable1];
        _D2 = _DATA[_logTable2];
        _C1 = _CONFIG.tables[_logTable1];
        _C2 = _CONFIG.tables[_logTable2];
        _G1 = [];
        _G2 = [];
        _ItemCount1 = 0;
        _ItemCount2 = 0;
        last = null;
        pre_last = null;
        it("get table 1", function(done) {
          table1 = dynDB.get(_logTable1);
          should.exist(table1);
          done();
        });
        it("get table 2", function(done) {
          table2 = dynDB.get(_logTable2);
          should.exist(table2);
          done();
        });
        it("insert " + _D1.inserts.length + " items to range list of table 1", function(done) {
          var aFns, insert, _i, _len, _ref2, _throtteldSet;
          aFns = [];
          _ref2 = _D1.inserts;
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            insert = _ref2[_i];
            _throtteldSet = _.throttle(table1.set, 250);
            aFns.push(_.bind(function(insert, cba) {
              var tbl;
              tbl = this;
              return _throtteldSet(_.clone(insert), function(err, item) {
                if (err) {
                  throw err;
                }
                if (tbl.isCombinedTable) {
                  item.id.should.equal(tbl.name + tbl.combinedHashDelimiter + insert.user);
                } else {
                  item.id.should.equal(insert.user);
                }
                item.t.should.equal(insert.t);
                item.user.should.equal(insert.user);
                item.title.should.equal(insert.title);
                _ItemCount1++;
                _G1.push(item);
                return cba(item);
              });
            }, table1, insert));
          }
          return _utils.runSeries(aFns, function(err) {
            return done();
          });
        });
        it("insert " + _D2.inserts.length + " items to range list of table 2", function(done) {
          var aFns, insert, _i, _len, _ref2, _throtteldSet;
          aFns = [];
          _ref2 = _D2.inserts;
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            insert = _ref2[_i];
            _throtteldSet = _.throttle(table2.set, 250);
            aFns.push(_.bind(function(insert, cba) {
              var tbl;
              tbl = this;
              return _throtteldSet(_.clone(insert), function(err, item) {
                if (err) {
                  throw err;
                }
                if (tbl.isCombinedTable) {
                  item.id.should.equal(tbl.name + tbl.combinedHashDelimiter + insert.user);
                } else {
                  item.id.should.equal(insert.user);
                }
                item.t.should.equal(insert.t);
                item.user.should.equal(insert.user);
                item.title.should.equal(insert.title);
                _ItemCount2++;
                _G2.push(item);
                return cba(item);
              });
            }, table2, insert));
          }
          return _utils.runSeries(aFns, function(err) {
            return done();
          });
        });
        it("try to get two items at once (mget)", function(done) {
          table1.mget([[_G1[1][_C1.hashKey], _G1[1][_C1.rangeKey]], [_G1[5][_C1.hashKey], _G1[5][_C1.rangeKey]]], function(err, items) {
            var aPred, item, _i, _len;
            if (err) {
              throw err;
            }
            items.should.have.length(2);
            aPred = [_G1[1], _G1[5]];
            for (_i = 0, _len = items.length; _i < _len; _i++) {
              item = items[_i];
              aPred.should.includeEql(item);
            }
            done();
          });
        });
        it("try to get two items plus a unkown at once (mget)", function(done) {
          table2.mget([[_G2[1][_C2.hashKey], _G2[1][_C2.rangeKey]], [_G2[5][_C2.hashKey], _G2[5][_C2.rangeKey]], [_G2[3][_C2.hashKey], 999]], function(err, items) {
            var aPred, item, _i, _len;
            if (err) {
              throw err;
            }
            items.should.have.length(2);
            aPred = [_G2[1], _G2[5]];
            for (_i = 0, _len = items.length; _i < _len; _i++) {
              item = items[_i];
              aPred.should.includeEql(item);
            }
            done();
          });
        });
        it("get a range of table 1", function(done) {
          var _q;
          if (_logTable1.slice(0, 2) === "C_") {
            _q = {
              id: {
                "==": "" + _C1.name + "A"
              },
              t: {
                ">=": 5
              }
            };
          } else {
            _q = {
              id: {
                "==": "A"
              },
              t: {
                ">=": 5
              }
            };
          }
          return table1.find(_q, function(err, items) {
            if (err) {
              throw err;
            }
            items.length.should.equal(3);
            return done();
          });
        });
        it("get a range of table 2", function(done) {
          var _q;
          if (_logTable2.slice(0, 2) === "C_") {
            _q = {
              id: {
                "==": "" + _C2.name + "D"
              },
              t: {
                ">=": 3
              }
            };
          } else {
            _q = {
              id: {
                "==": "D"
              },
              t: {
                ">=": 3
              }
            };
          }
          return table2.find(_q, function(err, items) {
            if (err) {
              throw err;
            }
            items.length.should.equal(1);
            return done();
          });
        });
        it("get a single item of table 1", function(done) {
          var _item;
          _item = _G1[4];
          return table1.get([_item.id, _item.t], function(err, item) {
            if (err) {
              throw err;
            }
            item.should.eql(_item);
            return done();
          });
        });
        it("should return only 3 items", function(done) {
          var _count, _o, _q;
          _count = 3;
          if (_logTable2.slice(0, 2) === "C_") {
            _q = {
              id: {
                "==": "" + _C2.name + "A"
              },
              t: {
                ">=": 0
              }
            };
          } else {
            _q = {
              id: {
                "==": "A"
              },
              t: {
                ">=": 0
              }
            };
          }
          _o = {
            limit: _count
          };
          return table2.find(_q, _o, function(err, items) {
            if (err) {
              throw err;
            }
            should.exist(items);
            items.length.should.equal(_count);
            last = items[_count - 1];
            pre_last = items[_count - 2];
            return done();
          });
        });
        it("should return the next 3 by `startAt`", function(done) {
          var _c, _count, _o, _q;
          _count = 3;
          if (_logTable2.slice(0, 2) === "C_") {
            _q = {
              id: {
                "==": "" + _C2.name + "A"
              },
              t: {
                ">=": 0
              }
            };
          } else {
            _q = {
              id: {
                "==": "A"
              },
              t: {
                ">=": 0
              }
            };
          }
          _o = {
            limit: _count
          };
          _c = [pre_last.id, pre_last.t];
          return table2.find(_q, _c, _o, function(err, items) {
            var predicted_first;
            if (err) {
              throw err;
            }
            predicted_first = items[0];
            predicted_first.should.eql(last);
            items.length.should.equal(_count);
            last = items[_count - 1];
            pre_last = items[_count - 2];
            return done();
          });
        });
        it("delete whole data from table 1", function(done) {
          var aFns, item, _i, _len, _throtteldDel;
          aFns = [];
          for (_i = 0, _len = _G1.length; _i < _len; _i++) {
            item = _G1[_i];
            _throtteldDel = _.throttle(table1.del, 250);
            aFns.push(_.bind(function(item, cba) {
              return _throtteldDel([item.id, item.t], function(err) {
                if (err) {
                  throw err;
                }
                _ItemCount1--;
                return cba();
              });
            }, table1, item));
          }
          return _utils.runSeries(aFns, function(err) {
            return done();
          });
        });
        it("delete whole data from table 2", function(done) {
          var aFns, item, _i, _len, _throtteldDel;
          aFns = [];
          for (_i = 0, _len = _G2.length; _i < _len; _i++) {
            item = _G2[_i];
            _throtteldDel = _.throttle(table2.del, 250);
            aFns.push(_.bind(function(item, cba) {
              return _throtteldDel([item.id, item.t], function(err) {
                if (err) {
                  throw err;
                }
                _ItemCount2--;
                return cba();
              });
            }, table2, item));
          }
          return _utils.runSeries(aFns, function(err) {
            return done();
          });
        });
        it("check for empty table 1", function(done) {
          var _q;
          _q = {};
          return table1.find(_q, function(err, items) {
            if (err) {
              throw err;
            }
            items.length.should.equal(_ItemCount1);
            return done();
          });
        });
        return it("check for empty table 2", function(done) {
          var _q;
          _q = {};
          return table2.find(_q, function(err, items) {
            if (err) {
              throw err;
            }
            items.length.should.equal(_ItemCount2);
            return done();
          });
        });
      });
      describe("" + testTitle + " Set Tests", function() {
        var table, _C, _D, _G, _ItemCount;
        _C = _CONFIG.tables[_setTable];
        _D = _DATA[_setTable];
        _G = {};
        _ItemCount = 0;
        table = null;
        it("get table", function(done) {
          table = dynDB.get(_setTable);
          should.exist(table);
          done();
        });
        it("create the test item", function(done) {
          table.set(_.clone(_D["insert1"]), function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.users.should.exist;
            item.name.should.equal(_D["insert1"].name);
            item.users.should.eql(["a"]);
            _ItemCount++;
            _G["insert1"] = item;
            done();
          });
        });
        it("test raw reset", function(done) {
          table.set(_G["insert1"].id, _.clone(_D["update1"]), function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.users.should.exist;
            item.name.should.equal(_D["insert1"].name);
            item.users.should.eql(["a", "b"]);
            _G["insert1"] = item;
            done();
          });
        });
        it("test $add action", function(done) {
          table.set(_G["insert1"].id, _.clone(_D["update2"]), function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.users.should.exist;
            item.name.should.equal(_D["insert1"].name);
            item.users.should.eql(["a", "b", "c"]);
            _G["insert1"] = item;
            done();
          });
        });
        it("test $rem action", function(done) {
          table.set(_G["insert1"].id, _.clone(_D["update3"]), function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.users.should.exist;
            item.name.should.equal(_D["insert1"].name);
            item.users.should.eql(["b", "c"]);
            _G["insert1"] = item;
            done();
          });
        });
        it("test $reset action", function(done) {
          table.set(_G["insert1"].id, _.clone(_D["update4"]), function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.users.should.exist;
            item.name.should.equal(_D["insert1"].name);
            item.users.should.eql(["x", "y"]);
            _G["insert1"] = item;
            done();
          });
        });
        it("test $add action with string", function(done) {
          table.set(_G["insert1"].id, _.clone(_D["update5"]), function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.users.should.exist;
            item.name.should.equal(_D["insert1"].name);
            item.users.should.eql(["x", "y", "z"]);
            _G["insert1"] = item;
            done();
          });
        });
        it("test $rem action with string", function(done) {
          table.set(_G["insert1"].id, _.clone(_D["update6"]), function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.users.should.exist;
            item.name.should.equal(_D["insert1"].name);
            item.users.should.eql(["y", "z"]);
            _G["insert1"] = item;
            done();
          });
        });
        it("test $reset action with string", function(done) {
          table.set(_G["insert1"].id, _.clone(_D["update7"]), function(err, item) {
            if (err) {
              throw err;
            }
            item.id.should.exist;
            item.name.should.exist;
            item.users.should.exist;
            item.name.should.equal(_D["insert1"].name);
            item.users.should.eql(["y"]);
            _G["insert1"] = item;
            done();
          });
        });
        return it("delete test item", function(done) {
          table.del(_G["insert1"].id, function(err) {
            if (err) {
              throw err;
            }
            _ItemCount--;
            done();
          });
        });
      });
    });
  };

}).call(this);
