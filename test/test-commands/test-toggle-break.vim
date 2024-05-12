set nocompatible
set runtimepath^=../..
filetype plugin on


" tsb  /  Toggle line break
for [s:in, s:out] in [
      \ ['abc', 'abc \\'],
      \ ['  a + b = c', '  a + b = c \\'],
      \ ['abc \\', 'abc'],
      \ ['abc\\', 'abc'],
      \]
  call vimtex#test#keys('tsb', s:in, s:out)
endfor

call vimtex#test#finished()
