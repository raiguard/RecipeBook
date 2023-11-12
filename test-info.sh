#!/usr/bin/env sh

fmm sync RecipeBook
for mod in "base" "Krastorio2" "space-exploration" "IndustrialRevolution3" "galdocs-manufacturing" "freight-forwarding" "pyalternativeenergy"; do
  output=$(mktemp -d "${TMPDIR:-/tmp}"/kak.XXXXXXXX)/fifo
  mkfifo ${output}
  ( frun --start-game-load-scenario RecipeBook/test-info-pages > ${output} 2>&1 & ) > /dev/null 2>&1 < /dev/null
  pid=$!
  echo "PID: $pid"
  while true; do
   if read line; then
     echo $line
     if [ $(echo $line | grep -c "<< TEST COMPLETE >>") -gt 0 ]; then
       kill $pid
     fi
   fi
  done < $output
done
