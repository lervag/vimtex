set nocompatible
let &rtp = '../..,' . &rtp

nnoremap q :qall!<cr>

let s:lines = vimtex#parser#preamble('test_preamble_include.tex')

call vimtex#test#assert_equal(
      \ readfile('test_preamble_include.ref'),
      \ s:lines)

quitall!
