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
      \ 'code': '$\strut a + \avg{b}$',
      \ 'box': 'hbox',
      \}, vimtex#preview#get_fragment())

call cursor(7, 28)
call assert_equal('$\strut c^2$', vimtex#preview#get_fragment().code)

" Display math uses display style
call cursor(10, 5)
call assert_equal({
      \ 'lnum_start': 9,
      \ 'lnum_end': 11,
      \ 'code': '$\displaystyle\strut x = \frac{1}{2}$',
      \ 'box': 'hbox',
      \}, vimtex#preview#get_fragment())

" Alignment environments are converted to their inner variants, and labels
" and tags are removed
call cursor(14, 5)
call assert_equal(
      \ "$\\displaystyle\\strut \\begin{aligned}a &= b \\\\\n"
      \ . "  c &= d\\end{aligned}$",
      \ vimtex#preview#get_fragment().code)

call cursor(19, 5)
call assert_equal(
      \ "$\\displaystyle\\strut \\begin{alignedat}{2}\n"
      \ . "  a &= b & c &= d\\end{alignedat}$",
      \ vimtex#preview#get_fragment().code)

call cursor(23, 12)
call assert_equal('$\displaystyle\strut e = mc^2$',
      \ vimtex#preview#get_fragment().code)

" Empty math gives no fragment
call cursor(26, 8)
call assert_equal({}, vimtex#preview#get_fragment())

" The document reuses the preamble of the project
let s:lines = vimtex#preview#get_document(
      \ {'code': '$x$', 'box': 'hbox'}, 'FFFFFF')
call assert_equal('\documentclass{article}', s:lines[0])
call assert_equal('\newcommand{\avg}[1]{\langle #1 \rangle}', s:lines[2])
let s:i = index(s:lines, '\begin{document}')
call assert_true(index(s:lines, '\usepackage[active,tightpage]{preview}') < s:i)
call assert_equal([
      \ '\csname tikzexternaldisable\endcsname',
      \ '\begin{preview}',
      \ '\setbox\vimtexpreviewbox\hbox{\color[HTML]{FFFFFF}%',
      \ '$x$',
      \ '}%',
      \], s:lines[s:i + 1 : s:i + 5])
call assert_equal(['\end{preview}', '\end{document}'], s:lines[-2:])

" A vbox is used for code that should be typeset as a paragraph
let s:lines = vimtex#preview#get_document(
      \ {'code': '\begin{foo}x\end{foo}', 'box': 'vbox'}, 'FFFFFF')
call assert_notequal(-1, index(s:lines,
      \ '\setbox\vimtexpreviewbox\vbox{\noindent\color[HTML]{FFFFFF}%'))

call vimtex#test#finished()
