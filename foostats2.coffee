http = require 'http'
url  = require 'url'
fs   = require 'fs'
sys  = require 'sys'
util = require 'util'
sqlite = require './node-sqlite/sqlite'
jsontemplate = require './jsontemplate.js'

db = new sqlite.Database
db.open 'foostats.db', (err) -> throw err if err

create_sql = "CREATE TABLE matches (
id integer primary key autoincrement,ts datetime not null,
p1 text not null,p2 text not null,p3 text not null,p4 text not null,
s1 int not null,s2 int not null)"

addmatch = (p1,p2,p3,p4,s1,s2) ->
        db.execute "INSERT INTO matches (ts, p1, p2, p3, p4, s1, s2)
                    VALUES (datetime('now'), ? , ? , ? , ? , ? , ?)",
        [p1,p2,p3,p4,s1,s2],
        (error, rows) ->
                throw error if error
                console.log "row added ok"

matches = (cb) ->
    db.prepare "SELECT * from matches", (error, statement) ->
        throw error if error
        statement.fetchAll (error, rows) ->
            throw error if error
            cb rows
            statement.finalize (err) -> console.log err

template = (res, name, values) ->
    fs.readFile 't-'+name+'.html', (err, data) ->
        throw err if err
        res.writeHead 200, 'Content-Type': 'text/html'
        res.end jsontemplate.Template(data.toString('utf8')).expand(values)

handlers =
        '/' : (req, res) ->
                matches (rows) ->
                        template res, 'index', 'matches':rows
        '/list' : (req, res) ->
                throw 'not implemented'
         '/add' : (req, res) ->
                q = url.parse(req.url, true).query
                addmatch q.p1, q.p2, q.p3, q.p4, q.s1, q.s2
                res.writeHead 303, 'Location' : '/'
                res.end ''

http.createServer (req,res) ->
        path = url.parse(req.url).pathname
        handler = handlers[path]
        if handler?
                handler req, res
        else
                res.writeHead 200, 'Content-Type' : 'text/plain'
                res.end 'no handler for ' + req.url
