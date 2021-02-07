" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#array#load(cfg) abort " {{{1
  " For reference, refer to the docs:
  " https://texdoc.org/serve/array/0

  syntax match texTabularCol       "[mb]"   contained nextgroup=texTabularLength
  syntax match texTabularCol       "\*"     contained nextgroup=texTabularMulti
  syntax match texTabularVertline  "||\?"   contained
  syntax match texTabularPostPre   "[<>]"   contained nextgroup=texTabularPostPreArg
  syntax match texTabularMathdelim "\$\$\?" contained

  call vimtex#syntax#core#new_arg('texTabularMulti', {'next': 'texTabularArg'})
  call vimtex#syntax#core#new_arg('texTabularPostPreArg', {
        \ 'contains': 'texLength,texTabularCmd,texTabularMathdelim'
        \})

  syntax match texTabularCmd "\\\a\+"
        \ contained nextgroup=texTabularCmdOpt,texTabularCmdArg
        \ skipwhite skipnl
  call vimtex#syntax#core#new_opt('texTabularCmdOpt', {
        \ 'next': 'texTabularCmdArg'
        \})
  call vimtex#syntax#core#new_arg('texTabularCmdArg', {
        \ 'next': 'texTabularCmdArg',
        \ 'opts': 'contained transparent',
        \})

  syntax cluster texClusterTabular
        \ add=texTabularVertline,texTabularPostPre,texTabularMathdelim

  highlight def link texTabularCmd        texCmd
  highlight def link texTabularCmdOpt     texOpt
  highlight def link texTabularVertline   texMathDelim
  highlight def link texTabularPostPre    texMathDelim
  highlight def link texTabularMathdelim  texMathDelimZone
endfunction

" }}}1
