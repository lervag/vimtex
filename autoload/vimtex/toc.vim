" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#toc#init_buffer() abort " {{{1
  if !g:vimtex_toc_enabled | return | endif

  command! -buffer VimtexTocOpen   call b:vimtex.toc.open()
  command! -buffer VimtexTocToggle call b:vimtex.toc.toggle()

  nnoremap <buffer> <plug>(vimtex-toc-open)   :call b:vimtex.toc.open()<cr>
  nnoremap <buffer> <plug>(vimtex-toc-toggle) :call b:vimtex.toc.toggle()<cr>
endfunction

" }}}1
function! vimtex#toc#init_state(state) abort " {{{1
  if !g:vimtex_toc_enabled | return | endif

  let a:state.toc = vimtex#index#new(s:toc.new())
endfunction

" }}}1

function! vimtex#toc#get_entries() abort " {{{1
  if !has_key(b:vimtex, 'toc') | return [] | endif

  return b:vimtex.toc.update(0)
endfunction

" }}}1
function! vimtex#toc#refresh() abort " {{{1
  if has_key(b:vimtex, 'toc')
    call b:vimtex.toc.update(1)
  endif
endfunction

" }}}1

let s:toc = {
      \ 'name' : 'Table of contents (vimtex)',
      \ 'help' : [
      \   '-:       decrease g:vimtex_toc_tocdepth',
      \   '+:       increase g:vimtex_toc_tocdepth',
      \   's:       hide numbering',
      \   'u:       update',
      \ ],
      \ 'show_numbers' : g:vimtex_toc_show_numbers,
      \ 'tocdepth' : g:vimtex_toc_tocdepth,
      \}

function! s:toc.new() abort dict " {{{1
  let l:toc = deepcopy(self)

  let l:toc.matchers = [
        \ s:m_preamble_start,
        \ s:m_preamble_end,
        \ s:m_vimtex_include,
        \ s:m_bib,
        \ s:m_struct,
        \ s:m_sec,
        \ { 'title' : 'Table of contents',
        \   're'    : '\v^\s*\\tableofcontents' },
        \ { 'title' : 'Alphabetical index',
        \   're'    : '\v^\s*\\printindex\[?' },
        \ { 'title' : 'Titlepage',
        \   're'    : '\v^\s*\\begin\{titlepage\}' },
        \ { 'title' : 'Bibliography',
        \   're'    : '\v^\s*\\%('
        \             .  'printbib%(liography|heading)\s*(\{|\[)?'
        \             . '|begin\s*\{\s*thebibliography\s*\}'
        \             . '|bibliography\s*\{)' },
        \] + g:vimtex_toc_custom_matchers

  unlet l:toc.new
  return l:toc
endfunction

" }}}1
function! s:toc.update(force) abort dict " {{{1
  if has_key(self, 'entries') && !g:vimtex_toc_refresh_always && !a:force
    return self.entries
  endif

  let l:content = vimtex#parser#tex(b:vimtex.tex)

  let self.entries = []
  let self.max_level = 0
  let self.topmatters = 0

  "
  " First iteration: Prepare total values
  "
  call self.parse_prepare(l:content)

  "
  " Main iteration: Generate entries
  "
  call self.parse(l:content)

  if a:force && self.is_open()
    call self.refresh()
  endif

  return self.entries
endfunction

" }}}1

function! s:toc.parse_prepare(content) " {{{1
  for [l:file, l:lnum, l:line] in a:content
    if l:line =~# s:m_sec.re
      let self.max_level = max([
            \ self.max_level,
            \ s:sec_to_value[matchstr(l:line, s:m_sec.re_level)]
            \])
    elseif l:line =~# '\v^\s*\\%(front|main|back)matter>'
      let self.topmatters += 1
    endif
  endfor
endfunction

" }}}1
function! s:toc.parse(content) abort dict " {{{1
  "
  " Parses tex project for TOC entries.  Each entry is a dictionary similar to
  " the following:
  "
  "   entry = {
  "     title  : "Some title",
  "     number : "3.1.2",
  "     file   : /path/to/file.tex,
  "     line   : 142,
  "     level  : 2,
  "   }
  "

  call s:level.reset('preamble', self.max_level)

  let l:included = {
        \ 'toc_length' : 0,
        \ 'prev' : a:content[0][0],
        \ 'files' : [a:content[0][0]],
        \ 'current' : { 'entries' : 0 },
        \}

  for [l:file, l:lnum, l:line] in a:content
    " Handle multi-line entries
    if exists('s:matcher_continue')
      call s:matcher_continue.continue(self.entries[-1], l:file, l:lnum, l:line)
      continue
    endif

    " Add TOC entry for each included file
    " Note: We do some "magic" in order to filter out the TOC entries that are
    "       not necessaries. In other words, we only want to keep TOC entries
    "       for included files that do not have other TOC entries inside them.
    if l:file !=# l:included.prev
      let l:included.prev = l:file
      let l:included.current.entries = len(self.entries) - l:included.toc_length
      let l:included.toc_length = len(self.entries)

      if index(l:included.files, l:file) < 0
        let l:included.files += [l:file]
        let l:included.current = {
              \ 'title'   : fnamemodify(l:file, ':t'),
              \ 'number'  : '[i]',
              \ 'file'    : l:file,
              \ 'line'    : 1,
              \ 'level'   : s:level.current,
              \ 'entries' : 0,
              \ }
        call add(self.entries, l:included.current)
      else
        let l:included.current = { 'entries' : 0 }
      endif
    endif

    for l:matcher in self.matchers
      if (s:level.preamble && !get(l:matcher, 'in_preamble'))
            \ || (!s:level.preamble && !get(l:matcher, 'in_content', 1))
        continue
      endif

      if l:line =~# l:matcher.re
        if has_key(l:matcher, 'action')
          call l:matcher.action(l:file, l:lnum, l:line, self.max_level)
        elseif has_key(l:matcher, 'get_entry')
          let l:entry = l:matcher.get_entry(l:file, l:lnum, l:line, self.max_level)
          if !empty(l:entry)
            call add(self.entries, l:entry)
          endif
        elseif has_key(l:matcher, 'title')
          call add(self.entries, {
                \ 'title'  : l:matcher.title,
                \ 'number' : '',
                \ 'file'   : l:file,
                \ 'line'   : l:lnum,
                \ 'level'  : self.max_level,
                \ })
        endif
        break
      endif
    endfor
  endfor

  " Remove superfluous TOC entries (cf. the "included files" section above)
  call filter(self.entries, 'get(v:val, ''entries'', 1) == 1')
endfunction

" }}}1

function! s:toc.hook_init_post() abort dict " {{{1
  if g:vimtex_toc_fold
    let self.fold_level = function('s:fold_level')
    let self.fold_text  = function('s:fold_text')
    setlocal foldmethod=expr
    setlocal foldexpr=b:index.fold_level(v:lnum)
    setlocal foldtext=b:index.fold_text()
  endif

  nnoremap <buffer> <silent> s :call b:index.toggle_numbers()<cr>
  nnoremap <buffer> <silent> u :call b:index.update(1)<cr>
  nnoremap <buffer> <silent> - :call b:index.decrease_depth()<cr>
  nnoremap <buffer> <silent> + :call b:index.increase_depth()<cr>

  " Jump to closest index
  call vimtex#pos#set_cursor(self.pos_closest)
endfunction

" }}}1
function! s:toc.print_entries() abort dict " {{{1
  if g:vimtex_toc_number_width
    let self.number_width = g:vimtex_toc_number_width
  else
    let self.number_width = 2*(self.tocdepth + 2)
  endif
  let self.number_width = max([0, self.number_width])
  let self.number_format = '%-' . self.number_width . 's'

  let index = 0
  let closest_index = 0
  for entry in self.entries
    let index += 1
    call self.print_entry(entry)
    if entry.file == self.calling_file && entry.line <= self.calling_line
      let closest_index = index
    endif
  endfor

  let self.pos_closest = [0, closest_index + self.help_nlines, 0, 0]
endfunction

" }}}1
function! s:toc.print_entry(entry) abort dict " {{{1
  let level = self.max_level - a:entry.level

  let output = ''
  if self.show_numbers
    let number = level >= self.tocdepth + 2 ? ''
          \ : strpart(self.print_number(a:entry.number), 0, self.number_width - 1)
    let output .= printf(self.number_format, number)
  endif
  let output .= printf('%-140S%s', a:entry.title, level)

  call append('$', output)
endfunction

" }}}1
function! s:toc.print_number(number) abort dict " {{{1
  if empty(a:number) | return '' | endif
  if type(a:number) == type('') | return a:number | endif

  let number = [
        \ a:number.part,
        \ a:number.chapter,
        \ a:number.section,
        \ a:number.subsection,
        \ a:number.subsubsection,
        \ a:number.subsubsubsection,
        \ ]

  " Remove unused parts
  while number[0] == 0
    call remove(number, 0)
  endwhile
  while number[-1] == 0
    call remove(number, -1)
  endwhile

  " Change numbering in frontmatter, appendix, and backmatter
  if self.topmatters > 1
        \ && (a:number.frontmatter || a:number.backmatter)
    return ''
  elseif a:number.appendix
    let number[0] = nr2char(number[0] + 64)
  endif

  return join(number, '.')
endfunction

" }}}1
function! s:toc.decrease_depth() abort dict "{{{1
  let self.tocdepth = max([self.tocdepth - 1, -2])
  call self.refresh()
endfunction

" }}}1
function! s:toc.increase_depth() abort dict "{{{1
  let self.tocdepth = min([self.tocdepth + 1, 5])
  call self.refresh()
endfunction

" }}}1
function! s:toc.syntax() abort dict "{{{1
  syntax match VimtexTocHelp /^\S.*: .*/
  syntax match VimtexTocNum
        \ /^\(\([A-Z]\+\>\|\d\+\)\(\.\d\+\)*\)\?\s*/ contained
  syntax match VimtexTocTag
        \ /^\[.\]/ contained
  syntax match VimtexTocSec0 /^.*0$/ contains=VimtexTocNum,VimtexTocTag,@Tex
  syntax match VimtexTocSec1 /^.*1$/ contains=VimtexTocNum,VimtexTocTag,@Tex
  syntax match VimtexTocSec2 /^.*2$/ contains=VimtexTocNum,VimtexTocTag,@Tex
  syntax match VimtexTocSec3 /^.*3$/ contains=VimtexTocNum,VimtexTocTag,@Tex
  syntax match VimtexTocSec4 /^.*4$/ contains=VimtexTocNum,VimtexTocTag,@Tex
endfunction

" }}}1
function! s:toc.toggle_numbers() abort dict "{{{1
  let self.show_numbers = self.show_numbers ? 0 : 1
  call self.refresh()
endfunction

" }}}1

function! s:fold_level(lnum) abort " {{{1
  let pline = getline(a:lnum - 1)
  let cline = getline(a:lnum)
  let nline = getline(a:lnum + 1)
  let l:pn = matchstr(pline, '\d$')
  let l:cn = matchstr(cline, '\d$')
  let l:nn = matchstr(nline, '\d$')

  " Don't fold options
  if cline =~# '^\s*$'
    return 0
  endif

  if l:nn > l:cn && g:vimtex_toc_fold_levels >= l:nn
    return '>' . l:nn
  endif

  if l:cn < l:pn && l:cn >= l:nn && g:vimtex_toc_fold_levels >= l:cn
    return l:cn
  endif

  return '='
endfunction

" }}}1
function! s:fold_text() abort " {{{1
  return getline(v:foldstart)
endfunction

" }}}1

" Define simple type for TOC level
let s:level = {}
function! s:level.reset(part, level) abort dict " {{{1
  let self.current = 0
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
  let self.current = a:level
  let self[a:part] = 1
endfunction

" }}}1
function! s:level.increment(level) abort dict " {{{1
  let self.current = s:sec_to_value[a:level]

  if a:level ==# 'part'
    let self.part += 1
    let self.chapter = 0
    let self.section = 0
    let self.subsection = 0
    let self.subsubsection = 0
    let self.subsubsubsection = 0
  elseif a:level ==# 'chapter'
    let self.chapter += 1
    let self.section = 0
    let self.subsection = 0
    let self.subsubsection = 0
    let self.subsubsubsection = 0
  elseif a:level ==# 'section'
    let self.section += 1
    let self.subsection = 0
    let self.subsubsection = 0
    let self.subsubsubsection = 0
  elseif a:level ==# 'subsection'
    let self.subsection += 1
    let self.subsubsection = 0
    let self.subsubsubsection = 0
  elseif a:level ==# 'subsubsection'
    let self.subsubsection += 1
    let self.subsubsubsection = 0
  elseif a:level ==# 'subsubsubsection'
    let self.subsubsubsection += 1
  endif
endfunction

" }}}1

" Map for section hierarchy
let s:sec_to_value = {
      \ '_' : 0,
      \ 'subsubsubsection' : 1,
      \ 'subsubsection' : 2,
      \ 'subsection' : 3,
      \ 'section' : 4,
      \ 'chapter' : 5,
      \ 'part' : 6,
      \ }

"
" Define TOC matchers
"
" {{{1 Vimtex includes (convenience feature)

let s:m_vimtex_include = {
      \ 're' : '%\s*vimtex-include:\?\s\+\zs\f\+',
      \ 'in_preamble' : 1,
      \}
function! s:m_vimtex_include.get_entry(file, lnum, line, max_level) abort dict " {{{2
  let l:file = matchstr(a:line, self.re)
  if l:file[0] !=# '/'
    let l:file = b:vimtex.root . '/' . l:file
  endif
  let l:file = fnamemodify(l:file, ':~:.')
  return {
        \ 'title'  : (strlen(l:file) < 70
        \               ? l:file
        \               : l:file[0:30] . '...' . l:file[-36:]),
        \ 'number' : '[v]',
        \ 'file'   : l:file,
        \ 'level'  : s:level.current,
        \ 'link'   : 1,
        \ }
endfunction

" }}}2

" }}}1
" {{{1 Preamble start

let s:m_preamble_start = {
      \ 're' : '\v^\s*\\documentclass',
      \ 'in_preamble' : 1,
      \ 'in_content' : 0,
      \}
function! s:m_preamble_start.get_entry(file, lnum, line, max_level) " {{{2
  return g:vimtex_toc_show_preamble
        \ ? {
        \   'title'  : 'Preamble',
        \   'number' : '',
        \   'file'   : a:file,
        \   'line'   : a:lnum,
        \   'level'  : a:max_level,
        \   }
        \ : {}
endfunction

" }}}2

" }}}1
" {{{1 Preamble end (action to set preamble flag)

let s:m_preamble_end = {
      \ 're' : '\v^\s*\\begin\{document\}',
      \ 'in_preamble' : 1,
      \ 'in_content' : 0,
      \}
function! s:m_preamble_end.action(file, lnum, line, max_level) abort dict " {{{2
  let s:level.preamble = 0
endfunction

" }}}2

" }}}1
" {{{1 Bibliography file inputs

let s:m_bib = {
      \ 're' : g:vimtex#re#not_comment
      \        . '\\(bibliography|add(bibresource|globalbib|sectionbib))'
      \        . '\m\s*{\zs[^}]\+\ze}',
      \ 'in_preamble' : 1,
      \}
function! s:m_bib.get_entry(file, lnum, line, max_level) abort dict " {{{2
  let l:file = matchstr(a:line, self.re)

  " Ensure that the file name has extension
  if l:file !~# '\.bib$'
    let l:file .= '.bib'
  endif

  return {
        \ 'title'  : printf('%-.78s', fnamemodify(l:file, ':t')),
        \ 'number' : '[b]',
        \ 'file'   : vimtex#kpsewhich#find(l:file),
        \ 'line'   : 0,
        \ 'level'  : a:max_level,
        \ }
endfunction

" }}}2

" }}}1
" {{{1 Section structures (e.g. frontmatters)

let s:m_struct = {
      \ 're' : '\v^\s*\\\zs((front|main|back)matter|appendix)>',
      \}
function! s:m_struct.action(file, lnum, line, max_level) abort dict " {{{2
  call s:level.reset(matchstr(a:line, self.re), a:max_level)
endfunction

" }}}2

" }}}1
" {{{1 Sectionings

let s:m_sec = {
      \ 're' : '\v^\s*\\%(part|chapter|%(sub)*section)\*?\s*(\[|\{)',
      \ 're_starred' : '\v^\s*\\%(part|chapter|%(sub)*section)\*',
      \ 're_level' : '\v^\s*\\\zs%(part|chapter|%(sub)*section)',
      \}
let s:m_sec.re_title = s:m_sec.re . '\zs.{-}\ze\%?\s*$'
function! s:m_sec.get_entry(file, lnum, line, max_level) abort dict " {{{2
  let level = matchstr(a:line, self.re_level)
  let type = matchlist(a:line, self.re)[1]
  let title = matchstr(a:line, self.re_title)

  let [l:end, l:count] = s:find_closing(0, title, 1, type)
  if l:count == 0
    let title = self.parse_title(strpart(title, 0, l:end+1))
  else
    let self.type = type
    let self.count = l:count
    let s:matcher_continue = deepcopy(self)
  endif

  call s:level.increment(level)

  return {
        \ 'title'  : title,
        \ 'number' : a:line =~# self.re_starred ? '' : deepcopy(s:level),
        \ 'file'   : a:file,
        \ 'line'   : a:lnum,
        \ 'level'  : s:level.current,
        \ }
endfunction

" }}}2
function! s:m_sec.parse_title(title) abort dict " {{{2
  let l:title = substitute(a:title, '\v%(\]|\})\s*$', '', '')
  return s:clear_texorpdfstring(l:title)
endfunction

" }}}2
function! s:m_sec.continue(entry, file, lnum, line) abort dict " {{{2
  let [l:end, l:count] = s:find_closing(0, a:line, self.count, self.type)
  if l:count == 0
    let a:entry.title = self.parse_title(a:entry.title . strpart(a:line, 0, l:end+1))
    unlet! s:matcher_continue
  else
    let a:entry.title .= a:line
    let self.count = l:count
  endif
endfunction

" }}}2

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
  let l:i2 = a:start
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

" vim: fdm=marker sw=2
