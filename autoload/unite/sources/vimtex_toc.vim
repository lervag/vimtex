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
      \ 'syntax' : 'uniteSource__vimtex',
      \ 'hooks' : {},
      \}

function! s:source.gather_candidates(args, context) " {{{1
  let entries = vimtex#toc#get_entries()
  let maxlevel = max(map(copy(entries), 'v:val.level'))

  return map(entries, '{
        \ "word" : s:format_word(v:val),
        \ "abbr" : s:format_abbr(v:val, maxlevel - v:val.level),
        \ "action__path" : v:val.file,
        \ "action__line" : v:val.line,
        \ }')
endfunction

" }}}1
function! s:source.hooks.on_syntax(args, context) " {{{1
  syntax match VimtexTocSec0 /0.*/
        \ contains=VimtexTocLevel,@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexTocSec1 /1.*/
        \ contains=VimtexTocLevel,@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexTocSec2 /2.*/
        \ contains=VimtexTocLevel,@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexTocSec3 /3.*/
        \ contains=VimtexTocLevel,@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexTocSec4 /4.*/
        \ contains=VimtexTocLevel,@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexTocSecs /[5-9].*/
        \ contains=VimtexTocLevel,@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexTocLevel
        \ /\d/ conceal nextgroup=VimtexTocNum
        \ contained containedin=VimtexTocSec[0-4]
  syntax match VimtexTocNum
        \ /\(\([A-Z]\+\>\|\d\+\)\(\.\d\+\)*\)\?\s*/
        \ contained
endfunction

" }}}1

function! s:format_word(entry) " {{{1
  return printf('%-10s%s', s:print_number(a:entry.number), a:entry.title)
endfunction

" }}}1
function! s:format_abbr(entry, level) " {{{1
  return printf('%1s%-10s%s',
        \ a:level, s:print_number(a:entry.number), a:entry.title)
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

  if a:number.frontmatter || a:number.backmatter
    return ''
  elseif a:number.appendix
    let number[0] = nr2char(number[0] + 64)
  endif

  return join(number, '.')
endfunction

" }}}1

function! unite#sources#vimtex_toc#define()
  return s:source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
