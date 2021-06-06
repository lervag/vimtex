" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#test#finished() abort " {{{1
  for l:error in v:errors
    let l:match = matchlist(l:error, '\(.*\) line \(\d\+\): \(.*\)')
    let l:file = fnamemodify(l:match[1], ':.')
    let l:lnum = l:match[2]
    let l:msg = l:match[3]
    echo printf("%s:%d: %s\n", l:file, l:lnum, l:msg)
  endfor

  if len(v:errors) > 0
    cquit
  else
    quitall!
  endif
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
function! vimtex#test#main(file, expected) abort " {{{1
  execute 'silent edit' fnameescape(a:file)

  let l:expected = empty(a:expected) ? '' : fnamemodify(a:expected, ':p')
  call assert_true(exists('b:vimtex'))
  call assert_equal(l:expected, b:vimtex.tex)

  bwipeout!
endfunction

" }}}1

function! s:fail(...) abort " {{{1
  echo 'Assertion failed!'

  if a:0 > 0 && !empty(a:1)
    if type(a:1) == v:t_string
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
