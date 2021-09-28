set nocompatible
set runtimepath^=~/.local/plugged/vimtex
filetype plugin indent on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '../.'

silent edit test.tex

call assert_equal(
      \ 'test-kpsewhich-local-b/local.bib',
      \ vimtex#paths#relative(
      \   vimtex#kpsewhich#find('local.bib'),
      \ expand('%:p:h:h')))

call vimtex#test#finished()
