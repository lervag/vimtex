" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"
"
" Parses tex project for ToC-like entries.  Each entry is a dictionary
" similar to the following:
"
"   entry = {
"     title  : "Some title",
"     number : "3.1.2",
"     file   : /path/to/file.tex,
"     line   : 142,
"     rank   : cumulative line number,
"     level  : 2,
"     type   : [content | label | todo | include],
"     link   : [0 | 1],
"   }
"

function! vimtex#parser#toc#parse(file) abort " {{{1
  let l:entries = []
  let l:content = vimtex#parser#tex(a:file)

  let l:max_level = 0
  for [l:file, l:lnum, l:line] in l:content
    if l:line =~# s:matcher_sections.re
      let l:max_level = max([
            \ l:max_level,
            \ s:sec_to_value[matchstr(l:line, s:matcher_sections.re_level)]
            \])
    endif
  endfor

  call s:level.reset('preamble', l:max_level)

  " No more parsing if there is no content
  if empty(l:content) | return l:entries | endif

  "
  " Begin parsing LaTeX files
  "
  let l:lnum_total = 0
  let l:matchers = s:matchers_preamble
  for [l:file, l:lnum, l:line] in l:content
    let l:lnum_total += 1
    let l:context = {
          \ 'file' : l:file,
          \ 'line' : l:line,
          \ 'lnum' : l:lnum,
          \ 'lnum_total' : l:lnum_total,
          \ 'level' : s:level,
          \ 'max_level' : l:max_level,
          \ 'entry' : get(l:entries, -1, {}),
          \ 'num_entries' : len(l:entries),
          \}

    " Detect end of preamble
    if s:level.preamble && l:line =~# '\v^\s*\\begin\{document\}'
      let s:level.preamble = 0
      let l:matchers = s:matchers_content
      continue
    endif

    " Handle multi-line entries
    if exists('s:matcher_continue')
      call s:matcher_continue.continue(l:context)
      continue
    endif

    " Apply prefilter - this gives considerable speedup for large documents
    if l:line !~# s:re_prefilter | continue | endif

    " Apply the matchers
    for l:matcher in l:matchers
      if l:line =~# l:matcher.re
        let l:entry = l:matcher.get_entry(l:context)
        if type(l:entry) == type([])
          call extend(l:entries, l:entry)
        elseif !empty(l:entry)
          call add(l:entries, l:entry)
        endif
      endif
    endfor
  endfor

  for l:matcher in s:matchers
    try
      call l:matcher.filter(l:entries)
    catch /E716/
    endtry
  endfor

  return l:entries
endfunction

" }}}1
function! vimtex#parser#toc#get_topmatters() abort " {{{1
  let l:topmatters = s:level.frontmatter
  let l:topmatters += s:level.mainmatter
  let l:topmatters += s:level.appendix
  let l:topmatters += s:level.backmatter

  for l:level in get(s:level, 'old', [])
    let l:topmatters += l:level.frontmatter
    let l:topmatters += l:level.mainmatter
    let l:topmatters += l:level.appendix
    let l:topmatters += l:level.backmatter
  endfor

  return l:topmatters
endfunction

" }}}1
function! vimtex#parser#toc#get_entry_general(context) abort dict " {{{1
  return {
        \ 'title'  : self.title,
        \ 'number' : '',
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'rank'   : a:context.lnum_total,
        \ 'level'  : 0,
        \ 'type'   : 'content',
        \}
endfunction

" }}}1

" IMPORTANT: The following defines a prefilter for optimizing the toc parser.
"            Any line that should be parsed has to be matched by this regexp!
" {{{1 let s:re_prefilter = ...
let s:re_prefilter = '\v%(\\' . join([
      \ '%(front|main|back)matter',
      \ 'add%(global|section)?bib',
      \ 'appendix',
      \ 'begin',
      \ 'bibliography',
      \ 'chapter',
      \ 'documentclass',
      \ 'import',
      \ 'include',
      \ 'includegraphics',
      \ 'input',
      \ 'label',
      \ 'part',
      \ 'printbib',
      \ 'printindex',
      \ 'paragraph',
      \ 'section',
      \ 'subfile',
      \ 'tableofcontents',
      \ 'todo',
      \], '|') . ')'
      \ . '|\%\s*%(' . join(keys(g:vimtex_toc_todo_labels), '|') . ')'
      \ . '|\%\s*vimtex-include'
