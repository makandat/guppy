# Medaka server  v1.2.1 (2024-01-30)
import std/asynchttpserver
import std/asyncdispatch
import std/[files, paths, strtabs, json, mimetypes, strutils, strformat, logging]
import handlers

const VERSION = "1.2.1"
const USE_PORT:uint16 = 2024
const CONFIG_FILE = "medaka.json"
const LOG_FILE = "medaka.log"
let START_MSG = fmt"Start medaka server v{VERSION} ..."

# read medaka.json
proc readSettings(): StringTableRef =
  let settings = newStringTable()
  let s = readFile(CONFIG_FILE)
  let data = parseJson(s)
  for x in data.pairs:
    settings[x.key] = x.val.getStr("")
  return settings

# initialize logger
proc initLogger() =
  let file = open(LOG_FILE, fmAppend)
  let logger = newFileLogger(file, fmtStr=verboseFmtStr)
  addHandler(logger)

# return static file as Response
proc staticFile(filepath: string): (HttpCode, string, HttpHeaders) =
  try:
    let (dir, name, ext) = splitFile(Path(filepath))
    let m = newMimeTypes()
    var mime = m.getMimeType(ext)
    if ext == ".txt" or ext == ".html":
      mime = mime & "; charset=utf-8"
    var buff: string = readFile(filepath)
    result = (Http200, buff, newHttpHeaders({"Content-Type":mime}))
  except Exception as e:
    let message = e.msg
    error(message)
    result = (Http500, fmt"<h1>Internal error</h1><p>{message}</p>", newHttpHeaders({"Content-Type":"text/html; charset=utf-8"}))

# Callback on Http request
#   TODO: You must change below, when you create your own application. 
proc callback(req: Request) {.async.} =
  #info(req.url.path)
  echo req.url.path
  var status = Http200
  var content = ""
  var headers = newHttpHeaders({"Content-Type":"text/html; charset=utf-8"})
  let settings = readSettings()
  var filepath = ""
  let htdocs = settings["html"]
  let templates = settings["templates"]
  if req.url.path == "" or req.url.path == "/":
    filepath = htdocs & "/index.html"
  else:
    filepath = htdocs & "/" & req.url.path
  # ディスパッチ処理
  #   静的なファイル
  if req.reqMethod == HttpGet and fileExists(Path(filepath)):
    (status, content, headers) = staticFile(filepath)
  #  リモートディレクトリの参照 / list_files
  elif req.url.path == "/list_files":
    (status, content, headers) = handlers.list_files(req)
  #  ファイル取得 /get_file
  elif req.url.path == "/get_file":
    (status, content, headers) = handlers.get_file(req)
  #  リモートディレクトリを圧縮して取得 /get_tarball
  elif req.url.path == "/get_tarball":
    (status, content, headers) = handlers.get_tarball(req)
  #  ファイルアップロード /file_upload
  elif req.url.path == "/file_upload":
    (status, content, headers) = handlers.file_upload(req)
  #  複数ファイルのアップロード /multiple_files_upload
  elif req.url.path == "/multiple_files_upload":
    (status, content, headers) = handlers.multiple_files_upload(req)
  # アップロードされたファイルの移動
  elif req.url.path == "/move_files":
    (status, content, headers) = handlers.move_files(req)    
  else: # その他はエラーにする。
    status = Http403 # Forbidden
    headers = newHttpHeaders({"Content-Type":"text/html"})
    content = "<h1>Error: This path is fobidden.</h1><p>" & req.url.path & "</p>"
  # 応答を返す。
  await req.respond(status, content, headers)

#
#  Start as main
#  =============
when isMainModule:
  initLogger()
  var server = newAsyncHttpServer()
  server.listen(Port(USE_PORT))
  echo START_MSG & "\n URL: http://localhost:" & $USE_PORT
  info START_MSG
  while true:
    if server.shouldAcceptRequest():
      waitFor server.acceptRequest(callback)
    else:
      echo "Sleep"
      waitFor sleepAsync(500)

