" VimTeX - LaTeX plugin for Vim
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
  let l:matchers = vimtex#parser#toc#get_matchers()

  let l:max_level = 0
  for [l:file, l:lnum, l:line] in l:content
    if l:line =~# l:matchers.d['section'].re
      let l:max_level = max([
            \ l:max_level,
            \ vimtex#parser#toc#level(l:matchers.d['section'].level(l:line)),
            \])
    endif
  endfor

  call s:level.reset('preamble', l:max_level)

  " No more parsing if there is no content
  if empty(l:content) | return l:entries | endif

  "
  " Begin parsing LaTeX files
  "
  let l:context = {}
  let l:lnum_total = 0
  let l:matcher_list = l:matchers.preamble
  for [l:file, l:lnum, l:line] in l:content
    let l:lnum_total += 1

    " Handle multi-line entries
    if has_key(l:context, 'continue')
      call extend(l:context, {
            \ 'line': l:line,
            \ 'lnum': l:lnum,
            \ 'lnum_total': l:lnum_total,
            \ 'entry': get(l:entries, -1, {}),
            \})
      call l:matchers.d[l:context.continue].continue(l:context)
      continue
    endif

    let l:context = {
          \ 'file': l:file,
          \ 'line': l:line,
          \ 'lnum': l:lnum,
          \ 'lnum_total': l:lnum_total,
          \ 'level': s:level,
          \ 'max_level': l:max_level,
          \ 'entry': get(l:entries, -1, {}),
          \ 'num_entries': len(l:entries),
          \}

    " Detect end of preamble
    if s:level.preamble && l:line =~# '\v^\s*\\begin\{document\}'
      let s:level.preamble = 0
      let l:matcher_list = l:matchers.content
      continue
    endif

    " Apply prefilter - this gives considerable speedup for large documents
    if l:line !~# l:matchers.prefilter | continue | endif

    " Apply the matchers
    for l:matcher in l:matcher_list
      if l:line =~# l:matcher.re
        let l:entry = l:matcher.get_entry(l:context)

        if type(l:entry) == v:t_list
          call extend(l:entries, l:entry)
        elseif !empty(l:entry)
          call add(l:entries, l:entry)
        endif
      endif
    endfor
  endfor

  for l:matcher in l:matchers.all
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
function! vimtex#parser#toc#get_matchers() abort " {{{1
  let l:matchers = {
        \ 'all': [],
        \ 'preamble': [],
        \ 'content': [],
        \ 'd': {},
        \}

  " Collect all matchers
  for l:name in s:matchers
    let l:matcher = extend(
          \ vimtex#parser#toc#{l:name}#new(),
          \ get(g:vimtex_toc_config_matchers, l:name, {}))
    let l:matcher.name = l:name
    call add(l:matchers.all, l:matcher)
  endfor
  let l:matchers.all += g:vimtex_toc_custom_matchers

  " Remove disabled matchers
  call filter(l:matchers.all, {_, x -> !get(x, 'disable')})

  " Add dictionary that gives access to specific matchers
  let l:counter = 1
  for l:matcher in l:matchers.all
    if !has_key(l:matcher, 'name')
      let l:matcher.name = 'custom' . l:counter
      let l:counter += 1
    endif

    let l:matchers.d[l:matcher.name] = l:matcher
  endfor

  " Sort the matchers by priority
  function! s:sort_by_priority(d1, d2) abort
    let l:p1 = get(a:d1, 'priority')
    let l:p2 = get(a:d2, 'priority')
    return l:p1 >= l:p2 ? l:p1 > l:p2 : -1
  endfunction
  call sort(l:matchers.all, function('s:sort_by_priority'))

  " Further processing of the matchers
  for l:matcher in l:matchers.all
    " Initialize matchers if relevant
    try
      call l:matcher.init()
    catch /E716/
    endtry

    " Ensure the matcher have 'get_entry'
    if !has_key(l:matcher, 'get_entry')
      function! l:matcher.get_entry(context) abort dict
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
    endif

    " Populate the 'preamble' and 'content' lists
    if get(l:matcher, 'in_preamble')
      call add(l:matchers.preamble, l:matcher)
    endif
    if get(l:matcher, 'in_content', 1)
      call add(l:matchers.content, l:matcher)
    endif
  endfor

  " Populate the prefilter
  let l:cmds = []
  let l:re = ''
  for l:matcher in l:matchers.all
    let l:cmds += get(l:matcher, 'prefilter_cmds', [])
    if has_key(l:matcher, 'prefilter_re')
      let l:re .= '|' . l:matcher.prefilter_re
    endif
  endfor
  let l:matchers.prefilter = '\v\\%(' . join(l:cmds, '|') . ')' . l:re

  return l:matchers
endfunction

let s:matchers = map(
      \ glob(expand('<sfile>:r') . '/*.vim', 0, 1),
      \ { _, x -> fnamemodify(x, ':t:r') })

" }}}1
function! vimtex#parser#toc#level(level) abort " {{{1
  return s:sec_to_value[a:level]
endfunction

let s:sec_to_value = {
      \ '_': 0,
      \ 'subparagraph': 1,
      \ 'paragraph': 2,
      \ 'subsubsubsubsection': 3,
      \ 'subsubsubsection': 4,
      \ 'subsubsection': 5,
      \ 'subsection': 6,
      \ 'section': 7,
      \ 'chapter': 8,
      \ 'part': 9,
      \}

" }}}1

"
" Section level counter
"
let s:level = get(s:, 'level', {})
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
  let self.current = vimtex#parser#toc#level(a:level)

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
function! s:level.set_current(level) abort dict " {{{1
  let self.current = vimtex#parser#toc#level(a:level)
endfunction

" }}}1
