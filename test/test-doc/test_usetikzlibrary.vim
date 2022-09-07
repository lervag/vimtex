set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>
silent edit test.tex

if empty($INMAKE) | finish | endif

call cursor([3, 15])
call assert_equal({
      \ 'type': 'usepackage',
      \ 'candidates': ['amsmath', 'mathtools'],
      \ 'selected': 'amsmath'
      \}, vimtex#doc#get_context())

call cursor([3, 25])
call assert_equal({
      \ 'type': 'usepackage',
      \ 'candidates': ['amsmath', 'mathtools'],
      \ 'selected': 'mathtools'
      \}, vimtex#doc#get_context())

call cursor([5, 10])
call assert_equal({
      \ 'type': 'tikzlibrary',
      \ 'candidates': ['tikz', 'hobby'],
      \}, vimtex#doc#get_context())

call cursor([5, 20])
call assert_equal({
      \ 'type': 'tikzlibrary',
      \ 'candidates': ['tikz', 'hobby'],
      \ 'selected': 'hobby'
      \}, vimtex#doc#get_context())

call vimtex#test#finished()
