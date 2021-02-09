" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#tex#parse(file, opts) abort " {{{1
  let l:opts = extend({
        \ 'detailed': 1,
        \ 'root' : exists('b:vimtex.root') ? b:vimtex.root : '',
        \}, a:opts)

  let l:cache = vimtex#cache#open('texparser', {
        \ 'local': 1,
        \ 'persistent': 0,
        \ 'default': {'ftime': -2},
        \})

  let l:parsed = s:parse(a:file, l:opts, l:cache)

  if !l:opts.detailed
    call map(l:parsed, 'v:val[2]')
  endif

  return l:parsed
endfunction

" }}}1
function! vimtex#parser#tex#parse_files(file, opts) abort " {{{1
  let l:opts = extend({
        \ 'root' : exists('b:vimtex.root') ? b:vimtex.root : '',
        \}, a:opts)

  let l:cache = vimtex#cache#open('texparser', {
        \ 'local': 1,
        \ 'persistent': 0,
        \ 'default': {'ftime': -2},
        \})

  return vimtex#util#uniq_unsorted(
        \ s:parse_files(a:file, l:opts, l:cache))
endfunction

" }}}1
function! vimtex#parser#tex#parse_preamble(file, opts) abort " {{{1
  let l:opts = extend({
          \ 'inclusive' : 0,
          \ 'root' : exists('b:vimtex.root') ? b:vimtex.root : '',
          \}, a:opts)

  return s:parse_preamble(a:file, l:opts, [])
endfunction

" }}}1

function! vimtex#parser#tex#texorpdfstring(title) abort " {{{1
  " \texorpdfstring{TEXstring}{PDFstring} -> TEXstring

  let l:i1 = match(a:title, '\\texorpdfstring')
  if l:i1 < 0 | return a:title | endif

  " Find start of included part
  let l:i2 = match(a:title, '{', l:i1+1)
  if l:i2 < 0 | return a:title | endif

  " Find end of included part
  let [l:i3, l:dummy] = vimtex#parser#tex#find_closing(l:i2+1, a:title, 1, '{')
  if l:i3 < 0 | return a:title | endif

  " Find start, then end of excluded part
  let l:i4 = match(a:title, '{', l:i3+1)
  if l:i4 < 0 | return a:title | endif
  let [l:i4, l:dummy] = vimtex#parser#tex#find_closing(l:i4+1, a:title, 1, '{')

  return strpart(a:title, 0, l:i1)
        \ . strpart(a:title, l:i2+1, l:i3-l:i2-1)
        \ . vimtex#parser#tex#texorpdfstring(strpart(a:title, l:i4+1))
endfunction

" }}}1
function! vimtex#parser#tex#find_closing(start, string, count, type) abort " {{{1
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

function! s:parse(file, opts, cache) abort " {{{1
  let l:current = a:cache.get(a:file)
  let l:ftime = getftime(a:file)
  if l:ftime > l:current.ftime
    let l:current.ftime = l:ftime
    call s:parse_current(a:file, a:opts, l:current)
  endif

  let l:parsed = []

  for l:val in l:current.lines
    if type(l:val) == v:t_list
      call add(l:parsed, l:val)
    else
      call extend(l:parsed, s:parse(l:val, a:opts, a:cache))
    endif
  endfor

  return l:parsed
endfunction

" }}}1
function! s:parse_files(file, opts, cache) abort " {{{1
  let l:current = a:cache.get(a:file)
  let l:ftime = getftime(a:file)
  if l:ftime > l:current.ftime
    let l:current.ftime = l:ftime
    call s:parse_current(a:file, a:opts, l:current)
  endif

  " Only include existing files
  if !filereadable(a:file) | return [] | endif

  let l:files = [a:file]
  for l:file in l:current.includes
    let l:files += s:parse_files(l:file, a:opts, a:cache)
  endfor

  return l:files
endfunction

" }}}1
function! s:parse_current(file, opts, current) abort " {{{1
  let a:current.lines = []
  let a:current.includes = []

  " Also load includes from glsentries
  let l:re_input = g:vimtex#re#tex_input . '|^\s*\\loadglsentries'

  if filereadable(a:file)
    let l:lnum = 0
    for l:line in readfile(a:file)
      let l:lnum += 1
      call add(a:current.lines, [a:file, l:lnum, l:line])

      " Continue if the current line has \input{...} or similar
      " Note: The 'stridx' is a minor optimization to avoid running a complex
      "       regex on "simple" lines
      if stridx(l:line, '\') < 0 || l:line !~# l:re_input
        continue
      endif

      let l:file = s:input_parser(l:line, a:file, a:opts.root)
      call add(a:current.lines, l:file)

      if a:file ==# l:file
        call vimtex#log#error([
              \ 'Recursive file inclusion!',
              \ 'File: ' . fnamemodify(a:file, ':.'),
              \ 'Line ' . l:lnum . ':',
              \ l:line,
              \])
      else
        call add(a:current.includes, l:file)
      endif
    endfor
  endif
endfunction

" }}}1
function! s:parse_preamble(file, opts, parsed_files) abort " {{{1
  if !filereadable(a:file) || index(a:parsed_files, a:file) >= 0
    return []
  endif
  call add(a:parsed_files, a:file)

  let l:lines = []
  for l:line in readfile(a:file)
    if l:line =~# '\\begin\s*{document}'
      if a:opts.inclusive
        call add(l:lines, l:line)
      endif
      break
    endif

    if l:line =~# g:vimtex#re#tex_input
      let l:file = s:input_parser(l:line, a:file, a:opts.root)
      call extend(l:lines, s:parse_preamble(l:file, a:opts, a:parsed_files))
    else
      call add(l:lines, l:line)
    endif
  endfor

  return l:lines
endfunction

" }}}1

function! s:input_parser(line, current_file, root) abort " {{{1
  " Handle \space commands
  let l:file = substitute(a:line, '\\space\s*', ' ', 'g')

  " Handle import and subfile package commands
  if l:file =~# g:vimtex#re#tex_input_import
    let l:root = l:file =~# '\\sub'
          \ ? fnamemodify(a:current_file, ':p:h')
          \ : a:root

    let l:candidate = s:input_to_filename(
          \ substitute(copy(l:file), '}\s*{', '', 'g'), l:root)
    if !empty(l:candidate)
      return l:candidate
    else
      return s:input_to_filename(
          \ substitute(copy(l:file), '{.{-}}', '', ''), l:root)
    endif
  else
    return s:input_to_filename(l:file, a:root)
  endif
endfunction

" }}}1
function! s:input_to_filename(input, root) abort " {{{1
  let l:file = matchstr(a:input, '\zs[^{}]\+\ze}\s*\%(%\|$\)')

  " Trim whitespaces and quotes from beginning/end of string
  let l:file = substitute(l:file, '^\(\s\|"\)*', '', '')
  let l:file = substitute(l:file, '\(\s\|"\)*$', '', '')

  " Ensure that the file name has extension
  if empty(fnamemodify(l:file, ':e'))
    let l:file .= '.tex'
  endif

  if vimtex#paths#is_abs(l:file)
    return l:file
  endif

  let l:candidate = a:root . '/' . l:file
  if filereadable(l:candidate)
    return l:candidate
  endif

  let l:candidate = vimtex#kpsewhich#find(l:file)
  return filereadable(l:candidate) ? l:candidate : l:file
endfunction

" }}}1
