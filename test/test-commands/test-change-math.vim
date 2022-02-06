set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin indent on
syntax on

set shiftwidth=2
set expandtab

setfiletype tex


" cs$ -> $
call vimtex#test#keys("jjcs$$\<cr>",
      \ [ 'text',
      \   '\[',
      \   '  math',
      \   '\]',
      \   'text' ],
      \ ['text $math$ text'])

" cs$ -> $
call vimtex#test#keys("3jcs$$\<cr>",
      \ [ '  indented text',
      \   '',
      \   '  \[',
      \   '          m = a t_h',
      \   '  \]',
      \   '  More text' ],
      \ [ '  indented text',
      \   '',
      \   '  $m = a t_h$ More text'])

" cs$ -> $
call vimtex#test#keys("jjcs$$\<cr>",
      \ [ '  indented text',
      \   '  \[',
      \   '          m = a t_h',
      \   '  \]',
      \   '',
      \   '  More text' ],
      \ [ '  indented text $m = a t_h$',
      \   '',
      \   '  More text'])

" cs$ -> \[
call vimtex#test#keys("f$cs$\\[\<cr>",
      \ ['text $math$ text'],
      \ ['text',
      \  '\[',
      \  '  math',
      \  '\]',
      \  'text'])

" cs$ -> \[
call vimtex#test#keys("cs$\\[\<cr>",
      \ ['$math$ text'],
      \ ['\[',
      \  '  math',
      \  '\]',
      \  'text'])

" cs$ -> \[
call vimtex#test#keys("f$cs$\\[\<cr>",
      \ ['text $',
      \  'math',
      \  '$ text'],
      \ ['text',
      \  '\[',
      \  '  math',
      \  '\]',
      \  'text'])

" cs$ -> \[
call vimtex#test#keys("jcs$\\[\<cr>",
      \ ['text',
      \  '$',
      \  'math',
      \  '$',
      \  'text'],
      \ ['text',
      \  '\[',
      \  '  math',
      \  '\]',
      \  'text'])

" cs$ -> \[
call vimtex#test#keys("jcs$\\[\<cr>",
      \ ['  text $f(x)',
      \ ' = 1$ text'],
      \ ['  text',
      \  '  \[',
      \  '    f(x)',
      \  '    = 1',
      \  '  \]',
      \  '  text'])

" cs$ -> \(
call vimtex#test#keys("jjcs$\\(\<cr>",
      \ ['text',
      \  '\[',
      \  '  math',
      \  '\]',
      \  'text' ],
      \ ['text \(math\) text'])


call vimtex#test#finished()
