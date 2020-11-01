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
  syntax match texDelimMathmodeTab /\$\$\?/ contained

  syntax match texCmdTabular '\\begin{tabular}'
        \ nextgroup=texOptEnvModifierTab,texArgTabular skipwhite skipnl contains=texCmdEnv
  call vimtex#syntax#core#new_cmd_opt('texOptEnvModifierTab', 'texArgTabular', 'texComment,@NoSpell')
  call vimtex#syntax#core#new_cmd_arg('texArgTabular', '', 'texTabular.*')

  call vimtex#syntax#core#new_cmd_arg('texTabularMulti', 'texArgTabular')
  call vimtex#syntax#core#new_cmd_arg('texTabularLength', '', 'texLength,texCmd')
  call vimtex#syntax#core#new_cmd_arg('texTabularPostPreArg', '', 'texLength,texCmd,texDelimMathmodeTab')

  highlight def link texTabularCol        texOpt
  highlight def link texTabularAtSep      texDelimMath
  highlight def link texTabularVertline   texDelimMath
  highlight def link texTabularPostPre    texDelimMath
  highlight def link texOptEnvModifierTab texOptEnvModifier
  highlight def link texDelimMathmodeTab  texDelimMathmode
endfunction

" }}}1
