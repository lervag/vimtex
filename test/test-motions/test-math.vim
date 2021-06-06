set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on
syntax on

nnoremap q :qall!<cr>

silent edit test-math.tex

if empty($INMAKE) | finish | endif

" vint: -ProhibitCommandRelyOnUser

normal 19G2]n
call assert_equal(line('.'), 25)

normal 19G]N
call assert_equal(line('.'), 22)

normal 19G2[n
call assert_equal(line('.'), 7)

normal 19G[N
call assert_equal(line('.'), 11)

call vimtex#test#finished()