for s:m in g:vimtex_toc_custom_matchers
  if has_key(s:m, 'prefilter')
    let s:re_prefilter .= '|' . s:m.prefilter
  endif
endfor

" }}}1

" Adds entries for included files
let s:matcher_include = {
      \ 're' : vimtex#re#tex_input . '\zs\f{-}\s*\ze\}',
      \ 'in_preamble' : 1,
      \ 'priority' : 0,
      \}
function! s:matcher_include.get_entry(context) abort dict " {{{1
  let l:file = matchstr(a:context.line, self.re)
  if !vimtex#paths#is_abs(l:file[0])
    let l:file = b:vimtex.root . '/' . l:file
  endif
  let l:file = fnamemodify(l:file, ':~:.')
  if !filereadable(l:file)
    let l:file .= '.tex'
  endif
  return {
        \ 'title'  : 'tex incl: ' . (strlen(l:file) < 70
        \               ? l:file
        \               : l:file[0:30] . '...' . l:file[-36:]),
        \ 'number' : '',
        \ 'file'   : l:file,
        \ 'line'   : 1,
        \ 'level'  : a:context.max_level - a:context.level.current,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'include',
        \ }
endfunction

" }}}1

" Adds entries for included graphics files (filetype tikz, tex)
let s:matcher_include_graphics = {
      \ 're' : '\v^\s*\\includegraphics\*?%(\s*\[[^]]*\]){0,2}\s*\{\zs[^}]*',
      \ 'priority' : 1,
      \}
function! s:matcher_include_graphics.get_entry(context) abort dict " {{{1
  let l:file = matchstr(a:context.line, self.re)
  if !vimtex#paths#is_abs(l:file)
    let l:file = vimtex#misc#get_graphicspath(l:file)
  endif
  let l:file = fnamemodify(l:file, ':~:.')
  let l:ext = fnamemodify(l:file, ':e')

  return !filereadable(l:file) || index(['asy', 'tikz'], l:ext) < 0
        \ ? {}
        \ : {
        \     'title'  : 'fig incl: ' . (strlen(l:file) < 70
        \                   ? l:file
        \                   : l:file[0:30] . '...' . l:file[-36:]),
        \     'number' : '',
        \     'file'   : l:file,
        \     'line'   : 1,
        \     'level'  : a:context.max_level - a:context.level.current,
        \     'rank'   : a:context.lnum_total,
        \     'type'   : 'include',
        \     'link'   : 1,
        \   }
endfunction

" }}}1

" Adds entries for included files through vimtex specific syntax (this allows
" to add entries for any filetype or file)
let s:matcher_include_vimtex = {
      \ 're' : '^\s*%\s*vimtex-include:\?\s\+\zs\f\+',
      \ 'in_preamble' : 1,
      \ 'priority' : 1,
      \}
function! s:matcher_include_vimtex.get_entry(context) abort dict " {{{1
  let l:file = matchstr(a:context.line, self.re)
  if !vimtex#paths#is_abs(l:file)
    let l:file = b:vimtex.root . '/' . l:file
  endif
  let l:file = fnamemodify(l:file, ':~:.')
  return {
        \ 'title'  : 'vtx incl: ' . (strlen(l:file) < 70
        \               ? l:file
        \               : l:file[0:30] . '...' . l:file[-36:]),
        \ 'number' : '',
        \ 'file'   : l:file,
        \ 'line'   : 1,
        \ 'level'  : a:context.max_level - a:context.level.current,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'include',
        \ 'link'   : 1,
        \ }
endfunction

" }}}1

let s:matcher_include_bibtex = {
      \ 're' : '\v^\s*\\bibliography\s*\{\zs[^}]+\ze\}',
      \ 'in_preamble' : 1,
      \ 'priority' : 0,
      \}
