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
    call append('$', entry.number . "\t" . entry.title)

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

" Define dictionary to keep track of TOC numbers
let s:number = {}

" Define regular expressions to match document parts
let s:re_input = '\v^\s*\\%(input|include)\s*\{'
let s:re_input_file = s:re_input . '\zs[^\}]+\ze}'
let s:re_sec = '\v^\s*\\%(part|chapter|%(sub)*section)\*?\s*\{'
let s:re_sec_level = '\v^\s*\\\zs%(part|chapter|%(sub)*section)\*?'
let s:re_sec_title = s:re_sec . '\zs.{-}\ze\}?$'
let s:re_bib = '\v^\s*\\%('
      \ .  'printbib%(liography|heading)\s*(\{|\[)?'
      \ . '|begin\s*\{\s*thebibliography\s*\}'
      \ . '|bibliography\s*\{)'

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
  "   }

  " Test if file is readable
  if ! filereadable(a:file)
    echoerr "Error in latex#toc s:parse_file:"
    echoerr "File not readable: " . a:file
    return []
  endif

  " Reset TOC numbering
  if a:0 > 0
    call s:number_reset()
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
              \ })
        continue
      endif

      if line =~# '\v^\s*\\begin\{document\}'
        let s:number.preamble = 0
      endif

      continue
    endif

    " 3. Parse chapters, sections, and subsections
    if line =~# s:re_sec
      call add(toc, s:parse_line_sec(a:file, lnum, line))
      continue
    endif

    " 4. Parse biblography
    if line =~# s:re_bib
      call add(toc, {
            \ 'title'  : 'Bibliography',
            \ 'number' : '',
            \ 'file'   : a:file,
            \ 'line'   : lnum,
            \ })
      continue
    endif

    " 5. Reset and change numbering for the appendix
    if line =~# '\v^\s*\\appendix'
      call s:number_start_appendix()
    endif
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
  let number = s:number_increment(matchstr(a:line, s:re_sec_level))

  return {
        \ 'title'  : title,
        \ 'number' : number,
        \ 'file'   : a:file,
        \ 'line'   : a:lnum,
        \ }
endfunction

function! s:number_reset() " {{{1
  let s:number.part = 0
  let s:number.chapter = 0
  let s:number.section = 0
  let s:number.subsection = 0
  let s:number.subsubsection = 0
  let s:number.appendix = 0
  let s:number.preamble = 1
endfunction

function! s:number_start_appendix() " {{{1
  let s:number.part = 0
  let s:number.chapter = 0
  let s:number.section = 0
  let s:number.subsection = 0
  let s:number.subsubsection = 0
  let s:number.appendix = 1
endfunction

function! s:number_increment(level) " {{{1
  " Check if level should be incremented
  if a:level !~# '\v%(part|chapter|(sub)*section)$'
    return ''
  endif

  " Increment numbers
  if a:level == 'part'
    let s:number.part += 1
    let s:number.chapter = 0
    let s:number.section = 0
    let s:number.subsection = 0
    let s:number.subsubsection = 0
  elseif a:level == 'chapter'
    let s:number.chapter += 1
    let s:number.section = 0
    let s:number.subsection = 0
    let s:number.subsubsection = 0
  elseif a:level == 'section'
    let s:number.section += 1
    let s:number.subsection = 0
    let s:number.subsubsection = 0
  elseif a:level == 'subsection'
    let s:number.subsection += 1
    let s:number.subsubsection = 0
  elseif a:level == 'subsubsection'
    let s:number.subsubsection += 1
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
        \ ]

  while number[0] == 0
    call remove(number, 0)
  endwhile

  while number[-1] == 0
    call remove(number, -1)
  endwhile

  if s:number.appendix
    let number[0] = nr2char(number[0] + 64)
  endif

  return join(number, '.')
endfunction

" }}}1

" vim: fdm=marker
