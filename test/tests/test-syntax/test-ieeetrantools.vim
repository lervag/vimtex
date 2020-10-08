source common.vim

silent edit test-ieeetrantools.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texMathZoneIEEEeqnA', 8, 1))
call vimtex#test#assert(vimtex#syntax#in('texMathZoneIEEEeqnA', 13, 1))

if !get(g:, 'vimtex_syntax_alpha')
  call vimtex#test#assert(vimtex#syntax#in('texDocZone', 20, 1))
endif
call vimtex#test#assert(vimtex#syntax#in('texMathZoneC', 24, 1))

call vimtex#test#assert(vimtex#syntax#in('texMathZoneIEEEeqnB', 31, 1))

quit!