function! s:matcher_include_bibtex.get_entry(context) abort dict " {{{1
  let l:entries = []

  for l:file in split(matchstr(a:context.line, self.re), ',')
    " Ensure that the file name has extension
    if l:file !~# '\.bib$'
      let l:file .= '.bib'
    endif

    call add(l:entries, {
          \ 'title'  : printf('bib incl: %-.67s', fnamemodify(l:file, ':t')),
          \ 'number' : '',
          \ 'file'   : vimtex#kpsewhich#find(l:file),
          \ 'line'   : 1,
          \ 'level'  : 0,
          \ 'rank'   : a:context.lnum_total,
          \ 'type'   : 'include',
          \ 'link'   : 1,
          \})
  endfor

  return l:entries
endfunction

" }}}1

let s:matcher_include_biblatex = {
      \ 're' : '\v^\s*\\add(bibresource|globalbib|sectionbib)\s*\{\zs[^}]+\ze\}',
      \ 'in_preamble' : 1,
      \ 'in_content' : 0,
      \ 'priority' : 0,
      \}
function! s:matcher_include_biblatex.get_entry(context) abort dict " {{{1
  let l:file = matchstr(a:context.line, self.re)

  return {
        \ 'title'  : printf('bib incl: %-.67s', fnamemodify(l:file, ':t')),
        \ 'number' : '',
        \ 'file'   : vimtex#kpsewhich#find(l:file),
        \ 'line'   : 1,
        \ 'level'  : 0,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'include',
        \ 'link'   : 1,
        \}
endfunction

" }}}1

let s:matcher_preamble = {
      \ 're' : '\v^\s*\\documentclass',
      \ 'in_preamble' : 1,
      \ 'in_content' : 0,
      \ 'priority' : 0,
      \}
function! s:matcher_preamble.get_entry(context) abort " {{{1
  return g:vimtex_toc_show_preamble
        \ ? {
        \   'title'  : 'Preamble',
        \   'number' : '',
        \   'file'   : a:context.file,
        \   'line'   : a:context.lnum,
        \   'level'  : 0,
        \   'rank'   : a:context.lnum_total,
        \   'type'   : 'content',
        \   }
        \ : {}
endfunction

" }}}1

let s:matcher_parts = {
      \ 're' : '\v^\s*\\\zs((front|main|back)matter|appendix)>',
      \ 'priority' : 0,
      \}
function! s:matcher_parts.get_entry(context) abort dict " {{{1
  call a:context.level.reset(
        \ matchstr(a:context.line, self.re),
        \ a:context.max_level)
  return {}
endfunction

" }}}1

let s:matcher_sections = {
      \ 're' : '\v^\s*\\%(part|chapter|%(sub)*section|%(sub)?paragraph)\*?\s*(\[|\{)',
      \ 're_starred' : '\v^\s*\\%(part|chapter|%(sub)*section)\*',
      \ 're_level' : '\v^\s*\\\zs%(part|chapter|%(sub)*section|%(sub)?paragraph)',
      \ 'priority' : 0,
      \}
let s:matcher_sections.re_title = s:matcher_sections.re . '\zs.{-}\ze\%?\s*$'
function! s:matcher_sections.get_entry(context) abort dict " {{{1
  let level = matchstr(a:context.line, self.re_level)
  let type = matchlist(a:context.line, self.re)[1]
  let title = matchstr(a:context.line, self.re_title)
  let number = ''

  let [l:end, l:count] = s:find_closing(0, title, 1, type)
  if l:count == 0
    let title = self.parse_title(strpart(title, 0, l:end+1))
  else
    let self.type = type
    let self.count = l:count
    let s:matcher_continue = deepcopy(self)
  endif

  if a:context.line !~# self.re_starred
    call a:context.level.increment(level)
    if a:context.line !~# '\v^\s*\\%(sub)?paragraph'
      let number = deepcopy(a:context.level)
    endif
  endif

  return {
        \ 'title'  : title,
        \ 'number' : number,
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'level'  : a:context.max_level - a:context.level.current,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'content',
        \ }
endfunction

" }}}1
function! s:matcher_sections.parse_title(title) abort dict " {{{1
  let l:title = substitute(a:title, '\v%(\]|\})\s*$', '', '')
  return s:clear_texorpdfstring(l:title)
