" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#qf#latexlog#new() abort " {{{1
  return deepcopy(s:qf)
endfunction

" }}}1


let s:qf = {
      \ 'name' : 'LaTeX logfile',
      \}

function! s:qf.init(state) abort dict "{{{1
  let self.types = map(
        \ filter(items(s:), 'v:val[0] =~# ''^type_'''),
        \ 'v:val[1]')
endfunction

" }}}1
function! s:qf.set_errorformat() abort dict "{{{1
  "
  " Note: The errorformat assumes we're using the -file-line-error with
  "       [pdf]latex. For more info, see |errorformat-LaTeX|.
  "

  " Push file to file stack
  setlocal errorformat=%-P**%f
  setlocal errorformat+=%-P**\"%f\"

  " Match errors
  setlocal errorformat+=%E!\ LaTeX\ %trror:\ %m
  setlocal errorformat+=%E%f:%l:\ %m
  setlocal errorformat+=%+ERunaway\ argument?
  setlocal errorformat+=%+C{%m
  setlocal errorformat+=%C!\ %m

  " More info for undefined control sequences
  setlocal errorformat+=%Z<argument>\ %m

  " More info for some errors
  setlocal errorformat+=%Cl.%l\ %m

  "
  " Define general warnings
  "
  setlocal errorformat+=%+WLaTeX\ Font\ Warning:\ %.%#line\ %l%.%#
  setlocal errorformat+=%-CLaTeX\ Font\ Warning:\ %m
  setlocal errorformat+=%-C(Font)%m

  setlocal errorformat+=%+WLaTeX\ %.%#Warning:\ %.%#line\ %l%.%#
  setlocal errorformat+=%+WLaTeX\ %.%#Warning:\ %m

  setlocal errorformat+=%+WOverfull\ %\\%\\hbox%.%#\ at\ lines\ %l--%*\\d
  setlocal errorformat+=%+WOverfull\ %\\%\\hbox%.%#\ at\ line\ %l
  setlocal errorformat+=%+WOverfull\ %\\%\\vbox%.%#\ at\ line\ %l

  setlocal errorformat+=%+WUnderfull\ %\\%\\hbox%.%#\ at\ lines\ %l--%*\\d
  setlocal errorformat+=%+WUnderfull\ %\\%\\vbox%.%#\ at\ line\ %l

  "
  " Define package related warnings
  "
  setlocal errorformat+=%+WPackage\ natbib\ Warning:\ %m\ on\ input\ line\ %l.

  setlocal errorformat+=%+WPackage\ biblatex\ Warning:\ %m
  setlocal errorformat+=%-C(biblatex)%.%#in\ t%.%#
  setlocal errorformat+=%-C(biblatex)%.%#Please\ v%.%#
  setlocal errorformat+=%-C(biblatex)%.%#LaTeX\ a%.%#
  setlocal errorformat+=%-C(biblatex)%m

  setlocal errorformat+=%+WPackage\ babel\ Warning:\ %m
  setlocal errorformat+=%-Z(babel)%.%#input\ line\ %l.
  setlocal errorformat+=%-C(babel)%m

  setlocal errorformat+=%+WPackage\ hyperref\ Warning:\ %m
  setlocal errorformat+=%-C(hyperref)%m\ on\ input\ line\ %l.
  setlocal errorformat+=%-C(hyperref)%m

  setlocal errorformat+=%+WPackage\ scrreprt\ Warning:\ %m
  setlocal errorformat+=%-C(scrreprt)%m

  setlocal errorformat+=%+WPackage\ fixltx2e\ Warning:\ %m
  setlocal errorformat+=%-C(fixltx2e)%m

  setlocal errorformat+=%+WPackage\ titlesec\ Warning:\ %m
  setlocal errorformat+=%-C(titlesec)%m

  setlocal errorformat+=%+WPackage\ %.%#\ Warning:\ %m\ on\ input\ line\ %l.
  setlocal errorformat+=%+WPackage\ %.%#\ Warning:\ %m
  setlocal errorformat+=%-Z(%.%#)\ %m\ on\ input\ line\ %l.
  setlocal errorformat+=%-C(%.%#)\ %m

  " Ignore unmatched lines
  setlocal errorformat+=%-G%.%#
endfunction

" }}}1
function! s:qf.addqflist(tex, log) abort dict "{{{1
  if empty(a:log) || !filereadable(a:log)
    throw 'VimTeX: No log file found'
  endif

  call vimtex#qf#u#caddfile(self, fnameescape(a:log))

  " Apply some post processing of the quickfix list
  let self.main = a:tex
  let self.root = b:vimtex.root
  call self.fix_paths(a:log)
endfunction

" }}}1
function! s:qf.fix_paths(log) abort dict " {{{1
  let l:qflist = getqflist()
  let l:lines = readfile(a:log)
  let l:hbox_cache = {'index': {}, 'paths': {}}

  for l:qf in l:qflist
    " Handle missing buffer/filename: Fallback to the main file (this is always
    " correct in single-file projects and is thus a good fallback).
    if l:qf.bufnr == 0
      let l:bufnr_main = bufnr(self.main)
      if bufnr(self.main) < 0
        execute 'badd' self.main
        let l:bufnr_main = bufnr(self.main)
      endif
      let l:qf.bufnr = l:bufnr_main
    endif

    " Try to parse the filename from logfile for certain errors
    if s:fix_paths_hbox_warning(l:qf, l:lines, self.root, l:hbox_cache)
      continue
    endif

    " Check and possibly fix invalid file from file:line type entries
    call s:fix_paths_invalid_bufname(l:qf, self.root)
  endfor

  call setqflist(l:qflist, 'r')
endfunction

" }}}1

function! s:fix_paths_hbox_warning(qf, log, root, cache) abort " {{{1
  if a:qf.text !~# 'Underfull\|Overfull' | return v:false | endif

  let l:index = match(a:log, '\V' . escape(a:qf.text, '\'))
  if l:index < 0 | return v:false | endif

  " Check index cache first
  if has_key(a:cache.index, l:index)
    if has_key(a:cache.index[l:index], 'bufnr')
      let a:qf.bufnr = a:cache.index[l:index].bufnr
    else
      let a:qf.bufnr = 0
      let a:qf.filename = a:cache.index[l:index].filename
    endif
    return v:true
  endif

  " Search for a line above the Overflow/Underflow message that specifies the
  " correct source filename
  let l:file = ''
  let l:level = 1
  for l:lnum in range(l:index - 1, 1, -1)
    " Check line number cache
    if has_key(a:cache.paths, l:lnum)
      let l:file = a:cache.paths[l:lnum]
      let a:cache.paths[l:index] = l:file
      break
    endif

    let l:level += vimtex#util#count(a:log[l:lnum], ')')
    let l:level -= vimtex#util#count(a:log[l:lnum], '(')
    if l:lnum < l:index - 1 && l:level > 0 | continue | endif

    let l:file = matchstr(a:log[l:lnum], '\v\(\zs\f+\ze\)?\s*%(\[\d+]?)?$')
    if !empty(l:file)
      " Do some simple parsing and cleanup of the filename
      if !vimtex#paths#is_abs(l:file)
        let l:file = simplify(a:root . '/' . l:file)
      endif

      " Store in line number cache
      let a:cache.paths[l:index] = l:file
      break
    endif
  endfor

  if empty(l:file) || !filereadable(l:file) | return v:false | endif

  let l:bufnr = bufnr(l:file)
  if l:bufnr > 0
    let a:qf.bufnr = bufnr(l:file)
    let a:cache.index[l:index] = {'bufnr': a:qf.bufnr}
  else
    let a:qf.bufnr = 0
    let a:qf.filename = fnamemodify(l:file, ':.')
    let a:cache.index[l:index] = {'filename': a:qf.filename}
  endif

  return v:true
endfunction

" }}}1
function! s:fix_paths_invalid_bufname(qf, root) abort " {{{1
  " First check if the entry bufnr is already valid
  let l:file = getbufinfo(a:qf.bufnr)[0].name
  if filereadable(l:file) | return | endif

  " The file names of all file:line type entries in the log output are listed
  " relative to the root of the main LaTeX file. The quickfix mechanism adds
  " the buffer with the file string. Thus, if the current buffer is not
  " correct, we can fix by prepending the root to the filename.
  let l:file = fnamemodify(
        \ simplify(a:root . '/' . bufname(a:qf.bufnr)), ':.')
  if !filereadable(l:file) | return | endif

  let l:bufnr = bufnr(l:file)
  if l:bufnr > 0
    let a:qf.bufnr = bufnr(l:file)
  else
    let a:qf.bufnr = 0
    let a:qf.filename = l:file
  endif
endfunction

" }}}1
