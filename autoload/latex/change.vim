" {{{1 latex#change#init
function! latex#change#init(initialized)
  if g:latex_mappings_enabled
    nnoremap <silent><buffer> dse :call latex#change#env('')<cr>

    nnoremap <silent><buffer> cse :call latex#change#env_prompt()<cr>

    nnoremap <silent><buffer> tse :call latex#change#toggle_env_star()<cr>
    nnoremap <silent><buffer> tsd :call latex#change#toggle_delim()<cr>
  endif
endfunction

" {{{1 latex#change#delim
function! latex#change#delim(open, close)
  let [d1, l1, c1, d2, l2, c2] = latex#util#get_delim()

  let line = getline(l1)
  let line = strpart(line,0,c1 - 1) . a:open . strpart(line, c1 + len(d1) - 1)
  call setline(l1, line)

  if l1 == l2
    let n = len(a:open) - len(d1)
    let c2 += n
    let pos = getpos('.')
    let pos[2] += n
    call setpos('.', pos)
  endif

  let line = getline(l2)
  let line = strpart(line,0,c2 - 1) . a:close . strpart(line, c2 + len(d2) - 1)
  call setline(l2, line)
endfunction

" {{{1 latex#change#env
function! latex#change#env(new_env)
  let [env, l1, c1, l2, c2] = latex#util#get_env(1)

  if a:new_env == ''
    let beg = ''
    let end = ''
  elseif a:new_env == '\[' || a:new_env == '['
    let beg = '\['
    let end = '\]'
  elseif a:new_env == '\(' || a:new_env == '('
    let beg = '\('
    let end = '\)'
  else
    let beg = '\begin{' . a:new_env . '}'
    let end = '\end{' . a:new_env . '}'
  endif

  let n1 = len(env) - 1
  let n2 = len(env) - 1
  if env != '\[' && env != '\('
    let n1 += 8
    let n2 += 6
  endif

  let line = getline(l1)
  let line = strpart(line, 0, c1 - 1) . l:beg . strpart(line, c1 + n1)
  call setline(l1, line)
  let line = getline(l2)
  let line = strpart(line, 0, c2 - 1) . l:end . strpart(line, c2 + n2)
  call setline(l2, line)
endfunction

" {{{1 latex#change#env_prompt
function! latex#change#env_prompt()
  let new_env = input('Change ' . latex#util#get_env() . ' for: ', '',
        \ 'customlist,' . s:sidwrap('input_complete'))
  if empty(new_env)
    return
  else
    call latex#change#env(new_env)
  endif
endfunction

" {{{1 latex#change#toggle_delim
function! latex#change#toggle_delim()
  "
  " Toggle \left and \right variants of delimiters
  "
  let [d1, l1, c1, d2, l2, c2] = latex#util#get_delim()

  if d1 == ''
    return 0
  elseif d1 =~ 'left'
    let newd1 = substitute(d1, '\\left', '', '')
    let newd2 = substitute(d2, '\\right', '', '')
  elseif d1 !~ '\cbigg\?'
    let newd1 = '\left' . d1
    let newd2 = '\right' . d2
  else
    return
  endif

  let line = getline(l1)
  let line = strpart(line, 0, c1 - 1) . newd1 . strpart(line, c1 + len(d1) - 1)
  call setline(l1, line)

  if l1 == l2
    let n = len(newd1) - len(d1)
    let c2 += n
    let pos = getpos('.')
    let pos[2] += n
    call setpos('.', pos)
  endif

  let line = getline(l2)
  let line = strpart(line, 0, c2 - 1) . newd2 . strpart(line, c2 + len(d2) - 1)
  call setline(l2, line)
endfunction

" {{{1 latex#change#toggle_env_star
function! latex#change#toggle_env_star()
  let env = latex#util#get_env()

  if env == '\('
    return
  elseif env == '\['
    let new_env = equation
  elseif env[-1:] == '*'
    let new_env = env[:-2]
  else
    let new_env = env . '*'
  endif

  call latex#change#env(new_env)
endfunction


" {{{1 latex#change#wrap_selection
function! latex#change#wrap_selection(wrapper)
  keepjumps normal! `>a}
  execute 'keepjumps normal! `<i\' . a:wrapper . '{'
endfunction

" {{{1 latex#change#wrap_selection_prompt
function! latex#change#wrap_selection_prompt(...)
  let env = input('Environment: ', '',
        \ 'customlist,' . s:sidwrap('input_complete'))
  if empty(env)
    return
  endif

  " Make sure custom indentation does not interfere
  let ieOld = &indentexpr
  setlocal indentexpr=""

  if visualmode() ==# 'V'
    execute 'keepjumps normal! `>o\end{' . env . '}'
    execute 'keepjumps normal! `<O\begin{' . env . '}'
    " indent and format, if requested.
    if a:0 && a:1
      normal! gv>
      normal! gvgq
    endif
  else
    execute 'keepjumps normal! `>a\end{' . env . '}'
    execute 'keepjumps normal! `<i\begin{' . env . '}'
  endif

  exe "setlocal indentexpr=" . ieOld
endfunction
" }}}1

" {{{1 s:sidwrap
let s:SID = matchstr(expand('<sfile>'), '\zs<SNR>\d\+_\ze.*$')
function! s:sidwrap(func)
  return s:SID . a:func
endfunction

" {{{1 s:input_complete
function! s:input_complete(lead, cmdline, pos)
  let suggestions = []
  for entry in g:latex_complete_environments
    let env = entry.word
    if env =~ '^' . a:lead
      call add(suggestions, env)
    endif
  endfor
  return suggestions
endfunction

" {{{1 s:search_and_skip_comments
function! s:search_and_skip_comments(pat, ...)
  " Usage: s:search_and_skip_comments(pat, [flags, stopline])
  let flags             = a:0 >= 1 ? a:1 : ''
  let stopline  = a:0 >= 2 ? a:2 : 0
  let saved_pos = getpos('.')

  " search once
  let ret = search(a:pat, flags, stopline)

  if ret
    " do not match at current position if inside comment
    let flags = substitute(flags, 'c', '', 'g')

    " keep searching while in comment
    while latex#util#in_comment()
      let ret = search(a:pat, flags, stopline)
      if !ret
        break
      endif
    endwhile
  endif

  if !ret
    " if no match found, restore position
    call setpos('.', saved_pos)
  endif

  return ret
endfunction
" }}}1

" vim:fdm=marker:ff=unix
