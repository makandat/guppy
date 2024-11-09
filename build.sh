#!/bin/sh

echo Compiling ...
nim c --outdir: ./bin --debugger:native --hints:off medaka.nim
if [ $? -eq 0 ]; then
  echo "OK"
fi
