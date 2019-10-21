set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin indent on

nnoremap q :qall!<cr>

set nomore
set shiftwidth=2
set expandtab
let g:tex_flavor = 'latex'

if !empty($FLAGS)
  if $FLAGS == 1
    let g:vimtex_indent_on_ampersands = 0
  elseif $FLAGS == 2
    let g:vimtex_indent_ignored_envs = ['proof']
  elseif $FLAGS == 3
    let g:vimtex_indent_delims = {'close_indented': 1}
  endif
endif

execute 'silent edit' $FILEIN

if empty($INMAKE) | finish | endif

silent normal! gg=G
execute 'silent write!' $FILEOUT

quit!
