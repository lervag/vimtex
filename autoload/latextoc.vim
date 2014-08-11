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

function! latextoc#init() " {{{1
  if !exists('b:toc') | return | endif

  " Fill TOC entries
  call s:add_start()
  call s:add_entries()
  call s:add_help()
  call s:add_end()

  " Jump to closest index
  call setpos('.', b:toc_pos_closest)
endfunction
" }}}1
function! latextoc#refresh() " {{{1
  if !exists('b:toc') | return | endif

  " Fill TOC entries
  call s:add_start()
  call s:add_entries()
  call s:add_help()
  call s:add_end()

  " Restore old position
  call setpos('.', b:toc_pos_saved)
endfunction
" }}}1

function! s:add_start() " {{{1
  let b:toc_pos_saved = getpos('.')
  setlocal modifiable
  %delete
endfunction

" }}}1
function! s:add_entries() " {{{1
  let closest_index = 0
  let s:num_format = '%-' . 2*(b:toc_secnumdepth+2) . 's'

  let index = 0
  for entry in b:toc
    let index += 1
    call s:print_entry(entry)
    if entry.file == b:calling_file && entry.line <= b:calling_line
      let closest_index = index
    endif
  endfor

  let b:toc_pos_closest = [0, closest_index, 0, 0]
endfunction
" }}}1
function! s:add_help() " {{{1
  if !g:latex_toc_hide_help
    call append('$', "")
    call append('$', "<Esc>/q: close")
    call append('$', "<Space>: jump")
    call append('$', "<Enter>: jump and close")
    call append('$', "-:       decrease secnumpdeth")
    call append('$', "+:       increase secnumpdeth")
    call append('$', "s:       hide numbering")
  endif
endfunction
" }}}1
function! s:add_end() " {{{1
  0delete _
  setlocal nomodifiable
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
