set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

set nomore
set expandtab
set shiftwidth=2

let g:vimtex_imaps_leader = ';'
let g:vimtex_imaps_disabled = ['a']
call vimtex#imaps#add_map({'lhs' : 'vv', 'rhs' : '\vec{'})
call vimtex#imaps#add_map({
  \ 'lhs' : 'test',
  \ 'rhs' : 'tested',
  \ 'leader' : '',
  \ 'wrapper' : 'vimtex#imaps#wrap_trivial',
  \})
call vimtex#imaps#add_map({
  \ 'lhs' : 'cool',
  \ 'rhs' : '\item',
  \ 'leader' : '',
  \ 'wrapper' : 'vimtex#imaps#wrap_environment',
  \ 'context' : ['enumerate'],
  \})

setfiletype tex

" Test ;b -> \beta
call vimtex#test#keys('$i;b;;',
      \['$2+2 = $'],
      \['$2+2 = \beta;$'])

" Test #bv -> \mathbf{v}
call vimtex#test#keys('$i#bv',
      \['$2+2 = $'],
      \['$2+2 = \mathbf{v}$'])

" Should not gobble a character outside of math mode
call vimtex#test#keys('$a#bv',
      \['$2+2 = $'],
      \['$2+2 = $#bv'])

" Test ;; -> ; (leader escape)
call vimtex#test#keys('$i;;',
      \['$;; = $'],
      \['$;; = ;$'])

" Test ;a -> ;a (disabled imap)
call vimtex#test#keys('$i;a',
      \['$a = $'],
      \['$a = ;a$'])

" Test test -> tested
call vimtex#test#keys('itest',
      \[''],
      \['tested'])

" Test inside math: ;vv -> \vec{
call vimtex#test#keys('A;vvf}\cdot;vvf}$',
      \['$|f| = '],
      \['$|f| = \vec{f}\cdot\vec{f}$'])

" Test outside math: ;vv -> ;vv
call vimtex#test#keys('A --- ;vv',
      \['$|f| = \vec{f}\cdot\vec{f}$'],
      \['$|f| = \vec{f}\cdot\vec{f}$ --- ;vv'])

" Test inside itemize: cool -> cool
call vimtex#test#keys('ocool',
      \['\begin{itemize}', '\end{itemize}'],
      \['\begin{itemize}', '  cool', '\end{itemize}'])

" Test inside itemize: cool -> \item
call vimtex#test#keys('ocool',
      \['\begin{enumerate}', '\end{enumerate}'],
      \['\begin{enumerate}', '  \item', '\end{enumerate}'])

" Test inside align environment: ;b -> \beta (#1648)
call vimtex#syntax#p#amsmath#load()
call vimtex#test#keys('o;b',
      \ ['\begin{align}', '\end{align}'],
      \ ['\begin{align}', '  \beta', '\end{align}'])

quit!
