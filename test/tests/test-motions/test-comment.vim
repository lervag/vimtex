set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test-comment-motions.tex

if empty($INMAKE) | finish | endif

" vint: -ProhibitCommandRelyOnUser

normal ]*
call vimtex#test#assert_equal(line('.'), 6)

normal ]*
call vimtex#test#assert_equal(line('.'), 12)

normal 2[/
call vimtex#test#assert_equal(line('.'), 3)

normal ]/
call vimtex#test#assert_equal(line('.'), 10)

quit!
