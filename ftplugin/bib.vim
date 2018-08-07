" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !get(g:, 'vimtex_enabled', 1) || !get(g:, 'vimtex_toc_enabled', 1)
  finish
endif

if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal comments=sO:%\ -,mO:%\ \ ,eO:%%,:%
setlocal commentstring=\%\ %s
