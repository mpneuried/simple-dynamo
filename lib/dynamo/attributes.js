(function() {
  var Attributes, Helper, exports, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  _ = require("underscore");
  Helper = {
    val2dyn: function(value) {
      switch (typeof value) {
        case "number":
          return {
            N: String(value)
          };
        case "string":
          return {
            S: value
          };
      }
      if (value) {
        switch (typeof value[0]) {
          case "number":
            return {
              NN: value.map(String)
            };
          case "string":
            return {
              SS: value
            };
        }
      }
      throw new Error("Invalid key value type.");
    },
    dyn2val: function(data) {
      var name, value;
      name = Object.keys(data)[0];
      value = data[name];
      switch (name) {
        case "S":
        case "SS":
          return value;
        case "N":
          return Number(value);
        case "NS":
          return value.map(Number);
        default:
          throw new Error("Invalid data type: " + name);
      }
    },
    obj2dyn: function(attrs) {
      var obj;
      obj = {};
      Object.keys(attrs).forEach(function(key) {
        return obj[key] = Helper.val2dyn(attrs[key]);
      });
      return obj;
    },
    dyn2obj: function(data) {
      var obj;
      obj = {};
      Object.keys(data).forEach(function(key) {
        return obj[key] = Helper.dyn2val(data[key]);
      });
      return obj;
    }
  };
  Attributes = (function() {
    function Attributes(raw, table) {
      this.raw = raw;
      this.table = table;
      this._fixPredicateValue = __bind(this._fixPredicateValue, this);
      this._fixPredicate = __bind(this._fixPredicate, this);
      this.fixPredicates = __bind(this.fixPredicates, this);
      this.getQuery = __bind(this.getQuery, this);
      this.updateAttrsFn = __bind(this.updateAttrsFn, this);
      this.validateAttributes = __bind(this.validateAttributes, this);
      this.get = __bind(this.get, this);
      this.prepare = __bind(this.prepare, this);
      this.prepare();
      return;
    }
    Attributes.prototype.prepare = function() {
      var _attr, _i, _len, _outE, _ref;
      this.attrs || (this.attrs = {});
      _ref = this.raw;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _attr = _ref[_i];
        _outE = _.clone(_attr);
        if (_outE.key === this.table.hashKey) {
          _outE.isHash = true;
        }
        if (_outE.key === this.table.rangeKey) {
          _outE.isRange = true;
        }
        this.attrs[_outE.key] = _outE;
      }
    };
    Attributes.prototype.get = function(key) {
      return this.attrs[key] || null;
    };
    Attributes.prototype.validateAttributes = function(attrs, cb) {
      return cb(null, attrs);
    };
    Attributes.prototype.updateAttrsFn = function(_current, _new) {
      var self;
      self = this;
      return function() {
        var _i, _k, _kc, _kn, _len, _ref, _tbl, _v;
        _tbl = self.table;
        _kc = _.without(Object.keys(_current), _tbl.hashKey, _tbl.rangeKey);
        _kn = _.without(Object.keys(_new), _tbl.hashKey, _tbl.rangeKey);
        this._todel = _.difference(_kc, _kn);
        for (_k in _new) {
          _v = _new[_k];
          if (_k !== _tbl.hashKey) {
            if ((_current[_k] != null) && _current[_k] !== _v) {
              this.put(_k, _v);
            } else if (!(_current[_k] != null)) {
              this.put(_k, _v);
            }
          }
        }
        _ref = this._todel;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          _k = _ref[_i];
          this.remove(_k);
        }
      };
    };
    Attributes.prototype.getQuery = function(table, query) {
      var isScan, _q, _ref;
      _ref = this.fixPredicates(query), _q = _ref[0], isScan = _ref[1];
      if (isScan) {
        console.warn("WARNING! Dynamo-Scan on `" + table.TableName + "`. Query:", _q);
        return table.scan(_q);
      } else {
        return table.query(_q);
      }
    };
    Attributes.prototype.fixPredicates = function(predicates) {
      var isScan, key, predicate, _attr, _fixed;
      _fixed = {};
      isScan = false;
      for (key in predicates) {
        predicate = predicates[key];
        _attr = this.get(key);
        if (_attr) {
          if (!isScan || (!_attr.isHash && !_attr.isRange)) {
            isScan = true;
          }
          _fixed[key] = this._fixPredicate(predicate, _attr);
        }
      }
      return [_fixed, true];
    };
    Attributes.prototype._fixPredicate = function(predicate, _attr) {
      var val, _a, _arrayAcceptOps, _i, _len, _op, _ops, _ref, _v;
      _ops = Object.keys(predicate);
      _arrayAcceptOps = ["<=", ">=", "in"];
      if (_ops.length === 1) {
        _op = _ops[0];
        if (_.isArray(predicate[_op]) && __indexOf.call(_arrayAcceptOps, _op) >= 0) {
          _a = [];
          _ref = predicate[_op];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            val = _ref[_i];
            _v = this._fixPredicateValue(val, _attr.type);
            if (_v) {
              _a.push(_v);
            }
          }
          predicate[_op] = _a;
        } else if (!_.isArray(predicate[_op])) {
          _v = this._fixPredicateValue(predicate[_op], _attr.type);
          if (_v) {
            predicate[_op] = _v;
          }
        } else {
          throw new Error("Malformed query. Arrays only allowed for `" + _arrayAcceptOps);
        }
      } else {
        throw new Error("Malformed query. Only exact one query operator will be accepted per key");
      }
      return predicate;
    };
    Attributes.prototype._fixPredicateValue = function(value, type) {
      var _vt;
      if (type == null) {
        type = "string";
      }
      _vt = typeof value;
      switch (type) {
        case "string":
          if (_vt !== "string" && _vt !== "undefined") {
            return value.toString();
          } else {
            return value;
          }
          break;
        case "number":
          if (_vt !== "number" && _vt !== "undefined") {
            return parseFloat(value, 10);
          } else {
            return value;
          }
          break;
        case "boolean":
          if (_vt !== "boolean" && _vt !== "undefined") {
            return Boolean(10);
          } else {
            return value;
          }
      }
    };
    return Attributes;
  })();
  exports = module.exports = Attributes;
  exports.helper = Helper;
}).call(this);
