" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#tabularx#load(cfg) abort " {{{1
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
  call vimtex#syntax#core#new_opt('texTabularOpt', {'next': 'texTabularArg', 'contains': 'texComment,@NoSpell'})
  call vimtex#syntax#core#new_arg('texTabularArg', {'contains': '@texClusterTabular'})

  call vimtex#syntax#core#new_arg('texTabularMulti', {'next': 'texTabularArg'})
  call vimtex#syntax#core#new_arg('texTabularLength', {'contains': 'texLength,texCmd'})
  call vimtex#syntax#core#new_arg('texTabularPostPreArg', {'contains': 'texLength,texCmd,texTabularMathdelim'})

  highlight def link texTabularCol        texOpt
  highlight def link texTabularAtSep      texMathDelim
  highlight def link texTabularVertline   texMathDelim
  highlight def link texTabularPostPre    texMathDelim
  highlight def link texTabularMathdelim  texMathRegionDelim
  highlight def link texTabularOpt        texEnvOpt
endfunction

" }}}1
