# medaka_procs.nim v1.2.0 (2024-01-29)
import std/asynchttpserver
import std/[os, strtabs, strformat, strutils, uri, cookies, json, logging, mimetypes, paths, re]
import body_parser

const SESSION_NAME* = "medaka_session"

type
  HandlerResult* = (HttpCode, string, HttpHeaders)

func htmlHeader*(): HttpHeaders;
func textHeader*(): HttpHeaders;
func jsonHeader*(): HttpHeaders;
func octedHeader*(filename: string=""): HttpHeaders;

# parse query
func parseQuery*(query: string): StringTableRef =
  result = newStringTable()
  for k, v in decodeQuery(query):
    result[k] = v

# parse query (with multiple attribute)
func parseQueryMultiple*(query: string): StringTableRef =
  result = newStringTable()
  let exprs: seq[string] = query.split("&")
  for e in exprs:
    let kv: seq[string] = e.split("=")
    let key = kv[0]
    let val = kv[1]
    if result.hasKey(key):
      result[key] &= "," & val
    else:
      result[key] = val

# get hash value or default value
func getQueryValue*(hash: StringTableRef, key: string, default: string): string =
  if hash.hasKey(key):
    result = hash[key]
  else:
    result = default

# get posted content-type
func getContentType*(headers: HttpHeaders): string =
  return headers["content-type"]

# parse body (application/x-www-form-urlencoded)
proc parseBody*(body: string): StringTableRef =
  result = newStringTable()
  for k, v in decodeQuery(body):
    result[k] = v

# parse json body (application/json)
proc parseJsonBody*(body: string): JsonNode =
  return parseJson(body)

# parse arraybuffer body (application/octed-stream)
func parseArrayBufferBody*(body: string): string =
  var buff = ""
  for i in 0..<len(body):
    var b:byte = byte(body[i])
    buff &= fmt"{b:02x}"
  return buff

# parse mulitipart body (get dispositions from body)
func parseMultipartBody*(body: string, headers: HttpHeaders): seq[string] =
  let boundary = body_parser.getBoundary(headers)
  return body_parser.getDispositions(body, boundary)

# parse formdata body (mulitipart/form-data)
func parseFormDataBody*(body: string, headers: HttpHeaders): seq[string] =
  return parseMultipartBody(body, headers)

# return template file as Response
proc templateFile*(filepath: string, args: StringTableRef): (HttpCode, string) =
  try:
    var buff: string = readFile(filepath)
    for k, v in args:
      buff = buff.replace("{{" & k & "}}", v)
    result = (Http200, buff)
  except Exception as e:
    let message = e.msg
    result = (Http500, fmt"<h1>Internal error</h1><p>{message}</p>")

# get mime type
func getMimetype*(filepath: string): string =
  let m = newMimetypes()
  let p = Path(filepath)
  let (dir, file, ext) = p.splitFile()
  let mime = m.getMimetype(ext)
  return mime

# send file
proc sendFile*(filepath: string):HandlerResult  =
  var status: HttpCode = Http200
  var content = ""
  var headers = newHttpHeaders()
  try:
    content = readFile(filepath)
    let mime = getMimetype(filepath)
    headers["Content-Type"] = mime
  except Exception as e:
    error(e.msg)
    status = Http500
    content = fmt"<h1>Fatal error: {e.msg}</h1>"
  return (status, content, headers)

# get StringTable value
func getStValue*(hash: StringTableRef, key:string, default:string=""): string =
  if hash.haskey(key):
    result = hash[key]
  else:
    result = default

# is os Windows
proc is_windows*(): bool =
  return dirExists("C:/Windows")

# getCookies
proc getCookies*(headers: HttpHeaders): StringTableRef =
  var cookies: StringTableRef = newStringTable()
  for k, v in headers:
    if toLowerAscii(k) == "cookie":
      var cookies1 = parseCookies(v)
      for k1, v1 in cookies1:
        cookies[k1] = v1
  return cookies

