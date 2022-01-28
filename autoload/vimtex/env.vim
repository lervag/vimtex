" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#env#init_buffer() abort " {{{1
  nnoremap <silent><buffer> <plug>(vimtex-env-change)
        \ :<c-u>call <sid>operator_setup('change', 'normal')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-change-math)
        \ :<c-u>call <sid>operator_setup('change', 'math')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-delete)
        \ :<c-u>call <sid>operator_setup('delete', 'normal')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-delete-math)
        \ :<c-u>call <sid>operator_setup('delete', 'math')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-toggle-star)
        \ :<c-u>call <sid>operator_setup('toggle_star', '')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-toggle-math)
        \ :<c-u>call <sid>operator_setup('toggle_math', '')<bar>normal! g@l<cr>
endfunction

" }}}1

function! vimtex#env#get_surrounding(type) abort " {{{1
  " Get surrounding environment delimiters.
  "
  " This works similar to vimtex#delim#get_surrounding, except specialized for
  " environments. For normal environments it is equivalent to
  " vimtex#delim#get_surrounding('env_tex'). For math environments it combines
  " the 'env_math' delimiter type with normal known math environments.

  if a:type ==# 'normal'
    return vimtex#delim#get_surrounding('env_tex')
  endif

  if a:type !=# 'math'
    call vimtex#log#error('Wrong argument!')
    return [{}, {}]
  endif

  " First check for special math env delimiters
  let [l:open, l:close] = vimtex#delim#get_surrounding('env_math')
  if !empty(l:open) | return [l:open, l:close] | endif

  " Next check for standard math environments (only works for 1 level depth)
  let [l:open, l:close] = vimtex#delim#get_surrounding('env_tex')
  if !empty(l:open) &&
        \ index(s:math_envs, substitute(l:open.name, '\*$', '', '')) >= 0
    return [l:open, l:close]
  endif

  return [{}, {}]
endfunction

let s:math_envs = [
      \ 'align',
      \ 'alignat',
      \ 'displaymath',
      \ 'eqnarray',
      \ 'equation',
      \ 'flalign',
      \ 'gather',
      \ 'math',
      \ 'mathpar',
      \ 'multline',
      \ 'xalignat',
      \ 'xxalignat',
      \]

" }}}1

function! vimtex#env#get_inner() abort " {{{1
  let [l:open, l:close] = vimtex#env#get_surrounding('normal')

  return empty(l:open) || l:open.name ==# 'document'
        \ ? {}
        \ : {'name': l:open.name, 'open': l:open, 'close': l:close}
endfunction

" }}}1
function! vimtex#env#get_outer() abort " {{{1
  let l:save_pos = vimtex#pos#get_cursor()
  let l:current = {}

  while v:true
    let l:env = vimtex#env#get_inner()
    if empty(l:env)
      call vimtex#pos#set_cursor(l:save_pos)
      return l:current
    endif

    let l:current = l:env
    call vimtex#pos#set_cursor(vimtex#pos#prev(l:env.open))
  endwhile
endfunction

" }}}1
function! vimtex#env#get_all() abort " {{{1
  let l:save_pos = vimtex#pos#get_cursor()
  let l:stack = []

  while v:true
    let l:env = vimtex#env#get_inner()
    if empty(l:env)
      call vimtex#pos#set_cursor(l:save_pos)
      return l:stack
    endif

    call add(l:stack, l:env)
    call vimtex#pos#set_cursor(vimtex#pos#prev(l:env.open))
  endwhile
endfunction

" }}}1

function! vimtex#env#change_surrounding(type, new) abort " {{{1
  let [l:open, l:close] = vimtex#env#get_surrounding(a:type)
  if empty(l:open) | return | endif

  return vimtex#env#change(l:open, l:close, a:new)
endfunction

function! vimtex#env#change(open, close, new) abort " {{{1
  " Set target environment
  if a:new ==# ''
    let [l:beg, l:end] = ['', '']
  elseif a:new ==# '$'
    return vimtex#env#change_to_inline_math(a:open, a:close)
  elseif a:new ==# '$$'
    let [l:beg, l:end] = ['$$', '$$']
  elseif a:new ==# '\['
    if a:open.match ==# '$'
      return vimtex#env#change_to_displaymath(a:open, a:close)
    endif
    let [l:beg, l:end] = ['\[', '\]']
  elseif a:new ==# '\('
    let [l:beg, l:end] = ['\(', '\)']
  else
    let l:beg = '\begin{' . a:new . '}'
    let l:end = '\end{' . a:new . '}'
  endif

  let l:line = getline(a:open.lnum)
  call setline(a:open.lnum,
        \   strpart(l:line, 0, a:open.cnum-1)
        \ . l:beg
        \ . strpart(l:line, a:open.cnum + len(a:open.match) - 1))

  let l:c1 = a:close.cnum
  let l:c2 = a:close.cnum + len(a:close.match) - 1
  if a:open.lnum == a:close.lnum
    let n = len(l:beg) - len(a:open.match)
    let l:c1 += n
    let l:c2 += n
    let pos = vimtex#pos#get_cursor()
    if pos[2] > a:open.cnum + len(a:open.match) - 1
      let pos[2] += n
      call vimtex#pos#set_cursor(pos)
    endif
  endif

  let l:line = getline(a:close.lnum)
  call setline(a:close.lnum,
        \ strpart(l:line, 0, l:c1-1) . l:end . strpart(l:line, l:c2))
