" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#motion#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_motion_enabled', 1)
  if !g:vimtex_motion_enabled | return | endif

  call vimtex#util#set_default('g:vimtex_motion_matchparen', 1)
endfunction

" }}}1
function! vimtex#motion#init_script() " {{{1
  if !g:vimtex_motion_enabled | return | endif

  "
  " Define patterns used by motion.vim
  "

  " No preceding backslash
  let s:notbslash = '\%(\\\@<!\%(\\\\\)*\)\@<='

  " Not in a comment
  let s:notcomment = '\%(\%(\\\@<!\%(\\\\\)*\)\@<=%.*\)\@<!'

  " Pattern to match section/chapter/...
  let s:section  = s:notcomment . '\v\s*\\'
  let s:section .= '((sub)*section|chapter|part|'
  let s:section .= 'appendix|(front|back|main)matter)>'

  " List of paragraph boundaries
  let s:paragraph_boundaries = [
        \ '\%',
        \ '\\part',
        \ '\\chapter',
        \ '\\(sub)*section',
        \ '\\paragraph',
        \ '\\label',
        \ '\\begin',
        \ '\\end',
        \ ]
endfunction

" }}}1
function! vimtex#motion#init_buffer() " {{{1
  if !g:vimtex_motion_enabled | return | endif

  " Highlight matching delimiters ($, (), ...)
  if g:vimtex_motion_matchparen
    execute 'augroup vimtex_motion' . bufnr('%')
      autocmd!
      autocmd CursorMoved  <buffer> call s:highlight_matching_pair()
      autocmd CursorMovedI <buffer> call s:highlight_matching_pair()
    augroup END
  endif

  " Utility map to avoid conflict with "normal" command
  nnoremap <buffer> <sid>(v) v
  nnoremap <buffer> <sid>(V) V

  " Matching pairs
  nnoremap <silent><buffer> <plug>(vimtex-%) :call vimtex#motion#find_matching_pair()<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-%) :<c-u>call vimtex#motion#find_matching_pair(1)<cr>
  xmap     <silent><buffer> <plug>(vimtex-%) <sid>(vimtex-%)
  onoremap <silent><buffer> <plug>(vimtex-%) :execute "normal \<sid>(v)\<sid>(vimtex-%)"<cr>

  " Sections
  nnoremap <silent><buffer> <plug>(vimtex-]]) :call vimtex#motion#next_section(0,0,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-][) :call vimtex#motion#next_section(1,0,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-[]) :call vimtex#motion#next_section(1,1,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-[[) :call vimtex#motion#next_section(0,1,0)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-]]) :<c-u>call vimtex#motion#next_section(0,0,1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-][) :<c-u>call vimtex#motion#next_section(1,0,1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-[]) :<c-u>call vimtex#motion#next_section(1,1,1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-[[) :<c-u>call vimtex#motion#next_section(0,1,1)<cr>
  xmap     <silent><buffer> <plug>(vimtex-]]) <sid>(vimtex-]])
  xmap     <silent><buffer> <plug>(vimtex-][) <sid>(vimtex-][)
  xmap     <silent><buffer> <plug>(vimtex-[]) <sid>(vimtex-[])
  xmap     <silent><buffer> <plug>(vimtex-[[) <sid>(vimtex-[[)
  onoremap <silent><buffer> <plug>(vimtex-]]) :execute "normal \<sid>(v)\<sid>(vimtex-]])"<cr>
  onoremap <silent><buffer> <plug>(vimtex-][) :execute "normal \<sid>(v)\<sid>(vimtex-][)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-[]) :execute "normal \<sid>(v)\<sid>(vimtex-[])"<cr>
  onoremap <silent><buffer> <plug>(vimtex-[[) :execute "normal \<sid>(v)\<sid>(vimtex-[[)"<cr>
endfunction

" }}}1

function! vimtex#motion#find_matching_pair(...) " {{{1
  if a:0 > 0
    normal! gv
  endif

  let delim = vimtex#delim#get_current('all', 'both')
  if empty(delim)
    let delim = vimtex#delim#get_next('all', 'both')
    if empty(delim) | return | endif
  endif

  let delim = vimtex#delim#get_matching(delim)
  if empty(delim) | return | endif

  normal! m`
  call cursor(delim.lnum,
        \ (delim.is_open
        \   ? delim.cnum
        \   : delim.cnum + strlen(delim.match) - 1))
endfunction

" }}}1
function! vimtex#motion#next_paragraph(backwards, visual) " {{{1
  if a:visual
    normal! gv
  endif

  if a:backwards
    let l:flags = 'Wb'
    normal! k
  else
    let l:flags = 'W'
    call search('\S', l:flags)
  endif

  if vimtex#util#in_comment()
    let l:search = '^\s*\($\|\(%\)\@!\S\)'
  else
    let l:search = '\v^\s*($|' . join(s:paragraph_boundaries, '|') . ')'
  endif

  let n = 1
  while n <= max([v:count, 1])
    call search(l:search, l:flags)
    let n += 1
  endwhile

  if a:visual
    if a:backwards
      normal! j0
    else
      normal! k$
    endif
  endif
endfunction

" }}}1
function! vimtex#motion#next_section(type, backwards, visual) " {{{1
  " Restore visual mode if desired
  if a:visual
    normal! gv
  endif

  " For the [] and ][ commands we move up or down before the search
  if a:type == 1
    if a:backwards
      normal! k
    else
      normal! j
    endif
  endif

  " Define search pattern and do the search while preserving "/
  let flags = 'W'
  if a:backwards
    let flags = 'b' . flags
  endif

  " Perform the search
  call search(s:section, flags)

  " For the [] and ][ commands we move down or up after the search
  if a:type == 1
    if a:backwards
      normal! j
    else
      normal! k
    endif
  endif
endfunction

" }}}1

function! s:highlight_matching_pair() " {{{1
  if exists('w:vimtex_match_id1')
    silent! call matchdelete(w:vimtex_match_id1)
    silent! call matchdelete(w:vimtex_match_id2)
    unlet w:vimtex_match_id1
    unlet w:vimtex_match_id2
  endif
  if vimtex#util#in_comment() | return | endif

  let l:current = vimtex#delim#get_current('all', 'both')
  if empty(l:current) | return | endif

  let l:corresponding = vimtex#delim#get_matching(l:current)
  if empty(l:corresponding) | return | endif

  let [l:open, l:close] = l:current.is_open
        \ ? [l:current, l:corresponding]
        \ : [l:corresponding, l:current]

  let w:vimtex_match_id1 = matchadd('MatchParen',
        \ '\%' . l:open.lnum . 'l\%' . l:open.cnum . 'c' . l:open.re.this)
  let w:vimtex_match_id2 = matchadd('MatchParen',
        \ '\%' . l:close.lnum . 'l\%' . l:close.cnum . 'c' . l:close.re.this)
endfunction

" }}}1

" vim: fdm=marker sw=2
