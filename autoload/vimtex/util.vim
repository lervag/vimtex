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
    return shellescape(a:cmd)
  endif
endfunction

" }}}1
function! vimtex#util#get_os() " {{{1
  if has('win32')
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
function! vimtex#util#uniq(list) " {{{1
  if exists('*uniq')
    return uniq(a:list)
  elseif len(a:list) == 0
    return a:list
  endif

  let l:last = get(a:list, 0)
  let l:ulist = [l:last]

  for l:i in range(1, len(a:list) - 1)
    let l:next = get(a:list, l:i)
    if l:next != l:last
      let l:last = l:next
      call add(l:ulist, l:next)
    endif
  endfor

  return l:ulist
endfunction

" }}}1

" vim: fdm=marker sw=2
