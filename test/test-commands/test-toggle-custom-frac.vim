set nocompatible
set runtimepath^=../..
filetype plugin on

let g:vimtex_toggle_fractions = {
        \ 'INLINE': 'frac',
        \ 'frac': 'dfrac',
        \ 'dfrac': 'cfrac',
        \ 'cfrac': 'INLINE',
        \}


" tsf  /  Toggle surrounding fraction
for [s:in, s:out] in [
      \ ['$x / (x-1)$', '$\frac{x}{x-1}$'],
      \ ['$\frac{x}{x-1}$', '$\dfrac{x}{x-1}$'],
      \ ['$\dfrac{x}{x-1}$', '$\cfrac{x}{x-1}$'],
      \ ['$\cfrac{x}{x-1}$', '$x/(x-1)$'],
      \]
  if s:in =~# '\/'
    call vimtex#test#keys('f/ltsf', s:in, s:out)
    call vimtex#test#keys('f/htsf', s:in, s:out)
  else
    call vimtex#test#keys('f{tsf', s:in, s:out)
  endif
endfor

call vimtex#test#finished()
