" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#qf#bibtex#addqflist(blg) abort " {{{1
  if get(g:vimtex_quickfix_blgparser, 'disable') | return | endif

  try
    call s:qf.addqflist(a:blg)
  catch /BibTeX Aborted/
  endtry
endfunction

" }}}1


let s:qf = {
      \ 'file' : '',
      \ 'types' : [],
      \ 'db_files' : [],
      \}

function! s:qf.set_errorformat() abort dict "{{{1
  setlocal errorformat=%+E%.%#---line\ %l\ of\ file\ %f
  setlocal errorformat+=%+EI\ found\ %.%#---while\ reading\ file\ %f
  setlocal errorformat+=%+WWarning--empty\ %.%#\ in\ %.%m
  setlocal errorformat+=%+WWarning--entry\ type\ for%m
  setlocal errorformat+=%-C--line\ %l\ of\ file\ %f
  setlocal errorformat+=%-G%.%#
endfunction

" }}}1
function! s:qf.addqflist(blg) abort " {{{1
  let self.file = a:blg
  if empty(self.file) || !filereadable(self.file) | throw 'BibTeX Aborted' | endif

  let self.types = map(
        \ filter(items(s:), 'v:val[0] =~# ''^type_'''),
        \ 'v:val[1]')
  let self.db_files = []

  call vimtex#qf#u#caddfile(self, fnameescape(self.file))

  call self.fix_paths()
endfunction

" }}}1
function! s:qf.fix_paths() abort " {{{1
  let l:qflist = getqflist()
  try
    let l:title = getqflist({'title': 1})
  catch /E118/
    let l:title = 'VimTeX errors'
  endtry

  for l:qf in l:qflist
    for l:type in self.types
      if l:type.fix(self, l:qf) | break | endif
    endfor
  endfor

  call setqflist(l:qflist, 'r')

  " Set title if supported
  try
    call setqflist([], 'r', l:title)
  catch
  endtry
endfunction

" }}}1
function! s:qf.get_db_files() abort " {{{1
  if empty(self.db_files)
    let l:build_dir = fnamemodify(b:vimtex.ext('log'), ':.:h') . '/'
    for l:file in map(
          \ filter(readfile(self.file), 'v:val =~# ''Database file #\d:'''),
          \ 'matchstr(v:val, '': \zs.*'')')
      if filereadable(l:file)
        call add(self.db_files, l:file)
      elseif filereadable(l:build_dir . l:file)
        call add(self.db_files, l:build_dir . l:file)
      endif
    endfor
  endif

  return self.db_files
endfunction

" }}}1
function! s:qf.get_key_loc(key) abort " {{{1
  for l:file in self.get_db_files()
    let l:lines = readfile(l:file)
    let l:lnum = 0
    for l:line in l:lines
      let l:lnum += 1
      if l:line =~# '^\s*@\w*{\s*\V' . a:key
        return [l:file, l:lnum]
      endif
    endfor
  endfor

  return []
endfunction

" }}}1

"
" Parsers for the various warning types
"

let s:type_syn_error = {}
function! s:type_syn_error.fix(ctx, entry) abort " {{{1
  if a:entry.text =~# '---line \d\+ of file'
    let a:entry.text = split(a:entry.text, '---')[0]
    return 1
  endif
endfunction

" }}}1

let s:type_empty = {
      \ 're' : '\vWarning--empty (.*) in ([^ ;]*)(.*)',
      \}
function! s:type_empty.fix(ctx, entry) abort " {{{1
  let l:matches = matchlist(a:entry.text, self.re)
  if empty(l:matches) | return 0 | endif

  let l:type = l:matches[1]
  let l:key = l:matches[2]
  let l:more = matchstr(l:matches[3], '; \zs.*')

  unlet a:entry.bufnr
  let a:entry.text = empty(l:more)
        \ ? printf('Missing "%s" in "%s"', l:type, l:key)
        \ : printf('Missing "%s" in "%s" (%s)', l:type, l:key, l:more)

  let l:loc = a:ctx.get_key_loc(l:key)
  if !empty(l:loc)
    let a:entry.filename = l:loc[0]
    let a:entry.lnum = l:loc[1]
  endif

  return 1
endfunction

" }}}1

let s:type_style_file_defined = {
      \ 're' : '\vWarning--entry type for "(\w+)"',
      \}
function! s:type_style_file_defined.fix(ctx, entry) abort " {{{1
  let l:matches = matchlist(a:entry.text, self.re)
  if empty(l:matches) | return 0 | endif

  let l:key = l:matches[1]

  unlet a:entry.bufnr
  let a:entry.text = 'Entry type for "' . l:key . '" isn''t style-file defined'

  let l:loc = a:ctx.get_key_loc(l:key)
  if !empty(l:loc)
    let a:entry.filename = l:loc[0]
    let a:entry.lnum = l:loc[1]
  endif

  return 1
endfunction

" }}}1

let s:type_no_bibstyle = {}
function! s:type_no_bibstyle.fix(ctx, entry) abort " {{{1
  if a:entry.text =~# 'I found no \\bibstyle'
    let a:entry.text = 'BibTeX found no \bibstyle command (missing \bibliographystyle?)'
    let a:entry.filename = b:vimtex.tex
    unlet a:entry.bufnr
    for [l:file, l:lnum, l:line] in vimtex#parser#tex(b:vimtex.tex)
      if l:line =~# g:vimtex#re#not_comment . '\\bibliography'
        let a:entry.lnum = l:lnum
        let a:entry.filename = l:file
        break
      endif
    endfor
    return 1
  endif
endfunction

" }}}1
