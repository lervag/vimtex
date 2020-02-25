set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

if empty($INMAKE) | finish | endif

silent edit minimal.tex
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 1)

silent edit new1.tex
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 2)

silent edit new2.tex
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 3)

silent bwipeout
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 2)

" Don't clean the state unless it is wiped
silent bdelete
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 2)

silent 2bwipeout
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 1)

" Reload file with 'edit' should not clean states
silent edit
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 1)

silent bwipeout
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 0)

" Open included file should create two states (main and included)
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 0)
silent edit included.tex
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 2)

" Simple test of VimtexEventQuit
let g:test = 0
augroup Testing
  autocmd!
  autocmd User VimtexEventQuit let g:test += 1
augroup END

" Wiping the buffer when main state is active should wipe all states
silent bwipeout
call vimtex#test#assert_equal(len(vimtex#state#list_all()), 0)
call vimtex#test#assert_equal(g:test, 2)

quitall!
