#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")"
vim -u minivimrc -c 'Vader! *' > /dev/null
