set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on
syntax on

nnoremap q :qall!<cr>

silent edit test.tex

normal! 7G
let s:current = vimtex#delim#get_current('all', 'both')
let s:corresponding = vimtex#delim#get_matching(s:current)
call assert_equal(1, s:corresponding.lnum)

normal! 9G
let s:current = vimtex#delim#get_current('all', 'both')
let s:corresponding = vimtex#delim#get_matching(s:current)
call assert_equal(12, s:corresponding.lnum)
call assert_equal('a', s:current.name)
call assert_equal('d', s:corresponding.name)

call vimtex#test#finished()
