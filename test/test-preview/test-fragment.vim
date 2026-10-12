set nocompatible
set runtimepath^=../..
filetype plugin on
syntax on

nnoremap q :qall!<cr>

silent edit test.tex

if empty($INMAKE) | finish | endif

" Not in math
call cursor(7, 2)
call assert_equal({}, vimtex#preview#get_fragment())

" Inline math keeps text style
call cursor(7, 12)
call assert_equal({
      \ 'lnum_start': 7,
      \ 'lnum_end': 7,
      \ 'math': '$\strut a + \avg{b}$',
      \}, vimtex#preview#get_fragment())

call cursor(7, 28)
call assert_equal('$\strut c^2$', vimtex#preview#get_fragment().math)

" Display math uses display style
call cursor(10, 5)
call assert_equal({
      \ 'lnum_start': 9,
      \ 'lnum_end': 11,
      \ 'math': '$\displaystyle\strut x = \frac{1}{2}$',
      \}, vimtex#preview#get_fragment())

" Alignment environments are converted to their inner variants, and labels
" and tags are removed
call cursor(14, 5)
call assert_equal(
      \ "$\\displaystyle\\strut \\begin{aligned}a &= b \\\\\n"
      \ . "  c &= d\\end{aligned}$",
      \ vimtex#preview#get_fragment().math)

call cursor(19, 5)
call assert_equal(
      \ "$\\displaystyle\\strut \\begin{alignedat}{2}\n"
      \ . "  a &= b & c &= d\\end{alignedat}$",
      \ vimtex#preview#get_fragment().math)

call cursor(23, 12)
call assert_equal('$\displaystyle\strut e = mc^2$',
      \ vimtex#preview#get_fragment().math)

" Empty math gives no fragment
call cursor(26, 8)
call assert_equal({}, vimtex#preview#get_fragment())

" The document reuses the preamble of the project
let s:lines = vimtex#preview#get_document('$x$', 'FFFFFF')
call assert_equal('\documentclass{article}', s:lines[0])
call assert_equal('\newcommand{\avg}[1]{\langle #1 \rangle}', s:lines[2])
let s:i = index(s:lines, '\begin{document}')
call assert_true(index(s:lines, '\usepackage[active,tightpage]{preview}') < s:i)
call assert_equal([
      \ '\begin{preview}',
      \ '\setbox\vimtexpreviewbox\hbox{\color[HTML]{FFFFFF}%',
      \ '$x$',
      \ '}%',
      \], s:lines[s:i + 1 : s:i + 4])
call assert_equal(['\end{preview}', '\end{document}'], s:lines[-2:])

call vimtex#test#finished()
