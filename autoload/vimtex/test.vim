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
function! vimtex#test#assert_equal(expect, observe) abort " {{{1
  if a:expect ==# a:observe | return 1 | endif

  call s:fail([
        \ 'expect:  ' . string(a:expect),
        \ 'observe: ' . string(a:observe),
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

  let l:fail_msg = ['keys: ' . a:keys]
  let l:fail_msg += ['context:']
  let l:fail_msg += map(copy(a:context), '"  " . v:val')
  let l:fail_msg += ['expected:']
  let l:fail_msg += map(copy(a:expected), '"  " . v:val')

  try
    silent execute 'normal' a:keys
  catch
    let l:fail_msg += ['error:']
    let l:fail_msg += ['  ' . v:exception]
    call s:fail(l:fail_msg)
  endtry

  let l:result = getline(1, line('$'))
  if l:result ==# a:expected | return 1 | endif

  let l:fail_msg += ['result:']
  let l:fail_msg += map(l:result, '"  " . v:val')
  call s:fail(l:fail_msg)
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
