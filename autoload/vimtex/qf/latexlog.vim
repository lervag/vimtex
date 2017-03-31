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

  let self.config = get(g:, 'vimtex_qf_latexlog', {})
  let self.config.default = get(self.config, 'default', 1)
  let self.config.packages = get(self.config, 'packages', {})
  let self.config.packages.default = get(self.config.packages, 'default', 1)

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

" vim: fdm=marker sw=2