endfunction

" }}}1
function! s:matcher_sections.continue(context) abort dict " {{{1
  let [l:end, l:count] = s:find_closing(0, a:context.line, self.count, self.type)
  if l:count == 0
    let a:context.entry.title = self.parse_title(a:context.entry.title . strpart(a:context.line, 0, l:end+1))
    unlet! s:matcher_continue
  else
    let a:context.entry.title .= a:context.line
    let self.count = l:count
  endif
endfunction

" }}}1

let s:matcher_table_of_contents = {
      \ 'title' : 'Table of contents',
      \ 're' : '\v^\s*\\tableofcontents',
      \ 'priority' : 0,
      \}

let s:matcher_index = {
      \ 'title' : 'Alphabetical index',
      \ 're' : '\v^\s*\\printindex\[?',
      \ 'priority' : 0,
      \}

let s:matcher_titlepage = {
      \ 'title' : 'Titlepage',
      \ 're' : '\v^\s*\\begin\{titlepage\}',
      \ 'priority' : 0,
      \}

let s:matcher_bibliography = {
      \ 'title' : 'Bibliography',
      \ 're' : '\v^\s*\\%('
      \        .  'printbib%(liography|heading)\s*(\{|\[)?'
      \        . '|begin\s*\{\s*thebibliography\s*\}'
      \        . '|bibliography\s*\{)',
      \ 're_biblatex' : '\v^\s*\\printbib%(liography|heading)',
      \ 'priority' : 0,
      \}
function! s:matcher_bibliography.get_entry(context) abort dict " {{{1
  let l:entry = call('vimtex#parser#toc#get_entry_general', [a:context], self)

  if a:context.line !~# self.re_biblatex
    return l:entry
  endif

  let self.options = matchstr(a:context.line, self.re_biblatex . '\s*\[\zs.*')

  let [l:end, l:count] = s:find_closing(
        \ 0, self.options, !empty(self.options), '[')
  if l:count == 0
    let self.options = strpart(self.options, 0, l:end)
    call self.parse_options(a:context, l:entry)
  else
    let self.count = l:count
    let s:matcher_continue = deepcopy(self)
  endif

  return l:entry
endfunction

" }}}1
function! s:matcher_bibliography.continue(context) abort dict " {{{1
  let [l:end, l:count] = s:find_closing(0, a:context.line, self.count, '[')
  if l:count == 0
    let self.options .= strpart(a:context.line, 0, l:end)
    unlet! s:matcher_continue
    call self.parse_options(a:context, a:context.entry)
  else
    let self.options .= a:context.line
    let self.count = l:count
  endif
endfunction

