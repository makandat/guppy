# body_parser v1.2.2 (2024-02-12)
import std/asynchttpserver
import std/[strutils, uri]

var headers: HttpHeaders

# get boundary string
proc getBoundary*(headers: HttpHeaders): string =
  result = ""
  for k, v in headers:
    if k == "content-type":
      var a = v.split("; ")
      if a[0] == "multipart/form-data" and a[1].startsWith("boundary"):
        var b = a[1].split("=")
        result = b[1].substr(0, len(b[1]) - 1)

# get dispositions
proc getDispositions*(body: string, boundary: string): seq[string] =
  var disps: seq[string] = body.split(boundary)
  var indexes: seq[int] = @[]
  for i in 0..<len(disps):
    if disps[i].find("Content-Disposition: form-data;") < 0:
      indexes.add(i)
  for i in indexes:
    disps.delete(i)
  return disps;

# is this disposition with chunk
proc isWithChunk*(disposition: string): bool =
  var p = disposition.find("Content-Type: ")
  return p >= 0

# get the name of this disposition
proc getDispositionName*(disposition: string): string =
  var p = disposition.find("Content-Disposition: form-data; name=\"")
  if p < 0:
    return ""
  else:
    p += len("Content-Disposition: form-data; name=\"")
  var q = disposition.find("\"", p)
  return disposition.substr(p, q-1)

# get the value of this disposition
proc getDispositionValue*(disposition: string): string =
  if disposition.find("Content-Type: ") >= 0:
    return ""
  else:
    var lines = disposition.split("\n")
    let n = len(lines) - 2
    if n < 0:
      return ""
    return lines[n]

# get the filename of this disposition if exists
proc getDispositionFileName*(disposition: string, n=0): string =
  var p = disposition.find("Content-Disposition: form-data; name=\"")
  var q = disposition.find("filename=")
  var i = 0
  while i <= n:
    if p < 0 or q < 0:
      return ""
    else:
      p += len("Content-Disposition: form-data;")
      p = disposition.find("filename=\"", p)
      if p < 0:
        return ""
      else:
        p += len("filename=\"")
        var q = disposition.find("\"", p)
        return disposition.substr(p, q-1)

# get the chunk
proc getDispositionChunk*(disposition: string): string =
  var p = disposition.find("Content-Disposition:")
  var q = disposition.find("filename=")
  if p < 0 or q < 0:
    return ""
  else:
    p = disposition.find("Content-Type:")
    q = disposition.find("\r\n", p)
    p = q + 4
    return disposition.substr(p, len(disposition)-4)

# get value of the name
proc getValue*(dispositions: seq[string], name:string): string =
  var name1: string
  for d in dispositions:
    name1 = d.getDispositionName()
    if name == name1:
      var s = d.getDispositionValue().decodeUrl()
      if s.endsWith("\r"):
        s = s.substr(0, len(s)-2)
      return s
  return ""

# get chunk of the name
proc getChunk*(dispositions: seq[string], name:string, n=0): string =
  var name1: string
  var i = 0
  for d in dispositions:
    if d.isWithChunk() == true:
      name1 = d.getDispositionName()
      if name == name1 and i == n:
        let buff = d.getDispositionChunk()
        return buff
      else:
        i += 1
        continue
    else:
      continue
  return ""

# get filename of the name
proc getFileName*(dispositions: seq[string], name:string, n=0): string =
  var name1: string
  var i = 0
  for d in dispositions:
    if d.isWithChunk() == true:
      name1 = d.getDispositionName()
      if name == name1 and i == n:
        return d.getDispositionFileName().decodeUrl()
      else:
        i += 1
        continue
    else:
      continue
  return ""
  
# get count of dispositions which contains a chunk.
proc getChunkCount*(dispositions: seq[string]): int =
  var n = 0
  for d in dispositions:
    if d.isWithChunk() == true:
      n += 1
  return n


# start if main (for test)
when isMainModule:
  import std/strformat
  var headerData = {"accept":"text/html", "content-type":"multipart/form-data; boundary=---------------------------26767473973547735812633686047", "content-length":"618"}
  headers = newHttpHeaders(headerData)
  var boundary = getBoundary(headers)
  echo boundary
  var body = """-----------------------------26767473973547735812633686047
Content-Disposition: form-data; name="file1"; filename="CGIgw.ps1"
Content-Type: application/octet-stream

if ($args.length -le 0) {
  python D:\workspace\Scripts\Python3\bin\CGIInterpreter.py
}
else {
  python D:\workspace\Scripts\Python3\bin\CGIInterpreter.py $args[0]
}
-----------------------------26767473973547735812633686047
Content-Disposition: form-data; name="title"

TITLE
-----------------------------26767473973547735812633686047
Content-Disposition: form-data; name="path"

/post_request_json
-----------------------------26767473973547735812633686047
Content-Disposition: form-data; name="methods"

GET,POST
-----------------------------26767473973547735812633686047
Content-Disposition: form-data; name="query"

id
-----------------------------26767473973547735812633686047
Content-Disposition: form-data; name="info"

GetRow medaka by id
-----------------------------26767473973547735812633686047--"""

  var disps = getDispositions(body, boundary)
  var name, value, filename, chunk: string
  var with_chunk: bool
  for b in disps:
    echo b
  echo "(Parameters)"
  for b in disps:
    with_chunk = b.isWithChunk()
    echo fmt"with_chunk={with_chunk}"
    name = b.getDispositionName()
    echo fmt"name={name}"
    if with_chunk == false:
      value = b.getDispositionValue()
      echo fmt"value={value}"
    else:
      filename = b.getDispositionFileName()
      echo fmt"filename={filename}"
      chunk= b.getDispositionChunk()
      echo fmt"chunk={chunk}"
  echo "  getValue(name) ..."
  value = disps.getValue("title")
  chunk = disps.getChunk("file1")
  filename = disps.getFileName("file1")
  echo "title=", value
  echo "filename=", filename
  echo "chunk=", chunk
  value = disps.getValue("path")
  echo "path=",value
  value = disps.getValue("query")
  echo  "query=", value
  value = disps.getValue("info")
  echo "info=", value
