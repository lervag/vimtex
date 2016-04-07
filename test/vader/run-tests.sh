#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")"
vim -esNu minivimrc +"Vader! *" >/dev/null
