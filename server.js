(function() {
  var DynamoConnector, app, dynDB, express;
  root._ = require("underscore");
  express = require('express');
  root.utils = require("./lib/utils");
  DynamoConnector = require("./lib/dynamo");
  root.argv = require('optimist')["default"]('host', "127.0.0.1")["default"]('port', "8010")["default"]('config', "LOCAL").alias('config', "c").argv;
  root._CONFIG_TYPE = argv.config;
  root._CONFIG_PORT = argv.port;
  root._CONFIG = require("./config");
  app = express.createServer();
  app.use(express.bodyParser());
  dynDB = new DynamoConnector(_CONFIG.aws, _CONFIG.dynamo.region);
  app.get("/", function(req, res) {
    res.send("try '/_tables'");
  });
  app.get("/_tables", function(req, res) {
    dynDB.listTables(function(err, tables) {
      if (err) {
        res.json(err, 500);
      } else {
        res.json(tables);
      }
    });
  });
  app.get("/:table/_meta", function(req, res) {
    var _t;
    _t = req.params.table;
    dynDB.meta(_t, function(err, meta) {
      if (err) {
        res.json(err, 500);
      } else {
        res.json(meta);
      }
    });
  });
  app.get("/:table/", function(req, res) {
    var _q, _t;
    _t = req.params.table;
    _q = {};
    dynDB.scan(_t, _q, function(err, data) {
      if (err) {
        res.json(err, 500);
      } else {
        res.json(data);
      }
    });
  });
  app.put("/:table/", function(req, res) {
    var _data, _t;
    _t = req.params.table;
    _data = req.body;
    console.log(_data);
    dynDB.put(_t, _data, function(err, success) {
      if (err) {
        res.json(err, 500);
      } else {
        res.json(success);
      }
    });
  });
  app.get("/:table/:id", function(req, res) {
    var _id, _t;
    _t = req.params.table;
    _id = req.params.id;
    dynDB.get(_t, _id, function(err, success) {
      if (err) {
        res.json(err, 500);
      } else {
        res.json(success);
      }
    });
  });
  app.del("/:table/:id", function(req, res) {
    var _id, _t;
    _t = req.params.table;
    _id = req.params.id;
    dynDB.del(_t, _id, function(err, success) {
      if (err) {
        res.json(err, 500);
      } else {
        res.json(success);
      }
    });
  });
  app.listen(3000);
}).call(this);
