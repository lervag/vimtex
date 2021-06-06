set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

if empty($INMAKE) | finish | endif

" Open included file should create two states (main and included)
call assert_equal(len(vimtex#state#list_all()), 0)
silent edit included.tex
call assert_equal(len(vimtex#state#list_all()), 2)

" If we toggle to the included state then wipe it, we should not cleanup the
" main state
silent VimtexToggleMain
bwipeout
call assert_equal(len(vimtex#state#list_all()), 1)

"
" The main state should be cleaned up when we exit, though!
"

let g:test = 0
augroup Testing
  autocmd!
  autocmd User VimtexEventQuit let g:test += 1
augroup END

function! Finalize() abort
  call assert_equal(g:test, 1)
  call vimtex#test#finished()
endfunction

autocmd Testing VimLeave * call Finalize()
quitall!
