#!/usr/bin/env lsc
#
require! <[yargs]>

argv =
  yargs
    .alias \h, \help
    .command require \./src/json2mermaid
    .command require \./src/daily-backup.ls
    .demand 1
    .strict!
    .help!
    .argv