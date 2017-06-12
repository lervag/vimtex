" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

let g:vimtex#re#not_bslash =  '\v%(\\@<!%(\\\\)*)@<='
let g:vimtex#re#not_comment = '\v%(' . g:vimtex#re#not_bslash . '\%.*)@<!'

let g:vimtex#re#tex_input_latex = '\v\\%(input|include|subfile)\s*\{'
let g:vimtex#re#tex_input_import = 
      \ '\v\\%(sub)?%(import|%(input|include)from)\*?\{[^\}]*\}\{'
let g:vimtex#re#tex_input = '\v%(' . join([
      \   g:vimtex#re#tex_input_latex,
      \   g:vimtex#re#tex_input_import,
      \ ], '|') . ')'

" vim: fdm=marker sw=2
