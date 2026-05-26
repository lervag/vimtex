set nocompatible
set runtimepath^=../..
filetype plugin on


" tsc  Toggle star on whitelisted commands
call vimtex#test#keys('tsc', '\section{x}', '\section*{x}')
call vimtex#test#keys('tsc', '\section*{x}', '\section{x}')
call vimtex#test#keys('tsc', '\subsection{x}', '\subsection*{x}')
call vimtex#test#keys('tsc', '\subsubsection{x}', '\subsubsection*{x}')
call vimtex#test#keys('tsc', '\part{x}', '\part*{x}')
call vimtex#test#keys('tsc', '\vspace{1cm}', '\vspace*{1cm}')
call vimtex#test#keys('tsc', '\autocite{key}', '\autocite*{key}')
call vimtex#test#keys('tsc', '\citeauthor{key}', '\citeauthor*{key}')
call vimtex#test#keys('tsc', '\pageref{key}', '\pageref*{key}')
call vimtex#test#keys('tsc', '\cref{key}', '\cref*{key}')
call vimtex#test#keys('tsc', '\renewcommand{\x}{y}', '\renewcommand*{\x}{y}')
call vimtex#test#keys('tsc', '\newcommand{\x}{y}', '\newcommand*{\x}{y}')
call vimtex#test#keys('tsc', '\DeclareMathOperator{\x}{y}',
      \ '\DeclareMathOperator*{\x}{y}')

" tsc  Non-whitelisted commands are left unchanged
call vimtex#test#keys('tsc', '\frac{1}{2}', '\frac{1}{2}')
call vimtex#test#keys('tsc', '\sin', '\sin')
call vimtex#test#keys('tsc', '\left( x \right)', '\left( x \right)')
call vimtex#test#keys('tsc', '\textbf{x}', '\textbf{x}')

" tsc  An empty whitelist disables filtering (toggle any command)
let g:vimtex_toggle_star_cmds = []
call vimtex#test#keys('tsc', '\frac{1}{2}', '\frac*{1}{2}')

call vimtex#test#finished()
