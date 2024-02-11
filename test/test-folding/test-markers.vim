set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set fillchars=fold:\ 
set number
set foldcolumn=4

nnoremap q :qall!<cr>

call vimtex#log#set_silent()

let g:vimtex_fold_enabled = 1

silent edit test-markers.tex

if empty($INMAKE) | finish | endif

call assert_equal(0, foldlevel(4))
call assert_equal(1, foldlevel(7))
call assert_equal(0, foldlevel(12))

let g:vimtex_fold_types = {'markers': {'open': '<<:', 'close': ':>>'}}
VimtexReload

call assert_equal(1, foldlevel(12))

call vimtex#test#finished()
