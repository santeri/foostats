var http = require('http');
var url = require('url');
var jsontemplate = require('./jsontemplate.js');
var fs = require('fs');
var sys = require('sys');
var util = require('util');
var sqlite = require('./node-sqlite/sqlite');

var db = new sqlite.Database();
db.open("foostats.db", function(error) {
    if (error) throw error;});

var create_sql = "CREATE TABLE matches (id integer primary key autoincrement, ts timestamp not null, p1 text, p2 text, p3, text, p4 text, s1 int, s2 int);";

function addmatch(p1, p2, p3, p4, s1, s2) {
    db.execute("INSERT INTO matches (ts, p1, p2, p3, p4, s1, s2) " +
               "VALUES (datetime('now')    , ? , ? , ? , ? , ? , ?)",
               [p1,p2,p3,p4,s1,s2],
               function (error, rows) {
                   if (error) throw error;
                   console.log("row added ok");});}

function matches(fn) {
    db.prepare("SELECT * from matches", function(error, statement) {
        if (error) throw error;
        statement.fetchAll(function (error, rows) {
            fn(rows);
            statement.finalize(function(error) {});});});}
                    
var handlers = {
  '/' : function(req, res) {
    res.writeHead(200, {'Content-Type': 'text/html'});
    fs.readFile('t-index.html', function (err, data) {
      if (err) throw err;
      matches(function(rows) {
          var t = jsontemplate.Template(data.toString('utf8'));
          var text = t.expand({'name': 'js', 'matches' : rows});    
          res.end(text);
      });
    });
  },
  '/list' : function(req, res) {
      res.writeHead(200, {'Content-Type': 'text/html'});
      matches(function(rows) {
          console.log(rows);
          fs.readFile('t-list.html', function (err, data) {
              if (err) throw err;
              var t = jsontemplate.Template(data.toString('utf8'));
              var text = t.expand({'matches': 'rows'});    
              res.end(text);
          });
      });
  },
  '/add' : function(req, res) {
      var q = url.parse(req.url, true).query;
      console.log(req.url);
      console.log(q);
      addmatch(q.p1, q.p2, q.p3, q.p4, q.s1, q.s2);
      res.writeHead(303 /* see other */, {'Location': '/'});
      res.end('add\n' + console.log(q));
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
