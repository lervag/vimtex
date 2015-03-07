" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('g:vimtex_enabled') && !g:vimtex_enabled
  finish
endif
if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

if exists('g:latex_enabled')
  echohl Error
  echom "vim-latex has been renamed to vimtex!"
  echom "Please see docs for more information (:h vim-latex-namechange)."
  echohl None
  finish
endif

call vimtex#init()

" vim: fdm=marker sw=2
