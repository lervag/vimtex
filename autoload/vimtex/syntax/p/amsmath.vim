" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#amsmath#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'amsmath') | return | endif
  let b:vimtex_syntax.amsmath = 1

  call vimtex#syntax#core#new_region_math('align')
  call vimtex#syntax#core#new_region_math('alignat')
  call vimtex#syntax#core#new_region_math('flalign')
  call vimtex#syntax#core#new_region_math('gather')
  call vimtex#syntax#core#new_region_math('mathpar')
  call vimtex#syntax#core#new_region_math('multline')
  call vimtex#syntax#core#new_region_math('xalignat')
  call vimtex#syntax#core#new_region_math('xxalignat', {'starred': 0})

  " Amsmath [lr][vV]ert
  if &encoding ==# 'utf-8' && g:vimtex_syntax_config.conceal.math_delimiters
    syntax match texMathDelim contained conceal cchar=| "\\\%([bB]igg\?l\|left\)\\lvert"
    syntax match texMathDelim contained conceal cchar=| "\\\%([bB]igg\?r\|right\)\\rvert"
    syntax match texMathDelim contained conceal cchar=‖ "\\\%([bB]igg\?l\|left\)\\lVert"
    syntax match texMathDelim contained conceal cchar=‖ "\\\%([bB]igg\?r\|right\)\\rVert"
  endif

  syntax match texMathCmdEnv "\\begin{subarray}"       contained contains=texCmdEnv nextgroup=texMathArrayArg skipwhite skipnl
  syntax match texMathCmdEnv "\\begin{x\?alignat\*\?}" contained contains=texCmdEnv nextgroup=texMathArrayArg skipwhite skipnl
  syntax match texMathCmdEnv "\\begin{xxalignat}"      contained contains=texCmdEnv nextgroup=texMathArrayArg skipwhite skipnl
endfunction

" }}}1
