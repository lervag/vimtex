set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on
syntax on

nnoremap q :qall!<cr>

silent edit test-beamer.tex

if empty($INMAKE) | finish | endif

" vint: -ProhibitCommandRelyOnUser

normal 28G2]r
call assert_equal(line('.'), 37)

normal 28G]R
call assert_equal(line('.'), 35)

normal 28G2[r
call assert_equal(line('.'), 7)

normal 28G[R
call assert_equal(line('.'), 20)

call vimtex#test#finished()
