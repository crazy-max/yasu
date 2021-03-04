#!/bin/sh
set -ex

yasut() {
  spec="$1"; shift
  expec="$1"; shift

  real="$(yasu "$spec" id -u):$(yasu "$spec" id -g):$(yasu "$spec" id -G)"
  [ "$expec" = "$real" ]

  expec="$1"; shift

  # have to "|| true" this one because of "id: unknown ID 1000" (rightfully) having a nonzero exit code
  real="$(yasu "$spec" id -un):$(yasu "$spec" id -gn):$(yasu "$spec" id -Gn)" || true
  [ "$expec" = "$real" ]
}

id

yasut 0 "0:0:$(id -G root)" "root:root:$(id -Gn root)"
yasut 0:0 '0:0:0' 'root:root:root'
yasut root "0:0:$(id -G root)" "root:root:$(id -Gn root)"
yasut 0:root '0:0:0' 'root:root:root'
yasut root:0 '0:0:0' 'root:root:root'
yasut root:root '0:0:0' 'root:root:root'
yasut 1000 "1000:$(id -g):$(id -g)" "1000:$(id -gn):$(id -gn)"
yasut 0:1000 '0:1000:1000' 'root:1000:1000'
yasut 1000:1000 '1000:1000:1000' '1000:1000:1000'
yasut root:1000 '0:1000:1000' 'root:1000:1000'
yasut 1000:root '1000:0:0' '1000:root:root'
yasut 1000:daemon "1000:$(id -g daemon):$(id -g daemon)" '1000:daemon:daemon'
yasut games "$(id -u games):$(id -g games):$(id -G games)" 'games:games:games users'
yasut games:daemon "$(id -u games):$(id -g daemon):$(id -g daemon)" 'games:daemon:daemon'

yasut 0: "0:0:$(id -G root)" "root:root:$(id -Gn root)"
yasut '' "$(id -u):$(id -g):$(id -G)" "$(id -un):$(id -gn):$(id -Gn)"
yasut ':0' "$(id -u):0:0" "$(id -un):root:root"

[ "$(yasu 0 env | grep '^HOME=')" = 'HOME=/root' ]
[ "$(yasu 0:0 env | grep '^HOME=')" = 'HOME=/root' ]
[ "$(yasu root env | grep '^HOME=')" = 'HOME=/root' ]
[ "$(yasu 0:root env | grep '^HOME=')" = 'HOME=/root' ]
[ "$(yasu root:0 env | grep '^HOME=')" = 'HOME=/root' ]
[ "$(yasu root:root env | grep '^HOME=')" = 'HOME=/root' ]
[ "$(yasu 0:1000 env | grep '^HOME=')" = 'HOME=/root' ]
[ "$(yasu root:1000 env | grep '^HOME=')" = 'HOME=/root' ]
[ "$(yasu 1000 env | grep '^HOME=')" = 'HOME=/' ]
[ "$(yasu 1000:0 env | grep '^HOME=')" = 'HOME=/' ]
[ "$(yasu 1000:root env | grep '^HOME=')" = 'HOME=/' ]
[ "$(yasu games env | grep '^HOME=')" = 'HOME=/usr/games' ]
[ "$(yasu games:daemon env | grep '^HOME=')" = 'HOME=/usr/games' ]

# make sure we error out properly in unexpected cases like an invalid username
! yasu bogus true
! yasu 0day true
! yasu 0:bogus true
! yasu 0:0day true
