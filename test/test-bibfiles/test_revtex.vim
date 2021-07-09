set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

let g:ready = 0
nnoremap q :qall!<cr>

call vimtex#log#set_silent()

augroup test_revtex
  autocmd!
  autocmd User VimtexEventCompileSuccess let g:ready = 1
  autocmd User VimtexEventCompileFailed cquit
augroup END

silent edit test_revtex.tex

silent VimtexCompileSS

while !g:ready
  sleep 20m
endwhile

if empty($INMAKE) | finish | endif

call assert_equal(['../common/huge.bib'], vimtex#bib#files())

silent VimtexClean!
call delete('test_revtexNotes.bib')
call delete('test_revtex.bbl')
call vimtex#test#finished()
