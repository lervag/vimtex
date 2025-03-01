set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin indent on
syntax enable

set nomore

nnoremap q :qall!<cr>

silent edit glossaries.tex

if empty($INMAKE) | finish | endif

let s:handler = vimtex#context#get(15, 9).handler
call assert_equal('isbn', s:handler.selected)
let s:actions = s:handler.get_actions()
call assert_equal(6, len(s:actions.entry))

call vimtex#test#finished()
