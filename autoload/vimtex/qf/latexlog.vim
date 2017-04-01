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

function! s:qf.init() abort dict "{{{1
  let g:current_compiler = 'latexlog'

  let self.config = get(g:, 'vimtex_quickfix_latexlog', {})
  let self.config.default = get(self.config, 'default', 1)
  let self.config.packages = get(self.config, 'packages', {})
  let self.config.packages.default = get(self.config.packages, 'default', 1)
  let self.config.fix_paths = get(self.config, 'fix_paths', 1)

  CompilerSet makeprg=""

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
  CompilerSet errorformat=%-P**%f
  CompilerSet errorformat+=%-P**\"%f\"

  " Match errors
  CompilerSet errorformat+=%E!\ LaTeX\ %trror:\ %m
  CompilerSet errorformat+=%E%f:%l:\ %m
  CompilerSet errorformat+=%E!\ %m

  " More info for undefined control sequences
  CompilerSet errorformat+=%Z<argument>\ %m

  " More info for some errors
  CompilerSet errorformat+=%Cl.%l\ %m

  "
  " Define general warnings
  "
  let l:default = self.config.default
  if get(self.config, 'font', l:default)
    CompilerSet errorformat+=%+WLaTeX\ Font\ Warning:\ %.%#line\ %l%.%#
    CompilerSet errorformat+=%-CLaTeX\ Font\ Warning:\ %m
    CompilerSet errorformat+=%-C(Font)%m
  else
    CompilerSet errorformat+=%-WLaTeX\ Font\ Warning:\ %m
  endif

  if get(self.config, 'general', l:default)
    CompilerSet errorformat+=%+WLaTeX\ %.%#Warning:\ %.%#line\ %l%.%#
    CompilerSet errorformat+=%+WLaTeX\ %.%#Warning:\ %m
  endif

  if get(self.config, 'overfull', l:default)
    CompilerSet errorformat+=%+WOverfull\ %\\%\\hbox%.%#\ at\ lines\ %l--%*\\d
  endif

  if get(self.config, 'underfull', l:default)
    CompilerSet errorformat+=%+WUnderfull\ %\\%\\hbox%.%#\ at\ lines\ %l--%*\\d
  endif

  "
  " Define package related warnings
  "
  let l:default = self.config.packages.default
  if get(self.config.packages, 'natbib', l:default)
    CompilerSet errorformat+=%+WPackage\ natbib\ Warning:\ %m\ on\ input\ line\ %l%.
  endif

  if get(self.config.packages, 'biblatex', l:default)
    CompilerSet errorformat+=%+WPackage\ biblatex\ Warning:\ %m
    CompilerSet errorformat+=%-C(biblatex)%.%#in\ t%.%#
    CompilerSet errorformat+=%-C(biblatex)%.%#Please\ v%.%#
    CompilerSet errorformat+=%-C(biblatex)%.%#LaTeX\ a%.%#
    CompilerSet errorformat+=%-C(biblatex)%m
  endif

  if get(self.config.packages, 'babel', l:default)
    CompilerSet errorformat+=%-Z(babel)%.%#input\ line\ %l.
    CompilerSet errorformat+=%-C(babel)%m
  endif

  if get(self.config.packages, 'hyperref', l:default)
    CompilerSet errorformat+=%+WPackage\ hyperref\ Warning:\ %m
    CompilerSet errorformat+=%-C(hyperref)%.%#on\ input\ line\ %l.
    CompilerSet errorformat+=%-C(hyperref)%m
  endif

  if get(self.config.packages, 'scrreprt', l:default)
    CompilerSet errorformat+=%+WPackage\ scrreprt\ Warning:\ %m
    CompilerSet errorformat+=%-C(scrreprt)%m
  endif

  if get(self.config.packages, 'fixltx2e', l:default)
    CompilerSet errorformat+=%+WPackage\ fixltx2e\ Warning:\ %m
    CompilerSet errorformat+=%-C(fixltx2e)%m
  endif

  if get(self.config.packages, 'titlesec', l:default)
    CompilerSet errorformat+=%+WPackage\ titlesec\ Warning:\ %m
    CompilerSet errorformat+=%-C(titlesec)%m
  endif

  " Ignore unmatched lines
  CompilerSet errorformat+=%-G%.%#
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
  call setqflist(l:qflist, 'r', {'title': s:title})
endfunction

" }}}1

" vim: fdm=marker sw=2
