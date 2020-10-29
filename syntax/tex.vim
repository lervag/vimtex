" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"
"
" This script is a fork of version 119 (dated 2020-06-29) of the syntax script
" "tex.vim" created and maintained by Charles E. Campbell [0].
"
" [0]: http://www.drchip.org/astronaut/vim/index.html#SYNTAX_TEX

if !get(g:, 'vimtex_syntax_enabled', 1) | finish | endif
if exists('b:current_syntax') | finish | endif

" Syntax may be loaded without the main vimtex functionality, thus we need to
" ensure that the options are loaded!
call vimtex#options#init()


" Load core syntax (does not depend on vimtex state)
call vimtex#syntax#core#init()


" Initialize buffer local syntax state
let b:vimtex_syntax = {}
call vimtex#syntax#misc#include_reset()


" Load package specific syntax (may depend on vimtex state)
if exists('b:vimtex')
  call vimtex#syntax#packages#init()
else
  augroup vimtex_syntax
    autocmd!
    autocmd User VimtexEventInitPost ++once call vimtex#syntax#packages#init()
  augroup END
endif
