" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !get(g:, 'vimtex_enabled', 1)
  finish
endif

if exists('b:did_ftplugin_vimtex')
  finish
endif
let b:did_ftplugin_vimtex = 1

call vimtex#check_plugin_clash()
