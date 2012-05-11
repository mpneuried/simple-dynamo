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
        read: 3,
        write: 5
      }
    };
    function DynamoManager(options, tableSettings) {
      this.options = options;
      this.tableSettings = tableSettings;
      this.generate = __bind(this.generate, this);
      this.generateAll = __bind(this.generateAll, this);
      this.has = __bind(this.has, this);
      this.get = __bind(this.get, this);
      this.list = __bind(this.list, this);
      this._initTables = __bind(this._initTables, this);
      this._fetchTables = __bind(this._fetchTables, this);
      this._createClient = __bind(this._createClient, this);
      this.connect = __bind(this.connect, this);
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
      var neededParams, _client;
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
        cb({
          error: "missing-option",
          msg: "Missing options vars. required options are: '" + (neededParams.join(', ')) + "'"
        });
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
      var table, tableName, _opt;
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
          _opt = _.extend({}, {
            manager: this,
            defaults: this.defaults,
            external: this.client.tables[table.name]
          });
          this._tables[tableName] = new Table(table, _opt);
          this.emit("new-table", this._tables[tableName]);
        }
        this._connected = true;
        cb(null);
      } else {
        cb({
          error: "no-tables-fetched",
          msg: "Currently not tables fetched. Please run `Manager.connect()` first."
        });
      }
    };
    DynamoManager.prototype.list = function(cb) {
      this._fetchTables(__bind(function(err) {
        if (err) {
          cb(err);
        } else {
          cb(null, Object.keys(this.client.tables));
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
    DynamoManager.prototype.generateAll = function(cb) {
      var aCreate, tableName;
      aCreate = [];
      for (tableName in this._tables) {
        aCreate.push(_.bind(function(tableName, cba) {
          this.generate(tableName, __bind(function(err, generated) {
            cba(err, generated);
          }, this));
        }, this, tableName));
      }
      utils.runParallel(aCreate, __bind(function(err, _generated) {
        if (utils.checkArray(err)) {
          cb(err);
        } else {
          this.emit("all-tables-generated");
          cb(null);
        }
      }, this));
    };
    DynamoManager.prototype.generate = function(tableName, cb) {
      var tbl;
      tbl = this.get(tableName);
      if (!tbl) {
        cb({
          error: "table-not-found",
          msg: "Table `" + tableName + "` not found."
        });
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
