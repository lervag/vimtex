" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#beamer#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'beamer') | return | endif
  let b:vimtex_syntax.beamer = 1

  syntax match texBeamerDelimiter '<\|>' contained
  syntax match texBeamerOpt '<[^>]*>' contained contains=texBeamerDelimiter

  syntax match texStatementBeamer '\\only\(<[^>]*>\)\?' contains=texBeamerOpt
  syntax match texStatementBeamer '\\item<[^>]*>' contains=texBeamerOpt

  syntax match texInputFile
        \ '\\includegraphics<[^>]*>\(\[.\{-}\]\)\=\s*{.\{-}}'
        \ contains=texStatement,texBeamerOpt,texInputCurlies,texInputFileOpt

  call vimtex#syntax#misc#add_to_section_clusters('texStatementBeamer')

  highlight link texStatementBeamer texStatement
  highlight link texBeamerOpt Identifier
  highlight link texBeamerDelimiter Delimiter
endfunction

" }}}1
