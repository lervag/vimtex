" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#auxiliary#parse(file) abort " {{{1
  return s:parse_recurse(a:file, [])
endfunction

" }}}1

function! s:parse_recurse(file, parsed) abort " {{{1
  if !filereadable(a:file) || index(a:parsed, a:file) >= 0
    return []
  endif
  call add(a:parsed, a:file)

  let l:lines = []
  for l:line in readfile(a:file)
    call add(l:lines, l:line)

    if l:line =~# '\\@input{'
      let l:file = s:input_line_parser(l:line, a:file)
      call extend(l:lines, s:parse_recurse(l:file, a:parsed))
    endif
  endfor

  return l:lines
endfunction

" }}}1

function! s:input_line_parser(line, file) abort " {{{1
  let l:file = matchstr(a:line, '\\@input{\zs[^}]\+\ze}')

  " Remove extension to simplify the parsing (e.g. for "my file name".aux)
  let l:file = substitute(l:file, '\.aux', '', '')

  " Trim whitespaces and quotes from beginning/end of string, append extension
  let l:file = substitute(l:file, '^\(\s\|"\)*', '', '')
  let l:file = substitute(l:file, '\(\s\|"\)*$', '', '')
  let l:file .= '.aux'

  " Use absolute paths
  if l:file !~# '\v^(\/|[A-Z]:)'
    let l:file = fnamemodify(a:file, ':p:h') . '/' . l:file
  endif

  " Only return filename if it is readable
  return filereadable(l:file) ? l:file : ''
endfunction

" }}}1
