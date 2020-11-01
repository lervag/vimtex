" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#amsmath#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'amsmath') | return | endif
  let b:vimtex_syntax.amsmath = 1

  call vimtex#syntax#core#new_math_region('align', 1)
  call vimtex#syntax#core#new_math_region('alignat', 1)
  call vimtex#syntax#core#new_math_region('flalign', 1)
  call vimtex#syntax#core#new_math_region('gather', 1)
  call vimtex#syntax#core#new_math_region('multline', 1)
  call vimtex#syntax#core#new_math_region('xalignat', 1)
  call vimtex#syntax#core#new_math_region('xxalignat', 0)
  call vimtex#syntax#core#new_math_region('mathpar', 1)

  " Amsmath [lr][vV]ert
  if &encoding ==# 'utf-8' && g:vimtex_syntax_config.conceal.math_delimiters
    syntax match texDelimMath contained conceal cchar=| "\\\%([bB]igg\?l\|left\)\\lvert"
    syntax match texDelimMath contained conceal cchar=| "\\\%([bB]igg\?r\|right\)\\rvert"
    syntax match texDelimMath contained conceal cchar=‖ "\\\%([bB]igg\?l\|left\)\\lVert"
    syntax match texDelimMath contained conceal cchar=‖ "\\\%([bB]igg\?r\|right\)\\rVert"
  endif
endfunction

" }}}1
