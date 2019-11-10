" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#general#parse(file, opts) abort " {{{1
  let l:parser = s:parser.new(a:opts)
  return l:parser.parse(a:file)
endfunction

" }}}1

let s:parser = {
      \ 'detailed' : 1,
      \ 'prev_parsed' : [],
      \ 'root' : '',
      \ 'finished' : 0,
      \ 'type' : 'tex',
      \ 'input_re_tex' : g:vimtex#re#tex_input,
      \ 'input_re_aux' : '\\@input{',
      \}

function! s:parser.new(opts) abort dict " {{{1
  let l:parser = extend(deepcopy(self), a:opts)

  if empty(l:parser.root) && exists('b:vimtex.root')
    let l:parser.root = b:vimtex.root
  endif

  let l:parser.input_re = get(l:parser, 'input_re',
        \ get(l:parser, 'input_re_' . l:parser.type))
  let l:parser.input_parser = get(l:parser, 'input_parser',
        \ get(l:parser, 'input_line_parser_' . l:parser.type))

  unlet l:parser.new
  return l:parser
endfunction

" }}}1
function! s:parser.parse(file) abort dict " {{{1
  if !filereadable(a:file) || index(self.prev_parsed, a:file) >= 0
    return []
  endif
  call add(self.prev_parsed, a:file)

  let l:parsed = []
  let l:lnum = 0
  for l:line in readfile(a:file)
    let l:lnum += 1

    if self.finished
      break
    endif

    if has_key(self, 're_stop') && l:line =~# self.re_stop
      let self.finished = 1
      break
    endif

    if self.detailed
      call add(l:parsed, [a:file, l:lnum, l:line])
    else
      call add(l:parsed, l:line)
    endif

    if l:line =~# self.input_re
      let l:file = self.input_parser(l:line, a:file, self.input_re)
      call extend(l:parsed, self.parse(l:file))
      continue
    endif
  endfor

  return l:parsed
endfunction

" }}}1

"
" Input line parsers
"
function! s:parser.input_line_parser_tex(line, current_file, re) abort dict " {{{1
  " Handle \space commands
  let l:file = substitute(a:line, '\\space\s*', ' ', 'g')

  " Handle import package commands
  if l:file =~# g:vimtex#re#tex_input_import
    let l:root = l:file =~# '\\sub'
          \ ? fnamemodify(a:current_file, ':p:h')
          \ : self.root

    let l:candidate = s:input_to_filename(
          \ substitute(copy(l:file), '}\s*{', '', 'g'), l:root)
    if !empty(l:candidate)
      return l:candidate
    else
      return s:input_to_filename(
          \ substitute(copy(l:file), '{.{-}}', '', ''), l:root)
    endif
  else
    return s:input_to_filename(l:file, self.root)
  endif
endfunction

" }}}1
function! s:parser.input_line_parser_aux(line, file, re) abort dict " {{{1
  let l:file = matchstr(a:line, a:re . '\zs[^}]\+\ze}')

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

"
" Utility functions
"
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
