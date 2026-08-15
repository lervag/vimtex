set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set hidden

nnoremap q :qall!<cr>

let g:vimtex_view_method = 'lektra'
let g:vimtex_view_lektra_exe = 'lektra'
let g:vimtex_view_lektra_options = ''

silent edit main.tex
call cursor(7, 3)

let s:pdf = fnamemodify('main.pdf', ':p')
let s:tex = fnamemodify('main.tex', ':p')
let s:socket = vimtex#view#lektra#socket(s:pdf)
let s:prefix = 'lektra --single-instance --socket ' . s:socket

" The socket name must be stable and independent of how the path is specified
call assert_equal(s:socket, vimtex#view#lektra#socket('./main.pdf'))

" Starting the viewer performs a forward search by default
call assert_equal(
      \ printf("%s --synctex-forward '%s#%s:7:3'", s:prefix, s:pdf, s:tex),
      \ vimtex#view#lektra#cmdline(s:pdf, 1, 1))

" A forward search never passes the pdf file as a positional argument
call assert_equal(
      \ printf("%s --synctex-forward '%s#%s:7:3'", s:prefix, s:pdf, s:tex),
      \ vimtex#view#lektra#cmdline(s:pdf, 1, 0))

" Without synctex, we only open the pdf file
call assert_equal(
      \ printf("%s '%s'", s:prefix, s:pdf),
      \ vimtex#view#lektra#cmdline(s:pdf, 0, 1))

let g:vimtex_view_forward_search_on_start = 0
call assert_equal(
      \ printf("%s '%s'", s:prefix, s:pdf),
      \ vimtex#view#lektra#cmdline(s:pdf, 1, 1))
let g:vimtex_view_forward_search_on_start = 1

" Options are only applied when starting a new viewer instance
let g:vimtex_view_lektra_options = '--layout single'
call assert_equal(
      \ printf("%s --layout single --synctex-forward '%s#%s:7:3'",
      \        s:prefix, s:pdf, s:tex),
      \ vimtex#view#lektra#cmdline(s:pdf, 1, 1))
call assert_equal(
      \ printf("%s --synctex-forward '%s#%s:7:3'", s:prefix, s:pdf, s:tex),
      \ vimtex#view#lektra#cmdline(s:pdf, 1, 0))

call vimtex#test#finished()
