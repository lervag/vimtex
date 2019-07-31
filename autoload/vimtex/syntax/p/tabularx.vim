" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#tabularx#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'tabularx') | return | endif
  let b:vimtex_syntax.tabularx = 1

  call vimtex#syntax#misc#add_to_section_clusters('texTabular')

  syntax match texTabular '\\begin{tabular}\_[^{]\{-}\ze{'
        \ contains=texBeginEnd
        \ nextgroup=texTabularArg
        \ contained
  syntax region texTabularArg matchgroup=Delimiter
        \ start='{' end='}'
        \ contained

  syntax match texTabularCol /[lcr]/
        \ containedin=texTabularArg
        \ contained
  syntax match texTabularCol /[pmb]/
        \ containedin=texTabularArg
        \ nextgroup=texTabularLength
        \ contained
  syntax match texTabularCol /\*/
        \ containedin=texTabularArg
        \ nextgroup=texTabularMulti
        \ contained
  syntax region texTabularMulti matchgroup=Delimiter
        \ start='{' end='}'
        \ containedin=texTabularArg
        \ nextgroup=texTabularArg
        \ contained

  syntax match texTabularAtSep /@/
        \ containedin=texTabularArg
        \ nextgroup=texTabularLength
        \ contained
  syntax match texTabularVertline /||\?/
        \ containedin=texTabularArg
        \ contained
  syntax match texTabularPostPre /[<>]/
        \ containedin=texTabularArg
        \ nextgroup=texTabularPostPreArg
        \ contained

  syntax region texTabularPostPreArg matchgroup=Delimiter
        \ start='{' end='}'
        \ containedin=texTabularArg
        \ contains=texLength,texStatement,texMathDelimSingle
        \ contained

  syntax region texTabularLength matchgroup=Delimiter
        \ start='{' end='}'
        \ containedin=texTabularArg
        \ contains=texLength,texStatement
        \ contained

  syntax match texMathDelimSingle /\$\$\?/
        \ containedin=texTabularPostPreArg
        \ contained

  highlight def link texTabularCol        Directory
  highlight def link texTabularAtSep      Type
  highlight def link texTabularVertline   Type
  highlight def link texTabularPostPre    Type
  highlight def link texMathDelimSingle   Delimiter
endfunction

" }}}1
