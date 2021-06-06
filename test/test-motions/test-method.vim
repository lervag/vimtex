set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test-method.tex

if empty($INMAKE) | finish | endif

" vint: -ProhibitCommandRelyOnUser

normal 15G3[m
call assert_equal(line('.'), 5)

normal 15G]m
call assert_equal(line('.'), 21)

normal 15G[M
call assert_equal(line('.'), 10)

normal 15G4]M
call assert_equal(line('.'), line('$'))

call vimtex#test#finished()
