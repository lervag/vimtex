" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#tabularx#load(cfg) abort " {{{1
  syntax match texTabularCol       "[lcr]"  contained
  syntax match texTabularCol       "[pmb]"  contained nextgroup=texTabularLength
  syntax match texTabularCol       "\*"     contained nextgroup=texTabularMulti
  syntax match texTabularAtSep     "@"      contained nextgroup=texTabularLength
  syntax match texTabularVertline  "||\?"   contained
  syntax match texTabularPostPre   "[<>]"   contained nextgroup=texTabularPostPreArg
  syntax match texTabularMathdelim "\$\$\?" contained
  syntax cluster texClusterTabular contains=texTabular.*

  syntax match texTabularCmd contained nextgroup=texTabularCmdOpt,texTabularCmdArg skipwhite skipnl "\\\a\+"
  call vimtex#syntax#core#new_opt('texTabularCmdOpt', {'next': 'texTabularCmdArg'})
  call vimtex#syntax#core#new_arg('texTabularCmdArg', {
        \ 'next': 'texTabularCmdArg',
        \ 'opts': 'contained transparent',
        \})


  syntax match texCmdTabular "\\begin{tabular}"
        \ nextgroup=texTabularOpt,texTabularArg skipwhite skipnl contains=texCmdEnv
  call vimtex#syntax#core#new_opt('texTabularOpt', {'next': 'texTabularArg', 'contains': 'texComment,@NoSpell'})
  call vimtex#syntax#core#new_arg('texTabularArg', {'contains': '@texClusterTabular'})

  call vimtex#syntax#core#new_arg('texTabularMulti', {'next': 'texTabularArg'})
  call vimtex#syntax#core#new_arg('texTabularLength', {'contains': 'texLength,texCmd'})
  call vimtex#syntax#core#new_arg('texTabularPostPreArg', {'contains': 'texLength,texTabularCmd,texTabularMathdelim'})

  syntax match texCmdNewcolumn "\\newcolumntype\>"
        \ nextgroup=texCmdNewcolumnName,texNewcolumnArgName skipwhite skipnl
  syntax match texCmdNewcolumnName contained "\\\w\+"
        \ nextgroup=texNewcolumnOpt,texNewcolumnArg skipwhite skipnl
  call vimtex#syntax#core#new_arg('texNewcolumnArgName', {
        \ 'next': 'texNewcolumnOpt,texNewcolumnArg',
        \})

  call vimtex#syntax#core#new_opt('texNewcolumnOpt', {
        \ 'next': 'texNewcolumnArg',
        \ 'opts': 'oneline',
        \})
  call vimtex#syntax#core#new_arg('texNewcolumnArg', {'contains': '@texClusterTabular'})
  syntax match texNewcolumnParm contained "#\d\+"
        \ containedin=texNewcolumnArg,texTabularPostPreArg,texTabularCmdArg

  highlight def link texTabularCmd        texCmd
  highlight def link texTabularCmdOpt     texOpt
  highlight def link texCmdNewcolumn      texCmd
  highlight def link texCmdNewcolumnName  texCmd
  highlight def link texNewcolumnArgName  texArg
  highlight def link texNewcolumnOpt      texOpt
  highlight def link texNewcolumnParm     texParm
  highlight def link texTabularCol        texOpt
  highlight def link texTabularAtSep      texMathDelim
  highlight def link texTabularVertline   texMathDelim
  highlight def link texTabularPostPre    texMathDelim
  highlight def link texTabularMathdelim  texMathDelimRegion
  highlight def link texTabularOpt        texEnvOpt
endfunction

" }}}1
