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

setlocal comments=sO:%\ -,mO:%\ \ ,eO:%%,:%
setlocal commentstring=\%\ %s

" Initialize local LaTeX state if applicable
let b:vimtex = getbufvar('#', 'vimtex', {})
if empty(b:vimtex) | unlet b:vimtex | finish | endif

" Apply errorformat for properly handling quickfix entries
silent! call b:vimtex.qf.set_errorformat()
