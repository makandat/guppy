#
# handlers.nim v1.2.1 (2024-01-30)
#   メニューのハンドラ  for guppy
#
# メニューハンドラ
import medaka_procs
import std/asynchttpserver
import std/private/osdirs
import std/[paths, strtabs, strformat, strutils, uri, random, json, osproc, streams, files, envvars]
#import db_connector/db_sqlite
import body_parser

const UPLOAD = "./upload"

# ディレクトリ内の項目一覧を得る。
proc getFiles(dirpath: string): string =
  var s = "<ul>"
  var path: string
  for i in walkDir(dirpath):
    path = i.path
    let filename: string = extractFilename(path.Path).string
    if not filename.startswith("."):
      if i.kind == pcDir:
        s &= &"<li><a href=\"/list_files?path={path}\">{filename}/</a></li>"
      elif i.kind == pcLinkToFile:
        s &= &"<li>{filename}*</li>"
      elif i.kind == pcLinkToDir:
        s &= &"<li>{filename}*/</li>"
      else:
        s &= &"<li><a href=\"/get_file?path={path}\">{filename}</a></li>"
  s &= "</ul>" 
  return s

# リモートディレクトリの参照
proc list_files*(req: Request): HandlerResult =
  var args = newStringTable()
  if req.reqMethod == HttpGET and req.url.query == "":
    args["path"] = getEnv("HOME")
    args["parent"] = ""
    args["files"] = ""
  else:
    let hash = parseQuery(req.url.query)
    args["path"] = hash.getQueryValue("path", "")
    let parent = parentDir(args["path"].Path).string
    args["parent"] = parent
    args["files"] = getFiles(hash["path"])
  var (status, content) = templateFile("./templates/list_files.html", args)
  result = (status, content, htmlHeader())

# ファイル取得
proc get_file*(req: Request): HandlerResult =
  var args = newStringTable()
  if req.reqMethod == HttpGET:
    let hash = parseQuery(req.url.query)
    args["path"] = hash.getQueryValue("path", "")
    let (status, content) = templateFile("./templates/get_file.html", args)
    result = (status, content, htmlHeader())
  else: # POST
    let hash = parseQuery(req.body)
    let filepath = hash.getQueryValue("filepath", "")
    if filepath == "":
      result = (Http500, "The parameter 'path' does not exists.", textHeader())
      return result
    let filename = extractFilename(filepath.Path)
    let fs = newFileStream(filepath)
    let content = fs.readAll()
    fs.close()
    result = (Http200, content, octedHeader(filename.string))

# リモートディレクトリを圧縮して取得
proc get_tarball*(req: Request): HandlerResult =
  if req.reqMethod == HttpGET:
    let (status, content) = templateFile("./templates/get_tarball.html", {"path":"", "message":""}.newStringTable)
    result = (status, content, htmlHeader())
  else:
    let hash = parseQuery(req.body)
    let dirpath = hash.getQueryValue("dirpath", "")
    if dirExists(dirpath):
      randomize()
      let num = rand(100000)     
      var targz = "/tmp/guppy_" & $num & ".tar.gz"
      if is_windows():
        targz = "D:/temp/guppy_" & $num & ".tar.gz"
      let cmd = "tar cfz " & targz & " " & dirpath
      if execCmd(cmd) == 0:
        let filename = lastPathPart(dirpath.Path).string & ".tar.gz"
        let fs = newFileStream(targz)
        let content = fs.readAll()
        fs.close()
        result = (Http200, content, octedHeader(filename))
      else:
        result = (Http500, "Error: tar command has failed.", textHeader())
    else:
      result = (Http500, "Error: The directory path is empty or not exists.", textHeader())
      

# ファイルアップロード
proc file_upload*(req: Request): HandlerResult=
  let name = "file"
  let args = newStringTable()
  if req.reqMethod == HttpGET:
    args["message"] = ""
    let (status, content) = templateFile("./templates/file_upload.html", args)
    result = (status, content, htmlHeader())
  else:
    let dispositions = parseMultipartBody(req.body, req.headers)
    let savefile = UPLOAD & "/" & dispositions.getFileName(name)
    let chunk = dispositions.getChunk(name)
    writeFile(savefile, chunk)
    let message = &"ファイル '{savefile}' にアップロードされたファイルを保存しました。"
    args["message"] = message
    let (status, content) = templateFile("./templates/file_upload.html", args)
    result = (status, content, htmlHeader())
    

# 複数ファイルのアップロード
proc multiple_files_upload*(req: Request): HandlerResult =
  let args = newStringTable()
  if req.reqMethod == HttpGET:
    args["message"] = ""
    let (status, content) = templateFile("./templates/multiple_files_upload.html", args)
    result = (status, content, htmlHeader())
  else:
    let dispositions = parseMultipartBody(req.body, req.headers)
    let n = body_parser.getChunkCount(dispositions)
    for i in 1 .. n:
      let filename = body_parser.getFileName(dispositions, "files", i-1)
      let savefile = UPLOAD & "/" & filename
      let chunk = body_parser.getChunk(dispositions, "files", i-1)
      writeFile(savefile, chunk)
    args["message"] = fmt"{n} 個のファイルを ./upload に保存しました。"
    let (status, content) = templateFile("./templates/multiple_files_upload.html", args)
    result = (status, content, htmlHeader())


# アップロードフォルダの内容を得る。
proc getUploadedFiles(dirpath: string): string =
  var files = ""
  for i in walkDir(dirpath):
    let path = i.path
    let filename: string = extractFilename(path.Path).string
    files &= fmt"<option value='{filename}'>{filename}</option>"
  return files

# アップロードされたファイルの移動
proc move_files*(req: Request): HandlerResult =
  let args = newStringTable()
  if req.reqMethod == HttpGET:
    # upload_folder 内のファイル一覧を取得する。  
    args["files"] = getUploadedFiles(UPLOAD)
    args["message"] = ""
    let (status, content) = templateFile("./templates/move_files.html", args)
    result = (status, content, htmlHeader())
  else:
    let hash = parseQueryMultiple(req.body)
    let folder = decodeUrl(hash["folder"])
    let files = hash["files"].split(",")
    for f in files:
      moveFile((UPLOAD & "/" & f).Path, (folder & "/" & f).Path)
    args["message"] = hash["files"] & " are moved."
    args["files"] = getUploadedFiles(UPLOAD)
    let (status, content) = templateFile("./templates/move_files.html", args)
    result = (status, content, htmlHeader())
      
      
# テストでメインとして実行
when isMainModule:
  # proc post_request_xml*(body: string, headers: HttpHeaders): HandlerResult
  var status: HttpCode
  var content: string
  var ret_headers: HttpHeaders
  var headers = newHttpHeaders({"content-type":"application/xml"})
  var body = """<?xml version="1.0"?>
<data>
 <id>10</id>
 <name>James Bond</name>
</data>"""
  (status, content, ret_headers) = post_request_xml(body, headers)
  echo status
  echo content
  echo ret_headers

