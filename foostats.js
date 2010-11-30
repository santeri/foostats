var http = require('http');
var url = require('url');
var jsontemplate = require('./jsontemplate.js');
var fs = require('fs');
var sys = require('sys');
var util = require('util');

var handlers = {
  '/' : function(req, res) {
    res.writeHead(200, {'Content-Type': 'text/html'});
    fs.readFile('t-index.html', function (err, data) {
      if (err) throw err;
      var t = jsontemplate.Template(data);
      var text = t.expand({'name': 'js'});    
      res.end(text);
    });
  },
  '/list' : function(req, res) {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('list\n');
  },
  '/add' : function(req, res) {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    var q = url.parse(req.url, true).query;
    
    res.end('add\n' + q.p1);
  }
};

http.createServer(function (req, res) {
  var path = url.parse(req.url).pathname;
  var handler = handlers[path];
  if (handler) handler(req, res);
  else {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('no handler for ' + req.url);
  }
}).listen(8080);
