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

  " Highlight matching delimiters ($, (), ...)
  if g:vimtex_motion_matchparen
    augroup vimtex_motion
      autocmd!
      autocmd! CursorMoved  *.tex call s:highlight_matching_pair(1)
      autocmd! CursorMovedI *.tex call s:highlight_matching_pair()
    augroup END
  endif

  "
  " Define patterns used by motion.vim
  "

  " No preceding backslash
  let s:notbslash = '\%(\\\@<!\%(\\\\\)*\)\@<='

  " Not in a comment
  let s:notcomment = '\%(\%(\\\@<!\%(\\\\\)*\)\@<=%.*\)\@<!'

  " Patterns to match opening and closing delimiters/environments
  let s:delimiters_open = [
          \ '{',
          \ '(',
          \ '\[',
          \ '\\{',
          \ '\\(',
          \ '\\\[',
          \ '\\\Cbegin\s*{.\{-}}',
          \ '\\\Cleft\s*\%([^\\a-zA-Z0-9]\|\\.\|\\\a*\)',
          \ '\\\cbigg\?\((\|\[\|\\{\)',
        \ ]
  let s:delimiters_close = [
          \ '}',
          \ ')',
          \ '\]',
          \ '\\}',
          \ '\\)',
          \ '\\\]',
          \ '\\\Cend\s*{.\{-}}',
          \ '\\\Cright\s*\%([^\\a-zA-Z0-9]\|\\.\|\\\a*\)',
          \ '\\\cbigg\?\()\|\]\|\\}\)',
        \ ]
  let s:delimiters = join(s:delimiters_open + s:delimiters_close, '\|')
  let s:delimiters = '\(' . s:delimiters . '\|\$\)'

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

  " Utility map to avoid conflict with "normal" command
  nnoremap <buffer> <sid>(v) v
  nnoremap <buffer> <sid>(V) V

  " Matching pairs
  nnoremap <silent><buffer> <plug>(vimtex-%) :call vimtex#motion#find_matching_pair()<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-%) :<c-u>call vimtex#motion#find_matching_pair(1)<cr>
  xmap     <silent><buffer> <plug>(vimtex-%) <sid>(vimtex-%)
  onoremap <silent><buffer> <plug>(vimtex-%) :execute "normal \<sid>(v)\<sid>(vimtex-%)"<cr>

  " Paragraphs
  nnoremap <silent><buffer> <plug>(vimtex-})  :call vimtex#motion#next_paragraph(0,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-{)  :call vimtex#motion#next_paragraph(1,0)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-})  :<c-u>call vimtex#motion#next_paragraph(0,1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-{)  :<c-u>call vimtex#motion#next_paragraph(1,1)<cr>
  xmap     <silent><buffer> <plug>(vimtex-})  <sid>(vimtex-})
  xmap     <silent><buffer> <plug>(vimtex-{)  <sid>(vimtex-{)
  onoremap <silent><buffer> <plug>(vimtex-})  :execute "normal \<sid>(v)\<sid>(vimtex-})"<cr>
  onoremap <silent><buffer> <plug>(vimtex-{)  :execute "normal \<sid>(v)\<sid>(vimtex-{)"<cr>

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

  if vimtex#util#in_comment() | return | endif

  " Save position
  let nl = line('.')
  let nc = col('.')

  " Find delimiter under cursor
  let [lnum, cnum] = searchpos(s:delimiters, 'cbnW', nl-2)
  let delim = matchstr(getline(lnum), '^' . s:delimiters, cnum-1)

  " If delimiter not found, try to search forward instead
  if empty(delim)
    let [lnum, cnum] = searchpos(s:delimiters, 'cnW', nl+2)
    let delim = matchstr(getline(lnum), '^'. s:delimiters, cnum-1)
    if empty(delim)
      return
    endif
  endif

  " Utility pattern to NOT match the current cursor position
  let not_cursor = '\%(\%'. lnum . 'l\%' . cnum . 'c\)\@!'

  " Finally, find the matching delimiter
  if delim =~# '^\$'
    let inline = s:notcomment . s:notbslash . '\$'
    let [lnum0, cnum0] = searchpos('.', 'nW')
    if lnum0 && vimtex#util#in_syntax('texMathZoneX', lnum0, cnum0)
      let [lnum2, cnum2] = searchpos(inline, 'nW', 0, 200)
    else
      let [lnum2, cnum2] = searchpos(not_cursor . inline, 'bnW', 0, 200)
    endif

    call cursor(lnum2,cnum2)
  else
    for i in range(len(s:delimiters))
      let open_pat  = '\C' . s:notbslash . s:delimiters_open[i]
      let close_pat = '\C' . s:notbslash . s:delimiters_close[i]

      if delim =~# '^' . open_pat
        call searchpairpos(open_pat, '', close_pat,
              \ 'W', 'vimtex#util#in_comment()', 0, 200)
        call search(close_pat, 'ce')
        return
      elseif delim =~# '^' . close_pat
        call searchpairpos(open_pat, '', not_cursor . close_pat,
              \ 'bW', 'vimtex#util#in_comment()', 0, 200)
        return
      endif
    endfor
  endif
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

function! s:highlight_matching_pair(...) " {{{1
  if vimtex#util#in_comment() | return | endif
  let hmode = a:0 > 0 ? 1 : 0

  2match none

  " Save position
  let nl = line('.')
  let nc = col('.')
  let line = getline(nl)

  " Find delimiter under cursor
  let cnum = searchpos(s:delimiters, 'cbnW', nl)[1]
  let delim = matchstr(line, '^'. s:delimiters, cnum-1)

  " Only highlight when cursor is on delimiters
  if empty(delim) || strlen(delim)+cnum-hmode < nc
    return
  endif

  if delim =~# '^\$'
    "
    " Match inline math
    "
    let [lnum0, cnum0] = searchpos('.', 'nW')
    if lnum0 && vimtex#util#in_syntax('texMathZoneX', lnum0, cnum0)
      let [lnum2, cnum2] = searchpos(s:notcomment . s:notbslash . '\$',
            \ 'nW', line('w$'), 200)
    else
      let [lnum2, cnum2] = searchpos('\%(\%'. nl . 'l\%'
            \ . cnum . 'c\)\@!'. s:notcomment . s:notbslash . '\$',
            \ 'bnW', line('w0'), 200)
    endif

    execute '2match MatchParen /\%(\%' . nl . 'l\%'
          \ . cnum . 'c\$' . '\|\%' . lnum2 . 'l\%' . cnum2 . 'c\$\)/'
  else
    "
    " Match other delimitors
    "
    for i in range(len(s:delimiters_open))
      let open_pat  = '\C' . s:notbslash . s:delimiters_open[i]
      let close_pat = '\C' . s:notbslash . s:delimiters_close[i]

      if delim =~# '^' . open_pat
        let [lnum2, cnum2] = searchpairpos(open_pat, '', close_pat,
              \ 'nW', 'vimtex#util#in_comment()', line('w$'), 200)
        execute '2match MatchParen /\%(\%' . nl . 'l\%' . cnum
              \ . 'c' . s:delimiters_open[i] . '\|\%'
              \ . lnum2 . 'l\%' . cnum2 . 'c'
              \ . s:delimiters_close[i] . '\)/'
        return
      elseif delim =~# '^' . close_pat
        let [lnum2, cnum2] =  searchpairpos(open_pat, '',
              \ '\C\%(\%'. nl . 'l\%' . cnum . 'c\)\@!' . close_pat,
              \ 'bnW', 'vimtex#util#in_comment()', line('w0'), 200)
        execute '2match MatchParen /\%(\%' . lnum2 . 'l\%' . cnum2
              \ . 'c' . s:delimiters_open[i] . '\|\%'
              \ . nl . 'l\%' . cnum . 'c'
              \ . s:delimiters_close[i] . '\)/'
        return
      endif
    endfor
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
