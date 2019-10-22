" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#bib#parse(file, opts) abort " {{{1
  if !filereadable(a:file) | return [] | endif

  let l:backend = get(a:opts, 'backend', g:vimtex_parser_bib_backend)

  if l:backend ==# 'bibtex'
    if !executable('bibtex') | let l:backend = 'vim' | endif
  elseif l:backend ==# 'bibparse'
    if !executable('bibparse') | let l:backend = 'vim' | endif
  else
    let l:backend = 'vim'
  endif

  return s:parse_with_{l:backend}(a:file)
endfunction

" }}}1


function! s:parse_with_bibtex(file) abort " {{{1
  call s:parse_with_bibtex_init()
  if s:bibtex_not_executable | return [] | endif

  " Define temporary files
  let tmp = {
        \ 'aux' : 'tmpfile.aux',
        \ 'bbl' : 'tmpfile.bbl',
        \ 'blg' : 'tmpfile.blg',
        \ }

  " Write temporary aux file
  call writefile([
        \ '\citation{*}',
        \ '\bibstyle{' . s:bibtex_bstfile . '}',
        \ '\bibdata{' . fnamemodify(a:file, ':r') . '}',
        \ ], tmp.aux)

  " Create the temporary bbl file
  call vimtex#process#run('bibtex -terse ' . fnameescape(tmp.aux), {
        \ 'background' : 0,
        \ 'silent' : 1,
        \})

  " Parse temporary bbl file
  let lines = join(readfile(tmp.bbl), "\n")
  let lines = substitute(lines, '\n\n\@!\(\s\=\)\s*\|{\|}', '\1', 'g')
  let lines = vimtex#util#tex2unicode(lines)
  let lines = split(lines, "\n")

  let l:entries = []
  for line in lines
    let matches = split(line, '||')
    if empty(matches) || empty(matches[0]) | continue | endif

    let l:entry = {
          \ 'key':    matches[0],
          \ 'type':   matches[1],
          \}

    if !empty(matches[2])
      let l:entry.author = matches[2]
    endif
    if !empty(matches[3])
      let l:entry.year = matches[3]
    endif
    if !empty(get(matches, 4, ''))
      let l:entry.title = get(matches, 4, '')
    endif

    call add(l:entries, l:entry)
  endfor

  " Clean up
  call delete(tmp.aux)
  call delete(tmp.bbl)
  call delete(tmp.blg)

  return l:entries
endfunction

" }}}1
function! s:parse_with_bibtex_init() abort " {{{1
  if exists('s:bibtex_init_done') | return | endif

  " Check if bibtex is executable
  let s:bibtex_not_executable = !executable('bibtex')
  if s:bibtex_not_executable
    call vimtex#log#warning(
          \ 'bibtex is not executable and may not be used to parse bib files!')
  endif

  " Check if bstfile contains whitespace (not handled by vimtex)
  if stridx(s:bibtex_bstfile, ' ') >= 0
    let l:oldbst = s:bibtex_bstfile . '.bst'
    let s:bibtex_bstfile = tempname()
    call writefile(readfile(l:oldbst), s:bibtex_bstfile . '.bst')
  endif

  let s:bibtex_init_done = 1
endfunction

let s:bibtex_bstfile = expand('<sfile>:p:h') . '/vimcomplete'

" }}}1

function! s:parse_with_bibparse(file) abort " {{{1
  call s:parse_with_bibparse_init()
  if s:bibparse_not_executable | return [] | endif

  call vimtex#process#run('bibparse ' . fnameescape(a:file)
        \ . ' >_vimtex_bibparsed.log', {'background' : 0, 'silent' : 1})
  let l:lines = readfile('_vimtex_bibparsed.log')
  call delete('_vimtex_bibparsed.log')

  let l:current = {}
  let l:entries = []
  for l:line in l:lines
    if l:line[0] ==# '@'
      if !empty(l:current)
        call add(l:entries, l:current)
        let l:current = {}
      endif

      let l:index = stridx(l:line, ' ')
      if l:index > 0
        let l:type = l:line[1:l:index-1]
        let l:current.type = l:type
        let l:current.key = l:line[l:index+1:]
      endif
    elseif !empty(l:current)
      let l:index = stridx(l:line, '=')
      if l:index < 0 | continue | endif

      let l:key = l:line[:l:index-1]
      let l:value = l:line[l:index+1:]
      let l:current[tolower(l:key)] = l:value
    endif
  endfor

  if !empty(l:current)
    call add(l:entries, l:current)
  endif

  return l:entries
endfunction

" }}}1
function! s:parse_with_bibparse_init() abort " {{{1
  if exists('s:bibparse_init_done') | return | endif

  " Check if bibtex is executable
  let s:bibparse_not_executable = !executable('bibparse')
  if s:bibparse_not_executable
    call vimtex#log#warning(
          \ 'bibparse is not executable and may not be used to parse bib files!')
  endif

  let s:bibparse_init_done = 1
endfunction

" }}}1

function! s:parse_with_vim(file) abort " {{{1
  " Adheres to the format description found here:
  " http://www.bibtex.org/Format/

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
  let a:string.level += s:count(a:line, '{') - s:count(a:line, '}')
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
  let a:entry.level += s:count(a:line, '{') - s:count(a:line, '}')
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
  else
    return s:get_value_string(a:body, a:head, a:strings)
  endif

  return ['s:get_value failed', -1]
endfunction

" }}}1
function! s:get_value_string(body, head, strings) abort " {{{1
  if a:body[a:head] ==# '{'
    let l:sum = 1
    let l:i1 = a:head + 1
    let l:i0 = l:i1

    while l:sum > 0
      let [l:match, l:_, l:i1] = matchstrpos(a:body, '[{}]', l:i1)
      if l:i1 < 0 | break | endif

      let l:i0 = l:i1
      let l:sum += l:match ==# '{' ? 1 : -1
    endwhile

    let l:value = a:body[a:head+1:l:i0-2]
    let l:head = matchend(a:body, '^\s*', l:i0)
  elseif a:body[a:head] ==# '"'
    let l:index = match(a:body, '\\\@<!"', a:head+1)
    if l:index < 0
      return ['s:get_value_string failed', '']
    endif

    let l:value = a:body[a:head+1:l:index-1]
    let l:head = matchend(a:body, '^\s*', l:index+1)
    return [l:value, l:head]
  elseif a:body[a:head:] =~# '^\w'
    let l:value = matchstr(a:body, '^\w\+', a:head)
    let l:head = matchend(a:body, '^\s*', a:head + strlen(l:value))
    let l:value = get(a:strings, l:value, '@(' . l:value . ')')
  else
    let l:head = a:head
  endif

  if a:body[l:head] ==# '#'
    let l:head = matchend(a:body, '^\s*', l:head + 1)
    let [l:vadd, l:head] = s:get_value_string(a:body, l:head, a:strings)
    let l:value .= l:vadd
  endif

  return [l:value, matchend(a:body, '^,\s*', l:head)]
endfunction

" }}}1

function! s:count(container, item) abort " {{{1
  " Necessary because in old Vim versions, count() does not work for strings
  try
    let l:count = count(a:container, a:item)
  catch /E712/
    let l:count = count(split(a:container, '\zs'), a:item)
  endtry

  return l:count
endfunction

" }}}1
