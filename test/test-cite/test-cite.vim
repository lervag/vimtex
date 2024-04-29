set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin indent on
syntax enable

set nomore

nnoremap q :qall!<cr>

silent edit ../test-context-cite/test-cites.tex

if empty($INMAKE) | finish | endif

call assert_equal("Hemingway1940", vimtex#cite#get_key_at(11, 35))
call assert_equal("wilcox.e:2021", vimtex#cite#get_key_at(14, 56))

call vimtex#test#finished()
