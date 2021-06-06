set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

let g:vimtex_toc_custom_matchers = [
      \ { 'title' : 'My Custom Environment',
      \   're' : '\v^\s*\\begin\{quote\}' }
      \]

silent edit main.tex

if empty($INMAKE) | finish | endif

let s:toc = vimtex#toc#get_entries()

" let s:i = 0
" for s:x in s:toc
"   echo s:i '--' s:x.title "\n"
"   let s:i += 1
" endfor

call assert_equal(19, len(s:toc))
call assert_equal('chapters/sections/first.tex', s:toc[5].file)
call assert_equal('chapters/sections/second.tex', s:toc[8].file)
call assert_equal(
      \ 'eq:1                        (4.1 [p. 9])',
      \ s:toc[17].title)

call vimtex#test#finished()
