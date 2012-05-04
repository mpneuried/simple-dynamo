(function() {
  var DynamoConnector, dynamo, uuid;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  dynamo = require("dynamo");
  uuid = require('node-uuid');
  module.exports = DynamoConnector = (function() {
    function DynamoConnector(aws, region) {
      this._idQuery = __bind(this._idQuery, this);
      this.del = __bind(this.del, this);
      this.get = __bind(this.get, this);
      this.put = __bind(this.put, this);
      this.scan = __bind(this.scan, this);
      this.meta = __bind(this.meta, this);
      this.listTables = __bind(this.listTables, this);
      this.fetchTable = __bind(this.fetchTable, this);      this.client = dynamo.createClient(aws);
      this.db = this.client.get(region);
      return;
    }
    DynamoConnector.prototype.fetchTable = function(table, cb) {
      if (Object.keys(this.db.tables).length) {
        cb(null, this.db.get(table));
      } else {
        this.db.fetch(__bind(function(err) {
          if (err) {
            cb(err);
          } else {
            if (table === null) {
              cb(null, true);
            } else if (this.db.tables[table]) {
              cb(null, this.db.get(table));
            } else {
              cb({
                error: "table not found"
              });
            }
          }
        }, this));
      }
    };
    DynamoConnector.prototype.listTables = function(cb) {
      this.fetchTable(null, __bind(function(err, success) {
        if (err) {
          cb(err);
        } else {
          cb(null, Object.keys(this.db.tables));
        }
      }, this));
    };
    DynamoConnector.prototype.meta = function(_table, cb) {
      this.fetchTable(_table, __bind(function(err, table) {
        table.fetch(__bind(function(err, meta) {
          if (err) {
            cb(err);
          } else {
            cb(null, meta);
          }
        }, this));
      }, this));
    };
    DynamoConnector.prototype.scan = function(_table, query, cb) {
      this.fetchTable(_table, __bind(function(err, table) {
        var scan;
        scan = table.scan(query);
        scan.fetch(__bind(function(err, data) {
          if (err) {
            cb(err);
          } else {
            cb(null, data);
          }
        }, this));
      }, this));
    };
    DynamoConnector.prototype.put = function(_table, data, cb) {
      if (data == null) {
        data = {};
      }
      this.fetchTable(_table, __bind(function(err, table) {
        var item;
        if (!(data._id != null)) {
          data._id = uuid.v1();
        }
        if (!(data._t != null)) {
          data._t = Date.now();
        }
        item = table.put(data);
        item.save(__bind(function(err) {
          if (err) {
            cb(err);
          } else {
            cb(null, item);
          }
        }, this));
      }, this));
    };
    DynamoConnector.prototype.get = function(_table, _id, cb) {
      this.fetchTable(_table, __bind(function(err, table) {
        var item;
        item = table.get(this._idQuery(_id));
        item.fetch(__bind(function(err, data) {
          if (err) {
            cb(err);
          } else {
            cb(null, data);
          }
        }, this));
      }, this));
    };
    DynamoConnector.prototype.del = function(_table, _id, cb) {
      this.fetchTable(_table, __bind(function(err, table) {
        var item;
        item = table.get(this._idQuery(_id));
        item.destroy(__bind(function(err, success) {
          if (err) {
            cb(err);
          } else {
            cb(null, success);
          }
        }, this));
      }, this));
    };
    DynamoConnector.prototype._idQuery = function(_id, idKey, rageKey) {
      var _aId, _q;
      if (idKey == null) {
        idKey = "_id";
      }
      if (rageKey == null) {
        rageKey = "_t";
      }
      _q = {};
      if (__indexOf.call(_id, ":") >= 0) {
        _aId = _id.split(":");
        if (_aId.length === 2) {
          _q[idKey] = _aId[0];
          _q[rageKey] = parseInt(_aId[1], 10);
        } else {
          cb({
            error: "Wrong id format. Please use '[hash-key:range-key]'"
          });
          return;
        }
      } else {
        _q[idKey] = _id;
      }
      return _q;
    };
    return DynamoConnector;
  })();
}).call(this);