" }}}1
function! s:matcher_bibliography.parse_options(context, entry) abort dict " {{{1
  " Parse the options
  let l:opt_pairs = map(split(self.options, ','), 'split(v:val, ''='')')
  let l:opts = {}
  for [l:key, l:val] in l:opt_pairs
    let l:key = substitute(l:key, '^\s*\|\s*$', '', 'g')
    let l:val = substitute(l:val, '^\s*\|\s*$', '', 'g')
    let l:val = substitute(l:val, '{\|}', '', 'g')
    let l:opts[l:key] = l:val
  endfor

  " Check if entry should appear in the TOC
  let l:heading = get(l:opts, 'heading')
  let a:entry.added_to_toc = l:heading =~# 'intoc\|numbered'

  " Check if entry should be numbered
  if l:heading =~# '\v%(sub)?bibnumbered'
    if a:context.level.chapter > 0
      let l:levels = ['chapter', 'section']
    else
      let l:levels = ['section', 'subsection']
    endif
    call a:context.level.increment(l:levels[l:heading =~# '^sub'])
    let a:entry.level = a:context.max_level - a:context.level.current
    let a:entry.number = deepcopy(a:context.level)
  endif

  " Parse title
  try
    let a:entry.title = remove(l:opts, 'title')
  catch /E716/
    let a:entry.title = l:heading =~# '^sub' ? 'References' : 'Bibliography'
  endtry
endfunction

" }}}1
function! s:matcher_bibliography.filter(entries) abort dict " {{{1
  if !empty(
        \ filter(deepcopy(a:entries), 'get(v:val, "added_to_toc")'))
    call filter(a:entries, 'get(v:val, "added_to_toc", 1)')
  endif
endfunction

" }}}1

let s:matcher_todos = {
      \ 're' : g:vimtex#re#not_bslash . '\%\s+('
      \   . join(keys(g:vimtex_toc_todo_labels), '|') . ')[ :]+\s*(.*)',
      \ 'in_preamble' : 1,
      \ 'priority' : 2,
      \}
function! s:matcher_todos.get_entry(context) abort dict " {{{1
  let [l:type, l:text] = matchlist(a:context.line, self.re)[1:2]
  let l:label = g:vimtex_toc_todo_labels[toupper(l:type)]

  return {
        \ 'title'  : l:label . l:text,
        \ 'number' : '',
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'level'  : a:context.max_level - a:context.level.current,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'todo',
        \ }
endfunction

" }}}1

let s:matcher_todonotes = {
      \ 're' : g:vimtex#re#not_comment . '\\\w*todo\w*%(\[[^]]*\])?\{\zs.*',
      \ 'priority' : 2,
      \}
function! s:matcher_todonotes.get_entry(context) abort dict " {{{1
  let title = matchstr(a:context.line, self.re)

  let [l:end, l:count] = s:find_closing(0, title, 1, '{')
  if l:count == 0
    let title = strpart(title, 0, l:end)
  else
    let self.count = l:count
    let s:matcher_continue = deepcopy(self)
  endif

  let l:label = get(g:vimtex_toc_todo_labels, 'TODO', 'TODO: ')

  return {
        \ 'title'  : l:label . title,
        \ 'number' : '',
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'level'  : a:context.max_level - a:context.level.current,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'todo',
        \ }
endfunction

" }}}1
function! s:matcher_todonotes.continue(context) abort dict " {{{1
  let [l:end, l:count] = s:find_closing(0, a:context.line, self.count, '{')
  if l:count == 0
    let a:context.entry.title .= strpart(a:context.line, 0, l:end)
    unlet! s:matcher_continue
  else
    let a:context.entry.title .= a:context.line
    let self.count = l:count
  endif
endfunction

" }}}1

let s:matcher_labels = {
      \ 're' : g:vimtex#re#not_comment . '\\label\{\zs.{-}\ze\}',
      \ 'priority' : 1,
      \}
function! s:matcher_labels.get_entry(context) abort dict " {{{1
  return {
        \ 'title'  : matchstr(a:context.line, self.re),
        \ 'number' : '',
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'level'  : a:context.max_level - a:context.level.current,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'label',
        \ }
endfunction
" }}}1

let s:matcher_beamer_frame = {
      \ 're' : '^\s*\\begin{frame}',
      \ 'priority' : 0,
      \}
function! s:matcher_beamer_frame.get_entry(context) abort dict " {{{1
  let l:title = vimtex#util#trim(
        \ matchstr(a:context.line, self.re . '\s*{\zs.*\ze}\s*$'))

  return {
        \ 'title'  : 'Frame' . (empty(l:title) ? '' : ': ' . l:title),
        \ 'number' : '',
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'level'  : a:context.max_level - a:context.level.current,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'content',
        \ }
endfunction
" }}}1

"
" Utility functions
"
function! s:clear_texorpdfstring(title) abort " {{{1
  let l:i1 = match(a:title, '\\texorpdfstring')
  if l:i1 < 0 | return a:title | endif

  " Find start of included part
  let [l:i2, l:dummy] = s:find_closing(
        \ match(a:title, '{', l:i1+1), a:title, 1, '{')
  let l:i2 = match(a:title, '{', l:i2+1)
  if l:i2 < 0 | return a:title | endif

  " Find end of included part
  let [l:i3, l:dummy] = s:find_closing(l:i2, a:title, 1, '{')
  if l:i3 < 0 | return a:title | endif

  return strpart(a:title, 0, l:i1)
        \ . strpart(a:title, l:i2+1, l:i3-l:i2-1)
        \ . s:clear_texorpdfstring(strpart(a:title, l:i3+1))
endfunction

" }}}1
function! s:find_closing(start, string, count, type) abort " {{{1
  if a:type ==# '{'
    let l:re = '{\|}'
    let l:open = '{'
  else
    let l:re = '\[\|\]'
    let l:open = '['
  endif
  let l:i2 = a:start-1
  let l:count = a:count
  while l:count > 0
    let l:i2 = match(a:string, l:re, l:i2+1)
    if l:i2 < 0 | break | endif

    if a:string[l:i2] ==# l:open
      let l:count += 1
    else
      let l:count -= 1
    endif
  endwhile

  return [l:i2, l:count]
endfunction

" }}}1
function! s:sort_by_priority(d1, d2) abort " {{{1
  let l:p1 = get(a:d1, 'priority')
  let l:p2 = get(a:d2, 'priority')
  return l:p1 >= l:p2 ? l:p1 > l:p2 : -1
endfunction

" }}}1

"
" Section level counter
"
let s:level = {}
function! s:level.reset(part, level) abort dict " {{{1
  if a:part ==# 'preamble'
    let self.old = []
  else
    let self.old += [copy(self)]
  endif

  let self.preamble = 0
  let self.frontmatter = 0
  let self.mainmatter = 0
  let self.appendix = 0
  let self.backmatter = 0
  let self.part = 0
  let self.chapter = 0
  let self.section = 0
  let self.subsection = 0
  let self.subsubsection = 0
  let self.subsubsubsection = 0
  let self.paragraph = 0
  let self.subparagraph = 0
  let self.current = a:level
  let self[a:part] = 1
endfunction

" }}}1
function! s:level.increment(level) abort dict " {{{1
  let self.current = s:sec_to_value[a:level]

  let self.part_toggle = 0

  if a:level ==# 'part'
    let self.part += 1
    let self.part_toggle = 1
  elseif a:level ==# 'chapter'
    let self.chapter += 1
    let self.section = 0
    let self.subsection = 0
    let self.subsubsection = 0
    let self.subsubsubsection = 0
    let self.paragraph = 0
    let self.subparagraph = 0
  elseif a:level ==# 'section'
    let self.section += 1
    let self.subsection = 0
    let self.subsubsection = 0
    let self.subsubsubsection = 0
    let self.paragraph = 0
    let self.subparagraph = 0
  elseif a:level ==# 'subsection'
    let self.subsection += 1
    let self.subsubsection = 0
    let self.subsubsubsection = 0
    let self.paragraph = 0
    let self.subparagraph = 0
  elseif a:level ==# 'subsubsection'
    let self.subsubsection += 1
    let self.subsubsubsection = 0
    let self.paragraph = 0
    let self.subparagraph = 0
  elseif a:level ==# 'subsubsubsection'
    let self.subsubsubsection += 1
    let self.paragraph = 0
    let self.subparagraph = 0
  elseif a:level ==# 'paragraph'
    let self.paragraph += 1
    let self.subparagraph = 0
  elseif a:level ==# 'subparagraph'
    let self.subparagraph += 1
  endif
endfunction

" }}}1

let s:sec_to_value = {
      \ '_' : 0,
      \ 'subparagraph' : 1,
      \ 'paragraph' : 2,
      \ 'subsubsubsection' : 3,
      \ 'subsubsection' : 4,
      \ 'subsection' : 5,
      \ 'section' : 6,
      \ 'chapter' : 7,
      \ 'part' : 8,
      \ }

"
" Create the lists of matchers
"
let s:matchers = map(
      \ filter(items(s:), 'v:val[0] =~# ''^matcher_'''),
      \ 'v:val[1]')
      \ + g:vimtex_toc_custom_matchers
call sort(s:matchers, function('s:sort_by_priority'))

for s:m in s:matchers
  if !has_key(s:m, 'get_entry')
    let s:m.get_entry = function('vimtex#parser#toc#get_entry_general')
  endif
endfor
unlet! s:m

let s:matchers_preamble = filter(
      \ deepcopy(s:matchers), "get(v:val, 'in_preamble')")
let s:matchers_content = filter(
      \ deepcopy(s:matchers), "get(v:val, 'in_content', 1)")
