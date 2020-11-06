" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#tabularx#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'tabularx') | return | endif
  let b:vimtex_syntax.tabularx = 1

  syntax match texTabularCol       /[lcr]/  contained
  syntax match texTabularCol       /[pmb]/  contained nextgroup=texTabularLength
  syntax match texTabularCol       /\*/     contained nextgroup=texTabularMulti
  syntax match texTabularAtSep     /@/      contained nextgroup=texTabularLength
  syntax match texTabularVertline  /||\?/   contained
  syntax match texTabularPostPre   /[<>]/   contained nextgroup=texTabularPostPreArg
  syntax match texTabularMathdelim /\$\$\?/ contained
  syntax cluster texClusterTabular contains=texTabular.*

  syntax match texCmdTabular '\\begin{tabular}'
        \ nextgroup=texTabularOpt,texTabularArg skipwhite skipnl contains=texCmdEnv
  call vimtex#syntax#core#new_cmd_opt('texTabularOpt', 'texTabularArg', 'texComment,@NoSpell')
  call vimtex#syntax#core#new_cmd_arg('texTabularArg', '', '@texClusterTabular')

  call vimtex#syntax#core#new_cmd_arg('texTabularMulti', 'texTabularArg')
  call vimtex#syntax#core#new_cmd_arg('texTabularLength', '', 'texLength,texCmd')
  call vimtex#syntax#core#new_cmd_arg('texTabularPostPreArg', '', 'texLength,texCmd,texTabularMathdelim')

  highlight def link texTabularCol        texOpt
  highlight def link texTabularAtSep      texMathDelim
  highlight def link texTabularVertline   texMathDelim
  highlight def link texTabularPostPre    texMathDelim
  highlight def link texTabularMathdelim  texMathRegionDelim
  highlight def link texTabularOpt        texEnvOpt
endfunction

" }}}1
