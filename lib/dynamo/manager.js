(function() {
  var DynamoManager, EventEmitter, Table, dynamo, utils, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  dynamo = require("dynamo");
  EventEmitter = require("events").EventEmitter;
  Table = require("./table");
  utils = require("./utils");
  _ = require("underscore");
  module.exports = DynamoManager = (function() {
    __extends(DynamoManager, EventEmitter);
    DynamoManager.prototype._connected = false;
    DynamoManager.prototype._fetched = false;
    DynamoManager.prototype.defaults = {
      throughput: {
        read: 10,
        write: 5
      },
      overwriteExistingHash: true
    };
    function DynamoManager(options, tableSettings) {
      var _base;
      this.options = options;
      this.tableSettings = tableSettings;
      this.generate = __bind(this.generate, this);
      this.generateAll = __bind(this.generateAll, this);
      this._getTablesToGenerate = __bind(this._getTablesToGenerate, this);
      this.has = __bind(this.has, this);
      this.get = __bind(this.get, this);
      this.list = __bind(this.list, this);
      this._initTables = __bind(this._initTables, this);
      this._fetchTables = __bind(this._fetchTables, this);
      this._createClient = __bind(this._createClient, this);
      this.connect = __bind(this.connect, this);
      (_base = this.options).scanWarning || (_base.scanWarning = true);
      this._tables = {};
      this.__defineGetter__("fetched", __bind(function() {
        return this._fetched;
      }, this));
      this.__defineGetter__("connected", __bind(function() {
        return this._connected;
      }, this));
      return;
    }
    DynamoManager.prototype.connect = function(cb) {
      this._createClient(__bind(function(err) {
        if (err) {
          cb(err);
        } else {
          this._fetchTables(__bind(function(err) {
            if (err) {
              cb(err);
            } else {
              this._initTables(void 0, cb);
            }
          }, this));
        }
      }, this));
    };
    DynamoManager.prototype._createClient = function(cb) {
      var error, neededParams, _client;
      this.client || (this.client = null);
      neededParams = ["accessKeyId", "secretAccessKey", "region"];
      if (utils.params(this.options, neededParams)) {
        _client = dynamo.createClient({
          accessKeyId: this.options.accessKeyId,
          secretAccessKey: this.options.secretAccessKey
        });
        this.client = _client.get(this.options.region);
        cb(null);
      } else {
        error = new Error;
        error.name = "missing-option";
        error.message = "Missing options vars. required options are: '" + (neededParams.join(', ')) + "'";
      }
    };
    DynamoManager.prototype._fetchTables = function(cb) {
      this.client.fetch(__bind(function(err) {
        if (err) {
          cb(err);
        } else {
          this._fetched = true;
          cb(null, true);
        }
      }, this));
    };
    DynamoManager.prototype._initTables = function(tables, cb) {
      var error, table, tableName, _ext, _opt, _ref;
      if (tables == null) {
        tables = this.tableSettings;
      }
      if (this.fetched) {
        for (tableName in tables) {
          table = tables[tableName];
          tableName = tableName.toLowerCase();
          if (this._tables[tableName] != null) {
            delete this._tables[tableName];
          }
          _ext = ((_ref = table.combineTableTo) != null ? _ref.length : void 0) ? this.client.tables[table.combineTableTo] : this.client.tables[table.name];
          _opt = _.extend({}, {
            manager: this,
            defaults: this.defaults,
            external: _ext
          });
          this._tables[tableName] = new Table(table, _opt);
          this.emit("new-table", this._tables[tableName]);
        }
        this._connected = true;
        cb(null);
      } else {
        error = new Error;
        error.name = "no-tables-fetched";
        error.message = "Currently not tables fetched. Please run `Manager.connect()` first.";
        cb(error);
      }
    };
    DynamoManager.prototype.list = function(cb) {
      this._fetchTables(__bind(function(err) {
        if (err) {
          cb(err);
        } else {
          cb(null, Object.keys(this._tables));
        }
      }, this));
    };
    DynamoManager.prototype.get = function(tableName) {
      tableName = tableName.toLowerCase();
      if (this.has(tableName)) {
        return this._tables[tableName];
      } else {
        return null;
      }
    };
    DynamoManager.prototype.has = function(tableName) {
      tableName = tableName.toLowerCase();
      return this._tables[tableName] != null;
    };
    DynamoManager.prototype._getTablesToGenerate = function() {
      var tbl, _n, _ref, _ret;
      _ret = {};
      _ref = this._tables;
      for (_n in _ref) {
        tbl = _ref[_n];
        if (!(_ret[tbl.tableName] != null)) {
          _ret[tbl.tableName] = {
            name: _n,
            tableName: tbl.tableName
          };
        }
      }
      return _ret;
    };
    DynamoManager.prototype.generateAll = function(cb) {
      var aCreate, table, _n, _ref;
      aCreate = [];
      _ref = this._getTablesToGenerate();
      for (_n in _ref) {
        table = _ref[_n];
        aCreate.push(_.bind(function(tableName, cba) {
          this.generate(tableName, __bind(function(err, generated) {
            cba(err, generated);
          }, this));
        }, this, table.name));
      }
      utils.runSeries(aCreate, __bind(function(err, _generated) {
        if (utils.checkArray(err)) {
          cb(err);
        } else {
          this.emit("all-tables-generated");
          cb(null);
        }
      }, this));
    };
    DynamoManager.prototype.generate = function(tableName, cb) {
      var error, tbl;
      tbl = this.get(tableName);
      if (!tbl) {
        error = new Error;
        error.name = "table-not-found";
        error.message = "Table `" + tableName + "` not found.";
        cb(error);
      } else {
        tbl.generate(__bind(function(err, generated) {
          if (err) {
            cb(err);
            return;
          }
          this.emit("table-generated", generated);
          cb(null, generated);
        }, this));
        return;
      }
    };
    return DynamoManager;
  })();
}).call(this);
