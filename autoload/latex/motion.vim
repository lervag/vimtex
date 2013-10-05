" {{{1 latex#motion#init
function! latex#motion#init(initialized)
  if !g:latex_motion_enabled | return | endif

  if g:latex_default_mappings
    nnoremap <silent><buffer> % :call latex#motion#find_matching_pair('n')<cr>
    vnoremap <silent><buffer> %
          \ :<c-u>call latex#motion#find_matching_pair('v')<cr>
    onoremap <silent><buffer> % :call latex#motion#find_matching_pair('o')<cr>

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
      autocmd! CursorMoved  *.tex call latex#motion#find_matching_pair('h')
      autocmd! CursorMovedI *.tex call latex#motion#find_matching_pair('i')
    augroup END
  endif
endfunction

" {{{1 latex#motion#find_matching_pair
function! latex#motion#find_matching_pair(mode)
  "
  " Note: This code is ugly, but it seems to work.
  "
  if a:mode =~ 'h\|i'
    2match none
  elseif a:mode == 'v'
    normal! gv
  endif

  if latex#util#in_comment() | return | endif

  let lnum = line('.')
  let cnum = searchpos('\A', 'cbnW', lnum)[1]

  " Check if previous char is a backslash
  if strpart(getline(lnum), cnum-2, 1) == '\'
    let cnum = cnum-1
  endif

  " Make pattern to combine all open/close pats
  let all_pats = join(g:latex_motion_open_pats+g:latex_motion_close_pats, '\|')
  let all_pats = '\(' . all_pats . '\|\$\)'

  let delim = matchstr(getline(lnum), '\C^'. all_pats, cnum-1)
  if empty(delim) || strlen(delim)+cnum-1 < col('.')
    if a:mode =~ 'n\|v\|o'
      " if not found, search forward
      let cnum = match(getline(lnum), '\C'. all_pats, col('.') - 1) + 1
      if cnum == 0 | return | endif
      call cursor(lnum, cnum)
      let delim = matchstr(getline(lnum), '\C^'. all_pats, cnum - 1)
    elseif a:mode =~ 'i'
      " if not found, move one char bacward and search
      let cnum = searchpos('\A', 'bnW', lnum)[1]
      " if the previous char is a backslash
      if strpart(getline(lnum), cnum-2, 1) == '\'
        let cnum = cnum-1
      endif
      let delim = matchstr(getline(lnum), '\C^'. all_pats, cnum - 1)
      if empty(delim) || strlen(delim)+cnum< col('.')
        return
      endif
    elseif a:mode =~ 'h'
      return
    endif
  endif

  if delim =~ '^\$'
    " match $-pairs
    " check if next character is in inline math
    let [lnum0, cnum0] = searchpos('.', 'nW')
    if lnum0 && latex#util#has_syntax('texMathZoneX', lnum0, cnum0)
      let [lnum2, cnum2] = searchpos(b:notcomment . b:notbslash . '\$',
            \ 'nW', line('w$')*(a:mode =~ 'h\|i'), 200)
    else
      let [lnum2, cnum2] = searchpos('\%(\%'. lnum . 'l\%'
            \ . cnum . 'c\)\@!'. b:notcomment . b:notbslash . '\$',
            \ 'bnW', line('w0')*(a:mode =~ 'h\|i'), 200)
    endif

    if a:mode =~ 'h\|i'
      execute '2match MatchParen /\%(\%' . lnum . 'l\%'
            \ . cnum . 'c\$' . '\|\%' . lnum2 . 'l\%' . cnum2 . 'c\$\)/'
    elseif a:mode =~ 'n\|v\|o'
      call cursor(lnum2,cnum2)
    endif
  else
    " match other pairs
    for i in range(len(g:latex_motion_open_pats))
      let open_pat = b:notbslash . g:latex_motion_open_pats[i]
      let close_pat = b:notbslash . g:latex_motion_close_pats[i]

      if delim =~# '^' . open_pat
        " if on opening pattern, search for closing pattern
        let [lnum2, cnum2] = searchpairpos('\C' . open_pat, '', '\C'
              \ . close_pat, 'nW', 'latex#util#in_comment()',
              \ line('w$')*(a:mode =~ 'h\|i'), 200)
        if a:mode =~ 'h\|i'
          execute '2match MatchParen /\%(\%' . lnum . 'l\%' . cnum
                \ . 'c' . g:latex_motion_open_pats[i] . '\|\%'
                \ . lnum2 . 'l\%' . cnum2 . 'c'
                \ . g:latex_motion_close_pats[i] . '\)/'
        elseif a:mode =~ 'n\|v\|o'
          call cursor(lnum2,cnum2)
          if strlen(close_pat)>1 && a:mode =~ 'o'
            call cursor(lnum2, matchend(getline('.'), '\C'
                  \ . close_pat, col('.')-1))
          endif
        endif
        break
      elseif delim =~# '^' . close_pat
        " if on closing pattern, search for opening pattern
        let [lnum2, cnum2] =  searchpairpos('\C' . open_pat, '',
              \ '\C\%(\%'. lnum . 'l\%' . cnum . 'c\)\@!'
              \ . close_pat, 'bnW', 'latex#util#in_comment()',
              \ line('w0')*(a:mode =~ 'h\|i'), 200)
        if a:mode =~ 'h\|i'
          execute '2match MatchParen /\%(\%' . lnum2 . 'l\%' . cnum2
                \ . 'c' . g:latex_motion_open_pats[i] . '\|\%'
                \ . lnum . 'l\%' . cnum . 'c'
                \ . g:latex_motion_close_pats[i] . '\)/'
        elseif a:mode =~ 'n\|v\|o'
          call cursor(lnum2,cnum2)
        endif
        break
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

" vim:fdm=marker:ff=unix
