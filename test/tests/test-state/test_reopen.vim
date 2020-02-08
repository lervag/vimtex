set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

if empty($INMAKE) | finish | endif

silent edit minimal.tex
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 1)

bwipeout
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 0)

silent edit minimal.tex
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 1)

bdelete
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 1)

silent edit minimal.tex
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 1)

quitall!
