http = require 'http'
url  = require 'url'
fs   = require 'fs'
sys  = require 'sys'
util = require 'util'
querystring = require 'querystring'
sqlite = require './node-sqlite/sqlite'
jsontemplate = require './json-template/lib/json-template'

String.prototype.extension = () ->
  return this.substring(this.lastIndexOf("."))

db = new sqlite.Database
db.open 'foostats.db', (err) -> throw err if err
log = console.log

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
      log "row added ok"

matches = (cb) ->
  db.prepare "SELECT * from matches", (error, statement) ->
    throw error if error
    statement.fetchAll (error, rows) ->
      throw error if error
      cb rows
      statement.finalize (err) -> console.log err if err

template = (res, name, values) ->
  fs.readFile 't-'+name+'.html', (err, data) ->
    throw err if err
    res.writeHead 200, 'Content-Type': 'text/html'
    res.end jsontemplate.Template(data.toString('utf8')).expand(values)

redirect = (url, res) ->
  res.writeHead 303, 'Location' : url
  res.end()

redirect_root = (res) ->
  redirect '/', res

collect_body = (req, fn) ->
  body = ""
  req.setEncoding 'utf8'
  req.on 'data', (chunk) -> body += chunk
  req.on 'end', () -> fn(body)

handlers =
  '/list' : (req, res, err_fn) ->
    matches (rows) ->
      template res, 'list', 'matches':rows

  '/add' : (req, res, err_fn) ->
    q = url.parse(req.url, true).query
    addmatch q.p1, q.p2, q.p3, q.p4, q.s1, q.s2
    redirect_root(res)

  '/delete' : (req, res, err_fn) ->
    log req.method, req.url.toString()
    collect_body req, (body) ->
      if body != ""
        q = querystring.parse(body)
        log "deleting row " + q.id
        db.execute "DELETE FROM matches WHERE id = ?", [q.id], (error, rows) ->
          if error err_fn(res, error)
          else log "row " + q.id + " deleted"
      else
        log "delete: no body"
      redirect('/list', res)

  '/' : (req, res, err_fn) ->
    matches (rows) ->
      template res, 'index', 'matches':rows

content_types =
  '.js' : 'application/javascript'
  '.css' : 'text/css'


# server a file at path to res or throw an exception
servefile = (res, path, err_fn) ->
  if path[0] == '/' # strip leading slash
    path = path.substring(1)
  fs.readFile path, (err, data) ->
    if err
      err_fn(res, err)
    else
      log "serving file ", path, "with content type", content_types[path.extension()]
      res.writeHead 200, 'Content-Type': content_types[path.extension()]
      res.end data

error = (res, err) ->
  log err
  res.writeHead 500, "Content-Type" : "text/plain"
  res.end "Error: " + err.message

server = http.createServer (req,res) ->
  path = url.parse(req.url).pathname
  log url.parse(req.url)

  try
    if path.match('/scripts') then servefile(res, path, error)
    else if handler = handlers[path]
      handler req, res, error
    else
      res.writeHead 200, 'Content-Type' : 'text/plain'
      res.end 'no handler for ' + req.url
  catch err
    log err
    res.writeHead 404, 'Content-Type' : 'text/plain'
    res.end path, " not valid"

log "Starting server on 8080"
server.listen(8080)