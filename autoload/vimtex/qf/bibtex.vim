" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#qf#bibtex#addqflist() abort " {{{1
  if !get(g:vimtex_quickfix_bibtex, 'enabled') | return | endif

  call s:bibtex.init()

  try
    call s:bibtex.prepare()
    call s:bibtex.addqflist()
    call s:bibtex.restore()
  catch /BibTeX Aborted/
  endtry
endfunction

" }}}1

let s:bibtex = {
      \ 'file' : '',
      \ 'types' : [],
      \ 'db_files' : [],
      \}
function! s:bibtex.init() abort " {{{1
  let self.types = map(
        \ filter(items(s:), 'v:val[0] =~# ''^type_'''),
        \ 'v:val[1]')
  let self.db_files = []
endfunction

" }}}1
function! s:bibtex.prepare() abort " {{{1
  let self.file = b:vimtex.ext('blg')
  if empty(self.file) | throw 'BibTeX Aborted' | endif

  augroup vimtex_qf_tmp
    autocmd!
    autocmd QuickFixCmdPost [cl]*file call s:bibtex.fix_paths()
  augroup END

  let self.errorformat_saved = &l:errorformat

  setlocal errorformat=%+E%.%#---line\ %l\ of\ file\ %f
  setlocal errorformat+=%+WWarning--empty\ %.%#\ in\ %.%m
  setlocal errorformat+=%+WWarning--entry\ type\ for%m
  setlocal errorformat+=%-C--line\ %l\ of\ file\ %f
  setlocal errorformat+=%-G%.%#
endfunction

" }}}1
function! s:bibtex.addqflist() abort " {{{1
  execute 'caddfile' fnameescape(self.file)
endfunction

" }}}1
function! s:bibtex.restore() abort " {{{1
  let &l:errorformat = self.errorformat_saved
  autocmd! vimtex_qf_tmp
endfunction

" }}}1
function! s:bibtex.fix_paths() abort " {{{1
  let l:qflist = getqflist()

  for l:qf in l:qflist
    for l:type in self.types
      if l:type.fix(self, l:qf) | break | endif
    endfor
  endfor

  call setqflist(l:qflist, 'r')
endfunction

" }}}1
function! s:bibtex.get_db_files() abort " {{{1
  if empty(self.db_files)
    let self.db_files = map(
          \ filter(readfile(self.file), 'v:val =~# ''Database file #\d:'''),
          \ 'matchstr(v:val, '': \zs.*'')')
  endif

  return self.db_files
endfunction

" }}}1
function! s:bibtex.get_key_loc(key) abort " {{{1
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
      \ 're' : '\vWarning--empty (\w+) in (\S*)',
      \}
function! s:type_empty.fix(ctx, entry) abort " {{{1
  let l:matches = matchlist(a:entry.text, self.re)
  if empty(l:matches) | return 0 | endif

  let l:type = l:matches[1]
  let l:key = l:matches[2]

  unlet a:entry.bufnr
  let a:entry.text = printf('Missing "%s" in "%s"', l:type, l:key)

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

" vim: fdm=marker sw=2
