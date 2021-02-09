" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#siunitx#load(cfg) abort " {{{1
  syntax match texSIDelim contained "[;x]"
  syntax match texSICmd contained "\\\w\+\>"

  syntax match texCmdSI nextgroup=texSIOptU,texSIArgUnit skipwhite "\\si\>"
  call vimtex#syntax#core#new_opt('texSIOptU', {'contains': '', 'next': 'texSIArgUnit'})
  call vimtex#syntax#core#new_arg('texSIArgUnit', {'contains': 'texSICmd'})

  syntax match texCmdSI nextgroup=texSIOptN,texSIArgNum skipwhite "\\num\(list\)\?\>"
  syntax match texCmdSI nextgroup=texSIOptN,texSIArgNum skipwhite "\\ang\>"
  call vimtex#syntax#core#new_opt('texSIOptN', {'contains': '', 'next': 'texSIArgNum'})
  call vimtex#syntax#core#new_arg('texSIArgNum', {'contains': 'texSIDelim'})

  syntax match texCmdSI nextgroup=texSIOptNN,texSIArgNumN skipwhite "\\numrange\>"
  call vimtex#syntax#core#new_opt('texSIOptNN', {'contains': '', 'next': 'texSIArgNumN'})
  call vimtex#syntax#core#new_arg('texSIArgNumN', {'contains': 'texSIDelim'})

  syntax match texCmdSI nextgroup=texSIOptNU,texSIArgNumU skipwhite "\\SI\(list\)\?\>"
  call vimtex#syntax#core#new_opt('texSIOptNU', {'contains': '', 'next': 'texSIArgNumU'})
  call vimtex#syntax#core#new_arg('texSIArgNumU', {'contains': 'texSIDelim', 'next': 'texSIArgUnit'})

  syntax match texCmdSI nextgroup=texSIOptNNU,texSIArgNumNU skipwhite "\\SIrange\>"
  call vimtex#syntax#core#new_opt('texSIOptNNU', {'contains': '', 'next': 'texSIArgNumNU'})
  call vimtex#syntax#core#new_arg('texSIArgNumNU', {'contains': 'texSIDelim', 'next': 'texSIArgNumU'})

  syntax match texMathCmdSI contained nextgroup=texSIOptU,texSIArgUnit skipwhite "\\si\>"
  syntax match texMathCmdSI contained nextgroup=texSIOptN,texSIArgNum skipwhite "\\num\>"
  syntax match texMathCmdSI contained nextgroup=texSIOptNU,texSIArgNumU skipwhite "\\SI\>"
  syntax match texMathCmdSI contained nextgroup=texSIOptNNU,texSIArgNumNU skipwhite "\\SIrange\>"
  syntax cluster texClusterMath add=texMathCmdSI

  highlight def link texCmdSI       texCmd
  highlight def link texMathCmdSI   texMathCmd
  highlight def link texSICmd       texMathCmd
  highlight def link texSIDelim     texSymbol
  highlight def link texSIOpt       texOpt
  highlight def link texSIOptU      texSIOpt
  highlight def link texSIOptN      texSIOpt
  highlight def link texSIOptNU     texSIOpt
  highlight def link texSIOptNNU    texSIOpt
  highlight def link texSIArgUnit   texArg
  highlight def link texSIArgNum    texLength
  highlight def link texSIArgNumN   texSIArgNum
  highlight def link texSIArgNumU   texSIArgNum
  highlight def link texSIArgNumNU  texSIArgNum
  highlight def link texSIArgNumNNU texSIArgNum
endfunction

" }}}1
