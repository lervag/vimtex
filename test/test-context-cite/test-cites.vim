set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin indent on
syntax enable

set nomore

nnoremap q :qall!<cr>

silent edit test-cites.tex

if empty($INMAKE) | finish | endif

let s:handler = vimtex#context#get(9, 49).handler
call assert_equal('Hemingway1940', s:handler.selected)
let s:actions = s:handler.get_actions()
call assert_equal(9, len(s:actions.entry))

call assert_equal('JiM2020', vimtex#context#get(11, 39).handler.selected)

call vimtex#test#finished()
