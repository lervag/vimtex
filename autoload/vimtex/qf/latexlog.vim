" vimtex - LaTeX plugin for Vim
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
  let self.config = get(g:, 'vimtex_quickfix_latexlog', {})
  let self.config.default = get(self.config, 'default', 1)
  let self.config.packages = get(self.config, 'packages', {})
  let self.config.packages.default = get(self.config.packages, 'default',
        \ self.config.default)

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
    setlocal errorformat+=%+WOverfull\ %\\%\\hbox%.%#\ at\ line\ %l
    setlocal errorformat+=%+WOverfull\ %\\%\\vbox%.%#\ at\ line\ %l
  endif

  if get(self.config, 'underfull', l:default)
    setlocal errorformat+=%+WUnderfull\ %\\%\\hbox%.%#\ at\ lines\ %l--%*\\d
    setlocal errorformat+=%+WUnderfull\ %\\%\\vbox%.%#\ at\ line\ %l
  endif

  "
  " Define package related warnings
  "
  let l:default = self.config.packages.default
  if get(self.config.packages, 'natbib', l:default)
    setlocal errorformat+=%+WPackage\ natbib\ Warning:\ %m\ on\ input\ line\ %l.
  else
    setlocal errorformat+=%-WPackage\ natbib\ Warning:\ %m\ on\ input\ line\ %l.
  endif

  if get(self.config.packages, 'biblatex', l:default)
    setlocal errorformat+=%+WPackage\ biblatex\ Warning:\ %m
    setlocal errorformat+=%-C(biblatex)%.%#in\ t%.%#
    setlocal errorformat+=%-C(biblatex)%.%#Please\ v%.%#
    setlocal errorformat+=%-C(biblatex)%.%#LaTeX\ a%.%#
    setlocal errorformat+=%-C(biblatex)%m
  else
    setlocal errorformat+=%-WPackage\ biblatex\ Warning:\ %m
  endif

  if get(self.config.packages, 'babel', l:default)
    setlocal errorformat+=%+WPackage\ babel\ Warning:\ %m
    setlocal errorformat+=%-Z(babel)%.%#input\ line\ %l.
    setlocal errorformat+=%-C(babel)%m
  else
    setlocal errorformat+=%-WPackage\ babel\ Warning:\ %m
  endif

  if get(self.config.packages, 'hyperref', l:default)
    setlocal errorformat+=%+WPackage\ hyperref\ Warning:\ %m
    setlocal errorformat+=%-C(hyperref)%m\ on\ input\ line\ %l.
    setlocal errorformat+=%-C(hyperref)%m
  else
    setlocal errorformat+=%-WPackage\ hyperref\ Warning:\ %m
  endif

  if get(self.config.packages, 'scrreprt', l:default)
    setlocal errorformat+=%+WPackage\ scrreprt\ Warning:\ %m
    setlocal errorformat+=%-C(scrreprt)%m
  else
    setlocal errorformat+=%-WPackage\ scrreprt\ Warning:\ %m
  endif

  if get(self.config.packages, 'fixltx2e', l:default)
    setlocal errorformat+=%+WPackage\ fixltx2e\ Warning:\ %m
    setlocal errorformat+=%-C(fixltx2e)%m
  else
    setlocal errorformat+=%-WPackage\ fixltx2e\ Warning:\ %m
  endif

  if get(self.config.packages, 'titlesec', l:default)
    setlocal errorformat+=%+WPackage\ titlesec\ Warning:\ %m
    setlocal errorformat+=%-C(titlesec)%m
  else
    setlocal errorformat+=%-WPackage\ titlesec\ Warning:\ %m
  endif

  if get(self.config.packages, 'general', l:default)
    setlocal errorformat+=%+WPackage\ %.%#\ Warning:\ %m\ on\ input\ line\ %l.
    setlocal errorformat+=%+WPackage\ %.%#\ Warning:\ %m
    setlocal errorformat+=%-Z(%.%#)\ %m\ on\ input\ line\ %l.
    setlocal errorformat+=%-C(%.%#)\ %m
  endif

  " Ignore unmatched lines
  setlocal errorformat+=%-G%.%#
endfunction

" }}}1
function! s:qf.addqflist(tex, log) abort dict "{{{1
  if empty(a:log) || !filereadable(a:log)
    throw 'Vimtex: No log file found'
  endif

  let self.errorformat_saved = &l:errorformat
  call self.set_errorformat()
  execute 'caddfile' fnameescape(a:log)
  let &l:errorformat = self.errorformat_saved

  " Apply some post processing of the quickfix list
  let self.main = a:tex
  let self.root = b:vimtex.root
  call self.fix_paths()
endfunction

" }}}1
function! s:qf.pprint_items() abort dict " {{{1
  return [[ 'config', self.config ]]
endfunction

" }}}1
function! s:qf.fix_paths() abort dict " {{{1
  let l:qflist = getqflist()

  for l:qf in l:qflist
    " For errors and warnings that don't supply a file, the basename of the
    " main file is used. However, if the working directory is not the root of
    " the LaTeX project, than this results in bufnr = 0.
    if l:qf.bufnr == 0
      let l:qf.bufnr = bufnr(self.main)
      continue
    endif

    " The buffer names of all file:line type errors are relative to the root of
    " the main LaTeX file.
    let l:file = fnamemodify(
          \ simplify(self.root . '/' . bufname(l:qf.bufnr)), ':.')
    if !filereadable(l:file) | continue | endif

    if !bufexists(l:file)
      execute 'badd' l:file
    endif

    let l:qf.filename = l:file
    let l:qf.bufnr = bufnr(l:file)
  endfor

  call setqflist(l:qflist, 'r')
endfunction

" }}}1
