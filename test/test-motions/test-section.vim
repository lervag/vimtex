set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test-section.tex

if empty($INMAKE) | finish | endif

" vint: -ProhibitCommandRelyOnUser

normal ]]
call assert_equal(3, line('.'))
normal gg3]]
call assert_equal(11, line('.'))

normal gg][
call assert_equal(4, line('.'))
normal 16G2][
call assert_equal(28, line('.'))
normal 28G][
call assert_equal(34, line('.'))

normal 35G[]
call assert_equal(34, line('.'))
normal 35G2[]
call assert_equal(28, line('.'))
normal 8G[]
call assert_equal(4, line('.'))

normal 33G[[
call assert_equal(29, line('.'))
normal 3[[
call assert_equal(11, line('.'))

silent normal 35G^d][
call assert_equal(getline('.'), '\chapter{section 7}')
silent normal u

" Check file borders top
normal 2G[[
call assert_equal(1, line('.'))

" Check file borders bottom
normal Gk]]
call assert_equal(59, line('.'))

" Check \begin{document}
normal 5G[[
call assert_equal(3, line('.'))

" Check \end{document}
normal G5k]]
call assert_equal(57, line('.'))

call vimtex#test#finished()
