" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#util#command(cmd) abort " {{{1
  return split(execute(a:cmd, 'silent!'), "\n")
endfunction

" }}}1
function! vimtex#util#flatten(list) abort " {{{1
  let l:result = []

  for l:element in a:list
    if type(l:element) == v:t_list
      call extend(l:result, vimtex#util#flatten(l:element))
    else
      call add(l:result, l:element)
    endif
    unlet l:element
  endfor

  return l:result
endfunction

" }}}1
function! vimtex#util#get_os() abort " {{{1
  if has('win32') || has('win32unix')
    return 'win'
  elseif has('unix')
    if has('mac') || system('uname') =~# 'Darwin'
      return 'mac'
    else
      return 'linux'
    endif
  endif
endfunction

" }}}1
function! vimtex#util#extend_recursive(dict1, dict2, ...) abort " {{{1
  let l:option = a:0 > 0 ? a:1 : 'force'
  if index(['force', 'keep', 'error'], l:option) < 0
    throw 'E475: Invalid argument: ' . l:option
  endif

  for [l:key, l:value] in items(a:dict2)
    if !has_key(a:dict1, l:key)
      let a:dict1[l:key] = l:value
    elseif type(l:value) == v:t_dict
      call vimtex#util#extend_recursive(a:dict1[l:key], l:value, l:option)
    elseif l:option ==# 'error'
      throw 'E737: Key already exists: ' . l:key
    elseif l:option ==# 'force'
      let a:dict1[l:key] = l:value
    endif
    unlet l:value
  endfor

  return a:dict1
endfunction

" }}}1
function! vimtex#util#shellescape(cmd) abort " {{{1
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
function! vimtex#util#tex2unicode(line) abort " {{{1
  " Convert compositions to unicode
  let l:line = a:line
  for [l:pat, l:symbol] in s:tex2unicode_list
    let l:line = substitute(l:line, l:pat, l:symbol, 'g')
  endfor

  " Remove the \IeC macro
  let l:line = substitute(l:line, '\C\\IeC\s*{\s*\([^}]\{-}\)\s*}', '\1', 'g')

  return l:line
endfunction

"
" Define list for converting compositions like \"u to unicode ű
let s:tex2unicode_list = map([
      \ ['\\''A', 'Á'],
      \ ['\\`A',  'À'],
      \ ['\\^A',  'À'],
      \ ['\\¨A',  'Ä'],
      \ ['\\"A',  'Ä'],
      \ ['\\''a', 'á'],
      \ ['\\`a',  'à'],
      \ ['\\^a',  'à'],
      \ ['\\¨a',  'ä'],
      \ ['\\"a',  'ä'],
      \ ['\\\~a', 'ã'],
      \ ['\\''E', 'É'],
      \ ['\\`E',  'È'],
      \ ['\\^E',  'Ê'],
      \ ['\\¨E',  'Ë'],
      \ ['\\"E',  'Ë'],
      \ ['\\''e', 'é'],
      \ ['\\`e',  'è'],
      \ ['\\^e',  'ê'],
      \ ['\\¨e',  'ë'],
      \ ['\\"e',  'ë'],
      \ ['\\''I', 'Í'],
      \ ['\\`I',  'Î'],
      \ ['\\^I',  'Ì'],
      \ ['\\¨I',  'Ï'],
      \ ['\\"I',  'Ï'],
      \ ['\\''i', 'í'],
      \ ['\\`i',  'î'],
      \ ['\\^i',  'ì'],
      \ ['\\¨i',  'ï'],
      \ ['\\"i',  'ï'],
      \ ['\\''i', 'í'],
      \ ['\\''O', 'Ó'],
      \ ['\\`O',  'Ò'],
      \ ['\\^O',  'Ô'],
      \ ['\\¨O',  'Ö'],
      \ ['\\"O',  'Ö'],
      \ ['\\''o', 'ó'],
      \ ['\\`o',  'ò'],
      \ ['\\^o',  'ô'],
      \ ['\\¨o',  'ö'],
      \ ['\\"o',  'ö'],
      \ ['\\o',   'ø'],
      \ ['\\''U', 'Ú'],
      \ ['\\`U',  'Ù'],
      \ ['\\^U',  'Û'],
      \ ['\\¨U',  'Ü'],
      \ ['\\"U',  'Ü'],
      \ ['\\''u', 'ú'],
      \ ['\\`u',  'ù'],
      \ ['\\^u',  'û'],
      \ ['\\¨u',  'ü'],
      \ ['\\"u',  'ü'],
      \ ['\\`N',  'Ǹ'],
      \ ['\\\~N', 'Ñ'],
      \ ['\\''n', 'ń'],
      \ ['\\`n',  'ǹ'],
      \ ['\\\~n', 'ñ'],
      \], {_, x -> ['\C' . x[0], x[1]]})

" }}}1
function! vimtex#util#tex2tree(str) abort " {{{1
  let tree = []
  let i1 = 0
  let i2 = -1
  let depth = 0
  while i2 < len(a:str)
    let i2 = match(a:str, '[{}]', i2 + 1)
    if i2 < 0
      let i2 = len(a:str)
    endif
    if i2 >= len(a:str) || a:str[i2] ==# '{'
      if depth == 0
        let item = substitute(strpart(a:str, i1, i2 - i1),
              \ '^\s*\|\s*$', '', 'g')
        if !empty(item)
          call add(tree, item)
        endif
        let i1 = i2 + 1
      endif
      let depth += 1
    else
      let depth -= 1
      if depth == 0
        call add(tree, vimtex#util#tex2tree(strpart(a:str, i1, i2 - i1)))
        let i1 = i2 + 1
      endif
    endif
  endwhile
  return tree
endfunction

" }}}1
function! vimtex#util#trim(str) abort " {{{1
  if exists('*trim') | return trim(a:str) | endif

  let l:str = substitute(a:str, '^\s*', '', '')
  let l:str = substitute(l:str, '\s*$', '', '')

  return l:str
endfunction

" }}}1
function! vimtex#util#uniq_unsorted(list) abort " {{{1
  if len(a:list) <= 1 | return a:list | endif

  let l:visited = {}
  let l:result = []
  for l:x in a:list
    let l:key = string(l:x)
    if !has_key(l:visited, l:key)
      let l:visited[l:key] = 1
      call add(l:result, l:x)
    endif
  endfor

  return l:result
endfunction

" }}}1
function! vimtex#util#www(url) abort " {{{1
  let l:os = vimtex#util#get_os()

  silent execute (l:os ==# 'linux'
        \         ? '!xdg-open'
        \         : (l:os ==# 'mac'
        \            ? '!open'
        \            : '!start'))
        \ . ' ' . a:url
        \ . (l:os ==# 'win' ? '' : ' &')
endfunction

" }}}1
