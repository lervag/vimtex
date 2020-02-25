set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore
set hidden

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

if empty($INMAKE) | finish | endif

silent edit test_reload.cls

call vimtex#test#assert_equal(len(vimtex#state#list_all()), 1)
silent VimtexReload
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 1)

quitall!
