set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

function! TestMain(file, expected) abort " {{{1
  execute 'silent edit' fnameescape(a:file)
  call vimtex#test#assert_equal(b:vimtex.tex, fnamemodify(a:expected, ':p'))
  bwipeout!
endfunction

" }}}1

let g:tex_flavor = 'latex'

" Ugly paths
call TestMain('test-ugly-paths/[code college-1] title/test.tex',
      \ 'test-ugly-paths/[code college-1] title/test.tex')

" Simple recursion
call TestMain('simple.tex', 'simple.tex')

" Respect the TeX Root directive
call TestMain('test-texroot/included.tex', 'test-texroot/main.tex')

" Note: Even "something.tex" should use the proposed main file even if it is
"       not included.
for s:filename in [
      \ 'test-latexmain/included.tex',
      \ 'test-latexmain/section1/main.tex',
      \ 'test-latexmain/something.tex']
  call TestMain(s:filename, 'test-latexmain/main.tex')
endfor

" Test recursive searching and included files with subfiles
for s:filename in [
    \ 'test-includes/test/sub/include2.tex',
    \ 'test-includes/include3.tex',
    \ 'test-includes/subfile.tex']
  call TestMain(s:filename, 'test-includes/main.tex')
endfor

" Test subfiles 1: Recursive search
call TestMain('test-subfiles/sub/sub1.tex', 'test-subfiles/main.tex')

" Test subfiles 2: Recursive search, but the match does not include sub2
call TestMain('test-subfiles/sub/sub2.tex', 'test-subfiles/sub/sub2.tex')

" Test subfiles 3: Recursive search, not .tex extension
call TestMain('test-subfiles/sub/sub3.tex', 'test-subfiles/main.tex')

" Test mainfile specified in .latexmrc
call TestMain('test-latexmk/preamble.tex', 'test-latexmk/main.tex')

quit!
