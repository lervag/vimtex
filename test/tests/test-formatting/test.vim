set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin indent on
syntax on

nnoremap q :qall!<cr>

set nomore
set textwidth=79
set nojoinspaces
set shiftwidth=2

let g:tex_flavor = 'latex'
let g:vimtex_format_enabled = 1

let s:file = empty($FILE) ? 'test-01' : $FILE


execute 'silent edit' s:file . '.tex'

if empty($INMAKE) | finish | endif

silent normal! gggqG

execute 'silent write!' s:file . '.out'
quit!
