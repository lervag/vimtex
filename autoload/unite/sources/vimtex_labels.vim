" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

let s:save_cpo = &cpo
set cpo&vim

let s:source = {
      \ 'name' : 'vimtex_labels',
      \ 'sorters' : 'sorter_nothing',
      \ 'default_kind' : 'jump_list',
      \ 'syntax' : 'uniteSource__vimtex',
      \ 'hooks' : {},
      \}

function! s:source.gather_candidates(args, context) " {{{1
  let entries = vimtex#labels#get_entries()
  return map(entries, '{
        \ "word" : v:val.title,
        \ "action__path" : v:val.file,
        \ "action__line" : v:val.line,
        \ }')
endfunction

" }}}1
function! s:source.hooks.on_syntax(args, context) " {{{1
  syntax match VimtexLabelsChap /chap:.*$/ contains=@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexLabelsEq   /eq:.*$/ contains=@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexLabelsFig  /fig:.*$/ contains=@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexLabelsSec  /sec:.*$/ contains=@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexLabelsTab  /tab:.*$/ contains=@Tex
        \ contained containedin=uniteSource__vimtex

  highlight link VimtexLabelsChap PreProc
  highlight link VimtexLabelsEq   Statement
  highlight link VimtexLabelsFig  Identifier
  highlight link VimtexLabelsSec  Type
  highlight link VimtexLabelsTab  String
endfunction

" }}}1

function! unite#sources#vimtex_labels#define()
  return s:source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
