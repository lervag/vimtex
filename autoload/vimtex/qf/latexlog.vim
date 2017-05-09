" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#qf#latexlog#new() " {{{1
  return deepcopy(s:qf)
endfunction

" }}}1


let s:qf = {
      \ 'name' : 'LaTeX logfile',
      \}

function! s:qf.init(state) abort dict "{{{1
  let self.config = get(g:, 'vimtex_quickfix_latexlog', {})
  let self.config.default = get(self.config, 'default', 1)
  let self.config.packages = get(self.config, 'packages', {})
  let self.config.packages.default = get(self.config.packages, 'default', 1)
  let self.config.fix_paths = get(self.config, 'fix_paths', 1)

  call self.set_errorformat()
  unlet self.set_errorformat
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
  setlocal errorformat+=%E!\ %m

  " More info for undefined control sequences
  setlocal errorformat+=%Z<argument>\ %m

  " More info for some errors
  setlocal errorformat+=%Cl.%l\ %m

  "
  " Define general warnings
  "
  let l:default = self.config.default
  if get(self.config, 'font', l:default)
    setlocal errorformat+=%+WLaTeX\ Font\ Warning:\ %.%#line\ %l%.%#
    setlocal errorformat+=%-CLaTeX\ Font\ Warning:\ %m
    setlocal errorformat+=%-C(Font)%m
  else
    setlocal errorformat+=%-WLaTeX\ Font\ Warning:\ %m
  endif

  if !get(self.config, 'references', l:default)
    setlocal errorformat+=%-WLaTeX\ %.%#Warning:\ %.%#eference%.%#undefined%.%#line\ %l%.%#
    setlocal errorformat+=%-WLaTeX\ %.%#Warning:\ %.%#undefined\ references.
  endif

  if get(self.config, 'general', l:default)
    setlocal errorformat+=%+WLaTeX\ %.%#Warning:\ %.%#line\ %l%.%#
    setlocal errorformat+=%+WLaTeX\ %.%#Warning:\ %m
  endif

  if get(self.config, 'overfull', l:default)
    setlocal errorformat+=%+WOverfull\ %\\%\\hbox%.%#\ at\ lines\ %l--%*\\d
  endif

  if get(self.config, 'underfull', l:default)
    setlocal errorformat+=%+WUnderfull\ %\\%\\hbox%.%#\ at\ lines\ %l--%*\\d
  endif

  "
  " Define package related warnings
  "
  let l:default = self.config.packages.default
  if get(self.config.packages, 'natbib', l:default)
    setlocal errorformat+=%+WPackage\ natbib\ Warning:\ %m\ on\ input\ line\ %l%.
  endif

  if get(self.config.packages, 'biblatex', l:default)
    setlocal errorformat+=%+WPackage\ biblatex\ Warning:\ %m
    setlocal errorformat+=%-C(biblatex)%.%#in\ t%.%#
    setlocal errorformat+=%-C(biblatex)%.%#Please\ v%.%#
    setlocal errorformat+=%-C(biblatex)%.%#LaTeX\ a%.%#
    setlocal errorformat+=%-C(biblatex)%m
  endif

  if get(self.config.packages, 'babel', l:default)
    setlocal errorformat+=%-Z(babel)%.%#input\ line\ %l.
    setlocal errorformat+=%-C(babel)%m
  endif

  if get(self.config.packages, 'hyperref', l:default)
    setlocal errorformat+=%+WPackage\ hyperref\ Warning:\ %m
    setlocal errorformat+=%-C(hyperref)%.%#on\ input\ line\ %l.
    setlocal errorformat+=%-C(hyperref)%m
  endif

  if get(self.config.packages, 'scrreprt', l:default)
    setlocal errorformat+=%+WPackage\ scrreprt\ Warning:\ %m
    setlocal errorformat+=%-C(scrreprt)%m
  endif

  if get(self.config.packages, 'fixltx2e', l:default)
    setlocal errorformat+=%+WPackage\ fixltx2e\ Warning:\ %m
    setlocal errorformat+=%-C(fixltx2e)%m
  endif

  if get(self.config.packages, 'titlesec', l:default)
    setlocal errorformat+=%+WPackage\ titlesec\ Warning:\ %m
    setlocal errorformat+=%-C(titlesec)%m
  endif

  " Ignore unmatched lines
  setlocal errorformat+=%-G%.%#
endfunction

" }}}1
function! s:qf.setqflist(base, jump) abort dict "{{{1
  if empty(a:base)
    let l:tex = b:vimtex.tex
    let l:log = b:vimtex.log()
  else
    let l:tex = a:base
    let l:log = fnamemodify(a:base, ':r') . '.log'
  endif

  if empty(l:log)
    call setqflist([])
    throw 'Vimtex: No log file found'
  endif

  "
  " We use a temporary autocmd to fix some paths in the quickfix entry
  "
  if self.config.fix_paths
    let s:main = l:tex
    let s:title = 'Vimtex errors (' . self.name . ')'
    augroup vimtex_qf_tmp
      autocmd!
      autocmd QuickFixCmdPost [cl]*file call s:fix_paths()
    augroup END
  endif

  execute (a:jump ? 'cfile' : 'cgetfile') fnameescape(l:log)

  if self.config.fix_paths
    autocmd! vimtex_qf_tmp
  endif
endfunction

" }}}1
function! s:qf.pprint_items() abort dict " {{{1
  return [[ 'config', self.config ]]
endfunction

" }}}1

function! s:log_contains_error(logfile) " {{{1
  let lines = readfile(a:logfile)
  let lines = filter(lines, 'v:val =~# ''^.*:\d\+: ''')
  let lines = vimtex#util#uniq(map(lines, 'matchstr(v:val, ''^.*\ze:\d\+:'')'))
  let lines = map(lines, 'fnamemodify(v:val, '':p'')')
  let lines = filter(lines, 'filereadable(v:val)')
  return len(lines) > 0
endfunction

" }}}1

function! s:fix_paths() abort " {{{1
  let w:quickfix_title = s:title

  let l:qflist = getqflist()
  for l:qf in l:qflist
    " For errors and warnings that don't supply a file, the basename of the
    " main file is used. However, if the working directory is not the root of
    " the LaTeX project, than this results in bufnr = 0.
    if l:qf.bufnr == 0
      let l:qf.bufnr = bufnr(s:main)
      continue
    endif

    " The buffer names of all file:line type errors are relative to the root of
    " the main LaTeX file.
    let l:file = fnamemodify(
          \ simplify(b:vimtex.root . '/' . bufname(l:qf.bufnr)), ':.')
    if !filereadable(l:file) | continue | endif
    if !bufexists(l:file)
      execute 'badd' l:file
    endif
    let l:qf.bufnr = bufnr(l:file)
  endfor

  " Set title if setqflist supports it
  try
    call setqflist(l:qflist, 'r', {'title': s:title})
  catch /E118/
    call setqflist(l:qflist, 'r')
  endtry
endfunction

" }}}1

" vim: fdm=marker sw=2
