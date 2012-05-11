(function() {
  var DynamoManager, app, dynDB, express, _dynamoOpt, _ref, _ref2;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  root._ = require("underscore");
  express = require('express');
  root.utils = require("./lib/utils");
  DynamoManager = require("./lib/dynamo/");
  root.argv = require('optimist')["default"]('host', "127.0.0.1")["default"]('port', "8010")["default"]('config', "LOCAL").alias('config', "c").argv;
  root._CONFIG_TYPE = argv.config;
  root._CONFIG_PORT = argv.port;
  root._CONFIG = require("./config");
  if (((_ref = process.env) != null ? _ref.AWS_AKI : void 0) != null) {
    _CONFIG.aws.accessKeyId = process.env.AWS_AKI;
  }
  if (((_ref2 = process.env) != null ? _ref2.AWS_SAK : void 0) != null) {
    _CONFIG.aws.secretAccessKey = process.env.AWS_SAK;
  }
  app = express.createServer();
  app.use(express.bodyParser());
  _dynamoOpt = _.extend(_CONFIG.aws, {
    region: _CONFIG.dynamo.region
  });
  dynDB = new DynamoManager(_dynamoOpt, _CONFIG.dynamo.tables);
  dynDB.connect(__bind(function(err) {
    if (err) {
      return console.error(err);
    }
  }, this));
  dynDB.on("new-table", __bind(function(table) {
    console.log("new-table", table.name);
    table.on("create-status", __bind(function(status) {
      console.log("create-status", table.name, status);
    }, this));
  }, this)).on("all-tables-generated", __bind(function(generated) {
    console.log("all-tables-generated", generated);
  }, this)).on("table-generated", __bind(function() {
    console.log("table-generated");
  }, this));
  app.get("/", function(req, res) {
    res.send("try '/_tables'");
  });
  app.get("/_tables", function(req, res) {
    dynDB.list(function(err, tables) {
      if (err) {
        res.json(err, 500);
      } else {
        res.json(tables);
      }
    });
  });
  app.get("/createTables", function(req, res) {
    dynDB.generateAll(function(err, created) {
      if (err) {
        res.json(err, 500);
      } else {
        res.json(created || true);
      }
    });
  });
  app.get("/:table/_meta", function(req, res) {
    var _t, _tbl;
    _t = req.params.table;
    _tbl = dynDB.get(_t);
    if (!_tbl) {
      res.json("table '" + _t + "' not found", 404);
      return;
    }
    _tbl.meta(function(err, meta) {
      if (err) {
        res.json(err, 500);
      } else {
        res.json(meta);
      }
    });
  });
  app.get("/:table/", function(req, res) {
    var key, val, _key, _q, _ref3, _ref4, _regexQuery, _regexQueryType, _t, _tbl;
    _t = req.params.table;
    if (0) {
      _regexQuery = /\w+(\^|\*|!|<|>)$/i;
      _regexQueryType = /(\^|\*|!|<|>)$/i;
      _q = {};
      _ref3 = req.query || {};
      for (key in _ref3) {
        val = _ref3[key];
        if (_regexQuery.test(key)) {
          _key = key.replace(_regexQueryType, '');
          switch (_.last(key.split(''))) {
            case "^":
              _q[_key] = {
                "startsWith": val
              };
              break;
            case "*":
              _q[_key] = {
                "contains": val
              };
              break;
            case "<":
              _q[_key] = {
                "<": val
              };
              break;
            case ">":
              _q[_key] = {
                ">": val
              };
          }
        } else {
          _q[key] = {
            "==": val
          };
        }
      }
    } else {
      _q = JSON.parse(((_ref4 = req.query) != null ? _ref4.q : void 0) || "{}");
    }
    _tbl = dynDB.get(_t);
    if (!_tbl) {
      res.json("table '" + _t + "' not found", 404);
      return;
    }
    _tbl.find(_q, function(err, data) {
      if (err) {
        res.json(err, 500);
      } else {
        res.json(data);
      }
    });
  });
  app.put("/:table/", function(req, res) {
    var _data, _t, _tbl;
    _t = req.params.table;
    _data = req.body;
    _tbl = dynDB.get(_t);
    if (!_tbl) {
      res.json("table '" + _t + "' not found", 404);
      return;
    }
    _tbl.set(_data, function(err, success) {
      if (err) {
        res.json(err, 500);
      } else {
        res.json(success);
      }
    });
  });
  app.get("/:table/:id", function(req, res) {
    var _id, _t, _tbl;
    _t = req.params.table;
    _id = req.params.id;
    _tbl = dynDB.get(_t);
    if (!_tbl) {
      res.json("table '" + _t + "' not found", 404);
      return;
    }
    _tbl.get(_id, function(err, success) {
      if (err) {
        res.json(err, 500);
      } else {
        res.json(success);
      }
    });
  });
  app.post("/:table/:id", function(req, res) {
    var _data, _id, _t, _tbl;
    _t = req.params.table;
    _id = req.params.id;
    _data = req.body;
    _tbl = dynDB.get(_t);
    if (!_tbl) {
      res.json("table '" + _t + "' not found", 404);
      return;
    }
    _tbl.set(_id, _data, function(err, success) {
      if (err) {
        res.json(err, 500);
      } else {
        res.json(success);
      }
    });
  });
  app.del("/:table/:id", function(req, res) {
    var _id, _t, _tbl;
    _t = req.params.table;
    _id = req.params.id;
    _tbl = dynDB.get(_t);
    if (!_tbl) {
      res.json("table '" + _t + "' not found", 404);
      return;
    }
    _tbl.del(_id, function(err, success) {
      if (err) {
        res.json(err, 500);
      } else {
        res.json(success);
      }
    });
  });
  app.listen(3000);
}).call(this);
