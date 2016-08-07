" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#toc#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_toc_enabled', 1)
  if !g:vimtex_toc_enabled | return | endif

  call vimtex#util#set_default('g:vimtex_toc_fold', 0)
  call vimtex#util#set_default('g:vimtex_toc_fold_levels', 10)
  call vimtex#util#set_default('g:vimtex_toc_number_width', 0)
  call vimtex#util#set_default('g:vimtex_toc_secnumdepth', 3)
  call vimtex#util#set_default('g:vimtex_toc_show_numbers', 1)
  call vimtex#util#set_default('g:vimtex_toc_show_preamble', 1)
endfunction

" }}}1
function! vimtex#toc#init_script() " {{{1
  call vimtex#util#set_highlight('VimtexTocNum', 'Number')
  call vimtex#util#set_highlight('VimtexTocSec0', 'Title')
  call vimtex#util#set_highlight('VimtexTocSec1', 'Normal')
  call vimtex#util#set_highlight('VimtexTocSec2', 'helpVim')
  call vimtex#util#set_highlight('VimtexTocSec3', 'NonText')
  call vimtex#util#set_highlight('VimtexTocSec4', 'Comment')
  call vimtex#util#set_highlight('VimtexTocHelp', 'helpVim')

  if !g:vimtex_toc_enabled | return | endif

  let s:name = 'Table of contents (vimtex)'

  "
  " Define TOC variables
  "

  " Define counters
  let s:max_level = 0
  let s:count_matters = 0

  " Define dictionary to keep track of TOC numbers
  let s:number = {
        \ 'part' : 0,
        \ 'chapter' : 0,
        \ 'section' : 0,
        \ 'subsection' : 0,
        \ 'subsubsection' : 0,
        \ 'subsubsubsection' : 0,
        \ 'current_level' : 0,
        \ 'preamble' : 0,
        \ 'frontmatter' : 0,
        \ 'mainmatter' : 0,
        \ 'appendix' : 0,
        \ 'backmatter' : 0,
        \ }

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
  let s:re_sec = '\v^\s*\\%(part|chapter|%(sub)*section)\*?\s*%(\[.{-}\])?\{'
  let s:re_sec_starred = '\v^\s*\\%(part|chapter|%(sub)*section)\*'
  let s:re_sec_level = '\v^\s*\\\zs%(part|chapter|%(sub)*section)'
  let s:re_sec_title = s:re_sec . '\zs.{-}\ze\}?\%?\s*$'
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
        \   're'    : '\v^\s*\\begin{titlepage}',
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
endfunction

" }}}1
function! vimtex#toc#init_buffer() " {{{1
  if !g:vimtex_toc_enabled | return | endif

  " Define commands
  command! -buffer VimtexTocOpen   call vimtex#toc#open()
  command! -buffer VimtexTocToggle call vimtex#toc#toggle()

  " Define mappings
  nnoremap <buffer> <plug>(vimtex-toc-open)   :call vimtex#toc#open()<cr>
  nnoremap <buffer> <plug>(vimtex-toc-toggle) :call vimtex#toc#toggle()<cr>
endfunction

" }}}1

function! vimtex#toc#open() " {{{1
  if vimtex#index#open(s:name) | return | endif

  if !exists('b:vimtex')
    if exists('s:index')
      call vimtex#index#create(s:index)
    endif
    return
  endif

  let s:index = {
        \ 'name'            : s:name,
        \ 'calling_file'    : expand('%:p'),
        \ 'calling_line'    : line('.'),
        \ 'entries'         : vimtex#toc#get_entries(),
        \ 'show_numbers'    : g:vimtex_toc_show_numbers,
        \ 'max_level'       : s:max_level,
        \ 'topmatters'      : s:count_matters,
        \ 'secnumdepth'     : g:vimtex_toc_secnumdepth,
        \ 'help'            : [
        \   '-:       decrease secnumpdeth',
        \   '+:       increase secnumpdeth',
        \   's:       hide numbering',
        \ ],
        \ 'hook_init_post'  : function('s:index_hook_init_post'),
        \ 'print_entries'   : function('s:index_print_entries'),
        \ 'print_entry'     : function('s:index_print_entry'),
        \ 'print_number'    : function('s:index_print_number'),
        \ 'increase_depth'  : function('s:index_secnumdepth_increase'),
        \ 'decrease_depth'  : function('s:index_secnumdepth_decrease'),
        \ 'syntax'          : function('s:index_syntax'),
        \ 'toggle_numbers'  : function('s:index_toggle_numbers'),
        \ }

  call vimtex#index#create(s:index)
