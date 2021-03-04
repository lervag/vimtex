" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#amsmath#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_region_math('align')
  call vimtex#syntax#core#new_region_math('alignat')
  call vimtex#syntax#core#new_region_math('flalign')
  call vimtex#syntax#core#new_region_math('gather')
  call vimtex#syntax#core#new_region_math('mathpar')
  call vimtex#syntax#core#new_region_math('multline')
  call vimtex#syntax#core#new_region_math('xalignat')
  call vimtex#syntax#core#new_region_math('xxalignat', {'starred': 0})

  " Amsmath [lr][vV]ert
  if &encoding ==# 'utf-8' && g:vimtex_syntax_conceal.math_delimiters
    syntax match texMathDelim contained conceal cchar=| "\\\%([bB]igg\?l\|left\)\\lvert"
    syntax match texMathDelim contained conceal cchar=| "\\\%([bB]igg\?r\|right\)\\rvert"
    syntax match texMathDelim contained conceal cchar=‖ "\\\%([bB]igg\?l\|left\)\\lVert"
    syntax match texMathDelim contained conceal cchar=‖ "\\\%([bB]igg\?r\|right\)\\rVert"
  endif

  syntax match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathArrayArg skipwhite skipnl "\\begin{subarray}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathArrayArg skipwhite skipnl "\\begin{x\?alignat\*\?}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathArrayArg skipwhite skipnl "\\begin{xxalignat}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv                                            "\\end{subarray}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv                                            "\\end{x\?alignat\*\?}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv                                            "\\end{xxalignat}"

  " DeclareMathOperator
  syntax match texCmdDeclmathoper nextgroup=texDeclmathoperArgName skipwhite skipnl "\\DeclareMathOperator\>\*\?"
  call vimtex#syntax#core#new_arg('texDeclmathoperArgName', {
        \ 'next': 'texDeclmathoperArgBody',
        \ 'contains': ''
        \})
  call vimtex#syntax#core#new_arg('texDeclmathoperArgBody')

  " \tag{label} or \tag*{label}
  syntax match texMathCmd "\\tag\>\*\?" contained nextgroup=texMathTagArg
  call vimtex#syntax#core#new_arg('texMathTagArg')

  " Conceal the command and delims of "\operatorname{ ... }"
  if g:vimtex_syntax_conceal.math_delimiters
    syntax region texMathConcealedArg contained matchgroup=texMathCmd
          \ start="\\operatorname\*\?\s*{" end="}"
          \ concealends
    syntax cluster texClusterMath add=texMathConcealedArg
  endif

  highlight def link texCmdDeclmathoper     texCmdNew
  highlight def link texDeclmathoperArgName texArgNew
  highlight def link texMathConcealedArg    texMathTextArg
endfunction

" }}}1
