" LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! latextoc#fold_level(lnum) " {{{1
  let pline = getline(a:lnum - 1)
  let cline = getline(a:lnum)
  let nline = getline(a:lnum + 1)
  let l:pn = matchstr(pline, '\d$')
  let l:cn = matchstr(cline, '\d$')
  let l:nn = matchstr(nline, '\d$')

  " Don't fold options
  if cline =~# '^\s*$'
    return 0
  endif

  if l:nn > l:cn && g:latex_toc_fold_levels >= l:nn
    return '>' . l:nn
  endif

  if l:cn < l:pn && l:cn >= l:nn && g:latex_toc_fold_levels >= l:cn
    return l:cn
  endif

  return '='
endfunction

function! latextoc#fold_text() " {{{1
  return getline(v:foldstart)
endfunction
" }}}1

function! latextoc#refresh() " {{{1
  if !exists('b:toc') | return | endif
  set modifiable

  " Clean the buffer
  %delete

  " Add TOC entries (and keep track of closest index)
  let index = 0
  let closest_index = 0
  let s:num_format = '%-' . 2*(b:toc_secnumdepth+2) . 's'
  for entry in b:toc
    call s:print_entry(entry)

    let index += 1
    if entry.file == b:calling_file && entry.line <= b:calling_line
      let closest_index = index
    endif
  endfor

  " Add help info (if desired)
  if !g:latex_toc_hide_help
    call append('$', "")
    call append('$', "<Esc>/q: close")
    call append('$', "<Space>: jump")
    call append('$', "<Enter>: jump and close")
    call append('$', "-:       decrease secnumpdeth")
    call append('$', "+:       increase secnumpdeth")
    call append('$', "s:       hide numbering")
  endif

  " Delete empty first line and jump to the closest section
  0delete _
  set nomodifiable
  call setpos('.', [0, closest_index, 0, 0])
endfunction
" }}}1

function! s:print_entry(entry) " {{{1
  let level = b:toc_max_level - a:entry.level

  " Create entry string
  let entry = ''
  if b:toc_numbers
    let entry .= printf(s:num_format, level >= b:toc_secnumdepth + 2
          \ ? '' : s:print_number(a:entry.number))
  endif
  let entry .= printf('%-140s%s', a:entry.title, level)

  call append('$', entry)
endfunction
" }}}1
function! s:print_number(number) " {{{1
  if empty(a:number) | return "" | endif

  let number = [
        \ a:number.part,
        \ a:number.chapter,
        \ a:number.section,
        \ a:number.subsection,
        \ a:number.subsubsection,
        \ a:number.subsubsubsection,
        \ ]

  " Remove unused parts
  while number[0] == 0
    call remove(number, 0)
  endwhile
  while number[-1] == 0
    call remove(number, -1)
  endwhile

  " Change numbering in frontmatter, appendix, and backmatter
  if b:toc_topmatters > 1
        \ && (a:number.frontmatter || a:number.backmatter)
    return ""
  elseif a:number.appendix
    let number[0] = nr2char(number[0] + 64)
  endif

  return join(number, '.')
endfunction

" }}}1

" vim: fdm=marker
