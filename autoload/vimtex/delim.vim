" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#delim#init_buffer() abort " {{{1
  nnoremap <silent><buffer> <plug>(vimtex-delim-toggle-modifier)
        \ :<c-u>call <sid>operator_setup('toggle_modifier_next')
        \ <bar> normal! <c-r>=v:count ? v:count : ''<cr>g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-delim-toggle-modifier-reverse)
        \ :<c-u>call <sid>operator_setup('toggle_modifier_prev')
        \ <bar> normal! <c-r>=v:count ? v:count : ''<cr>g@l<cr>

  xnoremap <silent><buffer> <plug>(vimtex-delim-toggle-modifier)
        \ :<c-u>call vimtex#delim#toggle_modifier_visual()<cr>

  xnoremap <silent><buffer> <plug>(vimtex-delim-toggle-modifier-reverse)
        \ :<c-u>call vimtex#delim#toggle_modifier_visual({'dir': -1})<cr>

  nnoremap <silent><buffer> <plug>(vimtex-delim-change-math)
        \ :<c-u>call <sid>operator_setup('change')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-delim-delete)
        \ :<c-u>call <sid>operator_setup('delete')<bar>normal! g@l<cr>

  inoremap <silent><buffer> <plug>(vimtex-delim-close)
        \ <c-r>=vimtex#delim#close()<cr>
endfunction

" }}}1

function! vimtex#delim#close() abort " {{{1
  let l:save_pos = vimtex#pos#get_cursor()
  let l:posval_cursor = vimtex#pos#val(l:save_pos)
  let l:posval_current = l:posval_cursor
  let l:posval_last = l:posval_cursor + 1

  while l:posval_current < l:posval_last
    let l:open  = vimtex#delim#get_prev('all', 'open',
          \ { 'syn_exclude' : 'texComment' })
    if empty(l:open) || get(l:open, 'name', '') ==# 'document'
      break
    endif

    let l:close = vimtex#delim#get_matching(l:open)
    if empty(l:close.match)
      call vimtex#pos#set_cursor(l:save_pos)
      return l:open.corr
    endif

    let l:posval_last = l:posval_current
    let l:posval_current = vimtex#pos#val(l:open)
    let l:posval_try = vimtex#pos#val(l:close) + strlen(l:close.match)
    if l:posval_current != l:posval_cursor
          \ && l:posval_try > l:posval_cursor
      call vimtex#pos#set_cursor(l:save_pos)
      return l:open.corr
    endif

    call vimtex#pos#set_cursor(vimtex#pos#prev(l:open))
  endwhile

  call vimtex#pos#set_cursor(l:save_pos)
  return ''
endfunction

" }}}1
function! vimtex#delim#toggle_modifier(...) abort " {{{1
  let l:args = a:0 > 0 ? a:1 : {}
  call extend(l:args, {
      \ 'count': v:count1,
      \ 'dir': 1,
      \ 'repeat': 1,
      \ 'openclose': [],
      \ }, 'keep')

  let [l:open, l:close] = !empty(l:args.openclose)
        \ ? l:args.openclose
        \ : vimtex#delim#get_surrounding('delim_modq_math')
  if empty(l:open) | return | endif

  let l:direction = l:args.dir < 0 ? -l:args.count : l:args.count

  let newmods = ['', '']
  let modlist = [['', '']] + get(g:, 'vimtex_delim_toggle_mod_list',
        \ [['\left', '\right']])
  let n = len(modlist)
  for i in range(n)
    let j = (i + l:direction) % n
    if l:open.mod ==# modlist[i][0]
      let newmods = modlist[j]
      break
    endif
  endfor

  let line = getline(l:open.lnum)
  let line = strpart(line, 0, l:open.cnum - 1)
        \ . newmods[0]
        \ . strpart(line, l:open.cnum + len(l:open.mod) - 1)
  call setline(l:open.lnum, line)

  let l:cnum = l:close.cnum
  if l:open.lnum == l:close.lnum
    let n = len(newmods[0]) - len(l:open.mod)
    let l:cnum += n
    let pos = vimtex#pos#get_cursor()
    if pos[2] > l:open.cnum + len(l:open.mod)
      let pos[2] += n
      call vimtex#pos#set_cursor(pos)
    endif
  endif

  let line = getline(l:close.lnum)
  let line = strpart(line, 0, l:cnum - 1)
        \ . newmods[1]
        \ . strpart(line, l:cnum + len(l:close.mod) - 1)
  call setline(l:close.lnum, line)

  return newmods
endfunction

