set nocompatible
let &rtp = '../..,' . &rtp
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


let s:example2 = [
      \ '\begin{enumerate}',
      \ '  \item text here',
      \ '    \begin{enumerate}',
      \ '      \item',
      \ '      \item',
      \ '    \end{enumerate}',
      \ '    and here.',
      \ '  \item and more text here',
      \ '\end{enumerate}',
      \]
call vimtex#test#keys('jjdim', s:example2,
      \[
      \ '\begin{enumerate}',
      \ '  \item ',
      \ '  \item and more text here',
      \ '\end{enumerate}',
      \])
call vimtex#test#keys('jjdam', s:example2,
      \[
      \ '\begin{enumerate}',
      \ '  \item and more text here',
      \ '\end{enumerate}',
      \])
call vimtex#test#keys('6jdim', s:example2,
      \[
      \ '\begin{enumerate}',
      \ '  \item ',
      \ '  \item and more text here',
      \ '\end{enumerate}',
      \])
call vimtex#test#keys('6jdam', s:example2,
      \[
      \ '\begin{enumerate}',
      \ '  \item and more text here',
      \ '\end{enumerate}',
      \])


let s:example3 = [
      \ '\begin{enumerate}',
      \ '  \item hello world',
      \ '  \item hello',
      \ '    \begin{itemize}',
      \ '      \item moon',
      \ '      \item and sun',
      \ '    \end{itemize}',
      \ '    and galaxy.',
      \ '\end{enumerate}',
      \]
call vimtex#test#keys('3jdam', s:example3,
      \[
      \ '\begin{enumerate}',
      \ '  \item hello world',
      \ '\end{enumerate}',
      \])


let s:example4 = [
      \ '\begin{itemize}',
      \ '  \item \begin{enumerate}',
      \ '    \item (...)',
      \ '  \end{enumerate}',
      \ '\end{itemize}',
      \]
call vimtex#test#keys('3jdim', s:example4,
      \[
      \ '\begin{itemize}',
      \ '  \item ',
      \ '\end{itemize}',
      \])


let s:example5 = [
      \ '\begin{itemize}',
      \ '  \item \begin{enumerate}',
      \ '      \item (...)',
      \ '    \end{enumerate}',
      \ '    foo',
      \ '  \item',
      \ '\end{itemize}',
      \]
call vimtex#test#keys('4jwdim', s:example5,
      \[
      \ '\begin{itemize}',
      \ '  \item ',
      \ '  \item',
      \ '\end{itemize}',
      \])


call vimtex#test#keys('j$damp', [
      \ '\begin{enumerate}',
      \ '  \item First one.',
      \ '  \item Second one.',
      \ '\end{enumerate}',
      \], [
      \ '\begin{enumerate}',
      \ '  \item Second one.',
      \ '  \item First one.',
      \ '\end{enumerate}',
      \])


call vimtex#test#finished()
