" VimTeX - LaTeX plugin for Vim
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

" Check for plugin clashes.
" Note: This duplicates the code in health/vimtex.vim:s:check_plugin_clash()
let s:scriptnames = vimtex#util#command('scriptnames')

let s:latexbox = !empty(filter(copy(s:scriptnames), "v:val =~# 'latex-box'"))
if s:latexbox
  call vimtex#log#warning([
        \ 'Conflicting plugin detected: LaTeX-Box',
        \ 'VimTeX does not work as expected when LaTeX-Box is installed!',
        \ 'Please disable or remove it to use VimTeX!',
        \])
endif
