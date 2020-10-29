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

  " Amsmath [lr][vV]ert  (Holger Mitschke)
  if &encoding ==# 'utf-8' && g:vimtex_syntax_config.conceal.math_delimiters
    for l:texmath in [
          \ ['\\lvert', '|'] ,
          \ ['\\rvert', '|'] ,
          \ ['\\lVert', '‖'] ,
          \ ['\\rVert', '‖'] ,
          \ ]
        execute "syntax match texDelimMath '\\\\[bB]igg\\=[lr]\\="
              \ . l:texmath[0] . "' contained conceal cchar=" . l:texmath[1]
    endfor
  endif
endfunction

" }}}1
