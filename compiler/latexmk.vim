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

" Show warnings
if exists('g:vimtex_quickfix_ignore_all_warnings')
      \ && exists('g:vimtex_quickfix_ignored_warnings')
      \ && !g:vimtex_quickfix_ignore_all_warnings
  " Ignore some warnings
  for w in g:vimtex_quickfix_ignored_warnings
    let warning = escape(substitute(w, '[\,]', '%\\\\&', 'g'), ' ')
    exe 'CompilerSet errorformat+=%-G%.%#'. warning .'%.%#'
  endfor
  CompilerSet errorformat+=%+WLaTeX\ %.%#Warning:\ %.%#line\ %l%.%#
  CompilerSet errorformat+=%+W%.%#\ at\ lines\ %l--%*\\d
  CompilerSet errorformat+=%+WLaTeX\ %.%#Warning:\ %m
  CompilerSet errorformat+=%+WPackage\ natbib\ Warning:\ %m\ on\ input\ line\ %l%.
  CompilerSet errorformat+=%+W%.%#%.%#Warning:\ %m

  " Parse biblatex warnings
  CompilerSet errorformat+=%-C(biblatex)%.%#in\ t%.%#
  CompilerSet errorformat+=%-C(biblatex)%.%#Please\ v%.%#
  CompilerSet errorformat+=%-C(biblatex)%.%#LaTeX\ a%.%#
  CompilerSet errorformat+=%-Z(biblatex)%m

  " Parse babel warnings
  CompilerSet errorformat+=%-Z(babel)%.%#input\ line\ %l.
  CompilerSet errorformat+=%-C(babel)%m

  " Parse hyperref warnings
  CompilerSet errorformat+=%-C(hyperref)%.%#on\ input\ line\ %l.
  CompilerSet errorformat+=%-C(hyperref)%m

  " Parse more warnings
  CompilerSet errorformat+=%-C(scrreprt)%m
  CompilerSet errorformat+=%-C(fixltx2e)%m
  CompilerSet errorformat+=%-C(titlesec)%m
  CompilerSet errorformat+=%-C(Font)%m
endif

" Ignore unmatched lines
CompilerSet errorformat+=%-G%.%#
