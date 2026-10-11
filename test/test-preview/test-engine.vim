set nocompatible
set runtimepath^=../..
filetype plugin on

nnoremap q :qall!<cr>

if empty($INMAKE) | finish | endif

" No TeX program directive
silent edit test.tex
call assert_equal('pdflatex', vimtex#preview#get_engine())

" The engine of the compiler respects the TeX program directive
silent edit test-engine.tex
call assert_equal('lualatex', vimtex#preview#get_engine())

" Without a compiler, the TeX program directive is used directly
let g:vimtex_compiler_enabled = 0
silent VimtexReloadState
call assert_false(has_key(b:vimtex, 'compiler'))
call assert_equal('lualatex', vimtex#preview#get_engine())

call vimtex#test#finished()
