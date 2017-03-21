" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('current_compiler') | finish | endif
let current_compiler = 'latexmk'

CompilerSet makeprg=""

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
" Show warnings
"

let s:warnings = get(g:, 'vimtex_quickfix_warnings', {})
let s:packages = get(s:warnings, 'packages', {})
let s:wdefault = get(s:warnings, 'default', 1)
let s:pdefault = get(s:packages, 'default', 1)

if get(s:warnings, 'general', s:wdefault)
  CompilerSet errorformat+=%+WLaTeX\ %.%#Warning:\ %.%#line\ %l%.%#
  CompilerSet errorformat+=%+WLaTeX\ %.%#Warning:\ %m

  CompilerSet errorformat+=%-C(Font)%m
endif

if get(s:warnings, 'overfull', s:wdefault)
  CompilerSet errorformat+=%+WOverfull\ %\\%\\hbox%.%#\ at\ lines\ %l--%*\\d
endif

if get(s:warnings, 'underfull', s:wdefault)
  CompilerSet errorformat+=%+WUnderfull\ %\\%\\hbox%.%#\ at\ lines\ %l--%*\\d
endif

if get(s:packages, 'natbib', s:pdefault)
  CompilerSet errorformat+=%+WPackage\ natbib\ Warning:\ %m\ on\ input\ line\ %l%.
endif

if get(s:packages, 'biblatex', s:pdefault)
  CompilerSet errorformat+=%+WPackage\ biblatex\ Warning:\ %m
  CompilerSet errorformat+=%-C(biblatex)%.%#in\ t%.%#
  CompilerSet errorformat+=%-C(biblatex)%.%#Please\ v%.%#
  CompilerSet errorformat+=%-C(biblatex)%.%#LaTeX\ a%.%#
  CompilerSet errorformat+=%-C(biblatex)%m
endif

if get(s:packages, 'babel', s:pdefault)
  CompilerSet errorformat+=%-Z(babel)%.%#input\ line\ %l.
  CompilerSet errorformat+=%-C(babel)%m
endif

if get(s:packages, 'hyperref', s:pdefault)
  CompilerSet errorformat+=%+WPackage\ hyperref\ Warning:\ %m
  CompilerSet errorformat+=%-C(hyperref)%.%#on\ input\ line\ %l.
  CompilerSet errorformat+=%-C(hyperref)%m
endif

if get(s:packages, 'scrreprt', s:pdefault)
  CompilerSet errorformat+=%+WPackage\ scrreprt\ Warning:\ %m
  CompilerSet errorformat+=%-C(scrreprt)%m
endif

if get(s:packages, 'fixltx2e', s:pdefault)
  CompilerSet errorformat+=%+WPackage\ fixltx2e\ Warning:\ %m
  CompilerSet errorformat+=%-C(fixltx2e)%m
endif

if get(s:packages, 'titlesec', s:pdefault)
  CompilerSet errorformat+=%+WPackage\ titlesec\ Warning:\ %m
  CompilerSet errorformat+=%-C(titlesec)%m
endif

" Ignore unmatched lines
CompilerSet errorformat+=%-G%.%#

" vim: fdm=marker sw=2
