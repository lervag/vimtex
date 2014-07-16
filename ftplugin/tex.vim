" LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('g:latex_enabled') && !g:latex_enabled
  finish
endif
if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

call latex#init()

" vim: fdm=marker
