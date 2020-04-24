set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on
syntax on

set nomore

setfiletype tex

let s:example1 = [
      \ '\begin{itemize}',
      \ '  \item this is item 1',
      \ '  \item this is item 2',
      \ '\end{itemize}',
      \]

call vimtex#test#keys('dam', s:example1, s:example1)
call vimtex#test#keys('Gdam', s:example1, s:example1)

call vimtex#test#keys('j$dam', s:example1,
      \[
      \ '\begin{itemize}',
      \ '  \item this is item 2',
      \ '\end{itemize}',
      \])

call vimtex#test#keys('jj3wdam', s:example1,
      \[
      \ '\begin{itemize}',
      \ '  \item this is item 1',
      \ '\end{itemize}',
      \])

call vimtex#test#keys('jcimtest', s:example1,
      \[
      \ '\begin{itemize}',
      \ '  \item test',
      \ '  \item this is item 2',
      \ '\end{itemize}',
      \])

call vimtex#test#keys('jj$cimtest', s:example1,
      \[
      \ '\begin{itemize}',
      \ '  \item this is item 1',
      \ '  \item test',
      \ '\end{itemize}',
      \])

quit!
