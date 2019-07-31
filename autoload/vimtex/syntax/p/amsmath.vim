" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#amsmath#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'amsmath') | return | endif
  let b:vimtex_syntax.amsmath = 1

  " This is based on Charles E. Campbell's amsmath.vba file dated 2018-06-29

  call TexNewMathZone('E', 'align', 1)
  call TexNewMathZone('F', 'alignat', 1)
  call TexNewMathZone('H', 'flalign', 1)
  call TexNewMathZone('I', 'gather', 1)
  call TexNewMathZone('J', 'multline', 1)
  call TexNewMathZone('K', 'xalignat', 1)
  call TexNewMathZone('L', 'xxalignat', 0)
  call TexNewMathZone('M', 'mathpar', 1)

  execute 'syntax match texBadMath ''\\end\s*{\s*\(' . join([
        \ 'align',
        \ 'alignat',
        \ 'equation',
        \ 'flalign',
        \ 'gather',
        \ 'multline',
        \ 'xalignat',
        \ 'xxalignat'], '\|') . '\)\*\=\s*}'''

  " Amsmath [lr][vV]ert  (Holger Mitschke)
  for l:texmath in [
        \ ['\\lvert', '|'] ,
        \ ['\\rvert', '|'] ,
        \ ['\\lVert', '‖'] ,
        \ ['\\rVert', '‖'] ,
        \ ]
    execute "syntax match texMathDelim '\\\\[bB]igg\\=[lr]\\="
          \ . l:texmath[0] . "' contained conceal cchar=" . l:texmath[1]
  endfor
endfunction

" }}}1
