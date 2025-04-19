set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test-fakesection.tex

if empty($INMAKE) | finish | endif

" vint: -ProhibitCommandRelyOnUser

normal 2][
call assert_equal(10, line('.'))
normal gg3]]
call assert_equal(11, line('.'))

call vimtex#test#finished()
