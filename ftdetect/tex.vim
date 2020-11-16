" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !get(g:, 'vimtex_enabled', 1)
      \ || get(g:, 'tex_flavor', 'latex') !=# 'latex'
  finish
endif

autocmd BufNewFile,BufRead *.tex set filetype=tex
