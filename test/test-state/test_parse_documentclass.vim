set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test_parse_documentclass.tex

if empty($INMAKE) | finish | endif

call assert_equal('article', b:vimtex.documentclass)

call vimtex#test#finished()
