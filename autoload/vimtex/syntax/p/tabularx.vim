" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#tabularx#load(cfg) abort " {{{1
  call vimtex#syntax#packages#load('array')

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
  call vimtex#syntax#core#new_arg('texNewcolumnArg', {
        \ 'contains': '@texClusterTabular'
        \})
  syntax match texNewcolumnParm contained "#\d\+"
        \ containedin=texNewcolumnArg,texTabularPostPreArg,texTabularCmdArg

  highlight def link texCmdNewcolumn      texCmd
  highlight def link texCmdNewcolumnName  texCmd
  highlight def link texNewcolumnArgName  texArg
  highlight def link texNewcolumnOpt      texOpt
  highlight def link texNewcolumnParm     texParm
endfunction

" }}}1
