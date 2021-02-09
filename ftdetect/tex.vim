" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !get(g:, 'vimtex_enabled', 1)
      \ || get(g:, 'tex_flavor', 'latex') !=# 'latex'
  finish
endif

" For some reason, it seems the best way to ensure filetype "tex" is to just
" set the g:tex_flavor option. Overriding the autocmds or similar seems to make
" startup slower, for some unknown reason.
let g:tex_flavor = 'latex'
