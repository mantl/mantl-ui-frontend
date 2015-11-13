'use strict';

var bodyParser = require('body-parser');
var express    = require('express');
var fs         = require('fs');
var http       = require('http');
var logger     = require('morgan');
var Path       = require('path');

module.exports = function startServer(port, path, callback) {
    var app = express();
    var server = http.createServer(app);

    var mocks = {
        health: JSON.parse(fs.readFileSync("mock/health.json")),
        packages: JSON.parse(fs.readFileSync("mock/packages.json")),
        services: [
            {name: "mesos", path: "/mesos"},
            {name: "marathon", path: "/marathon"},
            {name: "consul", path: "/consul"},
            {name: "chronos", path: "/chronos"}
        ]
    };

    app.use(express.static(Path.join(__dirname, path)));
    app.use(logger('dev'));
    app.use(bodyParser.urlencoded({ extended: true }));

    app.get('/_internal/services.json', function(req, res) {
        res.json(mocks.services);
    });

    app.get('/consul/v1/health/state/any', function(req, res) {
        res.json(mocks.health);
    });

    app.get('/1/packages', function(req, res) {
        res.json(mocks.packages);
    });

    app.get('/1/packages/:name', function(req, res) {
        var name = req.params.name;

        for (var i in mocks.packages) {
            var app = mocks.packages[i];
            if (app.name === name) {
                res.json(app);
                return;
            }
        }

        res.status(400).end();
    });

    server.listen(port, callback);
    return server;
};
