set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin indent on

set shiftwidth=2

setfiletype tex


" ]]   /  Close current delimiter or environment
call vimtex#test#keys('A]]',
      \ '$\bigl( \left. a \right) ',
      \ '$\bigl( \left. a \right) \bigr)')
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
      \ '  \end{array}',
      \])


call vimtex#test#finished()
