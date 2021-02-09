" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#mathtools#load(cfg) abort " {{{1
  call vimtex#syntax#packages#load('amsmath')

  " Support for various envionrments with option groups
  syntax match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathToolsOptPos1 "\\begin{aligned}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathToolsOptPos1 "\\begin{[lr]gathered}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathToolsOptPos1 "\\begin{[pbBvV]\?\%(small\)\?matrix\*}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathToolsOptPos2 "\\begin{multlined}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv                               "\\end{aligned}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv                               "\\end{[lr]gathered}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv                               "\\end{[pbBvV]\?\%(small\)\?matrix\*}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv                               "\\end{multlined}"
  call vimtex#syntax#core#new_opt('texMathToolsOptPos1', {'contains': ''})
  call vimtex#syntax#core#new_opt('texMathToolsOptPos2', {'contains': '', 'next': 'texMathToolsOptWidth'})
  call vimtex#syntax#core#new_opt('texMathToolsOptWidth', {'contains': 'texLength'})

  highlight def link texMathToolsOptPos1  texOpt
  highlight def link texMathToolsOptPos2  texOpt
  highlight def link texMathToolsOptWidth texOpt
endfunction

" }}}1
