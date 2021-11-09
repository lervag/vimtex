" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#chemformula#load(cfg) abort " {{{1
  syntax match texCHSymb contained "->\|+\|-"

  syntax region texCHText matchgroup=texDelim keepend start=/"/ end=/"/
        \ contains=TOP,@NoSpell
  syntax region texCHText matchgroup=texDelim keepend start=/'/ end=/'/
        \ contains=TOP,@NoSpell

  syntax match texCmdCH "\\ch\>"
        \ nextgroup=texCHOpt,texCHArg skipwhite skipnl
  syntax match texMathCmdCH "\\ch\>" contained
        \ nextgroup=texCHOpt,texCHArg skipwhite skipnl
  call vimtex#syntax#core#new_opt('texCHOpt', {'next': 'texCHArg'})
  call vimtex#syntax#core#new_arg('texCHArg', {
        \ 'contains': 'texCmd,texCHArg,texMathZone,texMathZoneX,texCHSymb,texCHText'
        \})

  syntax cluster texClusterMath add=texMathCmdCH

  highlight def link texCmdCH       texCmd
  highlight def link texMathCmdCH   texMathCmd
  highlight def link texCHOpt       texOpt
  highlight def link texCHArg       texArg
  highlight def link texCHSymb      texSymbol
endfunction

" }}}1