endfunction

" }}}1
function! vimtex#toc#toggle() " {{{1
  if vimtex#index#open(s:name)
    call vimtex#index#close(s:name)
  else
    call vimtex#toc#open()
    silent execute 'wincmd w'
  endif
endfunction

" }}}1

function! vimtex#toc#get_entries() " {{{1
  if !exists('b:vimtex') | return [] | endif

  "
  " Parses tex project for TOC entries
  "
  " The function returns a list of entries.  Each entry is a dictionary:
  "
  "   entry = {
  "     title  : "Some title",
  "     number : "3.1.2",
  "     file   : /path/to/file.tex,
  "     line   : 142,
  "     level  : 2,
  "   }
  "

  let l:parsed = vimtex#parser#tex(b:vimtex.tex)

  let s:max_level = 0
  let s:count_matters = 0
  for [l:file, l:lnum, l:line] in l:parsed
    if l:line =~# s:re_sec
      let s:max_level = max([s:max_level,
            \ s:sec_to_value[matchstr(l:line, s:re_sec_level)]])
    elseif l:line =~# s:re_matters
      let s:count_matters += 1
    endif
  endfor

  call s:number_reset('preamble')

  let l:toc = []
  let l:included = {
        \ 'toc_length' : 0,
        \ 'prev' : l:parsed[0][0],
        \ 'files' : [l:parsed[0][0]],
        \ 'current' : { 'entries' : 0 },
        \}

  for [l:file, l:lnum, l:line] in l:parsed

    " Add TOC entry for each included file
    " Note: We do some "magic" in order to filter out the TOC entries that are
    "       not necessaries. In other words, we only want to keep TOC entries
    "       for included files that do not have other TOC entries inside them.
    if l:file ==# l:included.prev
      if l:included.toc_length < len(l:toc)
        let l:included.toc_length = len(l:toc)
        let l:included.current.entries += 1
      endif
    else
      if index(l:included.files, l:file) < 0
        let l:included.files += [l:file]
        let l:included.prev = l:file
        let l:included.current = {
              \ 'title'   : 'Included: ' . fnamemodify(l:file, ':t'),
              \ 'number'  : '',
              \ 'file'    : l:file,
              \ 'line'    : 1,
              \ 'level'   : s:number.current_level,
              \ 'entries' : 0,
              \ }
        call add(l:toc, l:included.current)
      else
        let l:included.current = { 'entries' : 0 }
      endif
    endif

    " Bibliography files
    if l:line =~# s:re_bibs
      call add(l:toc, s:parse_bib_input(l:line))
      continue
    endif

    " Preamble
    if s:number.preamble
      if g:vimtex_toc_show_preamble && l:line =~# '\v^\s*\\documentclass'
        call add(l:toc, {
              \ 'title'  : 'Preamble',
              \ 'number' : '',
              \ 'file'   : l:file,
              \ 'line'   : l:lnum,
              \ 'level'  : s:max_level,
              \ })
        continue
      endif

      if l:line =~# '\v^\s*\\begin\{document\}'
        let s:number.preamble = 0
      endif

      continue
    endif

    " Document structure (front-/main-/backmatter, appendix)
    if l:line =~# s:re_structure
      call s:number_reset(matchstr(l:line, s:re_structure_match))
      continue
    endif

    " Sections (\parts, \chapters, \sections, and \subsections, ...)
    if l:line =~# s:re_sec
      call add(l:toc, s:parse_line_sec(l:file, l:lnum, l:line))
      continue
    endif

    " Other stuff
    for l:other in values(s:re_other)
      if l:line =~# l:other.re
        call add(l:toc, {
              \ 'title'  : l:other.title,
              \ 'number' : '',
              \ 'file'   : l:file,
              \ 'line'   : l:lnum,
              \ 'level'  : s:max_level,
              \ })
        continue
      endif
    endfor
  endfor

  " Remove the superfluous TOC entries and return
  return filter(l:toc, 'get(v:val, ''entries'', 1) == 1')
endfunction

" }}}1

function! s:index_fold_level(lnum) " {{{1
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
function! s:index_fold_text() " {{{1
  return getline(v:foldstart)
endfunction

