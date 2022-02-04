set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on
syntax on

set shiftwidth=2
set expandtab

setfiletype tex


" cs$  /  Change between math inline and display
call vimtex#test#keys("f$cs$\\[\<cr>",
      \ ['text $math$ text'],
      \ ['text',
      \  '\[',
      \  '  math',
      \  '\]',
      \  'text'])
call vimtex#test#keys("jjcs$$\<cr>",
      \ [ 'text',
      \   '\[',
      \   '  math',
      \   '\]',
      \   'text' ],
      \ ['text $math$ text'])
call vimtex#test#keys("jjcs$\\(\<cr>",
      \ [ 'text',
      \   '\[',
      \   '  math',
      \   '\]',
      \   'text' ],
      \ ['text \(math\) text'])
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


call vimtex#test#finished()
