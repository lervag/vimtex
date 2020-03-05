set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on
syntax on

set nomore
set autoindent

setfiletype tex

" ]]   /  Close current delimiter or environment
call vimtex#test#keys('A]]', [
      \ '$\bigl( \left. a \right) '
      \], [
      \ '$\bigl( \left. a \right) \bigr)',
      \])
call vimtex#test#keys('Go]]', [
      \ '\documentclass{article}',
      \ '\usepackage{stackengine}',
      \ '\begin{document}',
      \ '\begin{equation}',
      \ '  \begin{array}{c}',
      \ '    a = \stackunder{p6mm}{',
      \ '      \left\{ b \right.',
      \ '    }',
      \], [
      \ '\documentclass{article}',
      \ '\usepackage{stackengine}',
      \ '\begin{document}',
      \ '\begin{equation}',
      \ '  \begin{array}{c}',
      \ '    a = \stackunder{p6mm}{',
      \ '      \left\{ b \right.',
      \ '    }',
      \ '    \end{array}',
      \])

" csc  /  Change surrounding command
call vimtex#test#keys("csctest\<cr>", ['\cmd{foo}'], ['\test{foo}'])

" dsc  /  Delete surrounding command
call vimtex#test#keys('dsc', ['\cmd{foo}'], ['foo'])

" F7   /  Insert command (insert mode, normal mode and visual mode)
call vimtex#test#keys("lla\<f7>}", ['foobar'], ['\foo{bar}'])
call vimtex#test#keys("fbve\<f7>emph\<cr>", ['foobar'], ['foo\emph{bar}'])
call vimtex#test#keys("\<f7>emph\<cr>", ['foo'], ['\emph{foo}'])

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

" Personal settings to get consistent results
set wildmode=longest:full,full
set wildcharm=<c-z>

" cse  /  Change surrounding environment
" .    /  Dot repeat
call vimtex#test#keys("cse\<c-z>\<c-z>\<c-z>\<cr>",
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
call vimtex#test#keys('dsedse',
      \[
      \ '\begin{test}',
      \ '  \begin{center} a \end{center}',
      \ '\end{test}',
      \],
      \['   a '])

" ds$  /  Delete surrounding math ($...$ and \[...\])
call vimtex#test#keys('f$ds$',
      \['for $ 2+2 = 4 = 3 $ etter'],
      \['for 2+2 = 4 = 3 etter'])
call vimtex#test#keys('jds$',
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
call vimtex#test#keys('ds$',
      \[
      \ '\[',
      \ '2+2 = 4',
      \ '\]',
      \],
      \[
      \ '2+2 = 4',
      \])

quit!
