if exists("b:did_indent")
  finish
endif
let b:did_indent = 1
let s:cpo_save = &cpo
let s:tikz_indented = 0
set cpo&vim

" {{{1 Options and common patterns
setlocal autoindent
setlocal indentexpr=LatexIndent()
setlocal indentkeys&
setlocal indentkeys+=[,(,{,),},],\&,=\\item

" Define some common patterns
let s:envs_lists = 'itemize\|description\|enumerate\|thebibliography'
let s:envs_noindent = 'document\|verbatim\|lstlisting'
let s:delimiters_open = '\(' . join([
        \ '{',
        \ '(',
        \ '\[',
        \ '\\{',
        \ '\\(',
        \ '\\\[',
        \ '\\\Cbegin\s*{.\{-}}',
        \ '\\\Cleft\s*\%([^\\]\|\\.\|\\\a*\)',
        \ '\\\cbigg\?\((\|\[\|\\{\)',
      \ ], '\|') . '\)'
let s:delimiters_close = '\(' . join([
        \ '}',
        \ ')',
        \ '\]',
        \ '\\}',
        \ '\\)',
        \ '\\\]',
        \ '\\\Cend\s*{.\{-}}',
        \ '\\\Cright\s*\%([^\\]\|\\.\|\\\a*\)',
        \ '\\\cbigg\?\()\|\]\|\\}\)',
      \ ], '\|') . '\)'
let s:tikz_commands = '\\\(' . join([
        \ 'draw',
        \ 'fill',
        \ 'path',
        \ 'node',
        \ 'add\(legendentry\|plot\)',
      \ ], '\|') . '\)'
" }}}1

" {{{1 LatexIndent
function! LatexIndent()
  " Find a non-blank non-comment line above the current line
  let lnum = prevnonblank(v:lnum - 1)
  while lnum != 0 && getline(lnum) =~ '^\s*%'
    let lnum = prevnonblank(lnum - 1)
  endwhile

  " Zero indent for top of file
  if lnum == 0
    return 0
  endif

  " Get current and previous line, remove comments
  let cline = substitute(getline(v:lnum), '\\\@<!%.*', '', '')
  let pline = substitute(getline(lnum),   '\\\@<!%.*', '', '')

  " Check for verbatim modes
  if synIDattr(synID(v:lnum, indent(v:lnum), 1), "name") == "texZone"
    if empty(cline)
      return indent(lnum)
    else
      return indent(v:lnum)
    end
  endif

  " Align on ampersands
  if cline =~ '^\s*&' && pline =~ '\\\@<!&.*'
    return indent(v:lnum) + match(pline, '\\\@<!&') - stridx(cline, "&")
  endif

  " Find previous non-empty non-comment non-ampersand line
  while lnum != 0 && (match(pline, '\\\@<!&') != -1 || pline =~ '^\s*%')
    let lnum = prevnonblank(lnum - 1)
    let pline = getline(lnum)
  endwhile

  " Zero indent for top of file
  if lnum == 0
    return 0
  endif

  " Use previous indentation for comments
  if cline =~ '^\s*%'
    return indent(v:lnum)
  endif

  let ind = indent(lnum)

  " Add indent on begin environment
  if pline =~ '\\begin{.*}' && pline !~ s:envs_noindent
    let ind = ind + &sw

    " Add extra indent for list environments
    if pline =~ s:envs_lists
      let ind = ind + &sw
    endif
  endif

  " Subtract indent on end environment
  if cline =~ '\\end{.*}' && cline !~ s:envs_noindent
    let ind = ind - &sw

    " Subtract extra indent for list environments
    if cline =~ s:envs_lists
      let ind = ind - &sw
    endif
  endif

  " Indent opening and closing delimiters
  let ind += s:indent_braces(cline, pline) * &sw

  " Indent list items
  if pline =~ '^\s*\\\(bib\)\?item'
    let ind += &sw
  endif
  if cline =~ '^\s*\\\(bib\)\?item'
    let ind -= &sw
  endif

  " Indent tikz elements
  if pline =~ s:tikz_commands
    let ind += &sw
    let s:tikz_indented += 1
  endif
  if s:tikz_indented > 0 && pline =~ ';\s*$'
    let ind -= &sw
    let s:tikz_indented -= 1
  endif

  return ind
endfunction
"}}}

" {{{1 s:indent_braces
function! s:indent_braces(cline, pline)
  return     s:match_brace(a:pline, s:delimiters_open)
         \ - s:match_brace(a:pline, s:delimiters_close)
endfunction

" {{{1 s:match_brace
function! s:match_brace(line, pattern)
  let sum = 0
  let indx = match(a:line, a:pattern)
  while indx >= 0
    let sum += 1
    let match = matchstr(a:line, a:pattern, indx)
    let indx += len(match)
    let indx = match(a:line, a:pattern, indx)
  endwhile
  return sum
endfunction
" }}}1

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: fdm=marker
