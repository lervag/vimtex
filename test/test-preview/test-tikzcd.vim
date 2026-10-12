set nocompatible
set runtimepath^=../..
filetype plugin on
syntax on

nnoremap q :qall!<cr>

silent edit test-tikzcd.tex

if empty($INMAKE) | finish | endif

" tikz-cd inside math
call cursor(9, 5)
call assert_equal({
      \ 'lnum_start': 7,
      \ 'lnum_end': 11,
      \ 'math': "$\\displaystyle\\strut \\begin{tikzcd}\n"
      \   . "    A \\arrow[r, \"f\"] & B\n"
      \   . "  \\end{tikzcd}$",
      \}, vimtex#preview#get_fragment())

" tikz-cd outside math
call cursor(14, 5)
call assert_equal({
      \ 'lnum_start': 13,
      \ 'lnum_end': 15,
      \ 'math': "$\\displaystyle\\strut \\begin{tikzcd}[column sep=large]\n"
      \   . "  A \\arrow[r] & B\\end{tikzcd}$",
      \}, vimtex#preview#get_fragment())

" The diagrams compile, i.e. the & is not read as part of a macro argument
if executable('pdflatex')
  let s:dir = tempname()
  call mkdir(s:dir, 'p')
  for s:lnum in [9, 14]
    call cursor(s:lnum, 5)
    call writefile(vimtex#preview#get_document(
          \ vimtex#preview#get_fragment().math, '000000'),
          \ s:dir . '/doc.tex')
    call system(printf('pdflatex -interaction=nonstopmode -halt-on-error'
          \ . ' -output-directory=%s %s',
          \ shellescape(s:dir), shellescape(s:dir . '/doc.tex')))
    call assert_equal(0, v:shell_error, 'line ' . s:lnum)
  endfor
  call delete(s:dir, 'rf')
endif

call vimtex#test#finished()
