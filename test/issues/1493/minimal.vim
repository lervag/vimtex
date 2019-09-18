set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

silent edit main.tex

call search('input-b')
execute 'normal gf'
if expand('%') ==# 'input-b.tex'
  echo 'Success'
  quitall!
else
  echo 'Failed -' expand('%')
  cquit!
endif
