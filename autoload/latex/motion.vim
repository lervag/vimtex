" {{{1 latex#motion#init
function! latex#motion#init(initialized)
  if !g:latex_motion_enabled | return | endif

  if g:latex_default_mappings
    nnoremap <silent><buffer> % :call latex#motion#find_matching_pair()<cr>
    vnoremap <silent><buffer> %
          \ :<c-u>call latex#motion#find_matching_pair(1)<cr>
    onoremap <silent><buffer> % :normal v%<cr>

    nnoremap <silent><buffer> ]] :call latex#motion#next_sec(0,0,0)<cr>
    nnoremap <silent><buffer> ][ :call latex#motion#next_sec(1,0,0)<cr>
    nnoremap <silent><buffer> [] :call latex#motion#next_sec(1,1,0)<cr>
    nnoremap <silent><buffer> [[ :call latex#motion#next_sec(0,1,0)<cr>
    vnoremap <silent><buffer> ]] :<c-u>call latex#motion#next_sec(0,0,1)<cr>
    vnoremap <silent><buffer> ][ :<c-u>call latex#motion#next_sec(1,0,1)<cr>
    vnoremap <silent><buffer> [] :<c-u>call latex#motion#next_sec(1,1,1)<cr>
    vnoremap <silent><buffer> [[ :<c-u>call latex#motion#next_sec(0,1,1)<cr>
    onoremap <silent><buffer> ]] :normal v]]<cr>
    onoremap <silent><buffer> ][ :normal v][<cr>
    onoremap <silent><buffer> [] :normal v[]<cr>
    onoremap <silent><buffer> [[ :normal v[[<cr>

    vnoremap <silent><buffer> ie :latex#motion#select_current_env('inner')<cr>
    vnoremap <silent><buffer> ae :latex#motion#select_current_env('outer')<cr>
    onoremap <silent><buffer> ie :normal vie<cr>
    onoremap <silent><buffer> ae :normal vae<cr>

    vnoremap <silent><buffer> i$ :latex#motion#select_inline_math('inner')<cr>
    vnoremap <silent><buffer> a$ :latex#motion#select_inline_math('outer')<cr>
    onoremap <silent><buffer> i$ :normal vi$<cr>
    onoremap <silent><buffer> a$ :normal va$<cr>
  endif

  "
  " Highlight matching parens ($, (), ...)
  "
  if !a:initialized && g:latex_motion_matchparen
    augroup latex_motion
      autocmd!
      " Disable matchparen autocommands
      autocmd BufEnter *.tex
            \   if !exists("g:loaded_matchparen") || !g:loaded_matchparen
            \ |   runtime plugin/matchparen.vim
            \ | endif
      autocmd BufEnter *.tex
            \ 3match none | unlet! g:loaded_matchparen | au! matchparen

      " Enable latex matchparen functionality
      autocmd! CursorMoved  *.tex call s:highlight_matching_pair(1)
      autocmd! CursorMovedI *.tex call s:highlight_matching_pair()
    augroup END
  endif
endfunction

" {{{1 latex#motion#find_matching_pair
function! latex#motion#find_matching_pair(...)
  "
  " Note: This code is ugly, but it seems to work.
  "
  if a:0 > 0
    normal! gv
  endif

  if latex#util#in_comment() | return | endif

  " Save position
  let nl = line('.')
  let nc = col('.')

  " Combine all open/close pats
  let all_pats = join(g:latex_motion_open_pats+g:latex_motion_close_pats, '\|')
  let all_pats = '\C\(' . all_pats . '\|\$\)'

  " Find delimiter under cursor
  let [lnum, cnum] = searchpos(all_pats, 'cbnW', nl-2)
  let delim = matchstr(getline(lnum), '^'. all_pats, cnum-1)

  " If delimiter not found, try to search forward instead
  if empty(delim)
    let [lnum, cnum] = searchpos(all_pats, 'cnW', nl+2)
    let delim = matchstr(getline(lnum), '^'. all_pats, cnum-1)
    if empty(delim)
      return
    endif
  endif

  " Utility pattern to NOT match the current cursor position
  let not_cursor = '\%(\%'. lnum . 'l\%' . cnum . 'c\)\@!'

  " Finally, find the matching delimiter
  if delim =~ '^\$'
    let inline = b:notcomment . b:notbslash . '\$'
    let [lnum0, cnum0] = searchpos('.', 'nW')
    if lnum0 && latex#util#has_syntax('texMathZoneX', lnum0, cnum0)
      let [lnum2, cnum2] = searchpos(inline, 'nW', 0, 200)
    else
      let [lnum2, cnum2] = searchpos(not_cursor . inline, 'bnW', 0, 200)
    endif

    call cursor(lnum2,cnum2)
  else
    for i in range(len(g:latex_motion_open_pats))
      let open_pat  = '\C' . b:notbslash . g:latex_motion_open_pats[i]
      let close_pat = '\C' . b:notbslash . g:latex_motion_close_pats[i]

      if delim =~# '^' . open_pat
        call searchpairpos(open_pat, '', close_pat,
              \ 'W', 'latex#util#in_comment()', 0, 200)
        call search(close_pat, 'ce')
        return
      elseif delim =~# '^' . close_pat
        call searchpairpos(open_pat, '', not_cursor . close_pat,
              \ 'bW', 'latex#util#in_comment()', 0, 200)
        return
      endif
    endfor
  endif
endfunction

" {{{1 latex#motion#next_sec
function! latex#motion#next_sec(type, backwards, visual)
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
  let save_search = @/
  let flags = 'W'
  if a:backwards
    let flags = 'b' . flags
  endif

  " Define section pattern
  let sec_pat = join([
          \ '(sub)*section',
          \ 'chapter',
          \ 'part',
          \ 'appendix',
          \ '(front|back|main)matter',
          \ ], '|')
  let sec_pat = b:notcomment . '\v\s*\\(' . sec_pat . ')>'

  " Perform the search
  call search(sec_pat, flags)
  let @/ = save_search

  " For the [] and ][ commands we move down or up after the search
  if a:type == 1
    if a:backwards
      normal! j
    else
      normal! k
    endif
  endif
endfunction

" {{{1 latex#motion#select_current_env
function! latex#motion#select_current_env(seltype)
  let [env, lnum, cnum, lnum2, cnum2] = latex#util#get_env(1)
  call cursor(lnum, cnum)
  if a:seltype == 'inner'
    if env =~ '^\'
      call search('\\.\_\s*\S', 'eW')
    else
      call search('}\(\_\s*\[\_[^]]*\]\)\?\_\s*\S', 'eW')
    endif
  endif
  if visualmode() ==# 'V'
    normal! V
  else
    normal! v
  endif
  call cursor(lnum2, cnum2)
  if a:seltype == 'inner'
    call search('\S\_\s*', 'bW')
  else
    if env =~ '^\'
      normal! l
    else
      call search('}', 'eW')
    endif
  endif
endfunction

" {{{1 latex#motion#select_inline_math
function! latex#motion#select_inline_math(seltype)
  " seltype is either 'inner' or 'outer'

  let dollar_pat = '\\\@<!\$'

  if latex#util#has_syntax('texMathZoneX')
    call s:search_and_skip_comments(dollar_pat, 'cbW')
  elseif getline('.')[col('.') - 1] == '$'
    call s:search_and_skip_comments(dollar_pat, 'bW')
  else
    return
  endif

  if a:seltype == 'inner'
    normal! l
  endif

  if visualmode() ==# 'V'
    normal! V
  else
    normal! v
  endif

  call s:search_and_skip_comments(dollar_pat, 'W')

  if a:seltype == 'inner'
    normal! h
  endif
endfunction
" }}}1

" {{{1 s:highlight_matching_pair
function! s:highlight_matching_pair(...)
  if latex#util#in_comment() | return | endif
  let hmode = a:0 > 0 ? 1 : 0

  2match none

  " Save position
  let nl = line('.')
  let nc = col('.')
  let line = getline(nl)

  " Combine all open/close pats
  let all_pats = join(g:latex_motion_open_pats+g:latex_motion_close_pats, '\|')
  let all_pats = '\C\(' . all_pats . '\|\$\)'

  " Find delimiter under cursor
  let cnum = searchpos(all_pats, 'cbnW', nl)[1]
  let delim = matchstr(line, '^'. all_pats, cnum-1)

  " Only highlight when cursor is on delimiters
  if empty(delim) || strlen(delim)+cnum-hmode < nc
    return
  endif

  if delim =~ '^\$'
    "
    " Match inline math
    "
    let [lnum0, cnum0] = searchpos('.', 'nW')
    if lnum0 && latex#util#has_syntax('texMathZoneX', lnum0, cnum0)
      let [lnum2, cnum2] = searchpos(b:notcomment . b:notbslash . '\$',
            \ 'nW', line('w$'), 200)
    else
      let [lnum2, cnum2] = searchpos('\%(\%'. nl . 'l\%'
            \ . cnum . 'c\)\@!'. b:notcomment . b:notbslash . '\$',
            \ 'bnW', line('w0'), 200)
    endif

    execute '2match MatchParen /\%(\%' . nl . 'l\%'
          \ . cnum . 'c\$' . '\|\%' . lnum2 . 'l\%' . cnum2 . 'c\$\)/'
  else
    "
    " Match other delimitors
    "
    for i in range(len(g:latex_motion_open_pats))
      let open_pat  = '\C' . b:notbslash . g:latex_motion_open_pats[i]
      let close_pat = '\C' . b:notbslash . g:latex_motion_close_pats[i]

      if delim =~# '^' . open_pat
        let [lnum2, cnum2] = searchpairpos(open_pat, '', close_pat,
              \ 'nW', 'latex#util#in_comment()', line('w$'), 200)
        execute '2match MatchParen /\%(\%' . nl . 'l\%' . cnum
              \ . 'c' . g:latex_motion_open_pats[i] . '\|\%'
              \ . lnum2 . 'l\%' . cnum2 . 'c'
              \ . g:latex_motion_close_pats[i] . '\)/'
        return
      elseif delim =~# '^' . close_pat
        let [lnum2, cnum2] =  searchpairpos(open_pat, '',
              \ '\C\%(\%'. nl . 'l\%' . cnum . 'c\)\@!' . close_pat,
              \ 'bnW', 'latex#util#in_comment()', line('w0'), 200)
        execute '2match MatchParen /\%(\%' . lnum2 . 'l\%' . cnum2
              \ . 'c' . g:latex_motion_open_pats[i] . '\|\%'
              \ . nl . 'l\%' . cnum . 'c'
              \ . g:latex_motion_close_pats[i] . '\)/'
        return
      endif
    endfor
  endif
endfunction
" }}}1

" vim:fdm=marker:ff=unix
