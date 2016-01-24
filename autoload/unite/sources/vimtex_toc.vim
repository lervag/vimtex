" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

let s:save_cpo = &cpo
set cpo&vim

let s:source = {
      \ 'name' : 'vimtex_toc',
      \ 'sorters' : 'sorter_nothing',
      \ 'default_kind' : 'jump_list',
      \}

function! s:source.gather_candidates(args, context) " {{{1
  let entries = vimtex#toc#get_entries()
  return map(entries, '{
        \ "word" : s:format_entry(v:val),
        \ "action__path" : v:val.file,
        \ "action__line" : v:val.line,
        \ }')
endfunction

" }}}1

function! s:format_entry(entry) " {{{1
  return printf('%-10s%s', s:print_number(a:entry.number), a:entry.title)
endfunction

" }}}1
function! s:print_number(number) " {{{1
  if empty(a:number) | return '' | endif

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

  return join(number, '.')
endfunction

" }}}1

function! unite#sources#vimtex_toc#define()
  return s:source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
