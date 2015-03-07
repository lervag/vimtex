" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists("current_compiler") | finish | endif
let current_compiler = "lacheck"

CompilerSet makeprg=lacheck\ %
CompilerSet errorformat="%f",\ line\ %l:\ %m