# setCookieValue
proc setCookieValue*(name, value: string, ret_headers: HttpHeaders): HttpHeaders =
  if name.match(re(r"\w[\w|\d|_]*")):
    var ret_cookies: seq[string] = @[]
    for k, v in ret_headers:
      if k.toLowerAscii() == "set-cookie":
        ret_cookies.add(v)
    ret_cookies.add(name & "=" & encodeUrl(value))
    ret_headers["set-cookie"] = ret_cookies
  return ret_headers

# removeCookie
proc removeCookie*(name: string, in_headers: HttpHeaders): HttpHeaders =
  var ret_headers = newHttpHeaders()
  if in_headers.hasKey("cookie"):
    var cookie = fmt"{name}=; max-age=0"
    ret_headers["set-cookie"] = cookie
  return ret_headers

# getCookieValue
proc getCookieValue*(name: string, in_headers: HttpHeaders): string =
  var cookies = getCookies(in_headers)
  if len(cookies) == 0:
    return ""
  elif cookies.hasKey(name):
    return cookies[name]
  else:
    return ""

# getCookieItems
proc getCookieItems*(headers: HttpHeaders): StringTableRef =
  var cookies = getCookies(headers)
  var items = newStringTable()
  for k, v in cookies:
    items[k] = v
  return items

# setSessionValue
proc setSessionValue*(name:string, value:string, headers:HttpHeaders): string =
  if not name.match(re(r"\w[\w|\d|_]*")):
    return ""
  var cookies1: StringTableRef = getCookies(headers)
  var session = ""
  var session_value = ""
  if cookies1.hasKey(SESSION_NAME) and len(cookies1[SESSION_NAME]) > 0:
    session_value = decodeUrl(cookies1[SESSION_NAME])
    var jn: JsonNode = parseJson(session_value)
    jn[name] = % value
    session = $jn
  else:
    session_value = '"' & name & '"' & ':' & '"' & value & '"'
    session = "{" & session_value & "}"
  return session

# getSessionString
proc getSessionString*(headers:HttpHeaders): string =
  var cookies = getCookies(headers)
  var session = decodeUrl(cookies[SESSION_NAME])
  return session

# getSessionValue
proc getSessionValue*(name: string, headers:HttpHeaders): string =
  var session = getSessionString(headers)
  var jn = parseJson(session)
  return $jn[name]

# redirect proc
proc redirect*(url: string): HandlerResult =
  var args = newStringTable()
  args["location"] = url;
  var (status, buff) = templateFile("./templates/redirect.html", args)
  return (status, buff, htmlHeader())

# quote
func q*(s: string):string =
  return "\"" & s & "\""

# escapeHtml proc
func escapeHtml*(s: string): string =
  return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

# html header
func htmlHeader*(): HttpHeaders =
  return newHttpHeaders({"Content-Type":"text/html; charset=utf-8"})

# text header
func textHeader*(): HttpHeaders =
  return newHttpHeaders({"Content-Type":"text/plain; charset=utf-8"})

# json header
func jsonHeader*(): HttpHeaders =
  return newHttpHeaders({"Content-Type":"application/json; charset=utf-8"})

# octed-stream header
func octedHeader*(filename=""): HttpHeaders =
  if filename == "":
    result = newHttpHeaders({"Content-Type":"application/octed-stream"})
  else:
    let attachment = "attachment; filename=\"" & filename & "\""
    result = newHttpHeaders({"Content-Type": "application/octed-stream", "Content-Disposition": attachment})


