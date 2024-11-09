$src = "medaka.nim"
"Compiling $src ..."
nim --hints:off --debugger:native --outdir:bin c $src
if ($LASTEXITCODE -eq 0) {
  $out = "... Saved to './bin/medaka.exe'"
  echo $out
}
else {
  echo "Failed."
}
