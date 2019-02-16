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

if !(!get(g:, 'vimtex_version_check', 1)
      \ || has('nvim-0.1.7')
      \ || v:version >= 704)
  echoerr 'Error: vimtex does not support your version of Vim'
  echom 'Please update to Vim 7.4 or neovim 0.1.7 or later!'
  echom 'For more info, please see :h vimtex_version_check'
  finish
endif

call vimtex#init()
