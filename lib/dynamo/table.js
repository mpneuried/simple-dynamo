(function() {
  var Attributes, DynamoTable, EventEmitter, attributesHelper, uuid, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __slice = Array.prototype.slice, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  uuid = require('node-uuid');
  _ = require("underscore");
  Attributes = require("./attributes");
  attributesHelper = Attributes.helper;
  EventEmitter = require("events").EventEmitter;
  module.exports = DynamoTable = (function() {
    __extends(DynamoTable, EventEmitter);
    function DynamoTable(table, options) {
      this.options = options;
      this.scan = __bind(this.scan, this);
      this._getThroughput = __bind(this._getThroughput, this);
      this._getShema = __bind(this._getShema, this);
      this._generate = __bind(this._generate, this);
      this._checkSetOptions = __bind(this._checkSetOptions, this);
      this._convertValue = __bind(this._convertValue, this);
      this._defaultRangeKey = __bind(this._defaultRangeKey, this);
      this._defaultHashKey = __bind(this._defaultHashKey, this);
      this._createRangeKey = __bind(this._createRangeKey, this);
      this._createHashKey = __bind(this._createHashKey, this);
      this._createId = __bind(this._createId, this);
      this._deFixHash = __bind(this._deFixHash, this);
      this._fixHash = __bind(this._fixHash, this);
      this._dynamoItem2JSONSingle = __bind(this._dynamoItem2JSONSingle, this);
      this._dynamoItem2JSON = __bind(this._dynamoItem2JSON, this);
      this._del = __bind(this._del, this);
      this._create = __bind(this._create, this);
      this._update = __bind(this._update, this);
      this._get = __bind(this._get, this);
      this._isExistend = __bind(this._isExistend, this);
      this.destroy = __bind(this.destroy, this);
      this.find = __bind(this.find, this);
      this.del = __bind(this.del, this);
      this.set = __bind(this.set, this);
      this.get = __bind(this.get, this);
      this.meta = __bind(this.meta, this);
      this.generate = __bind(this.generate, this);
      this.init = __bind(this.init, this);
      this.name = null;
      this.mng = this.options.manager;
      this.defaults = this.options.defaults;
      this.external = this.options.external;
      this.__defineGetter__("hashRangeDelimiter", __bind(function() {
        return "::";
      }, this));
      this.__defineGetter__("existend", __bind(function() {
        return this.external != null;
      }, this));
      this.__defineGetter__("hasRange", __bind(function() {
        var _ref, _ref2;
        if ((_ref = this._model_settings) != null ? (_ref2 = _ref.rangeKey) != null ? _ref2.length : void 0 : void 0) {
          return true;
        } else {
          return false;
        }
      }, this));
      this.__defineGetter__("hashKey", __bind(function() {
        var _ref;
        return ((_ref = this._model_settings) != null ? _ref.hashKey : void 0) || null;
      }, this));
      this.__defineGetter__("rangeKey", __bind(function() {
        var _ref;
        return ((_ref = this._model_settings) != null ? _ref.rangeKey : void 0) || null;
      }, this));
      this.__defineGetter__("overwriteDoubleHash", __bind(function() {
        var _ref;
        if (((_ref = this._model_settings) != null ? _ref.overwriteDoubleHash : void 0) != null) {
          return this._model_settings.overwriteDoubleHash;
        } else if (this.defaults.overwriteDoubleHash != null) {
          return this.defaults.overwriteDoubleHash;
        } else {
          return false;
        }
      }, this));
      this.init(table);
      return;
    }
    DynamoTable.prototype.init = function(table) {
      this._model_settings = table;
      this._attrs = new Attributes(table.attributes, this);
      this.name = table.name;
    };
    DynamoTable.prototype.generate = function(cb) {
      var err;
      err = {};
      if (!(this.external != null)) {
        this._generate(cb);
      } else {
        this.emit("create-status", "already-active");
        cb(null, false);
      }
    };
    DynamoTable.prototype.meta = function(cb) {
      if (this._meta != null) {
        cb(null, this._meta);
      } else if (this._isExistend(cb)) {
        this.external.fetch(__bind(function(err, _meta) {
          if (err) {
            cb(err);
          } else {
            this._meta = _meta;
            cb(null, _meta);
          }
        }, this));
      }
    };
    DynamoTable.prototype.get = function(_id, cb) {
      var query;
      if (this._isExistend(cb)) {
        query = this._deFixHash(_id);
        this._get(query, __bind(function(err, _item) {
          var _obj;
          if (err) {
            cb(err);
          } else {
            if (_item) {
              _obj = this._dynamoItem2JSON(_item, false);
              this.emit("get", _obj);
              cb(null, _obj);
            } else {
              this.emit("get-empty", _obj);
              cb(null, null);
            }
          }
        }, this));
      }
    };
    DynamoTable.prototype.set = function() {
      var args, attributes, cb, _create, _i, _id;
      args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), cb = arguments[_i++];
      if (this._isExistend(cb)) {
        switch (args.length) {
          case 1:
            _create = true;
            _id = null;
            attributes = args[0];
            break;
          case 2:
            _create = false;
            _id = args[0], attributes = args[1];
        }
        this._attrs.validateAttributes(attributes, __bind(function(err, attributes) {
          if (err) {
            return cb(err);
          } else {
            if (_create) {
              return this._create(attributes, __bind(function(err, _item) {
                var _obj;
                if (err) {
                  cb(err);
                } else {
                  _obj = this._dynamoItem2JSON(_item, true);
                  this.emit("create", _obj);
                  cb(null, _obj);
                }
              }, this));
            } else {
              return this._update(_id, attributes, __bind(function(err, _curr, _old, _deletedKeys) {
                var _k, _new, _obj, _oldRem, _v;
                if (err) {
                  cb(err);
                } else {
                  if (_old) {
                    _obj = this._dynamoItem2JSON(_curr, true);
                    _oldRem = {};
                    for (_k in _old) {
                      _v = _old[_k];
                      if (__indexOf.call(_deletedKeys, _k) < 0) {
                        _oldRem[_k] = _v;
                      }
                    }
                    _new = _.extend(_oldRem, _obj);
                    this.emit("update", _new, _old);
                    cb(null, _new);
                  } else {
                    this.emit("update", _curr, _curr);
                    cb(null, _curr);
                  }
                }
              }, this));
            }
          }
        }, this));
      }
    };
    DynamoTable.prototype.del = function(_id, cb) {
      var query;
      if (this._isExistend(cb)) {
        query = this._deFixHash(_id);
        this._del(query, __bind(function(err, success) {
          if (err) {
            cb(err);
          } else {
            this.emit("delete", _id);
            cb(null, success);
          }
        }, this));
      }
    };
    DynamoTable.prototype.find = function(query, cb) {
      var _query;
      if (query == null) {
        query = {};
      }
      if (arguments.length === 1 && _.isFunction(query)) {
        cb = query;
        query = {};
      }
      if (this._isExistend(cb)) {
        _query = this._attrs.getQuery(this.external, query);
        _query.fetch(__bind(function(err, _items) {
          if (err) {
            cb(err);
          } else {
            cb(null, this._dynamoItem2JSON(_items, false));
          }
        }, this));
      }
    };
    DynamoTable.prototype.destroy = function(cb) {
      if (this._isExistend(cb)) {
        return this.external.destroy(cb);
      }
    };
    DynamoTable.prototype._isExistend = function(cb) {
      if (this.existend) {
        return true;
      } else {
        cb({
          error: "table-not-created",
          msg: "Table '" + this.name + "' not existend at AWS. please run `Table.generate()` or `Manager.generateAll()` first."
        });
        return false;
      }
    };
    DynamoTable.prototype._get = function(query, cb) {
      var _item;
      _item = this.external.get(query);
      _item.fetch(__bind(function(err, item) {
        if (err) {
          cb(err);
        } else {
          cb(null, item);
        }
      }, this));
    };
    DynamoTable.prototype._update = function(id, attributes, cb) {
      this.get(id, __bind(function(err, current) {
        var item, _upd;
        if (err) {
          return cb(err);
        } else {
          item = this.external.get(this._deFixHash(id));
          _upd = item.update(this._attrs.updateAttrsFn(current, attributes));
          _upd.returning("UPDATED_NEW");
          if (_upd.AttributeUpdates != null) {
            _upd.save(__bind(function(err, _saved) {
              if (err) {
                cb(err);
              } else {
                cb(null, _saved.Attributes, current, _upd._todel);
              }
            }, this));
          } else {
            cb(null, current, null);
          }
        }
      }, this));
    };
    DynamoTable.prototype._create = function(attributes, cb) {
      if (attributes == null) {
        attributes = {};
      }
      this._createId(attributes, __bind(function(attributes) {
        var _upd;
        _upd = this.external.put(attributes);
        _upd = this._checkSetOptions(_upd, attributes);
        _upd.save(__bind(function(err) {
          if (err) {
            cb(err);
          } else {
            cb(null, _upd);
          }
        }, this));
      }, this));
    };
    DynamoTable.prototype._del = function(query, cb) {
      var _item;
      _item = this.external.get(query);
      _item.destroy(__bind(function(err, success) {
        if (err) {
          cb(err);
        } else {
          cb(null, success);
        }
      }, this));
      return;
    };
    DynamoTable.prototype._dynamoItem2JSON = function(items, convertAttrs) {
      var idx, item, _len;
      if (convertAttrs == null) {
        convertAttrs = false;
      }
      if (_.isArray(item)) {
        for (idx = 0, _len = items.length; idx < _len; idx++) {
          item = items[idx];
          items[idx] = this._dynamoItem2JSONSingle(item, convertAttrs);
        }
        return items;
      } else {
        return this._dynamoItem2JSONSingle(items, convertAttrs);
      }
    };
    DynamoTable.prototype._dynamoItem2JSONSingle = function(item, convertAttrs) {
      var _obj;
      if (convertAttrs == null) {
        convertAttrs = false;
      }
      if (convertAttrs) {
        _obj = attributesHelper.dyn2obj(item.Item || item);
      } else {
        _obj = item;
      }
      return this._fixHash(_obj);
    };
    DynamoTable.prototype._fixHash = function(attrs) {
      var _attrs, _hName, _rName;
      _attrs = _.clone(attrs);
      if (this.hasRange) {
        _hName = this._model_settings.hashKey;
        _rName = this._model_settings.rangeKey;
        if ((_attrs[_hName] != null) && _attrs[_rName]) {
          _attrs[_hName] = _attrs[_hName] + this.hashRangeDelimiter + _attrs[_rName];
        }
      }
      return _attrs;
    };
    DynamoTable.prototype._deFixHash = function(attrs) {
      var _attrs, _h, _hName, _hType, _r, _rName, _rType, _ref;
      if (_.isObject(attrs)) {
        _attrs = _.clone(attrs);
      } else {
        _hName = this._model_settings.hashKey;
        _attrs = {};
        _attrs[_hName] = attrs;
      }
      if (this.hasRange) {
        _hType = this._model_settings.hashKeyType || "S";
        _rName = this._model_settings.rangeKey;
        _rType = this._model_settings.rangeKeyType || "S";
        _ref = _attrs[_hName].split(this.hashRangeDelimiter), _h = _ref[0], _r = _ref[1];
        _attrs[_hName] = this._convertValue(_h, _hType);
        _attrs[_rName] = this._convertValue(_r, _rType);
      }
      return _attrs;
    };
    DynamoTable.prototype._createId = function(attributes, cb) {
      this._createHashKey(attributes, __bind(function(attributes) {
        if (this.hasRange) {
          this._createRangeKey(attributes, __bind(function(attributes) {
            cb(attributes);
          }, this));
        } else {
          cb(attributes);
        }
      }, this));
    };
    DynamoTable.prototype._createHashKey = function(attributes, cbH) {
      var _hName, _hType;
      _hName = this._model_settings.hashKey;
      _hType = this._model_settings.hashKeyType || "S";
      if (this._model_settings.fnCreateHash && _.isFunction(this._model_settings.fnCreateHash)) {
        this._model_settings.fnCreateHash(attributes, __bind(function(_hash) {
          attributes[_hName] = this._convertValue(_hash, _hType);
          cbH(attributes);
        }, this));
      } else if (attributes[_hName] != null) {
        attributes[_hName] = this._convertValue(attributes[_hName], _hType);
        cbH(attributes);
      } else {
        attributes[_hName] = this._convertValue(this._defaultHashKey(), _hType);
        cbH(attributes);
      }
    };
    DynamoTable.prototype._createRangeKey = function(attributes, cbR) {
      var _rName, _rType;
      _rName = this._model_settings.rangeKey;
      _rType = this._model_settings.rangeKeyType || "S";
      if (this._model_settings.fnCreateRange && _.isFunction(this._model_settings.fnCreateRange)) {
        this._model_settings.fnCreateRange(attributes, __bind(function(__range) {
          attributes[_rName] = this._convertValue(__range, _rType);
          cbR(attributes);
        }, this));
      } else if (attributes[_rName] != null) {
        attributes[_rName] = this._convertValue(attributes[_rName], _rType);
        cbR(attributes);
      } else {
        attributes[_rName] = this._convertValue(this._defaultRangeKey(), _rType);
        cbR(attributes);
      }
    };
    DynamoTable.prototype._defaultHashKey = function() {
      return uuid.v1();
    };
    DynamoTable.prototype._defaultRangeKey = function() {
      return Date.now();
    };
    DynamoTable.prototype._convertValue = function(val, type) {
      switch (type.toUpperCase()) {
        case "N":
          return parseFloat(val, 10);
        case "S":
          if (val) {
            return val.toString(val);
          }
          break;
        default:
          return val;
      }
    };
    DynamoTable.prototype._checkSetOptions = function(_upd, attributes) {
      var _pred;
      if (!this.overwriteDoubleHash) {
        _pred = {};
        _pred[this.hashKey] = {
          "==": []
        };
        _upd.when(_pred);
      }
      return _upd;
    };
    DynamoTable.prototype._generate = function(cb) {
      var _cr;
      _cr = this.mng.client.add({
        name: this._model_settings.name,
        throughput: this._getThroughput(),
        schema: this._getShema()
      });
      _cr.save(__bind(function(err, _table) {
        if (err) {
          cb(err);
        } else {
          this.emit("create-status", "waiting");
          _table.watch(__bind(function(err, _table) {
            if (err) {
              cb(err);
            } else {
              this.emit("create-status", "active");
              this.external = _table;
              cb(null, _table);
            }
          }, this));
        }
      }, this));
    };
    DynamoTable.prototype._getShema = function() {
      var oShema, _hName, _hType, _rName, _rType;
      oShema = {};
      _hName = this._model_settings.hashKey;
      _hType = this._model_settings.hashKeyType || "S";
      oShema[_hName] = _hType === "S" ? String : Number;
      if (this.hasRange) {
        _rName = this._model_settings.rangeKey;
        _rType = this._model_settings.rangeKeyType || "N";
        oShema[_rName] = _rType === "S" ? String : Number;
      }
      return oShema;
    };
    DynamoTable.prototype._getThroughput = function() {
      var oRet, _ref, _ref2, _ref3, _ref4;
      oRet = this.defaults.throughput;
      if (((_ref = this.options) != null ? (_ref2 = _ref.throughput) != null ? _ref2.read : void 0 : void 0) != null) {
        oRet.read = this.options.throughput.read;
      }
      if (((_ref3 = this.options) != null ? (_ref4 = _ref3.throughput) != null ? _ref4.write : void 0 : void 0) != null) {
        oRet.write = this.options.throughput.write;
      }
      return oRet;
    };
    DynamoTable.prototype.scan = function(_table, query, cb) {
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
    return DynamoTable;
  })();
}).call(this);
