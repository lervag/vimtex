set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on
syntax on

set nomore
set autoindent

setfiletype tex

" tsd  /  Toggle surrounding delimiter
call vimtex#test#keys('3jtsd', [
      \ '$\bigl(\begin{smallmatrix}',
      \ '  \Q^* &   \\',
      \ '       & 1 \\',
      \ '\end{smallmatrix}\bigr)$',
      \], [
      \ '$(\begin{smallmatrix}',
      \ '  \Q^* &   \\',
      \ '       & 1 \\',
      \ '\end{smallmatrix})$',
      \])

" tsd  /  Toggle surrounding delimiter (cf. #1620)
call vimtex#test#keys('f+tsd', [
      \ '\( a^2 + b^2 = c^2 \)',
      \], [
      \ '\( a^2 + b^2 = c^2 \)',
      \])

" tsf  /  Toggle surrounding fraction
for [s:in, s:out] in [
      \ ['$\frac{x+1}{x-1}$', '$(x+1)/(x-1)$'],
      \ ['$\frac {x+1}  {x-1}$', '$(x+1)/(x-1)$'],
      \ ['$\frac {x-1} x$', '$(x-1)/x$'],
      \ ['$\frac x  {x-1}$', '$x/(x-1)$'],
      \ ['$x / (x-1)$', '$\frac{x}{x-1}$'],
      \ ['$(x-1) /x$', '$\frac{x-1}{x}$'],
      \ ['$(x+1)  /(x-1)$', '$\frac{x+1}{x-1}$'],
      \ ['$(x+1)/ (x-1)$', '$\frac{x+1}{x-1}$'],
      \ ['$\alpha/\mu$', '$\frac{\alpha}{\mu}$'],
      \ ['$\frac{\alpha}{\mu}$', '$\alpha/\mu$'],
      \ ['$(r+t)/((\mu))$', '$\frac{r+t}{(\mu)}$'],
      \ ['$((\mu))/(r+t)$', '$\frac{(\mu)}{r+t}$'],
      \ ['$\frac{\delta_{02}}{\delta_{02} + \delta_{01}}$',
      \  '$(\delta_{02})/(\delta_{02} + \delta_{01})$'],
      \ ['$(\delta_{02})/(\delta_{02} + \delta_{01})$',
      \  '$\frac{\delta_{02}}{\delta_{02} + \delta_{01}}$'],
      \ ['\(a/p_\text{b}\)', '\(\frac{a}{p_\text{b}}\)'],
      \ ['$f(x+y)/g(z)$', '$\frac{f(x+y)}{g(z)}$'],
      \ ['$f(x)g(y)/h(z)$', '$\frac{f(x)g(y)}{h(z)}$'],
      \]
  if s:in =~# '\/'
    call vimtex#test#keys('f/ltsf', [s:in], [s:out])
    call vimtex#test#keys('f/htsf', [s:in], [s:out])
  else
    call vimtex#test#keys('f{tsf', [s:in], [s:out])
  endif
endfor

quit!
