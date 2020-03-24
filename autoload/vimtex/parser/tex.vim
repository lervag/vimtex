" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#tex#parse(file, opts) abort " {{{1
  let l:parser = s:parser.new(a:opts)
  let l:parsed = l:parser.parse(a:file)

  if !l:parser.detailed
    call map(l:parsed, 'v:val[2]')
  endif

  return l:parsed
endfunction

" }}}1

let s:parser = {
      \ 'detailed' : 1,
      \ 'prev_parsed' : [],
      \ 'root' : '',
      \ 'finished' : 0,
      \ 're_input' : g:vimtex#re#tex_input,
      \}

function! s:parser.new(opts) abort dict " {{{1
  let l:parser = extend(deepcopy(self), a:opts)

  if empty(l:parser.root) && exists('b:vimtex.root')
    let l:parser.root = b:vimtex.root
  endif

  unlet l:parser.new
  return l:parser
endfunction

" }}}1
function! s:parser.parse(file) abort dict " {{{1
  if !filereadable(a:file) || index(self.prev_parsed, a:file) >= 0
    return []
  endif
  call add(self.prev_parsed, a:file)

  let l:lnum = 0
  let l:parsed = []
  for l:line in readfile(a:file)
    let l:lnum += 1

    if has_key(self, 're_stop') && l:line =~# self.re_stop
      if get(self, 're_stop_inclusive')
        call add(l:parsed, [a:file, l:lnum, l:line])
      endif
      break
    endif

    call add(l:parsed, [a:file, l:lnum, l:line])

    " Minor optimization: Avoid complex regex on "simple" lines
    if stridx(l:line, '\') < 0 | continue | endif

    if l:line =~# self.re_input
      let l:file = self.input_parser(l:line, a:file)
      call extend(l:parsed, self.parse(l:file))
    endif
  endfor

  return l:parsed
endfunction

" }}}1
function! s:parser.input_parser(line, current_file) abort dict " {{{1
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
