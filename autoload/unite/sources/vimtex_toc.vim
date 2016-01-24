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
        \ "word" : v:val.title,
        \ "action__path" : v:val.file,
        \ "action__line" : v:val.line,
        \ }')
endfunction

" }}}1

function! unite#sources#vimtex_toc#define()
  return s:source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
