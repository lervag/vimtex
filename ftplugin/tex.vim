" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !get(g:, 'vimtex_enabled', 1)
  finish
endif

if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

if !(!get(g:, 'vimtex_version_check', 1) || has('nvim'))
      \ && (v:version < 704 || !has('patch-7.4.52'))
  echoerr 'Error: vimtex does not support your version of Vim'
  echom 'Please update to Vim 7.4.52 or later'
  echom 'Please see :h vimtex_version_check'
  finish
endif

call vimtex#init()

" vim: fdm=marker sw=2
