set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set fillchars=fold:\ 
set number
set foldcolumn=4

nnoremap q :qall!<cr>

call vimtex#log#set_silent()

let g:vimtex_fold_enabled = 1

silent edit test-envs.tex

if empty($INMAKE) | finish | endif

call assert_equal(1, foldlevel(7))
call assert_match('\\begin{foo}{bar}', foldtextresult(6))

call vimtex#test#finished()
