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

  syntax match texCmdBeamer '\\only\(<[^>]*>\)\?' contains=texBeamerOpt
  syntax match texCmdBeamer '\\item<[^>]*>' contains=texBeamerOpt

  syntax match texCmd "\\includegraphics<[^>]*>"
        \ contains=texBeamerOpt,
        \ nextgroup=texOptGenericFile,texFilename

  highlight link texCmdBeamer texCmd
  highlight link texBeamerOpt texCmdArgs
  highlight link texBeamerDelimiter texDelimiter
endfunction

" }}}1