" }}}1
function! vimtex#delim#toggle_modifier_visual(...) abort " {{{1
  let l:args = a:0 > 0 ? a:1 : {}
  call extend(l:args, {
      \ 'count': v:count1,
      \ 'dir': 1,
      \ 'reselect': 1,
      \ }, 'keep')

  let l:save_pos = vimtex#pos#get_cursor()
  let l:start_pos = getpos("'<")
  let l:end_pos = getpos("'>")
  let l:end_pos_val = vimtex#pos#val(l:end_pos) + 1000
  let l:cur_pos = l:start_pos

  "
  " Check if selection is swapped
  "
  let l:end_pos[1] += 1
  call setpos("'>", l:end_pos)
  let l:end_pos[1] -= 1
  normal! gv
  let l:swapped = l:start_pos != getpos("'<")

  "
  " First we generate a stack of all delimiters that should be toggled
  "
  let l:stack = []
  while vimtex#pos#val(l:cur_pos) < l:end_pos_val
    call vimtex#pos#set_cursor(l:cur_pos)
    let l:open = vimtex#delim#get_next('delim_modq_math', 'open')
    if empty(l:open) | break | endif

    if vimtex#pos#val(l:open) >= l:end_pos_val
      break
    endif

    let l:close = vimtex#delim#get_matching(l:open)
    if !empty(get(l:close, 'match'))

      if l:end_pos_val >= vimtex#pos#val(l:close) + strlen(l:close.match) - 1
        let l:newmods = vimtex#delim#toggle_modifier({
              \ 'repeat': 0,
              \ 'count': l:args.count,
              \ 'dir': l:args.dir,
              \ 'openclose': [l:open, l:close],
              \ })

        let l:col_diff  = (l:open.lnum == l:end_pos[1])
              \ ? strlen(newmods[0]) - strlen(l:open.mod) : 0
        let l:col_diff += (l:close.lnum == l:end_pos[1])
              \ ? strlen(newmods[1]) - strlen(l:close.mod) : 0

        if l:col_diff != 0
          let l:end_pos[2] += l:col_diff
          let l:end_pos_val += l:col_diff
        endif
      endif
    endif

    let l:cur_pos = vimtex#pos#next(l:open)
  endwhile

  "
  " Finally we return to original position and reselect the region
  "
  call setpos(l:swapped? "'>" : "'<", l:start_pos)
  call setpos(l:swapped? "'<" : "'>", l:end_pos)
  call vimtex#pos#set_cursor(l:save_pos)
  if l:args.reselect
    normal! gv
  endif
endfunction

" }}}1

function! vimtex#delim#change(...) abort " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding('delim_math')
  if empty(l:open) | return | endif

  if a:0 > 0
    let l:new_delim = a:1
  else
    let l:name = get(l:open, 'name', l:open.is_open
          \ ? l:open.match . ' ... ' . l:open.corr
          \ : l:open.match . ' ... ' . l:open.corr)

    let l:new_delim = vimtex#echo#input({
          \ 'info' :
          \   ['Change surrounding delimiter: ', ['VimtexWarning', l:name]],
          \ 'complete' : 'customlist,vimtex#delim#change_input_complete',
          \})
  endif

  if empty(l:new_delim) | return | endif
  call vimtex#delim#change_with_args(l:open, l:close, l:new_delim)
endfunction