" }}}1
function! s:index_hook_init_post() dict " {{{1
  if g:vimtex_toc_fold
    let self.fold_level = function('s:index_fold_level')
    let self.fold_text  = function('s:index_fold_text')
    setlocal foldmethod=expr
    setlocal foldexpr=b:index.fold_level(v:lnum)
    setlocal foldtext=b:index.fold_text()
  endif

  nnoremap <buffer> <silent> s :call b:index.toggle_numbers()<cr>
  nnoremap <buffer> <silent> - :call b:index.decrease_depth()<cr>
  nnoremap <buffer> <silent> + :call b:index.increase_depth()<cr>

  " Jump to closest index
  call setpos('.', self.pos_closest)
endfunction

" }}}1
function! s:index_print_entries() dict " {{{1
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
function! s:index_print_entry(entry) dict " {{{1
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
function! s:index_print_number(number) dict " {{{1
  if empty(a:number) | return '' | endif

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
function! s:index_secnumdepth_decrease() dict "{{{1
  let self.secnumdepth = max([self.secnumdepth - 1, -2])
  call self.refresh()
endfunction

" }}}1
function! s:index_secnumdepth_increase() dict "{{{1
  let self.secnumdepth = min([self.secnumdepth + 1, 5])
  call self.refresh()
endfunction

" }}}1
function! s:index_syntax() dict "{{{1
  syntax match VimtexTocNum
        \ /^\(\([A-Z]\+\>\|\d\+\)\(\.\d\+\)*\)\?\s*/ contained
  syntax match VimtexTocSec0 /^.*0$/ contains=VimtexTocNum,@Tex
  syntax match VimtexTocSec1 /^.*1$/ contains=VimtexTocNum,@Tex
  syntax match VimtexTocSec2 /^.*2$/ contains=VimtexTocNum,@Tex
  syntax match VimtexTocSec3 /^.*3$/ contains=VimtexTocNum,@Tex
  syntax match VimtexTocSec4 /^.*4$/ contains=VimtexTocNum,@Tex
  syntax match VimtexTocHelp /^\S.*: .*/
endfunction

" }}}1
function! s:index_toggle_numbers() dict "{{{1
  let self.show_numbers = self.show_numbers ? 0 : 1
  call self.refresh()
endfunction

" }}}1

function! s:parse_line_sec(file, lnum, line) " {{{1
  let title = matchstr(a:line, s:re_sec_title)
  let level = matchstr(a:line, s:re_sec_level)

  " Check if section is starred
  if a:line =~# s:re_sec_starred
    let number = ''
    let s:number.current_level = s:sec_to_value[level]
  else
    let number = s:number_increment(level)
  endif

  return {
        \ 'title'  : title,
        \ 'number' : number,
        \ 'file'   : a:file,
        \ 'line'   : a:lnum,
        \ 'level'  : s:number.current_level,
        \ }
endfunction

" }}}1
function! s:parse_bib_input(line) " {{{1
  let l:file = matchstr(a:line, s:re_bibs)

  " Ensure that the file name has extension
  if l:file !~# '\.bib$'
    let l:file .= '.bib'
  endif

  return {
        \ 'title'  : printf('Included bib file: %-.60s', fnamemodify(l:file, ':t')),
        \ 'number' : '',
        \ 'file'   : vimtex#util#kpsewhich(l:file),
        \ 'line'   : 0,
        \ 'level'  : s:max_level,
        \ }
endfunction

" }}}1

function! s:number_reset(part) " {{{1
  for key in keys(s:number)
    let s:number[key] = 0
  endfor
  let s:number[a:part] = 1

  let s:number.current_level = s:max_level
endfunction

" }}}1
function! s:number_increment(level) " {{{1
  if a:level ==# 'part'
    let s:number.part += 1
    let s:number.chapter = 0
    let s:number.section = 0
    let s:number.subsection = 0
    let s:number.subsubsection = 0
    let s:number.subsubsubsection = 0
  elseif a:level ==# 'chapter'
    let s:number.chapter += 1
    let s:number.section = 0
    let s:number.subsection = 0
    let s:number.subsubsection = 0
    let s:number.subsubsubsection = 0
  elseif a:level ==# 'section'
    let s:number.section += 1
    let s:number.subsection = 0
    let s:number.subsubsection = 0
    let s:number.subsubsubsection = 0
  elseif a:level ==# 'subsection'
    let s:number.subsection += 1
    let s:number.subsubsection = 0
    let s:number.subsubsubsection = 0
  elseif a:level ==# 'subsubsection'
    let s:number.subsubsection += 1
    let s:number.subsubsubsection = 0
  elseif a:level ==# 'subsubsubsection'
    let s:number.subsubsubsection += 1
  endif

  " Store current level
  let s:number.current_level = s:sec_to_value[a:level]

  return copy(s:number)
endfunction

" }}}1

" vim: fdm=marker sw=2
