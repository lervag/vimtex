" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#amsmath#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'amsmath') | return | endif
  let b:vimtex_syntax.amsmath = 1

  call vimtex#syntax#core#new_math_zone('align', 1)
  call vimtex#syntax#core#new_math_zone('alignat', 1)
  call vimtex#syntax#core#new_math_zone('flalign', 1)
  call vimtex#syntax#core#new_math_zone('gather', 1)
  call vimtex#syntax#core#new_math_zone('multline', 1)
  call vimtex#syntax#core#new_math_zone('xalignat', 1)
  call vimtex#syntax#core#new_math_zone('xxalignat', 0)
  call vimtex#syntax#core#new_math_zone('mathpar', 1)

  " Amsmath [lr][vV]ert  (Holger Mitschke)
  if &encoding ==# 'utf-8' && g:vimtex_syntax_config.conceal.math_delimiters
    for l:texmath in [
          \ ['\\lvert', '|'] ,
          \ ['\\rvert', '|'] ,
          \ ['\\lVert', '‖'] ,
          \ ['\\rVert', '‖'] ,
          \ ]
        execute "syntax match texMathDelim '\\\\[bB]igg\\=[lr]\\="
              \ . l:texmath[0] . "' contained conceal cchar=" . l:texmath[1]
    endfor
  endif
endfunction

" }}}1
