set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

if empty($INMAKE) | finish | endif

let g:test = 0
augroup Testing
  autocmd!
  autocmd User VimtexEventQuit let g:test += 1
augroup END

silent edit included.tex

" 'hidden' is not set, so quitting should not wipe any states
normal! GOtest
try
  quit
catch /E37/
endtry
call vimtex#test#assert_equal(g:test, 0)

quit!
