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

  " Paragraph motion
  nnoremap <silent><buffer> <plug>(vimtex-})  :call vimtex#motion#next_paragraph(0,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-{)  :call vimtex#motion#next_paragraph(1,0)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-})  :<c-u>call vimtex#motion#next_paragraph(0,1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-{)  :<c-u>call vimtex#motion#next_paragraph(1,1)<cr>
  xmap     <silent><buffer> <plug>(vimtex-})  <sid>(vimtex-})
  xmap     <silent><buffer> <plug>(vimtex-{)  <sid>(vimtex-{)
  onoremap <silent><buffer> <plug>(vimtex-})  :execute "normal \<sid>(V)\<sid>(vimtex-})"<cr>
  onoremap <silent><buffer> <plug>(vimtex-{)  :execute "normal \<sid>(V)\<sid>(vimtex-{)"<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-ip) :<c-u>call vimtex#motion#sel_paragraph(1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-ap) :<c-u>call vimtex#motion#sel_paragraph()<cr>
  xmap     <silent><buffer> <plug>(vimtex-ip) <sid>(vimtex-ip)
  xmap     <silent><buffer> <plug>(vimtex-ap) <sid>(vimtex-ap)
  onoremap <silent><buffer> <plug>(vimtex-ip) :execute "normal \<sid>(V)\<sid>(vimtex-ip)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-ap) :execute "normal \<sid>(V)\<sid>(vimtex-ap)"<cr>

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

  " Text object for environments
  xnoremap <silent><buffer>  <sid>(vimtex-ie) :<c-u>call vimtex#motion#sel_environment(1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-ae) :<c-u>call vimtex#motion#sel_environment()<cr>
  xmap     <silent><buffer> <plug>(vimtex-ie) <sid>(vimtex-ie)
  xmap     <silent><buffer> <plug>(vimtex-ae) <sid>(vimtex-ae)
  onoremap <silent><buffer> <plug>(vimtex-ie) :execute "normal \<sid>(v)\<sid>(vimtex-ie)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-ae) :execute "normal \<sid>(v)\<sid>(vimtex-ae)"<cr>

  " Text object for inline math
  xnoremap <silent><buffer>  <sid>(vimtex-i$) :<c-u>call vimtex#motion#sel_inline_math(1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-a$) :<c-u>call vimtex#motion#sel_inline_math()<cr>
  xmap     <silent><buffer> <plug>(vimtex-i$) <sid>(vimtex-i$)
  xmap     <silent><buffer> <plug>(vimtex-a$) <sid>(vimtex-a$)
  onoremap <silent><buffer> <plug>(vimtex-i$) :execute "normal \<sid>(v)\<sid>(vimtex-i$)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-a$) :execute "normal \<sid>(v)\<sid>(vimtex-a$)"<cr>

  " Text object for delimiters
  xnoremap <silent><buffer>  <sid>(vimtex-id) :<c-u>call vimtex#motion#sel_delimiter(1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-ad) :<c-u>call vimtex#motion#sel_delimiter()<cr>
  xmap     <silent><buffer> <plug>(vimtex-id) <sid>(vimtex-id)
  xmap     <silent><buffer> <plug>(vimtex-ad) <sid>(vimtex-ad)
  onoremap <silent><buffer> <plug>(vimtex-id) :execute "normal \<sid>(v)\<sid>(vimtex-id)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-ad) :execute "normal \<sid>(v)\<sid>(vimtex-ad)"<cr>
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
    if lnum0 && vimtex#util#has_syntax('texMathZoneX', lnum0, cnum0)
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
  call search(l:search, l:flags)

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
function! vimtex#motion#sel_delimiter(...) " {{{1
  let inner = a:0 > 0

  let [d1, l1, c1, d2, l2, c2] = vimtex#util#get_delim()

  if inner
    let c1 += len(d1)
    if c1 != len(getline(l1))
      let l1 += 1
      let c1 = 1
    endif
  endif

  if inner
    let c2 -= 1
    if c2 < 1
      let l2 -= 1
      let c2 = len(getline(l2))
    endif
  else
    let c2 += len(d2) - 1
  endif

  if l1 < l2 || (l1 == l2 && c1 < c2)
    call cursor(l1,c1)
    if visualmode() ==# 'V'
      normal! V
    else
      normal! v
    endif
    call cursor(l2,c2)
  endif
endfunction

" }}}1
function! vimtex#motion#sel_environment(...) " {{{1
  let inner = a:0 > 0

  let [env, lnum, cnum, lnum2, cnum2] = vimtex#util#get_env(1)
  call cursor(lnum, cnum)
  if inner
    if env =~# '^\'
      call search('\\.\_\s*\S', 'eW')
    else
      call search('}\(\_\s*\(\[\_[^]]*\]\|{\_\S\{-}}\)\)\?\_\s*\S', 'eW')
    endif
  endif
  if visualmode() ==# 'V'
    normal! V
  else
    normal! v
  endif
  call cursor(lnum2, cnum2)
  if inner
    call search('\S\_\s*', 'bW')
  else
    if env =~# '^\'
      normal! l
    else
      call search('}', 'eW')
    endif
  endif
endfunction

" }}}1
function! vimtex#motion#sel_inline_math(...) " {{{1
  let l:inner = a:0 > 0

  let l:flags = 'bW'
  let l:dollar = 0
  let l:dollar_pat = '\\\@<!\$'

  if vimtex#util#has_syntax('texMathZoneX')
    let l:dollar = 1
    let l:pattern = [l:dollar_pat, l:dollar_pat]
    let l:flags .= 'c'
  elseif getline('.')[col('.') - 1] ==# '$'
    let l:dollar = 1
    let l:pattern = [l:dollar_pat, l:dollar_pat]
  elseif vimtex#util#has_syntax('texMathZoneV')
    let l:pattern = ['\\(', '\\)']
    let l:flags .= 'c'
  elseif getline('.')[col('.') - 2:col('.') - 1] ==# '\)'
    let l:pattern = ['\\(', '\\)']
  else
    return
  endif

  call s:search_and_skip_comments(l:pattern[0], l:flags)

  if l:inner
    execute 'normal! ' l:dollar ? 'l' : 'll'
  endif

  execute 'normal! ' visualmode() ==# 'V' ? 'V' : 'v'

  call s:search_and_skip_comments(l:pattern[1], 'W')

  if l:inner
    normal! h
  elseif !l:dollar
    normal! l
  endif
endfunction
" }}}1
function! vimtex#motion#sel_paragraph(...) " {{{1
  let inner = a:0 > 0

  " Define selection
  normal! 0j
  call vimtex#motion#next_paragraph(1,0)
  normal! jV
  call vimtex#motion#next_paragraph(0,0)

  " Go back one line for inner objects
  if inner
    normal! k
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
    if lnum0 && vimtex#util#has_syntax('texMathZoneX', lnum0, cnum0)
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
function! s:search_and_skip_comments(pat, ...) " {{{1
  " Usage: s:search_and_skip_comments(pat, [flags, stopline])
  let flags             = a:0 >= 1 ? a:1 : ''
  let stopline  = a:0 >= 2 ? a:2 : 0
  let saved_pos = getpos('.')

  " search once
  let ret = search(a:pat, flags, stopline)

  if ret
    " do not match at current position if inside comment
    let flags = substitute(flags, 'c', '', 'g')

    " keep searching while in comment
    while vimtex#util#in_comment()
      let ret = search(a:pat, flags, stopline)
      if !ret
        break
      endif
    endwhile
  endif

  if !ret
    " if no match found, restore position
    call setpos('.', saved_pos)
  endif

  return ret
endfunction
" }}}1

" vim: fdm=marker sw=2
