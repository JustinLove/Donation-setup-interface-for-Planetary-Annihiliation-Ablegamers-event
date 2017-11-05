cp -R public/* dist
node bin/r.js -o baseUrl=public name=almond include=donate-main out=dist/require-donate.js paths.requireLib=require
