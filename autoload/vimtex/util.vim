" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#util#command(cmd) " {{{1
  let l:a = @a
  try
    silent! redir @a
    silent! execute a:cmd
    redir END
  finally
    let l:res = @a
    let @a = l:a
    return split(l:res, "\n")
  endtry
endfunction

" }}}1
function! vimtex#util#get_os() " {{{1
  if has('win32') || has('win32unix')
    return 'win'
  elseif has('unix')
    if system('uname') =~# 'Darwin'
      return 'mac'
    else
      return 'linux'
    endif
  endif
endfunction

" }}}1
function! vimtex#util#in_comment(...) " {{{1
  return call('vimtex#util#in_syntax', ['texComment'] + a:000)
endfunction

" }}}1
function! vimtex#util#in_mathzone(...) " {{{1
  return call('vimtex#util#in_syntax', ['texMathZone'] + a:000)
endfunction

" }}}1
function! vimtex#util#in_syntax(name, ...) " {{{1

  " Usage: vimtex#util#in_syntax(name, [line, col])

  " Get position and correct it if necessary
  let l:pos = a:0 > 0 ? [a:1, a:2] : [line('.'), col('.')]
  if mode() ==# 'i'
    let l:pos[1] -= 1
  endif
  call map(l:pos, 'max([v:val, 1])')

  " Check syntax at position
  return match(map(synstack(l:pos[0], l:pos[1]),
        \          "synIDattr(v:val, 'name')"),
        \      '^' . a:name) >= 0
endfunction

" }}}1
function! vimtex#util#extend_recursive(dict1, dict2, ...) " {{{1
  let l:option = a:0 > 0 ? a:1 : 'force'
  if index(['force', 'keep', 'error'], l:option) < 0
    throw 'E475: Invalid argument: ' . l:option
  endif

  for [l:key, l:value] in items(a:dict2)
    if !has_key(a:dict1, l:key)
      let a:dict1[l:key] = l:value
    elseif type(l:value) == type({})
      call vimtex#util#extend_recursive(a:dict1[l:key], l:value, l:option)
    elseif l:option ==# 'error'
      throw 'E737: Key already exists: ' . l:key
    elseif l:option ==# 'force'
      let a:dict1[l:key] = l:value
    endif
  endfor

  return a:dict1
endfunction

" }}}1
function! vimtex#util#shellescape(cmd) " {{{1
  "
  " Path used in "cmd" only needs to be enclosed by double quotes.
  " shellescape() on Windows with "shellslash" set will produce a path
  " enclosed by single quotes, which "cmd" does not recognize and reports an
  " error.
  "
  if has('win32')
    let l:shellslash = &shellslash
    set noshellslash
    let l:cmd = escape(shellescape(a:cmd), '\')
    let &shellslash = l:shellslash
    return l:cmd
  else
    return escape(shellescape(a:cmd), '\')
  endif
endfunction

" }}}1
function! vimtex#util#uniq(list) " {{{1
  if exists('*uniq') | return uniq(a:list) | endif
  if len(a:list) <= 1 | return a:list | endif

  let l:uniq = [a:list[0]]
  for l:next in a:list[1:]
    if l:uniq[-1] != l:next
      call add(l:uniq, l:next)
    endif
  endfor
  return l:uniq
endfunction

" }}}1
function! vimtex#util#uniq_unsorted(list) " {{{1
  if len(a:list) <= 1 | return a:list | endif

  let l:visited = [a:list[0]]
  for l:index in reverse(range(1, len(a:list)-1))
    if index(l:visited, a:list[l:index]) >= 0
      call remove(a:list, l:index)
    else
      call add(l:visited, a:list[l:index])
    endif
  endfor
  return a:list
endfunction

" }}}1
