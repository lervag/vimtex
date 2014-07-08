" {{{1 latex#toc#init
function! latex#toc#init(initialized)
  if g:latex_mappings_enabled && g:latex_toc_enabled
    nnoremap <silent><buffer> <LocalLeader>lt :call latex#toc#open()<cr>
    nnoremap <silent><buffer> <LocalLeader>lT :call latex#toc#toggle()<cr>
  endif
endfunction

" {{{1 latex#toc#open
function! latex#toc#open()
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

  " Add TOC entries (keep track of closest index)
  let index = 0
  let closest_index = 0
  for entry in toc
    call append('$', entry.number . "\t" . entry.title)
    let index += 1
    if closest_index == 0
      if calling_file == entry.file && calling_line > entry.line
        let closest_index = index
      endif
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

" {{{1 latex#toc#toggle
function! latex#toc#toggle()
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

" {{{1 s:parse_file
function! s:parse_file(file, ...)
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

  " Set limits for TOC numbering (only for the first call)
  if a:0 > 0
    let s:number = {}
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

    " 2. Parse chapters, sections, and subsections
    if line =~# s:re_sec
      call add(toc, s:parse_line_sec(a:file, lnum, line))
      continue
    endif
  endfor

  return toc
endfunction

"}}}1
" {{{1 s:parse_line_input
let s:re_input = '\v^\s*\\%(input|include)\s*\{'
let s:re_input_file = s:re_input . '\zs[^\}]+\ze}'

function! s:parse_line_input(line)
  let l:file = matchstr(a:line, s:re_input_file)
  if l:file !~# '.tex$'
    let l:file .= '.tex'
  endif
  return fnamemodify(l:file, ':p')
endfunction

" }}}1
" {{{1 s:parse_line_sec
let s:re_sec = '\v^\s*\\%(chapter|%(sub)*section)\*?\s*\{'
let s:re_sec_level = '\v^\s*\\\zs%(chapter|%(sub)*section)\*?'
let s:re_sec_title = s:re_sec . '\zs.{-}\ze\}?$'

function! s:parse_line_sec(file, lnum, line)
  let title = matchstr(a:line, s:re_sec_title)
  let level = matchstr(a:line, s:re_sec_level)

  return {
        \ 'title'  : title,
        \ 'number' : s:get_number(level),
        \ 'file'   : a:file,
        \ 'line'   : a:lnum,
        \ }
endfunction

function! s:get_number(level)
  if a:level =~# '\v%(part|chapter|(sub)*section)$'
    if has_key(s:number, a:level)
      let s:number.a:level += 1
    else
      let s:number.a:level = 1
    endif
  else
    return ''
  endif

  return PP(s:number)
endfunction

" }}}1

" vim: fdm=marker
