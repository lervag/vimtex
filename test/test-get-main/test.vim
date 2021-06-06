set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set nomore

" Ugly paths
call vimtex#test#main('test-ugly-paths/[code college-1] title/test.tex',
      \ 'test-ugly-paths/[code college-1] title/test.tex')

" Simple recursion
call vimtex#test#main('simple.tex', 'simple.tex')

" Respect the TeX Root directive
call vimtex#test#main('test-texroot/included.tex', 'test-texroot/main.tex')

" Note: Even "something.tex" should use the proposed main file even if it is
"       not included.
for s:filename in [
      \ 'test-latexmain/included.tex',
      \ 'test-latexmain/section1/main.tex',
      \ 'test-latexmain/something.tex']
  call vimtex#test#main(s:filename, 'test-latexmain/main.tex')
endfor

" Test recursive searching and included files with subfiles
for s:filename in [
    \ 'test-includes/test/sub/include2.tex',
    \ 'test-includes/include3.tex',
    \ 'test-includes/subfile.tex']
  call vimtex#test#main(s:filename, 'test-includes/main.tex')
endfor

" Test subfiles 1: Recursive search
call vimtex#test#main('test-subfiles/sub/sub1.tex', 'test-subfiles/main.tex')

" Test subfiles 2: Recursive search, but the match does not include sub2
call vimtex#test#main('test-subfiles/sub/sub2.tex', 'test-subfiles/sub/sub2.tex')

" Test subfiles 3: Recursive search, not .tex extension
call vimtex#test#main('test-subfiles/sub/sub3.tex', 'test-subfiles/main.tex')

" Test subfiles 4: g:vimtex_subfile_start_local
let g:vimtex_subfile_start_local = 1
call vimtex#test#main('test-subfiles/sub/sub3.tex', 'test-subfiles/sub/sub3.tex')
let g:vimtex_subfile_start_local = 0

" Test mainfile specified in .latexmrc
call vimtex#test#main('test-latexmk/preamble.tex', 'test-latexmk/main.tex')

" Test mainfile from bibfiles
call vimtex#test#main('test-bib-simple/references.bib', 'test-bib-simple/main.tex')
call vimtex#test#main('test-bib-notfound/references.bib', '')
call vimtex#test#main('test-bib-alternate/references.bib', '')

execute 'silent edit' fnameescape('test-bib-alternate/main.tex')
call vimtex#test#main('test-bib-alternate/references.bib', 'test-bib-alternate/main.tex')

call vimtex#test#finished()
