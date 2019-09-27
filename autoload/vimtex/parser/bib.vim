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
"     type : 'sometype',
"     key : 'key',
"     content : {
"       title   : "Some title",
"       year    : "2017",
"       author  : ["Author1", "Author2],
"       other   : "Something else",
"     },
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
  for l:line in readfile(a:file)
    if l:line =~# '^\s*%' | continue | endif

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

  return l:entries
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
  let a:string.level += s:count_braces(a:line)
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
  let a:entry.level += s:count_braces(a:line)
  if a:entry.level > 0
    let a:entry.body .= a:line
    return 0
  endif

  let a:entry.body .= matchstr(a:line, '.*\ze}')

  call add(a:entries, s:parse_entry_body(a:entry))
  return 1
endfunction

" }}}1
function! s:parse_entry_body(entry) abort " {{{1
  let l:result = {}
  let l:result.type = a:entry.type
  let l:result.key = a:entry.key
  let l:result.content = {}

  let l:key = ''
  let l:body = trim(a:entry.body)
  while !empty(l:body)
    if empty(l:key)
      let [l:key, l:body] = s:get_key(l:body)
    else
      let [l:value, l:body] = s:get_value(l:body)
      let l:result.content[l:key] = l:value
      let l:key = ''
    endif
  endwhile

  return l:result
endfunction

" }}}1

function! s:get_key(body) abort " {{{1
  let l:matches = matchlist(a:body, '^\v(\w+)\s*\=\s*')
  return empty(l:matches)
        \ ? ['', '']
        \ : [tolower(l:matches[1]), a:body[strlen(l:matches[0]):]]
endfunction

" }}}1
function! s:get_value(body) abort " {{{1
  " * The content needs to be enclosed by either curly braces or
  "   quotation-marks
  " * When quotation-marks are used, string concatenation using # is possible,
  "   but not when braces are used
  " * Numbers may be enclosed and not
  " * Variables are unenclosed -> should be made parseable
  "
  " Trivial solution first; not good!
  let l:matches = matchlist(a:body, '^\v(.{-}),\s*')
  return empty(l:matches)
        \ ? ['', '']
        \ : [l:matches[1], a:body[strlen(l:matches[0]):]]
endfunction

" }}}1

function! s:count_braces(line) abort " {{{1
  let l:sum = 0

  let l:indx = match(a:line, '{')
  while l:indx >= 0
    let l:sum += 1
    let l:indx += 1
    let l:indx = match(a:line, '{', l:indx)
  endwhile

  let l:indx = match(a:line, '}')
  while l:indx >= 0
    let l:sum -= 1
    let l:indx += 1
    let l:indx = match(a:line, '}', l:indx)
  endwhile

  return l:sum
endfunction

" }}}1
