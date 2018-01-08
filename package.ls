#!/usr/bin/env lsc -cj
#

# Known issue:
#   when executing the `package.ls` directly, there is always error
#   "/usr/bin/env: lsc -cj: No such file or directory", that is because `env`
#   doesn't allow space.
#
#   More details are discussed on StackOverflow:
#     http://stackoverflow.com/questions/3306518/cannot-pass-an-argument-to-python-with-usr-bin-env-python
#
#   The alternative solution is to add `envns` script to /usr/bin directory
#   to solve the _no space_ issue.
#
#   Or, you can simply type `lsc -cj package.ls` to generate `package.json`
#   quickly.
#

# package.json
#
name: \ifdb-008-size-analyzer

author:
  name: \yagamy
  email: \yagamy@t2t.io

description: 'The size distribution analyzer for the points of series in Influxdb v0.8.8'

version: \0.0.1

repository:
  type: \git
  url: ''

engines:
  node: \8.9.4

main: \lib/client.js

scripts:
  build: """
    mkdir -p ./lib && \\
    node ./node_modules/browserify/bin/cmd.js \\
      --node \\
      --extension=ls \\
      -t browserify-livescript \\
      --standalone Client \\
      --external="socket.io-client" \\
      --outfile ./lib/client.js \\
      ./src/client-nodejs.ls
  """
  test: "dms db delete sandbox && lsc -c ./tests/*.ls && ava --verbose"

dependencies:
  colors: \*
  async: \*
  lodash: \*
  mermaid: \*
  mkdirp: \*
  yargs: \*


devDependencies:
  browserify: \*
  \browserify-livescript : \*

keywords: <[influxdb size analyzer]>

license: \MIT
