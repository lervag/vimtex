" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#mleftright#load(cfg) abort " {{{1
  syntax match texMathDelimMod contained "\\m\(left\|right\)\>"

  " Add conceal rules
  if !g:vimtex_syntax_conceal.math_delimiters || &encoding !=# 'utf-8'
    return
  endif

  syntax match texMathDelim contained conceal cchar=| "\\mleft\\lvert"
  syntax match texMathDelim contained conceal cchar=| "\\mright\\rvert"
  syntax match texMathDelim contained conceal cchar=‖ "\\mleft\\lVert"
  syntax match texMathDelim contained conceal cchar=‖ "\\mright\\rVert"

  syntax match texMathDelim contained conceal cchar=| "\\mleft|"
  syntax match texMathDelim contained conceal cchar=| "\\mright|"
  syntax match texMathDelim contained conceal cchar=‖ "\\mleft\\|"
  syntax match texMathDelim contained conceal cchar=‖ "\\mright\\|"
  syntax match texMathDelim contained conceal cchar=( "\\mleft("
  syntax match texMathDelim contained conceal cchar=) "\\mright)"
  syntax match texMathDelim contained conceal cchar=[ "\\mleft\["
  syntax match texMathDelim contained conceal cchar=] "\\mright]"
  syntax match texMathDelim contained conceal cchar={ "\\mleft\\{"
  syntax match texMathDelim contained conceal cchar=} "\\mright\\}"
  syntax match texMathDelim contained conceal cchar=< "\\mleft<"
  syntax match texMathDelim contained conceal cchar=> "\\mright>"
  syntax match texMathDelim contained conceal cchar=( "\\mleft("
  syntax match texMathDelim contained conceal cchar=) "\\mright)"
  syntax match texMathDelim contained conceal cchar=[ "\\mleft\["
  syntax match texMathDelim contained conceal cchar=] "\\mright]"
  syntax match texMathDelim contained conceal cchar={ "\\mleft\\{"
  syntax match texMathDelim contained conceal cchar=} "\\mright\\}"
  syntax match texMathDelim contained conceal cchar=[ "\\mleft\\lbrace\>"
  syntax match texMathDelim contained conceal cchar=⌈ "\\mleft\\lceil\>"
  syntax match texMathDelim contained conceal cchar=⌊ "\\mleft\\lfloor\>"
  syntax match texMathDelim contained conceal cchar=⌊ "\\mleft\\lgroup\>"
  syntax match texMathDelim contained conceal cchar=⎛ "\\mleft\\lmoustache\>"
  syntax match texMathDelim contained conceal cchar=] "\\mright\\rbrace\>"
  syntax match texMathDelim contained conceal cchar=⌉ "\\mright\\rceil\>"
  syntax match texMathDelim contained conceal cchar=⌋ "\\mright\\rfloor\>"
  syntax match texMathDelim contained conceal cchar=⌋ "\\mright\\rgroup\>"
  syntax match texMathDelim contained conceal cchar=⎞ "\\mright\\rmoustache\>"
  syntax match texMathDelim contained conceal cchar=| "\\m\(left\|right\)|"
  syntax match texMathDelim contained conceal cchar=‖ "\\m\(left\|right\)\\|"
  syntax match texMathDelim contained conceal cchar=↓ "\\m\(left\|right\)\\downarrow\>"
  syntax match texMathDelim contained conceal cchar=⇓ "\\m\(left\|right\)\\Downarrow\>"
  syntax match texMathDelim contained conceal cchar=↑ "\\m\(left\|right\)\\uparrow\>"
  syntax match texMathDelim contained conceal cchar=↑ "\\m\(left\|right\)\\Uparrow\>"
  syntax match texMathDelim contained conceal cchar=↕ "\\m\(left\|right\)\\updownarrow\>"
  syntax match texMathDelim contained conceal cchar=⇕ "\\m\(left\|right\)\\Updownarrow\>"

  if &ambiwidth ==# 'double'
    syntax match texMathDelim contained conceal cchar=〈 "\\\%([bB]igg\?l\?\|left\)\\langle\>"
    syntax match texMathDelim contained conceal cchar=〉 "\\\%([bB]igg\?r\?\|right\)\\rangle\>"
  else
    syntax match texMathDelim contained conceal cchar=⟨ "\\\%([bB]igg\?l\?\|left\)\\langle\>"
    syntax match texMathDelim contained conceal cchar=⟩ "\\\%([bB]igg\?r\?\|right\)\\rangle\>"
  endif
endfunction

" }}}1
