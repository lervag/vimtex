" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !exists('b:current_syntax') || b:current_syntax !=# 'tex'
  echoerr 'vimtex syntax error: please report issue!'
  finish
endif

" Better support for cite commands
" \cite, \citep, \citet, \citeauthor, ...
syntax match texRefZone
      \ "\\\%(auto\|text\)\?cite\%([tp]\*\?\|author\)\?"
      \ nextgroup=texRefOption,texCite

" Add support for cleveref package
" \Cref, \cref, \cpageref, \labelcref, \labelcpageref
syntax region texRefZone matchgroup=texStatement
      \ start="\\\(\(label\)\?c\(page\)\?\|C\|auto\)ref{"
      \ end="}\|%stopzone\>"
      \ contains=@texRefGroup

" \crefrange, \cpagerefrange (these commands expect two arguments)
syntax match texStatement
      \ '\\c\(page\)\?refrange\>'
      \ nextgroup=texRefRangeStart skipwhite skipnl
syntax region texRefRangeStart
      \ start="{"rs=s+1  end="}"
      \ matchgroup=Delimiter
      \ contained contains=texRefZone
      \ nextgroup=texRefRangeEnd skipwhite skipnl
syntax region texRefRangeEnd
      \ start="{"rs=s+1 end="}"
      \ matchgroup=Delimiter
      \ contained contains=texRefZone
highlight link texRefRangeStart texRefZone
highlight link texRefRangeEnd   texRefZone

" Support for listings package
syntax region texZone
      \ start="\\begin{lstlisting}"
      \ end="\\end{lstlisting}\|%stopzone\>"
syntax match texInputFile
      \ "\\lstinputlisting\s*\(\[.*\]\)\={.\{-}}"
      \ contains=texStatement,texInputCurlies,texInputFileOpt
syntax match texZone "\\lstinline\s*\(\[.*\]\)\={.\{-}}"

" Nested syntax highlighting for dot
unlet b:current_syntax
syntax include @DOT syntax/dot.vim
syntax region texZone
      \ matchgroup=texRefZone
      \ start="\\begin{dot2tex}"
      \ matchgroup=texRefZone
      \ end="\\end{dot2tex}"
      \ keepend
      \ transparent
      \ contains=@DOT
let b:current_syntax = 'tex'

" vim: fdm=marker sw=2
