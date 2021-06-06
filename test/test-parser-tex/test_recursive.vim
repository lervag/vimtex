set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set nomore
set hidden

nnoremap q :qall!<cr>

if empty($INMAKE) | finish | endif

silent! edit test_recursive.tex

let s:log = vimtex#log#get()
call assert_equal(1, len(s:log))
call assert_equal('Recursive file inclusion!', s:log[0].msg[0])

call vimtex#test#finished()
