" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#test#finished() abort " {{{1
  for l:error in v:errors
    let l:match = matchlist(l:error, '\v(.{-})( line (\d+))?: (.*)')
    let l:file = fnamemodify(l:match[1], ':.')
    let l:lnum = l:match[3]
    let l:msg = l:match[4]

    if l:msg =~# 'Expected .*but got'
      call s:print_expected_but_got(l:file, l:lnum, l:msg)
    elseif l:msg =~# 'Pattern.*does\( not\)\? match'
      call s:print_pattern_does_not_match(l:file, l:lnum, l:msg)
    else
      echo printf("%s:%d: %s\n", l:file, l:lnum, l:msg)
    endif
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
  catch
    call assert_report(
          \ printf("\n  Context: %s\n  Base: %s\n%s",
          \        a:context, l:base, v:exception))
    return []
  endtry
endfunction

" }}}1
function! vimtex#test#keys(keys, context, expect) abort " {{{1
  bwipeout!
  setfiletype tex

  if type(a:context) == v:t_string
    let l:ctx = [a:context]
    let l:msg_context = printf("Context: %s", a:context)
  else
    let l:ctx = a:context
    let l:msg_context = printf("Context:\n%s", join(a:context, "\n"))
  endif

  try
    call append(1, l:ctx)
    normal! ggdd
    silent execute 'normal' a:keys
  catch
    call assert_report(
          \ printf("\n  Keys: %s\n  %s\n%s",
          \        a:keys, l:msg_context, v:exception))
  endtry

  let l:observe = getline(1, line('$'))
  let l:observe = type(a:expect) == v:t_string
        \ ? join(l:observe)
        \ : l:observe

  call assert_equal(a:expect, l:observe,
        \ printf("Keys: %s\n  %s", a:keys, l:msg_context))
endfunction

" }}}1
function! vimtex#test#main(file, expected, ...) abort " {{{1
  execute 'silent edit' fnameescape(a:file)

  " ToggleMain if extra arg supplied
  if a:0 > 0
    VimtexToggleMain
  endif

  let l:expected = empty(a:expected) ? '' : fnamemodify(a:expected, ':p')
  call assert_true(exists('b:vimtex'))
  call assert_equal(fnamemodify(l:expected, ':.'), fnamemodify(b:vimtex.tex, ':.'))

  bwipeout!
endfunction

" }}}1

function! s:print_expected_but_got(file, lnum, msg) abort " {{{1
  if !empty(a:lnum)
    echo printf("%s:%d\n", a:file, a:lnum)
  else
    echo printf("%s:\n", a:file)
  endif

  let l:intro = matchstr(a:msg, '.\{-}\ze\s*\(: \)\?Expected ')
  if !empty(l:intro)
    echo printf("  %s\n", l:intro)
  endif

  call s:print_msg_with_title(
        \ 'Expected', matchstr(a:msg, 'Expected \zs.*\zebut got'))
  call s:print_msg_with_title(
        \ 'Observed', matchstr(a:msg, 'Expected .*but got \zs.*'))

  echo ''
endfunction

" }}}1
function! s:print_pattern_does_not_match(file, lnum, msg) abort " {{{1
  echo printf("%s:%d\n", a:file, a:lnum)

  let l:intro = matchstr(a:msg, '.\{-}\ze\s*\(: \)\?Pattern ')
  if !empty(l:intro)
    echo printf("  %s\n", l:intro)
  endif

  let l:expect = matchstr(a:msg, 'Pattern.*does\( not\)\? match.*')
  echo printf("  %s\n", l:expect)
endfunction

" }}}1
function! s:print_msg_with_title(title, msg) abort " {{{1
  if a:msg[0] ==# '['
    echo printf("  %s:", a:title)
    for l:line in json_decode(substitute(escape(a:msg, '"'), "'", '"', 'g'))
      echo '   |' .. l:line
    endfor
  else
    echo printf("  %s: %s\n", a:title, a:msg)
  endif
endfunction

" }}}1
