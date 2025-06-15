set nocompatible
set runtimepath^=../..
filetype plugin on

nnoremap q :qall!<cr>

call vimtex#log#set_silent()

silent edit test_parse_package_options.tex

if empty($INMAKE) | finish | endif

let s:packages = {
      \ 'glossaries-extra': {'style': 'long', 'record': v:true},
      \ 'biblatex': {
      \    'backend': 'biber',
      \    'url': v:false,
      \    'giveninits': v:true,
      \    'style': 'numeric-comp',
      \    'maxcitenames': '99'
      \ },
      \ 'glossaries': {'acronyms': v:true},
      \ 'tikz': {},
      \ 'babel' : {'main': 'german', 'english': v:true},
      \ 'silence': {'debrief': v:true},
      \ 'package1': {'draft': v:true},
      \ 'biblatex-chicago': {'notes': v:true, 'useibid': v:true},
      \ 'amsmath': {},
      \ 'package2': {'draft': v:true},
      \ 'package': {'key': ''}
      \ }
call assert_equal(s:packages, b:vimtex.packages)

call vimtex#test#finished()