endfunction

function! vimtex#env#change_to_inline_math(open, close) abort " {{{1
  let l:line = getline(a:close.lnum)
  if l:line =~# '^\s*\\]\s*$'
    let l:line = substitute(getline(a:close.lnum - 1), '\s*$', '$', '')
    call setline(a:close.lnum - 1, l:line)
    execute a:close.lnum . 'delete _'
    if !empty(vimtex#util#trim(getline(a:close.lnum)))
      execute (a:close.lnum - 1) . 'join'
    endif
  elseif l:line =~# '^\s*\\]'
    let l:line1 = substitute(getline(a:close.lnum - 1), '\s*$', '$', '')
    let l:line2 = substitute(strpart(l:line, a:close.cnum + 1), '^\s*', ' ', '')
    call setline(a:close.lnum - 1, l:line1 . l:line2)
    execute a:close.lnum . 'delete _'
  else
    let l:line1 = substitute(strpart(l:line, 0, a:close.cnum - 1), '\s*$', '$', '')
    let l:line2 = strpart(l:line, a:close.cnum + len(a:close.match) - 1)
    call setline(a:close.lnum, l:line1 . l:line2)
  endif

  let l:line = getline(a:open.lnum)
  if l:line =~# '^\s*\\[\s*$'
    execute a:open.lnum . 'delete _'
    let l:line1 = substitute(getline(a:open.lnum - 1), '\s*$', ' ', '')
    let l:line2 = substitute(getline(a:open.lnum), '^\s*', '$', '')
    if l:line1 =~# '^\s*$'
      call setline(a:open.lnum, matchstr(l:line, '^\s*') . l:line2)
      call vimtex#pos#set_cursor([a:open.lnum, a:open.cnum])
    else
      call setline(a:open.lnum - 1, l:line1 . l:line2)
      execute a:open.lnum . 'delete _'
      call vimtex#pos#set_cursor([a:open.lnum - 1, strlen(l:line1)+1])
    endif
  elseif l:line =~# '\\[\s*$'
    let l:line1 = strpart(l:line, 0, a:open.cnum-1)
    let l:line2 = substitute(getline(a:open.lnum + 1), '^\s*', '$', '')
    call setline(a:open.lnum, l:line1 . l:line2)
    execute (a:open.lnum + 1) . 'delete _'
    call vimtex#pos#set_cursor([a:open.lnum, a:open.cnum])
  else
    let l:line1 = strpart(l:line, 0, a:open.cnum-1)
    let l:line2 = substitute(
          \ strpart(l:line, a:open.cnum + len(a:open.match) - 1),
          \ '^\s*', '$', '')
    call setline(a:open.lnum, l:line1 . l:line2)
    call vimtex#pos#set_cursor([a:open.lnum, a:open.cnum])
  endif
endfunction

function! vimtex#env#change_to_displaymath(open, close) abort " {{{1
  let l:pos = vimtex#pos#get_cursor()
  let l:nlines = a:close.lnum - a:open.lnum - 1 + 3

  let l:line = getline(a:close.lnum)
  let l:pre = substitute(
        \ strpart(l:line, 0, a:close.cnum - 1),
        \ '\s*$', '', '')
  call setline(a:close.lnum, l:pre)
  call append(a:close.lnum, '\]')
  let l:post = substitute(
        \ strpart(l:line, a:close.cnum + len(a:close.match) - 1),
        \ '^\s*', '', '')
  if !empty(l:post)
    call append(a:close.lnum+1, l:post)
    let l:nlines += 1
  endif

  let l:line = getline(a:open.lnum)
  let l:pre = substitute(
        \ strpart(l:line, 0, a:open.cnum - 1),
        \ '\s*$', '', '')
  let l:post = substitute(
        \ strpart(l:line, a:open.cnum + len(a:open.match) - 1),
        \ '^\s*', '', '')
  if !empty(l:pre)
    call setline(a:open.lnum, l:pre)
    call append(a:open.lnum, ['\[', l:post])
    call vimtex#pos#set_cursor(a:open.lnum+1, 1)
    let l:pos[1] += 2
  else
    call setline(a:open.lnum, '\[')
    call append(a:open.lnum, l:post)
    call vimtex#pos#set_cursor(a:open.lnum, 1)
    let l:pos[1] += 1
  endif

  " Indent the lines
  silent execute printf('normal! =%dj', l:nlines)

  " Adjust cursor position
  let l:pos[2] -= a:open.cnum - indent(a:open.lnum) - &shiftwidth
  call vimtex#pos#set_cursor(l:pos)
endfunction

" }}}1

function! vimtex#env#delete(type) abort " {{{1
  let [l:open, l:close] = vimtex#env#get_surrounding(a:type)
  if empty(l:open) | return | endif

  if a:type ==# 'normal'
    call vimtex#cmd#delete_all(l:close)
    call vimtex#cmd#delete_all(l:open)
  else
    call l:close.remove()
    call l:open.remove()
  endif

  if getline(l:close.lnum) =~# '^\s*$'
    execute l:close.lnum . 'd _'
  endif

  if getline(l:open.lnum) =~# '^\s*$'
    execute l:open.lnum . 'd _'
  endif
endfunction

function! vimtex#env#toggle_star() abort " {{{1
  let [l:open, l:close] = vimtex#env#get_surrounding('normal')
  if empty(l:open)
        \ || l:open.name ==# 'document' | return | endif

  call vimtex#env#change(l:open, l:close,
        \ l:open.starred ? l:open.name : l:open.name . '*')
