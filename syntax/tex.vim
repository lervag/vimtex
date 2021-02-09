" VimTeX - LaTeX plugin for Vim
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
if exists('s:is_loading') | finish | endif
let s:is_loading = 1

" Syntax may be loaded without the main VimTeX functionality, thus we need to
" ensure that the options are loaded!
call vimtex#options#init()


" Load core syntax (does not depend on VimTeX state)
call vimtex#syntax#core#init()

" Load core highlighting rules
call vimtex#syntax#core#init_highlights()

" Initialize buffer local syntax state
let b:vimtex_syntax = {}
call vimtex#syntax#nested#reset()


" Load package specific syntax (may depend on VimTeX state)
if exists('b:vimtex')
  call vimtex#syntax#packages#init()
else
  augroup vimtex_syntax
    autocmd!
    autocmd User VimtexEventInitPost call vimtex#syntax#packages#init()
  augroup END
endif

unlet s:is_loading
