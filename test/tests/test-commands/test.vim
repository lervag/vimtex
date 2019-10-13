set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on
syntax on

setfiletype tex

function! TestKeys(keys, context, expected) abort " {{{1
  normal! gg0dG
  call append(1, a:context)
  normal! ggdd

  silent execute 'normal' a:keys

  let l:observed = getline(1, line('$'))
  call vimtex#test#assert_equal(l:observed, a:expected)
endfunction

" }}}1

" csc  /  Change surrounding command
call TestKeys("csctest\<cr>", ['\cmd{foo}'], ['\test{foo}'])

" dsc  /  Delete surrounding command
call TestKeys('dsc', ['\cmd{foo}'], ['foo'])

" F7   /  Insert command (insert mode, normal mode and visual mode)
call TestKeys("lla\<f7>}", ['foobar'], ['\foo{bar}'])
call TestKeys("fbve\<f7>emph\<cr>", ['foobar'], ['foo\emph{bar}'])
call TestKeys("\<f7>emph\<cr>", ['foo'], ['\emph{foo}'])

" tsd  /  Toggle surrounding delimiter
call TestKeys('3jtsd', [
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

" cse  /  Change surrounding environment
" .    /  Dot repeat
call TestKeys("csebaz\<cr>}j.",
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

" Personal settings to get consistent results
set wildmode=longest:full,full
set wildcharm=<c-z>

" cse  /  Change surrounding environment
" .    /  Dot repeat
call TestKeys("cse\<c-z>\<c-z>\<c-z>\<cr>",
      \[
      \ '\begin{foo}',
      \ '  Foo',
      \ '\end{foo}',
      \],
      \[
      \ '\begin{abstract}',
      \ '  Foo',
      \ '\end{abstract}',
      \])

" Restore settings to default values
set wildmode&
set wildcharm&

" dse  /  Delete surrounding environment
call TestKeys('dsedse',
      \[
      \ '\begin{test}',
      \ '  \begin{center} a \end{center}',
      \ '\end{test}',
      \],
      \['   a '])

" ds$  /  Delete surrounding math ($...$ and \[...\])
call TestKeys('f$ds$',
      \['for $ 2+2 = 4 = 3 $ etter'],
      \['for 2+2 = 4 = 3 etter'])
call TestKeys('jds$',
      \[
      \ 'asd $',
      \ '2+2 = 4',
      \ '$ asd',
      \],
      \[
      \ 'asd',
      \ '2+2 = 4',
      \ 'asd',
      \])
call TestKeys('ds$',
      \[
      \ '\[',
      \ '2+2 = 4',
      \ '\]',
      \],
      \[
      \ '2+2 = 4',
      \])

quit!