endfunction

" }}}1
function! vimtex#env#toggle_math() abort " {{{1
  let [l:open, l:close] = vimtex#env#get_surrounding('math')
  if empty(l:open) | return | endif

  if l:open.match ==# '$' || l:open.match ==# '\('
    let l:target = '\['
  else
    let l:target = '$'
  endif

  call vimtex#env#change(l:open, l:close, l:target)
endfunction

" }}}1

function! vimtex#env#is_inside(env) abort " {{{1
  let l:re_start = '\\begin\s*{' . a:env . '\*\?}'
  let l:re_end = '\\end\s*{' . a:env . '\*\?}'
  try
    return searchpairpos(l:re_start, '', l:re_end, 'bnW', '', 0, 100)
  catch /E118/
    let l:stopline = max([line('.') - 500, 1])
    return searchpairpos(l:re_start, '', l:re_end, 'bnW', '', l:stopline)
  endtry
endfunction

" }}}1
function! vimtex#env#input_complete(lead, cmdline, pos) abort " {{{1
  let l:cands = map(vimtex#complete#complete('env', '', '\begin'), 'v:val.word')

  " Never include document and remove current env (place it first)
  call filter(l:cands, "index(['document', s:env_name], v:val) < 0")

  " Always include current env and displaymath
  let l:cands = [s:env_name] + l:cands + ['\[']

  return filter(l:cands, {_, x -> x =~# '^' . a:lead})
endfunction

" }}}1

function! s:change_prompt(type) abort " {{{1
  let [l:open, l:close] = vimtex#env#get_surrounding(a:type)
  if empty(l:open) | return | endif

  if g:vimtex_env_change_autofill
    let l:name = get(l:open, 'name', l:open.match)
    let s:env_name = l:name
    return vimtex#echo#input({
          \ 'prompt' : 'Change surrounding environment: ',
          \ 'default' : l:name,
          \ 'complete' : 'customlist,vimtex#env#input_complete',
          \})
  else
    let l:name = get(l:open, 'name', l:open.is_open
          \ ? l:open.match . ' ... ' . l:open.corr
          \ : l:open.match . ' ... ' . l:open.corr)
    let s:env_name = l:name
    return vimtex#echo#input({
          \ 'info' :
          \   ['Change surrounding environment: ', ['VimtexWarning', l:name]],
          \ 'complete' : 'customlist,vimtex#env#input_complete',
          \})
  endif
endfunction

" }}}1

function! s:operator_setup(operator, type) abort " {{{1
  let &opfunc = s:snr() . 'operator_function'

  let s:operator_abort = 0
  let s:operator = a:operator
  let s:operator_type = a:type

  " Ask for user input if necessary/relevant
  if s:operator ==# 'change'
    let l:new_env = s:change_prompt(s:operator_type)
    if empty(l:new_env)
      let s:operator_abort = 1
      return
    endif

    let s:operator_name = l:new_env
  endif
endfunction

" }}}1
function! s:operator_function(_) abort " {{{1
  if get(s:, 'operator_abort', 0) | return | endif

  let l:type = get(s:, 'operator_type', '')
  let l:name = get(s:, 'operator_name', '')

  execute 'call vimtex#env#' . {
        \   'change': 'change_surrounding(l:type, l:name)',
        \   'delete': 'delete(l:type)',
        \   'toggle_star': 'toggle_star()',
        \   'toggle_math': 'toggle_math()',
        \ }[s:operator]
endfunction

" }}}1
function! s:snr() abort " {{{1
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

" }}}1
