" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#bib#parse(file, opts) abort " {{{1
  if !filereadable(a:file) | return [] | endif

  let l:backend = get(a:opts, 'backend', g:vimtex_parser_bib_backend)

  try
    return s:parse_with_{l:backend}(a:file)
  catch /E117/
    call vimtex#log#error(
          \ printf('bib parser backend "%s" does not exist!', l:backend))
    return []
  endtry
endfunction

" }}}1
function! vimtex#parser#bib#parse_cheap(start_line, end_line, opts) abort " {{{1
  " This function implements a quick and dirty bib parser in Vimscript. It does
  " not parse all keys, just the type, the key, and the title/entryset. It is
  " used e.g. by wiki#fold#bib#foldtext().

  let l:get_description = get(a:opts, 'get_description', v:true)
  let l:entries = []
  let l:firstlines = filter(
        \ range(a:start_line, a:end_line),
        \ {_, i -> vimtex#util#trim(getline(i))[0] == "@"})
  let l:total_entries = len(l:firstlines)
  let l:entry_lines = map(l:firstlines, {idx, val -> [val,
        \ idx == l:total_entries - 1
        \  ? a:end_line
        \  : l:firstlines[idx + 1] - 1
        \ ]})

  let l:n = 0
  while l:n < l:total_entries
    let l:current = {}
    let l:firstline = l:entry_lines[l:n][0]
    let l:lastline = l:entry_lines[l:n][1]

    let l:lnum = l:firstline
    let l:entry_info = getline(l:lnum)
    while l:lnum <= l:lastline
      let l:type_key_match = matchlist(l:entry_info,
            \ '\v\@\s*(\a+)\s*\{\s*(\S+)\s*,')
      if empty(l:type_key_match)
        " Add the next line into the text to be matched and try again
        let l:entry_info .= getline(l:lnum + 1)
        let l:lnum += 1
        continue
      else
        let l:current.type = l:type_key_match[1]
        let l:current.key = l:type_key_match[2]
        break
      endif
    endwhile

    if empty(l:type_key_match)
      " This will happen e.g. with  @string{ foo = Mrs. Foo }
      let l:n += 1
      continue
    endif

    if l:get_description
      " The description for a @set is the 'entryset'; for all other entry
      " types it's the 'title'.
      let l:description_pattern = l:current.type == 'set' ?
            \ '\v^\s*entryset\s*\=\s*(\{.+\}|\".+\")\s*,?' :
            \ '\v^\s*title\s*\=\s*(\{.+\}|\".+\")\s*,?'
      while l:lnum <= l:lastline
        let l:description_match = matchlist(
              \ getline(l:lnum), l:description_pattern)
        if l:description_match != []
          " Remove surrounding braces or quotes
          let l:current.description = l:description_match[1][1:-2]
          break
        else
          let l:lnum += 1
        endif
      endwhile
    endif

    call add(l:entries, l:current)
    let l:n += 1
  endwhile

  return l:entries
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
  call vimtex#jobs#run('bibtex -terse ' . fnameescape(tmp.aux))

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

  " Check if bstfile contains whitespace (not handled by VimTeX)
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

  let l:lines = vimtex#jobs#capture('bibparse ' . fnameescape(a:file))

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

  " Check if bibparse is executable
  let s:bibparse_not_executable = !executable('bibparse')
  if s:bibparse_not_executable
    call vimtex#log#warning(
          \ 'bibparse is not executable and may not be used to parse bib files!')
  endif

  let s:bibparse_init_done = 1
endfunction

" }}}1

function! s:parse_with_bibtexparser(file) abort " {{{1
py3 << END
import vim
from bibtexparser import load
from bibtexparser.bparser import BibTexParser

parser = BibTexParser(common_strings=True)
parser.ignore_nonstandard_types = False

entries = load(open(vim.eval("a:file")), parser).entries
for e in entries:
    e['key'] = e['ID']
    e['type'] = e['ENTRYTYPE']
END

  return py3eval('entries')
endfunction

" }}}1

function! s:parse_with_lua(file) abort " {{{1
  if !has('nvim')
    call vimtex#log#error(
          \ 'bib parser backend "lua" only works with neovim!')
    return []
  endif

  return luaeval('require("vimtex.parser.bib").parse(_A)', a:file)
endfunction

" }}}1

function! s:parse_with_vim(file) abort " {{{1
  " Adheres to the format description found here:
  " http://www.bibtex.org/Format/

  if !filereadable(a:file)
    return []
  endif

  let l:items = []
  let l:strings = {}

  let l:item = {}
  let l:lnum = 0
  for l:line in readfile(a:file)
    let l:lnum += 1

    let l:item = empty(l:item)
          \ ? s:parse_head(a:file, l:lnum, l:line)
          \ : s:parse_tail(l:item, l:line)

    if has_key(l:item, 'parsed')
      if l:item.type == "string"
        let [l:key, l:value] = s:parse_string(l:item.body)
        if !empty(l:key)
          let l:strings[l:key] = l:value
        endif
      else
        call add(l:items, l:item)
      endif
      let l:item = {}
    endif
  endfor

  return map(l:items, 's:parse_item(v:val, l:strings)')
endfunction

" }}}1

function! s:parse_head(file, lnum, line) abort " {{{1
  let l:matches = matchlist(a:line, '\v^\@(\w+)\s*\{\s*(.*)')
  if empty(l:matches) | return {} | endif

  let l:type = tolower(l:matches[1])
  if l:type == 'preamble' || l:type == 'comment' | return {} | endif

  return s:parse_tail({
        \ 'level': 1,
        \ 'body': '',
        \ 'source_file': a:file,
        \ 'source_lnum': a:lnum,
        \ 'type': l:type,
        \}, l:matches[2])
endfunction

" }}}1
function! s:parse_tail(item, line) abort " {{{1
  let a:item.level += s:count(a:line, '{') - s:count(a:line, '}')
  if a:item.level > 0
    let a:item.body .= a:line
  else
    let a:item.body .= matchstr(a:line, '.*\ze}')
    let a:item.parsed = v:true
  endif

  return a:item
endfunction

" }}}1
function! s:parse_string(raw_string) abort " {{{1
  let l:matches = matchlist(a:raw_string, '\v^\s*(\S+)\s*\=\s*"(.*)"\s*$')
  if !empty(l:matches) && !empty(l:matches[1])
    return [l:matches[1], l:matches[2]]
  endif

  let l:matches = matchlist(a:raw_string, '\v^\s*(\S+)\s*\=\s*\{(.*)\}\s*$')
  if !empty(l:matches) && !empty(l:matches[1])
    return [l:matches[1], l:matches[2]]
  endif

  return ['', '']
endfunction

" }}}1

function! s:parse_item(item, strings) abort " {{{1
  let l:parts = matchlist(a:item.body, '\v^([^, ]*)\s*,\s*(.*)')

  let a:item.key = l:parts[1]
  if empty(a:item.key) | return {} | endif

  unlet a:item.level
  unlet a:item.body
  unlet a:item.parsed

  let l:body = l:parts[2]
  let l:tag = ''
  let l:head = 0
  while l:head >= 0
    if empty(l:tag)
      let [l:tag, l:head] = s:get_tag_name(l:body, l:head)
      if l:tag == 'key'
        let l:tag = 'keyfield'
      endif
    else
      let [l:value, l:head] = s:get_tag_value(l:body, l:head, a:strings)
      let a:item[l:tag] = l:value
      let l:tag = ''
    endif
  endwhile

  return a:item
endfunction

" }}}1
function! s:get_tag_name(body, head) abort " {{{1
  " Parse the name part of a bib entry tag.
  " Assumption: a:body is left trimmed and either empty or starts with a key.
  " Returns: The key and the remaining part of the entry body.

  let l:matches = matchlist(a:body, '^\v([-_:0-9a-zA-Z]+)\s*\=\s*', a:head)
  return empty(l:matches)
        \ ? ['', -1]
        \ : [tolower(l:matches[1]), a:head + strlen(l:matches[0])]
endfunction

" }}}1
function! s:get_tag_value(body, head, strings) abort " {{{1
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
  endif

  return s:get_tag_value_concat(a:body, a:head, a:strings, "")
endfunction

" }}}1
function! s:get_tag_value_concat(body, head, strings, pre_value) abort " {{{1
  let l:value = ""
  let l:head = a:head

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
      return ['s:get_tag_value_concat failed', -1]
    endif

    let l:value = a:body[a:head+1:l:index-1]
    let l:head = matchend(a:body, '^\s*', l:index+1)
  elseif a:body[a:head:] =~# '^\w'
    let l:value = matchstr(a:body, '^\w[0-9a-zA-Z_-]*', a:head)
    let l:head = matchend(a:body, '^\s*', a:head + strlen(l:value))
    let l:value = get(a:strings, l:value, '@(' . l:value . ')')
  endif

  if a:body[l:head] ==# '#'
    let l:head = matchend(a:body, '^\s*', l:head + 1)
    return s:get_tag_value_concat(
          \ a:body, l:head, a:strings, a:pre_value . l:value)
  endif

  return [a:pre_value . l:value, matchend(a:body, '^,\s*', l:head)]
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
