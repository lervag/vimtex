set nocompatible
set runtimepath^=../..
filetype plugin on


" cse  /  Change surrounding environment
" .    /  Dot repeat
call vimtex#test#keys("csebaz\<cr>}j.",
      \[
      \ '\begin{foo}',
      \ '  Foo',
      \ '\end{foo}',
      \ '',
      \ '\begin{bar}',
      \ '  Bar',
      \ '\end{bar}',
      \],
      \[
      \ '\begin{baz}',
      \ '  Foo',
      \ '\end{baz}',
      \ '',
      \ '\begin{baz}',
      \ '  Bar',
      \ '\end{baz}',
      \])


call vimtex#test#finished()
