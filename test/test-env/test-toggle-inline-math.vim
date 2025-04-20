set nocompatible
set runtimepath^=../..
filetype plugin indent on
syntax on

nnoremap q :qall!<cr>

set shiftwidth=2
set expandtab

let g:vimtex_indent_delims = {
      \ 'open' : ['{', '\\('],
      \ 'close' : ['}', '\\)'],
      \}

let g:vimtex_env_toggle_math_map = {
      \ '$': '\(',
      \ '\[': '\(',
      \}

silent edit test-toggle-inline-math.tex

normal! 4G
call vimtex#env#toggle_math()
call assert_equal([
      \ '\(',
      \ '  \Omega = \bigtimes_{\alpha \in \USet} \Omega_\alpha, \qquad',
      \ '  \calF = \bigtimes_{\alpha \in \USet} \calF_\alpha, \qquad',
      \ '  \prob = \prod_{\alpha \in \USet} \prob_\alpha, \qquad',
      \ '  % \quad',
      \ '  % \mathbb{U} =',
      \ '  % \begin{cases}',
      \ '  %   \{w,g,v\} & \text{if $\LSet = 1$,} \\[0.5em]',
      \ '  %   \{w,f,g,v\} & \text{if $\LSet = 0$.}',
      \ '  % \end{cases}',
      \ '\)',
      \], getline(4, 14))

normal! 16Gf$
call vimtex#env#toggle_math()
call assert_equal([
      \ 'Hello',
      \ '\(',
      \ '  1 + 1 = 2',
      \ '\)',
      \ 'world',
      \], getline(16,20))

if empty($INMAKE) | finish | endif
call vimtex#test#finished()
