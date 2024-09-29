" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#mathtools#load(cfg) abort " {{{1
  call vimtex#syntax#packages#load('amsmath')

  " Support for shortintertext
  if g:vimtex_syntax_conceal.styles
    syntax match texMathCmdText "\\shortintertext" contained skipwhite nextgroup=texMathTextConcArg conceal
  else
    syntax match texMathCmdText "\\shortintertext" contained skipwhite nextgroup=texMathTextArg
  endif

  " Support for various environments with option groups
  syntax match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathToolsOptPos1 "\%#=1\v\\begin\{%(
        \aligned
        \|[lr]gathered
        \|[pbBvV]?%(small)?matrix\*
        \)\}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathToolsOptPos2 "\\begin{multlined}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv                               "\%#=1\v\\end\{%(
        \aligned
        \|[lr]gathered
        \|[pbBvV]?%(small)?matrix\*
        \|multlined
        \)\}"
  call vimtex#syntax#core#new_opt('texMathToolsOptPos1', {'contains': ''})
  call vimtex#syntax#core#new_opt('texMathToolsOptPos2', {'contains': '', 'next': 'texMathToolsOptWidth'})
  call vimtex#syntax#core#new_opt('texMathToolsOptWidth', {'contains': 'texLength'})

  highlight def link texMathToolsOptPos1  texOpt
  highlight def link texMathToolsOptPos2  texOpt
  highlight def link texMathToolsOptWidth texOpt
endfunction

" }}}1
