set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test-method-motions.tex

if empty($INMAKE) | finish | endif

" vint: -ProhibitCommandRelyOnUser

normal 15G3[m
call vimtex#test#assert_equal(line('.'), 5)

normal 15G]m
call vimtex#test#assert_equal(line('.'), 21)

normal 15G[M
call vimtex#test#assert_equal(line('.'), 10)

normal 15G4]M
call vimtex#test#assert_equal(line('.'), line('$'))

quit!
