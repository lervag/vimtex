" {{{1 latex#toc#init
function! latex#toc#init(initialized)
  if g:latex_mappings_enabled && g:latex_toc_enabled
    nnoremap <silent><buffer> <LocalLeader>lt :call latex#toc#open()<cr>
    nnoremap <silent><buffer> <LocalLeader>lT :call latex#toc#toggle()<cr>
  endif
endfunction

" {{{1 latex#toc#open
function! latex#toc#open()
  " Check if buffer exists
  let winnr = bufwinnr(bufnr('LaTeX TOC'))
  if winnr >= 0
    silent execute winnr . 'wincmd w'
    return
  endif

  " Store buffer and file info
  let calling_buf = bufnr('%')
  let calling_file = expand('%:p')

  " Resize if wanted
  if g:latex_toc_resize
    silent exe "set columns+=" . g:latex_toc_width
  endif

  " Parse TOC data
  let toc = s:read_toc(g:latex#data[b:latex.id].tex)
  "let closest_index = s:find_closest_section(toc, calling_file)

  " Create TOC window
  silent exe g:latex_toc_split_side g:latex_toc_width . 'vnew LaTeX\ TOC'
  let b:toc = toc
  let b:toc_numbers = 1
  let b:calling_win = bufwinnr(calling_buf)

  " Add TOC entries
  for entry in toc
    call append('$', entry['number'] . "\t" . entry['text'])
  endfor

  " Add help info
  if !g:latex_toc_hide_help
    call append('$', "")
    call append('$', "<Esc>/q: close")
    call append('$', "<Space>: jump")
    call append('$', "<Enter>: jump and close")
    call append('$', "s:       hide numbering")
  endif
  0delete _

  " Jump to the closest section
  "execute 'normal! ' . (closest_index + 1) . 'G'

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

" {{{1 s:read_toc
function! s:read_toc(texfile, ...)
  " Allow recursion
  if a:0 != 2
    let toc = []
  else
    let toc = a:1
  endif

  let lnum = 1
  for line in readfile(a:texfile)
    let line_stat = s:test_line
    if s:test_line(line)
      call add(toc, s:parse_line(line, lnum, a:texfile))
    endif
    let lnum += 1
  endfor

  return toc
endfunction

" {{{1 s:test_line
function! s:test_line(line)
  return line =~# 
endfunction

" {{{1 s:parse_input_line
function! s:parse_input_line(line)
endfunction

" {{{1 s:parse_toc_line
function! s:parse_toc_line(line, lnum, file)
  return {
        \ 'title':  "sec",
        \ 'file':   a:texfile,
        \ 'line':   a:lnum,
        \ }
endfunction

" {{{1 s:find_closest_section
"
" 1. Binary search for the closest section
" 2. Return the index of the TOC entry
"
function! s:find_closest_section(toc, file)
  if !has_key(a:toc.fileindices, a:file)
    return
  endif

  let imax = len(a:toc.fileindices[a:file])
  if imax > 0
    let imin = 0
    while imin < imax - 1
      let i = (imax + imin) / 2
      let tocindex = a:toc.fileindices[a:file][i]
      let entry = a:toc.data[tocindex]
      let titlestr = substitute(entry['text'],
            \ '\\\w*\>\s*\%({[^}]*}\)\?', '.*', 'g')
      let titlestr = escape(titlestr, '\')
      let titlestr = substitute(titlestr, ' ', '\\_\\s\\+', 'g')
      let [lnum, cnum]
            \ = searchpos('\\'.entry['level'].'\_\s*{'.titlestr.'}', 'cnW')
      if lnum
        let imax = i
      else
        let imin = i
      endif
    endwhile
    return a:toc.fileindices[a:file][imin]
  else
    return 0
  endif
endfunction

" }}}1

" vim: fdm=marker
