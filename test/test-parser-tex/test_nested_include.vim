set nocompatible
let &rtp = '../..,' . &rtp

nnoremap q :qall!<cr>

let s:files = map(
      \ vimtex#parser#tex#parse_files('test_nested_include.tex', {}),
      \ { _, x -> fnamemodify(x, ':.') }
      \)
let s:files_expected = [
      \ 'test_nested_include.tex',
      \ 'test_nested_include/imported.tex',
      \ 'test_nested_include/more.tex',
      \]
call assert_equal(s:files_expected, s:files)

let s:lines = vimtex#parser#tex#parse('test_nested_include.tex', #{
      \ detailed: v:false,
      \})
let s:lines_expected = [
      \ '\documentclass{article}',
      \ '\usepackage{import}',
      \ '',
      \ '\begin{document}',
      \ '',
      \ '\part{My content}',
      \ '\import{test_nested_include/}{imported}',
      \ '\section{Imported section}',
      \ '',
      \ 'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod',
      \ 'tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At',
      \ 'vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd',
      \ 'gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.',
      \ '',
      \ '\input{more}',
      \ '\section{Traditional section}',
      \ '',
      \ 'And some associated content',
      \ '',
      \ '\part{Next part}',
      \ 'More content here',
      \ '',
      \ '\end{document}',
      \]
call assert_equal(s:lines_expected, s:lines)

call vimtex#test#finished()
