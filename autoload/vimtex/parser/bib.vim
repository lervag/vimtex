" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"
"
" Parses the entries in a bib file project, e.g.
"
" @SomeType{key,
"   title  = "Some title",
"   year   = {2017},
"   author = "Author1 and Author2",
"   other  = {Something else}
" }
"
" is turned into a dictionary like
"
"   entry = {
"     type   : 'sometype',
"     key    : 'key',
"     title  : "Some title",
"     year   : "2017",
"     author : ["Author1", "Author2],
"     other  : "Something else",
"   }
"
" Adheres to the format description found here:
" http://www.bibtex.org/Format/
"


function! vimtex#parser#bib#parse(file) abort " {{{1
  if !filereadable(a:file)
    return []
  endif

  let l:current = {}
  let l:strings = {}
  let l:entries = []
  for l:line in filter(readfile(a:file), 'v:val !~# ''^\s*\%(%\|$\)''')
    if empty(l:current)
      if s:parse_type(l:line, l:current, l:strings)
        let l:current = {}
      endif
      continue
    endif

    if l:current.type ==# 'string'
      if s:parse_string(l:line, l:current, l:strings)
        let l:current = {}
      endif
    else
      if s:parse_entry(l:line, l:current, l:entries)
        let l:current = {}
      endif
    endif
  endfor

  return map(l:entries, 's:parse_entry_body(v:val, l:strings)')
endfunction

" }}}1

function! s:parse_type(line, current, strings) abort " {{{1
  let l:matches = matchlist(a:line, '\v^\@(\w+)\s*\{\s*(.*)')
  if empty(l:matches) | return 0 | endif

  let l:type = tolower(l:matches[1])
  if index(['preamble', 'comment'], l:type) >= 0 | return 0 | endif

  let a:current.level = 1
  let a:current.body = ''

  if l:type ==# 'string'
    return s:parse_string(l:matches[2], a:current, a:strings)
  else
    let a:current.type = l:type
    let a:current.key = matchstr(l:matches[2], '.*\ze,\s*')
    return 0
  endif
endfunction

" }}}1
function! s:parse_string(line, string, strings) abort " {{{1
  let a:string.level += count(a:line, '{') - count(a:line, '}')
  if a:string.level > 0
    let a:string.body .= a:line
    return 0
  endif

  let a:string.body .= matchstr(a:line, '.*\ze}')

  let l:matches = matchlist(a:string.body, '\v^\s*(\w+)\s*\=\s*"(.*)"\s*$')
  if !empty(l:matches) && !empty(l:matches[1])
    let a:strings[l:matches[1]] = l:matches[2]
  endif

  return 1
endfunction

" }}}1
function! s:parse_entry(line, entry, entries) abort " {{{1
  let a:entry.level += count(a:line, '{') - count(a:line, '}')
  if a:entry.level > 0
    let a:entry.body .= a:line
    return 0
  endif

  let a:entry.body .= matchstr(a:line, '.*\ze}')

  call add(a:entries, a:entry)
  return 1
endfunction

" }}}1

function! s:parse_entry_body(entry, strings) abort " {{{1
  unlet a:entry.level

  let l:key = ''
  let l:pos = matchend(a:entry.body, '^\s*')
  while l:pos >= 0
    if empty(l:key)
      let [l:key, l:pos] = s:get_key(a:entry.body, l:pos)
    else
      let [l:value, l:pos] = s:get_value(a:entry.body, l:pos, a:strings)
      let a:entry[l:key] = l:value
      let l:key = ''
    endif
  endwhile

  unlet a:entry.body
  return a:entry
endfunction

" }}}1
function! s:get_key(body, head) abort " {{{1
  " Parse the key part of a bib entry tag.
  " Assumption: a:body is left trimmed and either empty or starts with a key.
  " Returns: The key and the remaining part of the entry body.

  let l:matches = matchlist(a:body, '^\v(\w+)\s*\=\s*', a:head)
  return empty(l:matches)
        \ ? ['', -1]
        \ : [tolower(l:matches[1]), a:head + strlen(l:matches[0])]
endfunction

" }}}1
function! s:get_value(body, head, strings) abort " {{{1
  " Parse the value part of a bib entry tag, until separating comma or end.
  " Assumption: a:body is left trimmed and either empty or starts with a value.
  " Returns: The value and the remaining part of the entry body.
  "
  " A bib entry value is either
  " 1. A number.
  " 2. A concatenation (with #s) of double quoted strings, curlied strings,
  "    and/or bibvariables,
  "
  if a:body[a:head] =~# '\d'
    let l:value = matchstr(a:body, '^\d\+', a:head)
    let l:head = matchend(a:body, '^\s*,\s*', a:head + len(l:value))
    return [l:value, l:head]
  elseif a:body[a:head] =~# '{\|"\|\w'
    return s:get_value_string(a:body, a:head, a:strings)
  endif

  return ['s:get_value failed', -1]
endfunction

" }}}1
function! s:get_value_string(body, head, strings) abort " {{{1
  let l:head = a:head

  if a:body[l:head] ==# '{'
    let l:sum = 1
    let l:i1 = l:head + 1
    let l:i0 = l:i1

    while v:true
      let l:iopen = stridx(a:body, '{', l:i1)
      let l:iclose = stridx(a:body, '}', l:i1)
      let [l:match, l:_, l:i1] = matchstrpos(a:body, '[{}]', l:i1)
      if empty(l:match) | break | endif

      let l:i0 = l:i1
      let l:sum += l:match ==# '{' ? 1 : -1
      if l:sum == 0 | break | endif
    endwhile

    let l:value = a:body[l:head+1:l:i0-2]
    let l:head = matchend(a:body, '^\s*', l:i0)
  elseif a:body[l:head] ==# '"'
    let l:index = match(a:body, '\\\@<!"', l:head+1)
    if l:index < 0
      return ['s:get_value_string failed', '']
    endif

    let l:value = a:body[l:head+1:l:index-1]
    let l:head = matchend(a:body, '^\s*', l:index+1)
  elseif a:body[l:head:] =~# '^\w\+'
    let l:value = matchstr(a:body, '^\w\+', l:head)
    let l:head = matchend(a:body, '^\s*', l:head + strlen(l:value))
    let l:value = get(a:strings, l:value, '@(' . l:value . ')')
  endif

  if a:body[l:head] ==# '#'
    let l:head = matchend(a:body, '^\s*', l:head + 1)
    let [l:vadd, l:head] = s:get_value_string(a:body, l:head, a:strings)
    let l:value .= l:vadd
  endif

  return [l:value, matchend(a:body, '^,\s*', l:head)]
endfunction

" }}}1
