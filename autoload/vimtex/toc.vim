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

  let a:state.toc = vimtex#index#new(deepcopy(s:toc))
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
      \   '-:       decrease secnumdepth',
      \   '+:       increase secnumdepth',
      \   's:       hide numbering',
      \   'u:       update',
      \ ],
      \ 'show_numbers' : g:vimtex_toc_show_numbers,
      \ 'secnumdepth' : g:vimtex_toc_secnumdepth,
      \}

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
    if l:line =~# s:re_sec
      let self.max_level = max([
            \ self.max_level,
            \ s:sec_to_value[matchstr(l:line, s:re_sec_level)]
            \])
    elseif l:line =~# s:re_matters
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
    " Handle multi-line sections (and chapter/subsection/etc)
    if get(s:, 'sec_continue', 0)
      let [l:end, l:count] = s:find_closing(0, l:line, s:sec_count, s:sec_type)
      if l:count == 0
        let self.entries[-1].title = self.parse_line_sec_title(
              \ self.entries[-1].title . strpart(l:line, 0, l:end+1))
        unlet s:sec_type
        unlet s:sec_count
        unlet s:sec_continue
      else
        let self.entries[-1].title .= l:line
        let s:sec_count = l:count
      endif
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

    " Convenience includes
    let l:fname = matchstr(l:line, s:re_vimtex_include)
    if !empty(l:fname)
      if l:fname[0] !=# '/'
        let l:fname = b:vimtex.root . '/' . l:fname
      endif
      let l:fname = fnamemodify(l:fname, ':~:.')
      call add(self.entries, {
            \ 'title'  : (strlen(l:fname) < 70
            \               ? l:fname
            \               : l:fname[0:30] . '...' . l:fname[-36:]),
            \ 'number' : '[v]',
            \ 'file'   : l:fname,
            \ 'level'  : s:level.current,
            \ 'link'   : 1,
            \ })
      continue
    endif

    " Bibliography files
    if l:line =~# s:re_bibs
      call add(self.entries, self.parse_bib_input(l:line))
      continue
    endif

    " Preamble
    if s:level.preamble
      if g:vimtex_toc_show_preamble && l:line =~# '\v^\s*\\documentclass'
        call add(self.entries, {
              \ 'title'  : 'Preamble',
              \ 'number' : '',
              \ 'file'   : l:file,
              \ 'line'   : l:lnum,
              \ 'level'  : self.max_level,
              \ })
        continue
      endif

      if l:line =~# '\v^\s*\\begin\{document\}'
        let s:level.preamble = 0
      endif

      continue
    endif

    " Document structure (front-/main-/backmatter, appendix)
    if l:line =~# s:re_structure
      call s:level.reset(matchstr(l:line, s:re_structure_match), self.max_level)
      continue
    endif

    " Sections (\parts, \chapters, \sections, and \subsections, ...)
    if l:line =~# s:re_sec
      call add(self.entries, self.parse_line_sec(l:file, l:lnum, l:line))
      continue
    endif

    " Other stuff
    for l:other in values(s:re_other)
      if l:line =~# l:other.re
        call add(self.entries, {
              \ 'title'  : l:other.title,
              \ 'number' : '',
              \ 'file'   : l:file,
              \ 'line'   : l:lnum,
              \ 'level'  : self.max_level,
              \ })
        continue
      endif
    endfor
  endfor

  " Remove superfluous TOC entries (cf. the "included files" section above)
  call filter(self.entries, 'get(v:val, ''entries'', 1) == 1')
endfunction

" }}}1
function! s:toc.parse_line_sec(file, lnum, line) abort dict " {{{1
  let level = matchstr(a:line, s:re_sec_level)
  let type = matchlist(a:line, s:re_sec)[1]
  let title = matchstr(a:line, s:re_sec_title)

  let [l:end, l:count] = s:find_closing(0, title, 1, type)
  if l:count == 0
    let title = self.parse_line_sec_title(strpart(title, 0, l:end+1))
  else
    let s:sec_type = type
    let s:sec_count = l:count
    let s:sec_continue = 1
  endif

  call s:level.increment(level)

  return {
        \ 'title'  : title,
        \ 'number' : a:line =~# s:re_sec_starred ? '' : deepcopy(s:level),
        \ 'file'   : a:file,
        \ 'line'   : a:lnum,
        \ 'level'  : s:level.current,
        \ }
endfunction

" }}}1
function! s:toc.parse_line_sec_title(title) abort dict " {{{1
  let l:title = substitute(a:title, '\v%(\]|\})\s*$', '', '')
  return s:clear_texorpdfstring(l:title)
endfunction

" }}}1
function! s:toc.parse_bib_input(line) abort dict " {{{1
  let l:file = matchstr(a:line, s:re_bibs)

  " Ensure that the file name has extension
  if l:file !~# '\.bib$'
    let l:file .= '.bib'
  endif

  return {
        \ 'title'  : printf('%-.78s', fnamemodify(l:file, ':t')),
        \ 'number' : '[b]',
        \ 'file'   : vimtex#kpsewhich#find(l:file),
        \ 'line'   : 0,
        \ 'level'  : self.max_level,
        \ }
endfunction

" }}}1

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

"
" Index related methods
"

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
    let self.number_width = 2*(self.secnumdepth + 2)
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
    let number = level >= self.secnumdepth + 2 ? ''
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
function! s:toc.secnumdepth_decrease() abort dict "{{{1
  let self.secnumdepth = max([self.secnumdepth - 1, -2])
  call self.refresh()
endfunction

" }}}1
function! s:toc.secnumdepth_increase() abort dict "{{{1
  let self.secnumdepth = min([self.secnumdepth + 1, 5])
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


" {{{1 Initialize module

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

" Define regular expressions to match document parts
let s:re_sec = '\v^\s*\\%(part|chapter|%(sub)*section)\*?\s*(\[|\{)'
let s:re_sec_title = s:re_sec . '\zs.{-}\ze\%?\s*$'
let s:re_sec_starred = '\v^\s*\\%(part|chapter|%(sub)*section)\*'
let s:re_sec_level = '\v^\s*\\\zs%(part|chapter|%(sub)*section)'
let s:re_vimtex_include = '%\s*vimtex-include:\?\s\+\zs\f\+'
let s:re_matters = '\v^\s*\\%(front|main|back)matter>'
let s:re_structure = '\v^\s*\\((front|main|back)matter|appendix)>'
let s:re_structure_match = '\v((front|main|back)matter|appendix)'
let s:re_other = {
      \ 'toc' : {
      \   'title' : 'Table of contents',
      \   're'    : '\v^\s*\\tableofcontents',
      \   },
      \ 'index' : {
      \   'title' : 'Alphabetical index',
      \   're'    : '\v^\s*\\printindex\[?',
      \   },
      \ 'titlepage' : {
      \   'title' : 'Titlepage',
      \   're'    : '\v^\s*\\begin\{titlepage\}',
      \   },
      \ 'bib' : {
      \   'title' : 'Bibliography',
      \   're'    : '\v^\s*\\%('
      \             .  'printbib%(liography|heading)\s*(\{|\[)?'
      \             . '|begin\s*\{\s*thebibliography\s*\}'
      \             . '|bibliography\s*\{)',
      \   },
      \ }

let s:nocomment = '\v%(%(\\@<!%(\\\\)*)@<=\%.*)@<!'
let s:re_bibs  = s:nocomment
let s:re_bibs .= '\\(bibliography|add(bibresource|globalbib|sectionbib))'
let s:re_bibs .= '\m\s*{\zs[^}]\+\ze}'

" }}}1

" vim: fdm=marker sw=2