" }}}1
function! vimtex#delim#change_with_args(open, close, new) abort " {{{1
  "
  " Set target environment
  "
  if a:new ==# ''
    let [l:beg, l:end] = ['', '']
  elseif index(['{', '}'], a:new) >= 0
    let [l:beg, l:end] = ['{', '}']
  else
    let l:side = a:new =~# g:vimtex#delim#re.delim_math.close
    let l:index = index(map(copy(g:vimtex#delim#lists.delim_math.name),
          \   'v:val[' . l:side . ']'),
          \ a:new)
    if l:index >= 0
      let [l:beg, l:end] = g:vimtex#delim#lists.delim_math.name[l:index]
    else
      let [l:beg, l:end] = [a:new, a:new]
    endif
  endif

  let l:line = getline(a:open.lnum)
  call setline(a:open.lnum,
        \   strpart(l:line, 0, a:open.cnum-1)
        \ . l:beg
        \ . strpart(l:line, a:open.cnum + len(a:open.match) - 1))

  let l:c1 = a:close.cnum
  let l:c2 = a:close.cnum + len(a:close.match) - 1
  if a:open.lnum == a:close.lnum
    let n = len(l:beg) - len(a:open.match)
    let l:c1 += n
    let l:c2 += n
    let pos = vimtex#pos#get_cursor()
    if pos[2] > a:open.cnum + len(a:open.match) - 1
      let pos[2] += n
      call vimtex#pos#set_cursor(pos)
    endif
  endif

  let l:line = getline(a:close.lnum)
  call setline(a:close.lnum,
        \ strpart(l:line, 0, l:c1-1) . l:end . strpart(l:line, l:c2))
endfunction

" }}}1
function! vimtex#delim#change_input_complete(lead, cmdline, pos) abort " {{{1
  let l:all = deepcopy(g:vimtex#delim#lists.delim_all.name)
  let l:open = map(copy(l:all), 'v:val[0]')
  let l:close = map(copy(l:all), 'v:val[1]')

  let l:lead_re = escape(a:lead, '\$[]')
  return filter(l:open + l:close, 'v:val =~# ''^' . l:lead_re . '''')
endfunction

" }}}1
function! vimtex#delim#delete() abort " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding('delim_modq_math')
  if empty(l:open) | return | endif

  call vimtex#delim#change_with_args(l:open, l:close, '')
endfunction

" }}}1

function! vimtex#delim#get_next(type, side, ...) abort " {{{1
  return s:get_delim(extend({
        \ 'direction' : 'next',
        \ 'type' : a:type,
        \ 'side' : a:side,
        \}, get(a:, '1', {})))
endfunction

" }}}1
function! vimtex#delim#get_prev(type, side, ...) abort " {{{1
  return s:get_delim(extend({
        \ 'direction' : 'prev',
        \ 'type' : a:type,
        \ 'side' : a:side,
        \}, get(a:, '1', {})))
endfunction

" }}}1
function! vimtex#delim#get_current(type, side, ...) abort " {{{1
  return s:get_delim(extend({
        \ 'direction' : 'current',
        \ 'type' : a:type,
        \ 'side' : a:side,
        \}, get(a:, '1', {})))
endfunction

" }}}1
function! vimtex#delim#get_matching(delim) abort " {{{1
  if empty(a:delim) || !has_key(a:delim, 'lnum') | return {} | endif

  "
  " Get the matching position
  "
  let l:save_pos = vimtex#pos#get_cursor()
  call vimtex#pos#set_cursor(a:delim)
  let [l:match, l:lnum, l:cnum] = a:delim.get_matching()
  call vimtex#pos#set_cursor(l:save_pos)

  "
  " Create the match result
  "
  let l:matching = deepcopy(a:delim)
  let l:matching.lnum = l:lnum
  let l:matching.cnum = l:cnum
  let l:matching.match = l:match
  let l:matching.corr  = a:delim.match
  let l:matching.side = a:delim.is_open ? 'close' : 'open'
  let l:matching.is_open = !a:delim.is_open
  let l:matching.re.corr = a:delim.re.this
  let l:matching.re.this = a:delim.re.corr

  if l:matching.type ==# 'delim'
    let l:matching.corr_delim = a:delim.delim
    let l:matching.corr_mod = a:delim.mod
    let l:matching.delim = a:delim.corr_delim
    let l:matching.mod = a:delim.corr_mod
  elseif l:matching.type ==# 'env' && has_key(l:matching, 'name')
    if l:matching.is_open
      let l:matching.env_cmd = vimtex#cmd#get_at(l:lnum, l:cnum)
    else
      unlet l:matching.env_cmd
    endif
  endif

  return l:matching
endfunction

" }}}1
function! vimtex#delim#get_surrounding(type) abort " {{{1
  let l:save_pos = vimtex#pos#get_cursor()
  let l:pos_val_cursor = vimtex#pos#val(l:save_pos)
  let l:pos_val_last = l:pos_val_cursor
  let l:pos_val_open = l:pos_val_cursor - 1

  while l:pos_val_open < l:pos_val_last
    let l:open = vimtex#delim#get_prev(a:type, 'open')
    if empty(l:open) | break | endif

    let l:close = vimtex#delim#get_matching(l:open)
    let l:pos_val_try = vimtex#pos#val(l:close) + strlen(l:close.match) - 1
    if l:pos_val_try >= l:pos_val_cursor
      call vimtex#pos#set_cursor(l:save_pos)
      return [l:open, l:close]
    else
      call vimtex#pos#set_cursor(vimtex#pos#prev(l:open))
      let l:pos_val_last = l:pos_val_open
      let l:pos_val_open = vimtex#pos#val(l:open)
    endif
  endwhile

  call vimtex#pos#set_cursor(l:save_pos)
  return [{}, {}]
endfunction

" }}}1

function! s:operator_setup(operator) abort " {{{1
  let &opfunc = s:snr() . 'operator_function'

  let s:operator = a:operator

  " Ask for user input if necessary/relevant
  if s:operator ==# 'change'
    let [l:open, l:close] = vimtex#delim#get_surrounding('delim_math')
    if empty(l:open) | return | endif

    let l:name = get(l:open, 'name', l:open.is_open
          \ ? l:open.match . ' ... ' . l:open.corr
          \ : l:open.match . ' ... ' . l:open.corr)

    let s:operator_delim = vimtex#echo#input({
          \ 'info' :
          \   ['Change surrounding delimiter: ', ['VimtexWarning', l:name]],
          \ 'complete' : 'customlist,vimtex#delim#change_input_complete',
          \})
  endif
endfunction

" }}}1
function! s:operator_function(_) abort " {{{1
  let l:delim = get(s:, 'operator_delim', '')

  execute 'call vimtex#delim#' . {
        \ 'change': 'change(l:delim)',
        \ 'delete': 'delete()',
        \ 'toggle_modifier_next': 'toggle_modifier()',
        \ 'toggle_modifier_prev': "toggle_modifier({'dir': -1})",
        \}[s:operator]
endfunction

" }}}1
function! s:snr() abort " {{{1
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

" }}}1
"

function! s:get_delim(opts) abort " {{{1
  "
  " Arguments:
  "   opts = {
  "     'direction'   :  next
  "                      prev
  "                      current
  "     'type'        :  env_tex
  "                      env_math
  "                      env_all
  "                      delim_tex
  "                      delim_math
  "                      delim_modq_math (possibly modified math delimiter)
  "                      delim_mod_math  (modified math delimiter)
  "                      delim_all
  "                      all
  "     'side'        :  open
  "                      close
  "                      both
  "     'syn_exclude' :  Don't match in given syntax
  "  }
  "
  " Returns:
  "   delim = {
  "     type    : env | delim
  "     side    : open | close
  "     name    : name of environment [only for type env]
  "     lnum    : number
  "     cnum    : number
  "     match   : unparsed matched delimiter
  "     corr    : corresponding delimiter
  "     re : {
  "       open  : regexp for the opening part
  "       close : regexp for the closing part
  "     }
  "     remove  : method to remove the delimiter
  "   }
  "
  let l:save_pos = vimtex#pos#get_cursor()
  let l:re = g:vimtex#delim#re[a:opts.type][a:opts.side]
  while 1
    let [l:lnum, l:cnum] = a:opts.direction ==# 'next'
          \ ? searchpos(l:re, 'cnW', line('.') + g:vimtex_delim_stopline)
          \ : a:opts.direction ==# 'prev'
          \   ? searchpos(l:re, 'bcnW', max([line('.') - g:vimtex_delim_stopline, 1]))
          \   : searchpos(l:re, 'bcnW', line('.'))
    if l:lnum == 0 | break | endif

    if has_key(a:opts, 'syn_exclude')
          \ && vimtex#util#in_syntax(a:opts.syn_exclude, l:lnum, l:cnum)
      call vimtex#pos#set_cursor(vimtex#pos#prev(l:lnum, l:cnum))
      continue
    endif

    break
  endwhile
  call vimtex#pos#set_cursor(l:save_pos)

  let l:match = matchstr(getline(l:lnum), '^' . l:re, l:cnum-1)

  if a:opts.direction ==# 'current'
        \ && l:cnum + strlen(l:match) + (mode() ==# 'i' ? 1 : 0) <= col('.')
    let l:match = ''
    let l:lnum = 0
    let l:cnum = 0
  endif

  let l:result = {
        \ 'type' : '',
        \ 'lnum' : l:lnum,
        \ 'cnum' : l:cnum,
        \ 'match' : l:match,
        \ 'remove' : function('s:delim_remove'),
        \}

  for l:type in s:types
    if l:match =~# '^' . l:type.re
      let l:result = extend(
            \ l:type.parser(l:match, l:lnum, l:cnum,
            \               a:opts.side, a:opts.type, a:opts.direction),
            \ l:result, 'keep')
      break
    endif
  endfor

  return empty(l:result.type) ? {} : l:result
endfunction

" }}}1

function! s:delim_remove() dict abort " {{{1
  let l:line = getline(self.lnum)
  let l:l1 = strpart(l:line, 0, self.cnum-1)
  let l:l2 = strpart(l:line, self.cnum + strlen(self.match) - 1)

  if self.side ==# 'close'
    let l:l1 = substitute(l:l1, '\s\+$', '', '')
    if empty(l:l1)
      let l:l2 = substitute(l:l2, '^\s\+', '', '')
    endif
  else
    let l:l2 = substitute(l:l2, '^\s\+', '', '')
    if empty(l:l2)
      let l:l1 = substitute(l:l1, '\s\+$', '', '')
    endif
  endif

  call setline(self.lnum, l:l1 . l:l2)
endfunction

" }}}1

function! s:parser_env(match, lnum, cnum, ...) abort " {{{1
  let result = {}

  let result.type = 'env'
  let result.name = matchstr(a:match, '{\zs\k*\ze\*\?}')
  let result.starred = match(a:match, '\*}$') > 0
  let result.side = a:match =~# '\\begin' ? 'open' : 'close'
  let result.is_open = result.side ==# 'open'
  let result.get_matching = function('s:get_matching_env')

  let result.gms_flags = result.is_open ? 'nW' : 'bnW'
  let result.gms_stopline = result.is_open
        \ ? line('.') + g:vimtex_delim_stopline
        \ : max([1, line('.') - g:vimtex_delim_stopline])

  if result.is_open
    let result.env_cmd = vimtex#cmd#get_at(a:lnum, a:cnum)
  endif

  let result.corr = result.is_open
        \ ? substitute(a:match, 'begin', 'end', '')
        \ : substitute(a:match, 'end', 'begin', '')

  let result.re = {
        \ 'open' : '\m\\begin\s*{' . result.name . '\*\?}',
        \ 'close' : '\m\\end\s*{' . result.name . '\*\?}',
        \}

  let result.re.this = result.is_open ? result.re.open  : result.re.close
  let result.re.corr = result.is_open ? result.re.close : result.re.open

  return result
endfunction

" }}}1
function! s:parser_tex(match, lnum, cnum, side, type, direction) abort " {{{1
  "
  " TeX shorthand are these
  "
  "   $ ... $   (inline math)
  "   $$ ... $$ (displayed equations)
  "
  " The notation does not provide the delimiter side directly, which provides
  " a slight problem. However, we can utilize the syntax information to parse
  " the side.
  "
  let result = {}
  let result.type = 'env'
  let result.corr = a:match
  let result.re = {
        \ 'this'  : '\m' . escape(a:match, '$'),
        \ 'corr'  : '\m' . escape(a:match, '$'),
        \ 'open'  : '\m' . escape(a:match, '$'),
        \ 'close' : '\m' . escape(a:match, '$'),
        \}
  let result.side = vimtex#util#in_syntax(
        \   (a:match ==# '$' ? 'texMathZoneX' : 'texMathZoneY'),
        \   a:lnum, a:cnum+1)
        \ ? 'open' : 'close'
  let result.is_open = result.side ==# 'open'
  let result.get_matching = function('s:get_matching_tex')
  let result.gms_flags = result.is_open ? 'nW' : 'bnW'
  let result.gms_stopline = result.is_open
        \ ? line('.') + g:vimtex_delim_stopline
        \ : max([1, line('.') - g:vimtex_delim_stopline])

  if (a:side !=# 'both') && (a:side !=# result.side)
    "
    " The current match ($ or $$) is not the correct side, so we must
    " continue the search recursively. We do this by changing the cursor
    " position, since the function searchpos relies on the current cursor
    " position.
    "
    let l:save_pos = vimtex#pos#get_cursor()

    " Move the cursor
    call vimtex#pos#set_cursor(a:direction ==# 'next'
          \ ? vimtex#pos#next(a:lnum, a:cnum)
          \ : vimtex#pos#prev(a:lnum, a:cnum))

    " Get new result
    let result = s:get_delim({
          \ 'direction' : a:direction,
          \ 'type' : a:type,
          \ 'side' : a:side,
          \})

    " Restore the cursor
    call vimtex#pos#set_cursor(l:save_pos)
  endif

  return result
endfunction

" }}}1
function! s:parser_latex(match, lnum, cnum, ...) abort " {{{1
  let result = {}

  let result.type = 'env'
  let result.side = a:match =~# '\\(\|\\\[' ? 'open' : 'close'
  let result.is_open = result.side ==# 'open'
  let result.get_matching = function('s:get_matching_latex')
  let result.gms_flags = result.is_open ? 'nW' : 'bnW'
  let result.gms_stopline = result.is_open
        \ ? line('.') + g:vimtex_delim_stopline
        \ : max([1, line('.') - g:vimtex_delim_stopline])

  let result.corr = result.is_open
        \ ? substitute(substitute(a:match, '\[', ']', ''), '(', ')', '')
        \ : substitute(substitute(a:match, '\]', '[', ''), ')', '(', '')

  let result.re = {
        \ 'open'  : a:match =~# '\\(\|\\)' ? '\m\\(' : '\m\\\[',
        \ 'close' : a:match =~# '\\(\|\\)' ? '\m\\)' : '\m\\\]',
        \}

  let result.re.this = result.is_open ? result.re.open  : result.re.close
  let result.re.corr = result.is_open ? result.re.close : result.re.open

  return result
endfunction

" }}}1
function! s:parser_delim(match, lnum, cnum, ...) abort " {{{1
  let result = {}
  let result.type = 'delim'
  let result.side =
        \ a:match =~# g:vimtex#delim#re.delim_all.open ? 'open' : 'close'
  let result.is_open = result.side ==# 'open'
  let result.get_matching = function('s:get_matching_delim')
  let result.gms_flags = result.is_open ? 'nW' : 'bnW'
  let result.gms_stopline = result.is_open
        \ ? line('.') + g:vimtex_delim_stopline
        \ : max([1, line('.') - g:vimtex_delim_stopline])

  "
  " Find corresponding delimiter and the regexps
  "
  if a:match =~# '^' . g:vimtex#delim#re.mods.both
    let m1 = matchstr(a:match, '^' . g:vimtex#delim#re.mods.both)
    let d1 = substitute(strpart(a:match, len(m1)), '^\s*', '', '')
    let s1 = !result.is_open
    let re1 = s:parser_delim_get_regexp(m1, s1, 'mods')
          \  . '\s*' . s:parser_delim_get_regexp(d1, s1, 'delim_math')

    let m2 = s:parser_delim_get_corr(m1, 'mods')
    let d2 = s:parser_delim_get_corr(d1, 'delim_math')
    let s2 = result.is_open
    let re2 = s:parser_delim_get_regexp(m2, s2, 'mods') . '\s*'
          \ . (m1 =~# '\\\%(left\|right\)'
          \   ? '\%(' . s:parser_delim_get_regexp(d2, s2, 'delim_math') . '\|\.\)'
          \   : s:parser_delim_get_regexp(d2, s2, 'delim_math'))
  else
    let d1 = a:match
    let m1 = ''
    let re1 = s:parser_delim_get_regexp(a:match, !result.is_open)

    let d2 = s:parser_delim_get_corr(a:match)
    let m2 = ''
    let re2 = s:parser_delim_get_regexp(d2, result.is_open)
  endif

  let result.delim = d1
  let result.mod = m1
  let result.corr = m2 . d2
  let result.corr_delim = d2
  let result.corr_mod = m2
  let result.re = {
        \ 'this'  : re1,
        \ 'corr'  : re2,
        \ 'open'  : result.is_open ? re1 : re2,
        \ 'close' : result.is_open ? re2 : re1,
        \}

  return result
endfunction

" }}}1
function! s:parser_delim_unmatched(match, lnum, cnum, ...) abort " {{{1
  let result = {}
  let result.type = 'delim'
  let result.side =
        \ a:match =~# g:vimtex#delim#re.delim_all.open ? 'open' : 'close'
  let result.is_open = result.side ==# 'open'
  let result.get_matching = function('s:get_matching_delim_unmatched')
  let result.gms_flags = result.is_open ? 'nW' : 'bnW'
  let result.gms_stopline = result.is_open
        \ ? line('.') + g:vimtex_delim_stopline
        \ : max([1, line('.') - g:vimtex_delim_stopline])
  let result.delim = '.'
  let result.corr_delim = '.'

  "
  " Find corresponding delimiter and the regexps
  "
  if result.is_open
    let result.mod = '\left'
    let result.corr_mod = '\right'
    let result.corr = '\right.'
    let re1 = '\\left\s*\.'
    let re2 = s:parser_delim_get_regexp('\right', 1, 'mods')
          \  . '\s*' . s:parser_delim_get_regexp('.', 0)
  else
    let result.mod = '\right'
    let result.corr_mod = '\left'
    let result.corr = '\left.'
    let re1 = '\\right\s*\.'
    let re2 = s:parser_delim_get_regexp('\left', 0, 'mods')
          \  . '\s*' . s:parser_delim_get_regexp('.', 0)
  endif

  let result.re = {
        \ 'this'  : re1,
        \ 'corr'  : re2,
        \ 'open'  : result.is_open ? re1 : re2,
        \ 'close' : result.is_open ? re2 : re1,
        \}

  return result
endfunction

" }}}1
function! s:parser_delim_get_regexp(delim, side, ...) abort " {{{1
  let l:type = a:0 > 0 ? a:1 : 'delim_all'

  " First check for unmatched math delimiter
  if a:delim ==# '.'
    return g:vimtex#delim#re.delim_math[a:side ? 'open' : 'close']
  endif

  " Next check normal delimiters
  let l:index = index(map(copy(g:vimtex#delim#lists[l:type].name),
        \   'v:val[' . a:side . ']'),
        \ a:delim)
  return l:index >= 0
        \ ? g:vimtex#delim#lists[l:type].re[l:index][a:side]
        \ : ''
endfunction

" }}}1
function! s:parser_delim_get_corr(delim, ...) abort " {{{1
  let l:type = a:0 > 0 ? a:1 : 'delim_all'

  for l:pair in g:vimtex#delim#lists[l:type].name
    if a:delim ==# l:pair[0]
      return l:pair[1]
    elseif a:delim ==# l:pair[1]
      return l:pair[0]
    endif
  endfor
endfunction

" }}}1

function! s:get_matching_env() dict abort " {{{1
  try
    let [lnum, cnum] = searchpairpos(self.re.open, '', self.re.close,
          \ self.gms_flags, '', 0, s:get_timeout())
  catch /E118/
    let [lnum, cnum] = searchpairpos(self.re.open, '', self.re.close,
          \ self.gms_flags, '', self.gms_stopline)
  endtry

  let match = matchstr(getline(lnum), '^' . self.re.corr, cnum-1)
  return [match, lnum, cnum]
endfunction

" }}}1
function! s:get_matching_tex() dict abort " {{{1
  let [lnum, cnum] = searchpos(self.re.corr, self.gms_flags, self.gms_stopline)

  let match = matchstr(getline(lnum), '^' . self.re.corr, cnum-1)
  return [match, lnum, cnum]
endfunction

" }}}1
function! s:get_matching_latex() dict abort " {{{1
  let [lnum, cnum] = searchpos(self.re.corr, self.gms_flags, self.gms_stopline)

  let match = matchstr(getline(lnum), '^' . self.re.corr, cnum-1)
  return [match, lnum, cnum]
endfunction

" }}}1
function! s:get_matching_delim() dict abort " {{{1
  try
    let [lnum, cnum] = searchpairpos(self.re.open, '', self.re.close,
          \ self.gms_flags,
          \ 'synIDattr(synID(line("."), col("."), 0), "name") =~? "comment"',
          \ 0, s:get_timeout())
  catch /E118/
    let [lnum, cnum] = searchpairpos(self.re.open, '', self.re.close,
          \ self.gms_flags,
          \ 'synIDattr(synID(line("."), col("."), 0), "name") =~? "comment"',
          \ self.gms_stopline)
  endtry

  let match = matchstr(getline(lnum), '^' . self.re.corr, cnum-1)
  return [match, lnum, cnum]
endfunction

" }}}1
function! s:get_matching_delim_unmatched() dict abort " {{{1
  let tries = 0
  let misses = []
  while 1
    try
      let [lnum, cnum] = searchpairpos(self.re.open, '', self.re.close,
            \ self.gms_flags,
            \ 'index(misses, [line("."), col(".")]) >= 0',
            \ 0, s:get_timeout())
    catch /E118/
      let [lnum, cnum] = searchpairpos(self.re.open, '', self.re.close,
            \ self.gms_flags,
            \ 'index(misses, [line("."), col(".")]) >= 0',
            \ self.gms_stopline)
    endtry
    let match = matchstr(getline(lnum), '^' . self.re.corr, cnum-1)
    if lnum == 0 | break | endif

    let cand = vimtex#delim#get_matching(extend({
          \ 'type' : '',
          \ 'lnum' : lnum,
          \ 'cnum' : cnum,
          \ 'match' : match,
          \}, s:parser_delim(match, lnum, cnum)))

    if !empty(cand) && [self.lnum, self.cnum] == [cand.lnum, cand.cnum]
      return [match, lnum, cnum]
    else
      let misses += [[lnum, cnum]]
      let tries += 1
      if tries == 10 | break | endif
    endif
  endwhile

  return ['', 0, 0]
endfunction

" }}}1

function! s:get_timeout() abort " {{{1
  return (empty(v:insertmode) ? mode() : v:insertmode) ==# 'i'
        \ ? g:vimtex_delim_insert_timeout
        \ : g:vimtex_delim_timeout
endfunction

" }}}1


function! s:init_delim_lists() abort " {{{1
  " Define the default value
  let l:lists = {
        \ 'env_tex' : {
        \   'name' : [['begin', 'end']],
        \   're' : [['\\begin\s*{[^}]*}', '\\end\s*{[^}]*}']],
        \ },
        \ 'env_math' : {
        \   'name' : [
        \     ['\(', '\)'],
        \     ['\[', '\]'],
        \     ['$$', '$$'],
        \     ['$', '$'],
        \   ],
        \   're' : [
        \     ['\\(', '\\)'],
        \     ['\\\@<!\\\[', '\\\]'],
        \     ['\$\$', '\$\$'],
        \     ['\$', '\$'],
        \   ],
        \ },
        \ 'delim_tex' : {
        \   'name' : [
        \     ['[', ']'],
        \     ['{', '}'],
        \   ]
        \ },
        \ 'delim_math' : {
        \   'name' : [
        \     ['(', ')'],
        \     ['[', ']'],
        \     ['\{', '\}'],
        \     ['\langle', '\rangle'],
        \     ['\lbrace', '\rbrace'],
        \     ['\lvert', '\rvert'],
        \     ['\lVert', '\rVert'],
        \     ['\lfloor', '\rfloor'],
        \     ['\lceil', '\rceil'],
        \     ['\ulcorner', '\urcorner'],
        \   ]
        \ },
        \ 'mods' : {
        \   'name' : [
        \     ['\left', '\right'],
        \     ['\bigl', '\bigr'],
        \     ['\Bigl', '\Bigr'],
        \     ['\biggl', '\biggr'],
        \     ['\Biggl', '\Biggr'],
        \     ['\big', '\big'],
        \     ['\Big', '\Big'],
        \     ['\bigg', '\bigg'],
        \     ['\Bigg', '\Bigg'],
        \   ],
        \   're' : [
        \     ['\\left', '\\right'],
        \     ['\\bigl', '\\bigr'],
        \     ['\\Bigl', '\\Bigr'],
        \     ['\\biggl', '\\biggr'],
        \     ['\\Biggl', '\\Biggr'],
        \     ['\\big\>', '\\big\>'],
        \     ['\\Big\>', '\\Big\>'],
        \     ['\\bigg\>', '\\bigg\>'],
        \     ['\\Bigg\>', '\\Bigg\>'],
        \   ]
        \ },
        \}

  " Get user defined lists
  call extend(l:lists, get(g:, 'vimtex_delim_list', {}))

  " Generate corresponding regexes if necessary
  for l:type in values(l:lists)
    if !has_key(l:type, 're') && has_key(l:type, 'name')
      let l:type.re = map(deepcopy(l:type.name),
            \ 'map(v:val, ''escape(v:val, ''''\$[]'''')'')')
    endif
  endfor

  " Generate combined lists
  let l:lists.env_all = {}
  let l:lists.delim_all = {}
  let l:lists.all = {}
  for k in ['name', 're']
    let l:lists.env_all[k] = l:lists.env_tex[k] + l:lists.env_math[k]
    let l:lists.delim_all[k] = l:lists.delim_math[k] + l:lists.delim_tex[k]
    let l:lists.all[k] = l:lists.env_all[k] + l:lists.delim_all[k]
  endfor

  return l:lists
endfunction

" }}}1
function! s:init_delim_regexes() abort " {{{1
  let l:re = {}
  let l:re.env_all = {}
  let l:re.delim_all = {}
  let l:re.all = {}

  let l:re.env_tex = s:init_delim_regexes_generator('env_tex')
  let l:re.env_math = s:init_delim_regexes_generator('env_math')
  let l:re.delim_tex = s:init_delim_regexes_generator('delim_tex')
  let l:re.delim_math = s:init_delim_regexes_generator('delim_math')
  let l:re.mods = s:init_delim_regexes_generator('mods')

  let l:o = join(map(copy(g:vimtex#delim#lists.delim_math.re), 'v:val[0]'), '\|')
  let l:c = join(map(copy(g:vimtex#delim#lists.delim_math.re), 'v:val[1]'), '\|')

  "
  " Matches modified math delimiters
  "
  let l:re.delim_mod_math = {
        \ 'open' : '\%(\%(' . l:re.mods.open . '\)\)\s*\%('
        \   . l:o . '\)\|\\left\s*\.',
        \ 'close' : '\%(\%(' . l:re.mods.close . '\)\)\s*\%('
        \   . l:c . '\)\|\\right\s*\.',
        \ 'both' : '\%(\%(' . l:re.mods.both . '\)\)\s*\%('
        \   . l:o . '\|' . l:c . '\)\|\\\%(left\|right\)\s*\.',
        \}

  "
  " Matches possibly modified math delimiters
  "
  let l:re.delim_modq_math = {
        \ 'open' : '\%(\%(' . l:re.mods.open . '\)\s*\)\?\%('
        \   . l:o . '\)\|\\left\s*\.',
        \ 'close' : '\%(\%(' . l:re.mods.close . '\)\s*\)\?\%('
        \   . l:c . '\)\|\\right\s*\.',
        \ 'both' : '\%(\%(' . l:re.mods.both . '\)\s*\)\?\%('
        \   . l:o . '\|' . l:c . '\)\|\\\%(left\|right\)\s*\.',
        \}

  for k in ['open', 'close', 'both']
    let l:re.env_all[k] = l:re.env_tex[k] . '\|' . l:re.env_math[k]
    let l:re.delim_all[k] = l:re.delim_modq_math[k] . '\|' . l:re.delim_tex[k]
    let l:re.all[k] = l:re.env_all[k] . '\|' . l:re.delim_all[k]
  endfor

  "
  " Be explicit about regex mode (set magic mode)
  "
  for l:type in values(l:re)
    for l:side in ['open', 'close', 'both']
      let l:type[l:side] = '\m' . l:type[l:side]
    endfor
  endfor

  return l:re
endfunction

" }}}1
function! s:init_delim_regexes_generator(list_name) abort " {{{1
  let l:list = g:vimtex#delim#lists[a:list_name]
  let l:open = join(map(copy(l:list.re), 'v:val[0]'), '\|')
  let l:close = join(map(copy(l:list.re), 'v:val[1]'), '\|')

  return {
        \ 'open' : '\%(' . l:open . '\)',
        \ 'close' : '\%(' . l:close . '\)',
        \ 'both' : '\%(' . l:open . '\|' . l:close . '\)'
        \}
endfunction

  " }}}1


" {{{1 Initialize module

"
" Initialize lists of delimiter pairs and regexes
"
let g:vimtex#delim#lists = s:init_delim_lists()
let g:vimtex#delim#re = s:init_delim_regexes()

"
" Initialize script variables
"
let s:types = [
      \ {
      \   're' : '\\\%(begin\|end\)\>',
      \   'parser' : function('s:parser_env'),
      \ },
      \ {
      \   're' : '\$\$\?',
      \   'parser' : function('s:parser_tex'),
      \ },
      \ {
      \   're' : '\\\%((\|)\|\[\|\]\)',
      \   'parser' : function('s:parser_latex'),
      \ },
      \ {
      \   're' : '\\\%(left\|right\)\s*\.',
      \   'parser' : function('s:parser_delim_unmatched'),
      \ },
      \ {
      \   're' : g:vimtex#delim#re.delim_all.both,
      \   'parser' : function('s:parser_delim'),
      \ },
      \]

" }}}1
