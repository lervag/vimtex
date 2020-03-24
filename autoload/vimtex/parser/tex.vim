" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#tex#parse(file, opts) abort " {{{1
  let l:opts = extend({
          \ 'preamble' : 0,
          \ 'preamble_inclusive' : 0,
          \ 'root' : exists('b:vimtex.root') ? b:vimtex.root : '',
          \ 're_input' : g:vimtex#re#tex_input,
          \}, a:opts)

  let l:parsed = s:parse_recurse(a:file, l:opts, [])

  if !get(a:opts, 'detailed', 1)
    call map(l:parsed, 'v:val[2]')
  endif

  return l:parsed
endfunction

" }}}1

function! s:parse_recurse(file, opts, parsed_files) abort " {{{1
  if !filereadable(a:file) || index(a:parsed_files, a:file) >= 0
    return []
  endif
  call add(a:parsed_files, a:file)

  let l:lnum = 0
  let l:parsed = []
  for l:line in readfile(a:file)
    let l:lnum += 1

    if a:opts.preamble && l:line =~# '\\begin\s*{document}'
      if a:opts.preamble_inclusive
        call add(l:parsed, [a:file, l:lnum, l:line])
      endif
      break
    endif

    call add(l:parsed, [a:file, l:lnum, l:line])

    " Minor optimization: Avoid complex regex on "simple" lines
    if stridx(l:line, '\') < 0 | continue | endif

    if l:line =~# a:opts.re_input
      let l:file = s:input_parser(l:line, a:file, a:opts.root)
      call extend(l:parsed, s:parse_recurse(l:file, a:opts, a:parsed_files))
    endif
  endfor

  return l:parsed
endfunction

" }}}1


function! s:input_parser(line, current_file, root) abort " {{{1
  " Handle \space commands
  let l:file = substitute(a:line, '\\space\s*', ' ', 'g')

  " Handle import package commands
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
