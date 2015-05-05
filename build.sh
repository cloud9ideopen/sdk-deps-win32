#!/bin/bash -e

# 
# get all dependencies for c9
# node.exe  -
# pty.js    - 
# sqlite3   -
# 

### node

cd `dirname $0`
SOURCE=`pwd`

NODE_VERSION=v0.12.2
if ! [[ -f node.exe && `node.exe --version` == $NODE_VERSION ]]; then
    curl -OL http://nodejs.org/dist/$NODE_VERSION/node.exe
fi

mkdir -p node_modules
npm install npm@latest --production

rm -rf node_modules/npm/doc
rm -rf node_modules/npm/man
rm -rf node_modules/npm/test
rm -rf node_modules/npm/html

cat $SOURCE/node_modules/.bin/npm | sed "s/\.\./node_modules/" >  $SOURCE/npm
cat $SOURCE/node_modules/.bin/npm.cmd | sed "s/\.\./node_modules/" >  $SOURCE/.cmd


if ! [ -d pty.js ]; then
    git clone git://github.com/cloud9ide/pty.js.git
fi



### pty.js
PATH="$SOURCE:$PATH"
echo `which npm`

pushd pty.js
git submodule update --init --recursive
npm install --production
popd

# cleanup
cp -R pty.js node_modules
pushd node_modules/pty.js
rm -rf tmp
mkdir -p tmp
cp build/Release/pty.node tmp/pty.node
cp build/Release/winpty.dll tmp/winpty.dll
cp build/Release/winpty-agent.exe tmp/winpty-agent.exe
rm -rf build

mkdir -p build/Release
cp tmp/* build/Release
rm -rf tmp
rm -rf .git
rm -rf deps
rm -rf node_modules/nan
rm -rf test

popd

# node -e "p=require('pty.js').spawn('bash.exe', ['-c', ' exit 0']);p.on('exit', function(e){if(e) process.exit(1)})"

### sqlite3
npm install sqlite3@3.0.5 --production
rm -rf node_modules/sqlite3/deps
rm -rf node_modules/sqlite3/node_modules/node-pre-gyp
rm -rf node_modules/sqlite3/node_modules/nan



mkdir -p ./releases
tar -zcvf ./releases/node.tar.gz --exclude="./.git" --exclude="./pty.js" --exclude="./release*"  --exclude="./msys" .
tar -zcvf ./releases/msys.tar.gz --exclude="./.git" msys

### upload
getGitToken() {
    token=`git config github.token` || true
    if [ "$token" == "" ]; then
        echo "Could not find token, run 'git config --global github.token <token>'"
        exit 1
    fi
    auth=$token:x-oauth-basic
}
createRelease() {
    getGitToken
    repoName="sdk-deps-win32" 
    name="v0.0.1"
    owner=cloud9ide
    curl -u "$auth" https://api.github.com/repos/$owner/$repoName/releases  -X POST -d '{
        "tag_name": "'$name'",
        "target_commitish": "master",
        "name": "'$name'",
        "body": "Description of the release",
        "draft": true,
        "prerelease": false
    }' # > /dev/null 2>&1
    # TODO upload
    # curl -u "$auth"  https://api.github.com/repos/$owner/$repoName/releases -X GET
    # POST https://<upload_url>/repos/:owner/:repo/releases/:id/assets?name=foo.zip
}