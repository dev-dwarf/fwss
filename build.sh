#!/bin/sh
cd $(dirname "$0")
zip -r ../builds/fwss-src.zip ./* -x "*git*" -x "lurker.lua" -x "lume.lua"

pushd ../builds/
bun love.js -c -t fwss fwss-src.zip fwss/

pushd fwss
# overwrite html to remove bullshit
cp ../../fwss/index.html ./

# delete crap
rm -r theme

zip -r ../fwss.zip ./*
popd

rm fwss-src.zip

butler push fwss.zip dev-dwarf/fwss:html
