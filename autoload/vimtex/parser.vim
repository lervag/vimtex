" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#init_options() " {{{1
endfunction

" }}}1
function! vimtex#parser#init_script() " {{{1
  let s:input_line = '\v^\s*\\%(input|include)\s*\{'
endfunction

" }}}1
function! vimtex#parser#init_buffer() " {{{1
endfunction

" }}}1

function! vimtex#parser#tex(file, ...) " {{{1
  let l:detailed = a:0 > 0 ? a:1 : 1
  let l:recurse = a:0 > 1 ? a:2 : 1

  let l:parsed = []

  if a:file ==# ''
    return l:parsed
  elseif !filereadable(a:file)
    echoerr 'File not readable: ' . a:file
    return l:parsed
  endif

  let l:lnum = 0
  for l:line in readfile(a:file)
    let l:lnum += 1

    if l:recurse && l:line =~# s:input_line
      call extend(l:parsed,
            \     vimtex#parser#tex(s:parse_input_line(l:line, a:file),
            \                       l:detailed, l:recurse))
      continue
    endif

    if l:detailed
      call add(l:parsed, [a:file, l:lnum, l:line])
    else
      call add(l:parsed, l:line)
    endif
  endfor

  return l:parsed
endfunction

" }}}1

function! s:parse_input_line(line, file) " {{{1
  " Included file names may include spaces through the use of the \space
  " command
  let l:file = substitute(a:line, '\\space\s*', ' ', 'g')

  " Match the file name inside the include command
  let l:file = matchstr(l:file, s:input_line . '\zs[^\}]+\ze}')

  " Trim whitespaces and quotes from beginning/end of string
  let l:file = substitute(l:file, '^\(\s\|"\)*', '', '')
  let l:file = substitute(l:file, '\(\s\|"\)*$', '', '')

  " Ensure that the file name has extension
  if l:file !~# '\.tex$'
    let l:file .= '.tex'
  endif

  " Use absolute paths
  if l:file !~# '\v^(\/|[A-Z]:)'
    let l:file = fnamemodify(a:file, ':p:h') . '/' . l:file
  endif

  " Only return filename if it is readable
  return filereadable(l:file) ? l:file : ''
endfunction

" }}}1

" vim: fdm=marker sw=2
