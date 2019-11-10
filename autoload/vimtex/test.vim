" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#test#assert(condition) abort " {{{1
  if a:condition | return 1 | endif

  call s:fail()
endfunction

" }}}1
function! vimtex#test#assert_equal(x, y) abort " {{{1
  if a:x ==# a:y | return 1 | endif

  call s:fail([
        \ 'x = ' . string(a:x),
        \ 'y = ' . string(a:y),
        \])
endfunction

" }}}1
function! vimtex#test#assert_match(x, regex) abort " {{{1
  if a:x =~# a:regex | return 1 | endif

  call s:fail([
        \ 'x = ' . string(a:x),
        \ 'regex = ' . a:regex,
        \])
endfunction

" }}}1

function! vimtex#test#completion(context, ...) abort " {{{1
  let l:base = a:0 > 0 ? a:1 : ''

  try
    silent execute 'normal GO' . a:context . "\<c-x>\<c-o>"
    silent normal! u
    return vimtex#complete#omnifunc(0, l:base)
  catch /.*/
    call s:fail(v:exception)
  endtry
endfunction

" }}}1
function! vimtex#test#keys(keys, context, expected) abort " {{{1
  normal! gg0dG
  call append(1, a:context)
  normal! ggdd

  silent execute 'normal' a:keys

  call vimtex#test#assert_equal(getline(1, line('$')), a:expected)
endfunction

" }}}1

function! s:fail(...) abort " {{{1
  echo 'Assertion failed!'

  if a:0 > 0 && !empty(a:1)
    if type(a:1) == type('')
      echo a:1
    else
      for line in a:1
        echo line
      endfor
    endif
  endif
  echon "\n"

  cquit
endfunction

" }}}1
