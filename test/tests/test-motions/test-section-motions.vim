set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test-section-motions.tex

if empty($INMAKE) | finish | endif

" vint: -ProhibitCommandRelyOnUser

normal ]]
call vimtex#test#assert_equal(line('.'), 4)
normal gg3]]
call vimtex#test#assert_equal(line('.'), 16)

normal gg][
call vimtex#test#assert_equal(line('.'), 9)
normal 16G2][
call vimtex#test#assert_equal(line('.'), 27)
normal 28G][
call vimtex#test#assert_equal(line('.'), 33)

normal 34G[]
call vimtex#test#assert_equal(line('.'), 33)
normal 34G2[]
call vimtex#test#assert_equal(line('.'), 27)
normal 8G[]
call vimtex#test#assert_equal(line('.'), 1)

normal 33G[[
call vimtex#test#assert_equal(line('.'), 28)
normal 3[[
call vimtex#test#assert_equal(line('.'), 10)

silent normal 35G^d][
call vimtex#test#assert_equal(getline('.'), '\chapter{section 7}')
silent normal u

quit!
