" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#amsmath#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'amsmath') | return | endif
  let b:vimtex_syntax.amsmath = 1

  " Allow subequations (fixes #1019)
  " - This should be temporary, as it seems subequations is erroneously part of
  "   texBadMath from Charles Campbell's syntax plugin.
  syntax match texBeginEnd
        \ "\(\\begin\>\|\\end\>\)\ze{subequations}"
        \ nextgroup=texBeginEndName

  call vimtex#syntax#misc#new_math_zone('AmsA', 'align', 1)
  call vimtex#syntax#misc#new_math_zone('AmsB', 'alignat', 1)
  call vimtex#syntax#misc#new_math_zone('AmsD', 'flalign', 1)
  call vimtex#syntax#misc#new_math_zone('AmsC', 'gather', 1)
  call vimtex#syntax#misc#new_math_zone('AmsD', 'multline', 1)
  call vimtex#syntax#misc#new_math_zone('AmsE', 'xalignat', 1)
  call vimtex#syntax#misc#new_math_zone('AmsF', 'xxalignat', 0)
  call vimtex#syntax#misc#new_math_zone('AmsG', 'mathpar', 1)

  " Amsmath [lr][vV]ert  (Holger Mitschke)
  if has('conceal') && &enc ==# 'utf-8' && get(g:, 'tex_conceal', 'd') =~# 'd'
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
