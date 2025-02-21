" VimTeX - LaTeX plugin for Vim
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
      \ || has('nvim-0.10')
      \ || has('patch-9.1.16'))
  echoerr 'Error: VimTeX does not support your version of Vim'
  echom 'Please update to Vim 9.1.16 or neovim 0.10 or later!'
  echom 'For more info, please see :h vimtex_version_check'
  finish
endif

call vimtex#init()
