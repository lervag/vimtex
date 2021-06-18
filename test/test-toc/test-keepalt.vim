set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit main.tex
silent edit main.aux
silent edit #

let s:alt = bufnr('#')

VimtexTocOpen
normal q

if empty($INMAKE) | finish | endif

call assert_equal(s:alt, bufnr('#'))
call vimtex#test#finished()
