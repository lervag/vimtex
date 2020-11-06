" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#amsmath#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'amsmath') | return | endif
  let b:vimtex_syntax.amsmath = 1

  call vimtex#syntax#core#new_region_math('align', 1)
  call vimtex#syntax#core#new_region_math('alignat', 1)
  call vimtex#syntax#core#new_region_math('flalign', 1)
  call vimtex#syntax#core#new_region_math('gather', 1)
  call vimtex#syntax#core#new_region_math('multline', 1)
  call vimtex#syntax#core#new_region_math('xalignat', 1)
  call vimtex#syntax#core#new_region_math('xxalignat', 0)
  call vimtex#syntax#core#new_region_math('mathpar', 1)

  " Amsmath [lr][vV]ert
  if &encoding ==# 'utf-8' && g:vimtex_syntax_config.conceal.math_delimiters
    syntax match texMathDelim contained conceal cchar=| "\\\%([bB]igg\?l\|left\)\\lvert"
    syntax match texMathDelim contained conceal cchar=| "\\\%([bB]igg\?r\|right\)\\rvert"
    syntax match texMathDelim contained conceal cchar=‖ "\\\%([bB]igg\?l\|left\)\\lVert"
    syntax match texMathDelim contained conceal cchar=‖ "\\\%([bB]igg\?r\|right\)\\rVert"
  endif
endfunction

" }}}1