# start if main (for test)
when isMainModule:
  if paramCount() == 0:
    echo "Enter the test number."
    quit(1)
  let tc = parseInt(paramStr(1))
  case tc
  of 0:  # parseQuery
    var hash: StringTableRef = parseQuery("a=Y%20N&b=123.5")
    echo $hash
    assert hash["a"] == "Y N"
    assert hash["b"] == "123.5"
  of 1:  # getQueryValue
    var hash: StringTableRef = parseQuery("a=Y%20N&b=123.5")
    echo hash.getQueryValue("a", "")
    echo hash.getQueryValue("X", "0")
  of 2: # getContentType
    var headers = newHttpHeaders({"content-type":"image/jpeg", "cookie":"XYZ"})
    echo getContentType(headers)
  of 3: # parseBody only application/x-www-form-urlencoded
    var body = "key1=Y%20N&key2=-5.84"
    var hash: StringTableRef = parseBody(body)
    echo $hash
  of 4: # parseJsonBody
    var body = "{\"x\":5.1, \"y\":-0.7}"
    var jn: JsonNode = parseJsonBody(body)
    echo $jn
  of 5: # parseArrayBufferBody
    var body = "\x45\x0a\x09\x55"
    var buff = parseArrayBufferBody(body)
    echo buff
  of 6: # parseMultipartBody
    var headerData = {"accept":"text/html", "content-type":"multipart/form-data; boundary=---------------------------26767473973547735812633686047", "content-length":"618"}
    var headers:HttpHeaders = newHttpHeaders(headerData)
    var body = """-----------------------------26767473973547735812633686047
Content-Disposition: form-data; name="id"

ID
-----------------------------26767473973547735812633686047
Content-Disposition: form-data; name="info"

INFO
-----------------------------26767473973547735812633686047--"""
    var dispos:seq[string] = parseMultipartBody(body, headers)
    for d in dispos:
      echo d
  of 7: # templateFile
    var filePath = "./templates/form1.html"
    var args = newStringTable({"id":"1", "title":"TITLE", "info":"INFO", "result":"RESULT"})
    var status:HttpCode
    var content:string
    (status, content) = templateFile(filePath, args)
    echo status
    echo content
  of 8: # getMimetype
    var mime: string = getMimetype("./templates/form1.html")
    echo mime
  of 9: # sendFile
    var filePath = "./templates/form1.html"
    var status:HttpCode
    var content:string
    var headers = newHttpHeaders()
    (status, content, headers) = sendFile(filepath)
    echo status
    echo content
    echo headers
  of 10: # getStValue
    var hash = newStringTable({"key1":"value1"})
    echo hash.getStValue("key1", "?1")
    echo hash.getStValue("key0", "?0")
  of 11: # is_windows
    echo is_windows()
  of 12: # getCookies
    var headers: HttpHeaders = newHttpHeaders({"content-type":"multipart/form-data", "cookie":"a=10; b=677"})
    var hash: StringTableRef = getCookies(headers)
    echo $hash
  of 13: # setCookieValue
    var headers = newHttpHeaders({"content-type":"text/html"})
    var ret_headers = setCookieValue("b", "467", headers)
    echo $ret_headers
    ret_headers = setCookieValue("c", "8", ret_headers)
    echo $ret_headers
  of 14: # removeCookie
    var headers = newHttpHeaders({"content-type":"text/html", "cookie":"a=A; b=BB"})
    var headers2 = removeCookie("a", headers)
    echo $headers2
  of 15: # getCookieValue
    var headers = newHttpHeaders({"content-type":"text/html", "cookie":"a=A; b=BB"})
    echo getCookieValue("a", headers)
    echo getCookieValue("b", headers)
  of 16: # getCookieItems
    var headers = newHttpHeaders({"content-type":"text/html", "cookie":"a=A; b=BB"})
    var cookies: StringTableRef = getCookieItems(headers)
    echo cookies
  of 17: # setSessionValue
    var headers = newHttpHeaders()
    var session = setSessionValue("x1", "0.5", headers)
    echo session
    headers["cookie"] = SESSION_NAME & "=" & session
    session = setSessionValue("y1", "5.0", headers)
    echo session
    headers["cookie"] = SESSION_NAME & "=" & session.encodeUrl()
    echo headers
  of 18: # getSeesionValue
    var headers = newHttpHeaders({"cookie":"medaka_session=%7B%22x1%22%3A%220.5%22%2C%22y1%22%3A%225.0%22%7D"})
    echo getSessionValue("x1", headers)
    echo getSessionValue("y1", headers)
  of 19: # redirect
    var status = Http200
    var content = ""
    var headers = htmlHeader()
    (status, content, headers) = redirect("http://localhost:2024/sample.html")
    echo status
    echo content
    echo headers
  of 20: # q
    echo q("Hello World!")
  of 21: # escapeHtml
    echo escapeHtml("<p>Hello & World</p>")
  of 22: # htmlHeader, textHeader, jsonHeader, octedHeader
    echo htmlHeader()
    echo textHeader()
    echo jsonHeader()
    echo octedHeader()
  else:
    echo "Not allowed."

