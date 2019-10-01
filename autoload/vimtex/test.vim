" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#test#assert(x, y) abort " {{{1
  if a:x == a:y | return 1 | endif

  echo 'Assertion failed!'
  echo 'x =' a:x
  echo 'y =' a:y
  echo "---\n"
  cquit
endfunction

" }}}1

function! vimtex#test#completion(context, ...) abort " {{{1
  let l:base = a:0 > 0 ? a:1 : ''

  try
    silent execute 'normal GO' . a:context . "\<c-x>\<c-o>"
    silent normal! u
    return vimtex#complete#omnifunc(0, l:base)
  catch /.*/
    echo v:exception "\n"
    cquit
  endtry
endfunction

" }}}1
