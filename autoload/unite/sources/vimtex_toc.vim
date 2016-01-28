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
  return map(entries, 's:create_candidate(v:val, maxlevel)')
endfunction

" }}}1
function! s:source.hooks.on_syntax(args, context) " {{{1
  syntax match VimtexTocSecs /.* @\d$/
        \ contains=VimtexTocNum,@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexTocSec0 /.* @0$/
        \ contains=VimtexTocNum,@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexTocSec1 /.* @1$/
        \ contains=VimtexTocNum,@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexTocSec2 /.* @2$/
        \ contains=VimtexTocNum,@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexTocSec3 /.* @3$/
        \ contains=VimtexTocNum,@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexTocSec4 /.* @4$/
        \ contains=VimtexTocNum,@Tex
        \ contained containedin=uniteSource__vimtex
  syntax match VimtexTocNum
        \ /\%69v\%(\%([A-Z]\+\>\|\d\+\)\%(\.\d\+\)*\)\?\s*@\d$/
        \ contains=VimtexTocLevel
        \ contained containedin=VimtexTocSec[0-9*]
  syntax match VimtexTocLevel
        \ /@\d$/ conceal
        \ contained containedin=VimtexTocNum
endfunction

" }}}1

function! s:create_candidate(entry, maxlevel) " {{{1
  let level = a:maxlevel - a:entry.level
  let title = printf('%-65S%-10s',
        \ strpart(repeat(' ', 2*level) . a:entry.title, 0, 60),
        \ s:print_number(a:entry.number))
  return {
        \ 'word' : title,
        \ 'abbr' : title . ' @' . level,
        \ 'action__path' : a:entry.file,
        \ 'action__line' : a:entry.line,
        \ }
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
