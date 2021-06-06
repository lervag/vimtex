set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test-section.tex

if empty($INMAKE) | finish | endif

" vint: -ProhibitCommandRelyOnUser

normal ]]
call assert_equal(line('.'), 4)
normal gg3]]
call assert_equal(line('.'), 16)

normal gg][
call assert_equal(line('.'), 9)
normal 16G2][
call assert_equal(line('.'), 27)
normal 28G][
call assert_equal(line('.'), 33)

normal 34G[]
call assert_equal(line('.'), 33)
normal 34G2[]
call assert_equal(line('.'), 27)
normal 8G[]
call assert_equal(line('.'), 1)

normal 33G[[
call assert_equal(line('.'), 28)
normal 3[[
call assert_equal(line('.'), 10)

silent normal 35G^d][
call assert_equal(getline('.'), '\chapter{section 7}')
silent normal u

call vimtex#test#finished()
