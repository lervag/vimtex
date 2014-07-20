function! latex#toc#init(initialized) " {{{1
  if !g:latex_toc_enabled | return | endif

  " Define commands
  command! -buffer VimLatexTocOpen   call latex#toc#open()
  command! -buffer VimLatexTocToggle call latex#toc#toggle()

  " Define mappings
  if g:latex_mappings_enabled
    nnoremap <buffer> <LocalLeader>lt :call latex#toc#open()<cr>
    nnoremap <buffer> <LocalLeader>lT :call latex#toc#toggle()<cr>
  endif
endfunction

function! latex#toc#open() " {{{1
  " Go to TOC if it already exists
  let winnr = bufwinnr(bufnr('LaTeX TOC'))
  if winnr >= 0
    silent execute winnr . 'wincmd w'
    return
  endif

  " Store current buffer number and position
  let calling_buf = bufnr('%')
  let calling_file = expand('%:p')
  let calling_line = line('.')

  " Parse tex files for max level
  let s:max_level = s:set_max_level(g:latex#data[b:latex.id].tex)

  " Parse tex files for TOC data
  let toc = s:parse_file(g:latex#data[b:latex.id].tex, 1)

  " Resize vim session if wanted, then create TOC window
  if g:latex_toc_resize
    silent exe "set columns+=" . g:latex_toc_width
  endif
  silent exe g:latex_toc_split_side g:latex_toc_width . 'vnew LaTeX\ TOC'

  " Set buffer local variables
  let b:toc = toc
  let b:toc_numbers = 1
  let b:calling_win = bufwinnr(calling_buf)

  " Add TOC entries (and keep track of closest index)
  let index = 0
  let closest_index = 0
  for entry in toc
    call append('$',
          \ printf('%-10s%-140s%s',
          \   entry.number,
          \   entry.title,
          \   s:max_level - entry.level))

    let index += 1
    if entry.file == calling_file && entry.line <= calling_line
      let closest_index = index
    endif
  endfor

  " Add help info (if desired)
  if !g:latex_toc_hide_help
    call append('$', "")
    call append('$', "<Esc>/q: close")
    call append('$', "<Space>: jump")
    call append('$', "<Enter>: jump and close")
    call append('$', "s:       hide numbering")
  endif

  " Delete empty first line and jump to the closest section
  0delete _
  call setpos('.', [0, closest_index, 0, 0])

  " Set filetype and lock buffer
  setlocal filetype=latextoc
  setlocal nomodifiable
endfunction

function! latex#toc#toggle() " {{{1
  if bufwinnr(bufnr('LaTeX TOC')) >= 0
    if g:latex_toc_resize
      silent exe "set columns-=" . g:latex_toc_width
    endif
    silent execute 'bwipeout' . bufnr('LaTeX TOC')
  else
    call latex#toc#open()
    silent execute 'wincmd w'
  endif
endfunction
" }}}1

" {{{1 TOC number variables
let s:max_level = 0

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
let s:re_input = '\v^\s*\\%(input|include)\s*\{'
let s:re_input_file = s:re_input . '\zs[^\}]+\ze}'
let s:re_sec = '\v^\s*\\%(part|chapter|%(sub)*section)\*?\s*\{'
let s:re_sec_starred = '\v^\s*\\%(part|chapter|%(sub)*section)\*'
let s:re_sec_level = '\v^\s*\\\zs%(part|chapter|%(sub)*section)'
let s:re_sec_title = s:re_sec . '\zs.{-}\ze\}?$'
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
      \ 'bib' : {
      \   'title' : 'Bibliography',
      \   're'    : '\v^\s*\\%('
      \             .  'printbib%(liography|heading)\s*(\{|\[)?'
      \             . '|begin\s*\{\s*thebibliography\s*\}'
      \             . '|bibliography\s*\{)',
      \   },
      \ }

" }}}1

function! s:parse_file(file, ...) " {{{1
  " Parses tex file for TOC entries
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

  if !filereadable(a:file)
    echoerr "Error in latex#toc s:parse_file:"
    echoerr "File not readable: " . a:file
    return []
  endif

  " Reset TOC numbering
  if a:0 > 0
    call s:number_reset('preamble')
  endif

  let toc = []

  let lnum = 0
  for line in readfile(a:file)
    let lnum += 1

    " 1. Parse inputs or includes
    if line =~# s:re_input
      call extend(toc, s:parse_file(s:parse_line_input(line)))
      continue
    endif

    " 2. Parse preamble
    if s:number.preamble
      if line =~# '\v^\s*\\documentclass'
        call add(toc, {
              \ 'title'  : 'Preamble',
              \ 'number' : '',
              \ 'file'   : a:file,
              \ 'line'   : lnum,
              \ 'level'  : s:max_level,
              \ })
        continue
      endif

      if line =~# '\v^\s*\\begin\{document\}'
        let s:number.preamble = 0
      endif

      continue
    endif

    " 3. Parse document structure (front-/main-/backmatter, appendix)
    if line =~# s:re_structure
      call s:number_reset(matchstr(line, s:re_structure_match))
      continue
    endif

    " 4. Parse \parts, \chapters, \sections, and \subsections
    if line =~# s:re_sec
      call add(toc, s:parse_line_sec(a:file, lnum, line))
      continue
    endif

    " 5. Parse other stuff
    for other in values(s:re_other)
      if line =~# other.re
        call add(toc, {
              \ 'title'  : other.title,
              \ 'number' : '',
              \ 'file'   : a:file,
              \ 'line'   : lnum,
              \ 'level'  : s:max_level,
              \ })
        continue
      endif
    endfor
  endfor

  return toc
endfunction

function! s:parse_line_input(line) " {{{1
  let l:file = matchstr(a:line, s:re_input_file)
  if l:file !~# '.tex$'
    let l:file .= '.tex'
  endif
  return fnamemodify(l:file, ':p')
endfunction

function! s:parse_line_sec(file, lnum, line) " {{{1
  let title = matchstr(a:line, s:re_sec_title)
  let level = matchstr(a:line, s:re_sec_level)
  let starred = a:line =~# s:re_sec_starred ? 1 : 0
  let number = s:number_increment(level, starred)

  return {
        \ 'title'  : title,
        \ 'number' : number,
        \ 'file'   : a:file,
        \ 'line'   : a:lnum,
        \ 'level'  : s:number.current_level,
        \ }
endfunction

" }}}1

function! s:number_reset(part) " {{{1
  for key in keys(s:number)
    let s:number[key] = 0
  endfor
  let s:number[a:part] = 1

  " Initialize for preamble
  if a:part == 'preamble'
  endif
endfunction

function! s:number_increment(level, starred) " {{{1
  " Store current level
  let s:number.current_level = s:sec_to_value[a:level]

  " Check if level should be incremented
  if a:starred
    return ''
  endif

  " Increment numbers
  if a:level == 'part'
    let s:number.part += 1
    let s:number.chapter = 0
    let s:number.section = 0
    let s:number.subsection = 0
    let s:number.subsubsection = 0
    let s:number.subsubsubsection = 0
  elseif a:level == 'chapter'
    let s:number.chapter += 1
    let s:number.section = 0
    let s:number.subsection = 0
    let s:number.subsubsection = 0
    let s:number.subsubsubsection = 0
  elseif a:level == 'section'
    let s:number.section += 1
    let s:number.subsection = 0
    let s:number.subsubsection = 0
    let s:number.subsubsubsection = 0
  elseif a:level == 'subsection'
    let s:number.subsection += 1
    let s:number.subsubsection = 0
    let s:number.subsubsubsection = 0
  elseif a:level == 'subsubsection'
    let s:number.subsubsection += 1
    let s:number.subsubsubsection = 0
  elseif a:level == 'subsubsubsection'
    let s:number.subsubsubsection += 1
  endif

  return s:number_print()
endfunction

function! s:number_print() " {{{1
  let number = [
        \ s:number.part,
        \ s:number.chapter,
        \ s:number.section,
        \ s:number.subsection,
        \ s:number.subsubsection,
        \ s:number.subsubsubsection,
        \ ]

  " Remove unused parts
  while number[0] == 0
    call remove(number, 0)
  endwhile
  while number[-1] == 0
    call remove(number, -1)
  endwhile

  " Change numbering in frontmatter, appendix, and backmatter
  if s:number.frontmatter || s:number.backmatter
    return ""
  elseif s:number.appendix
    let number[0] = nr2char(number[0] + 64)
  endif

  return join(number, '.')
endfunction

" }}}1

function! s:set_max_level(file) " {{{1
  if !filereadable(a:file)
    echoerr "Error in latex#toc s:get_depth:"
    echoerr "File not readable: " . a:file
    return ''
  endif

  let n = 0

  for line in readfile(a:file)
    if line =~# s:re_input
      let n = max([n, s:set_max_level(s:parse_line_input(line))])
    elseif line =~# s:re_sec
      let n = max([n, s:sec_to_value[matchstr(line, s:re_sec_level)]])
    endif
  endfor

  return n
endfunction

" }}}1

" vim: fdm=marker
