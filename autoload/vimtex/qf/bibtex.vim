" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#qf#bibtex#addqflist() " {{{1
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

  " Set errorformat for BibTeX errors
  setlocal errorformat=%+WWarning--empty\ %.%#\ in\ %.%m
  " setlocal errorformat+=%.%#---line\ %l\ of\ file\ %f
  " setlocal errorformat+=Sorry---you've\ exceeded\ BibTeX's\ %.%#
  " setlocal errorformat+=%.%#---this\ can't\ happen
  " setlocal errorformat+=I\ found\ %.%#---while\ reading\ file\ %f
  " setlocal errorformat+=refers\ to\ entry\ "%.%#
  " setlocal errorformat+=%tarning--%m
  " setlocal errorformat+=Aborted\ at\ line\ %l\ of\ file\ %f
  " setlocal errorformat+=%.%#\ WARN\ -\ %.%#
  " setlocal errorformat+=%.%#\ ERROR\ -\ %.%#
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
function! s:bibtex.get_db_files() " {{{1
  if empty(self.db_files)
    let self.db_files = map(
          \ filter(readfile(self.file), 'v:val =~# ''Database file #\d:'''),
          \ 'matchstr(v:val, '': \zs.*'')')
  endif

  return self.db_files
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

"
" Parsers for the various warning types
"
let s:type_empty = {
      \ 're' : '\vWarning--empty (\w+) in (\S*)',
      \}
function! s:type_empty.fix(ctx, entry) " {{{1
  let l:matches = matchlist(a:entry.text, self.re)
  if empty(l:matches) | return 0 | endif

  let l:type = l:matches[1]
  let l:key = l:matches[2]

  unlet a:entry.bufnr
  let a:entry.text = printf('BibTeX Warning: Missing "%s" in "%s"', l:type, l:key)

  for l:file in a:ctx.get_db_files()
    let l:lines = readfile(l:file)
    let l:lnum = 0
    for l:line in l:lines
      let l:lnum += 1
      if l:line =~# '^\s*@\w*{\s*\V' . l:key
        let a:entry.filename = l:file
        let a:entry.lnum = l:lnum
        return 1
      endif
    endfor
  endfor

  return 1
endfunction

" }}}1

" vim: fdm=marker sw=2
