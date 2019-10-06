set nocompatible
let &rtp = '../../..,' . &rtp

function! TestBackend(bibfile, backend) abort
  let g:vimtex_parser_bib_backend = a:backend
  return vimtex#parser#bib(a:bibfile)
endfunction

let s:parsed = TestBackend('test.bib', 'bibtex')
call vimtex#test#assert_equal(len(s:parsed), 5)

let s:parsed = TestBackend('test.bib', 'bibparse')
call vimtex#test#assert_equal(len(s:parsed), 6)

let s:parsed = TestBackend('test.bib', 'vim')
call vimtex#test#assert_equal(len(s:parsed), 6)

let s:parsed = TestBackend(
      \ '/usr/share/texmf-dist/bibtex/bib/biblatex/biblatex/biblatex-examples.bib',
      \ 'bibtex')
call vimtex#test#assert_equal(len(s:parsed), 92)

let s:parsed = TestBackend(
      \ '/usr/share/texmf-dist/bibtex/bib/biblatex/biblatex/biblatex-examples.bib',
      \ 'bibparse')
call vimtex#test#assert_equal(len(s:parsed), 92)

let s:parsed = TestBackend(
      \ '/usr/share/texmf-dist/bibtex/bib/biblatex/biblatex/biblatex-examples.bib',
      \ 'vim')
call vimtex#test#assert_equal(len(s:parsed), 92)

quit!
