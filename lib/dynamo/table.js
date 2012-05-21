(function() {
  var Attributes, DynamoTable, ERRORMAPPING, EventEmitter, attributesHelper, uuid, _;
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
      this._error = __bind(this._error, this);
      this.destroy = __bind(this.destroy, this);
      this.find = __bind(this.find, this);
      this.del = __bind(this.del, this);
      this.set = __bind(this.set, this);
      this.get = __bind(this.get, this);
      this.meta = __bind(this.meta, this);
      this.generate = __bind(this.generate, this);
      this.init = __bind(this.init, this);
      this.mng = this.options.manager;
      this.defaults = this.options.defaults;
      this.external = this.options.external;
      this.__defineGetter__("name", __bind(function() {
        return this._model_settings.name;
      }, this));
      this.__defineGetter__("tableName", __bind(function() {
        return this._model_settings.combineTableTo || this._model_settings.name || null;
      }, this));
      this.__defineGetter__("isCombinedTable", __bind(function() {
        return this._model_settings.combineTableTo != null;
      }, this));
      this.__defineGetter__("combinedHashDelimiter", __bind(function() {
        return "";
      }, this));
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
      this.__defineGetter__("hashKeyType", __bind(function() {
        var _ref;
        if (this.isCombinedTable) {
          return "S";
        } else {
          return ((_ref = this._model_settings) != null ? _ref.hashKeyType : void 0) || "S";
        }
      }, this));
      this.__defineGetter__("rangeKey", __bind(function() {
        var _ref;
        return ((_ref = this._model_settings) != null ? _ref.rangeKey : void 0) || null;
      }, this));
      this.__defineGetter__("rangeKeyType", __bind(function() {
        var _ref;
        if (this.hasRange) {
          return ((_ref = this._model_settings) != null ? _ref.rangeKeyType : void 0) || "N";
        } else {
          return null;
        }
      }, this));
      this.__defineGetter__("overwriteExistingHash", __bind(function() {
        var _ref;
        if (((_ref = this._model_settings) != null ? _ref.overwriteExistingHash : void 0) != null) {
          return this._model_settings.overwriteExistingHash;
        } else if (this.defaults.overwriteExistingHash != null) {
          return this.defaults.overwriteExistingHash;
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
      if (this.isCombinedTable) {
        this._regexRemCT = new RegExp("^" + this.name, "i");
      }
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
            this._error(cb, err);
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
            this._error(cb, err);
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
            return this._error(cb, err);
          } else {
            if (_create) {
              return this._create(attributes, __bind(function(err, _item) {
                var _obj;
                if (err) {
                  this._error(cb, err);
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
                  this._error(cb, err);
                } else {
                  if (_old) {
                    _old[this.hashKey] = _old[this.hashKey].replace(this._regexRemCT, "");
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
                    _curr[this.hashKey] = _curr[this.hashKey].replace(this._regexRemCT, "");
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
            this._error(cb, err);
          } else {
            this.emit("delete", _id);
            cb(null, success);
          }
        }, this));
      }
    };
    DynamoTable.prototype.find = function() {
      var args, cb, cursor, query, _i, _op, _query, _val;
      args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), cb = arguments[_i++];
      if (this._isExistend(cb)) {
        switch (args.length) {
          case 1:
            cursor = null;
            query = args[0];
            break;
          case 2:
            query = args[0], cursor = args[1];
        }
        if (cursor != null) {
          cursor = this._deFixHash(cursor);
        }
        if (this.isCombinedTable) {
          if (query[this.hashKey]) {
            _op = _.first(Object.keys(query[this.hashKey]));
            _val = query[this.hashKey][_op];
            switch (_op) {
              case "==":
                _val = this.name + this.combinedHashDelimiter + _val;
            }
            query[this.hashKey][_op] = _val;
          } else {
            query[this.hashKey] = {
              "startsWith": this.name
            };
          }
        }
        if (this._isExistend(cb)) {
          _query = this._attrs.getQuery(this.external, query, cursor);
          _query.fetch(__bind(function(err, _items) {
            if (err) {
              this._error(cb, err);
            } else {
              cb(null, this._dynamoItem2JSON(_items, false));
            }
          }, this));
        }
      }
    };
    DynamoTable.prototype.destroy = function(cb) {
      if (this._isExistend(cb)) {
        return this.external.destroy(cb);
      }
    };
    DynamoTable.prototype._error = function(cb, err) {
      if (ERRORMAPPING[err.name] != null) {
        cb(ERRORMAPPING[err.name]);
      } else {
        cb(err);
      }
    };
    DynamoTable.prototype._isExistend = function(cb) {
      var error;
      if (this.existend) {
        return true;
      } else {
        if (_.isFunction(cb)) {
          error = new Error;
          error.name = "table-not-created";
          error.message = "Table '" + this.tableName + "' not existend at AWS. please run `Table.generate()` or `Manager.generateAll()` first.";
          this._error(cb, error);
        }
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
      if (_.isArray(items)) {
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
      _hName = this.hashKey;
      if (this.hasRange) {
        _rName = this.rangeKey;
        if ((_attrs[_hName] != null) && _attrs[_rName]) {
          _attrs[_hName] = _attrs[_hName] + this.hashRangeDelimiter + _attrs[_rName];
        }
      }
      if (this.isCombinedTable && (_attrs[_hName] != null)) {
        _attrs[this.hashKey] = _attrs[_hName].replace(this._regexRemCT, "");
      }
      return _attrs;
    };
    DynamoTable.prototype._deFixHash = function(attrs) {
      var _attrs, _h, _hName, _hType, _r, _rName, _rType, _ref;
      if (_.isObject(attrs)) {
        _attrs = _.clone(attrs);
      } else {
        _hName = this.hashKey;
        _attrs = {};
        _attrs[_hName] = attrs;
      }
      if (this.hasRange) {
        _hType = this.hashKeyType;
        _rName = this.rangeKey;
        _rType = this.rangeKeyType;
        _ref = _attrs[_hName].split(this.hashRangeDelimiter), _h = _ref[0], _r = _ref[1];
        _attrs[_hName] = this._convertValue(_h, _hType);
        _attrs[_rName] = this._convertValue(_r, _rType);
      }
      if (this.isCombinedTable) {
        _attrs[_hName] = this.name + this.combinedHashDelimiter + _attrs[_hName];
      }
      return _attrs;
    };
    DynamoTable.prototype._createId = function(attributes, cb) {
      this._createHashKey(attributes, __bind(function(attributes) {
        var _hName;
        if (this.isCombinedTable) {
          _hName = this.hashKey;
          attributes[_hName] = this.name + this.combinedHashDelimiter + attributes[_hName];
        }
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
      _hName = this.hashKey;
      _hType = this.hashKeyType;
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
      _rName = this.rangeKey;
      _rType = this.rangeKeyType;
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
      if (!this.overwriteExistingHash) {
        _pred = {};
        _pred[this.hashKey] = {
          "==": null
        };
        _upd.when(_pred);
      }
      return _upd;
    };
    DynamoTable.prototype._generate = function(cb) {
      var _cr;
      _cr = this.mng.client.add({
        name: this.tableName,
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
      _hName = this.hashKey;
      _hType = this.hashKeyType;
      oShema[_hName] = _hType === "S" ? String : Number;
      if (this.hasRange) {
        _rName = this.rangeKey;
        _rType = this.rangeKeyType;
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
  ERRORMAPPING = {
    "com.amazonaws.dynamodb.v20111205#ConditionalCheckFailedException": {
      name: "conditional-check-failed",
      message: "This is not a valid request. It doesnt match the conditions or you tried to insert a existing hash."
    }
  };
}).call(this);
