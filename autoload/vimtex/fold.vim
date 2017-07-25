" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#init_buffer() " {{{1
  " b:vimtex_fold is a dictionary used to store dynamic fold information
  " Note: We define this even if folding is disabled, because people might want
  "       to enable folding manually
  let b:vimtex_fold = {}

  if !g:vimtex_fold_enabled | return | endif
  if s:foldmethod_in_modeline() | return | endif

  " Sanity check
  if g:vimtex_fold_preamble
        \ && has_key(s:cmds, 'documentclass')
    let g:vimtex_fold_preamble = 0
    call vimtex#echo#warning('Can''t fold both preamble and documentclass!')
    call vimtex#echo#wait()
  endif

  " Set fold options
  setlocal foldmethod=expr
  setlocal foldexpr=vimtex#fold#level(v:lnum)
  setlocal foldtext=vimtex#fold#text()

  if g:vimtex_fold_manual
    " Remap zx to refresh fold levels
    nnoremap <silent><buffer> zx :call vimtex#fold#refresh('zx')<cr>
    nnoremap <silent><buffer> zX :call vimtex#fold#refresh('zX')<cr>

    " Define commands
    command! -buffer VimtexRefreshFolds call vimtex#fold#refresh('zx')

    " Set options for automatic/manual folding mode
    let s:fold_manual_id = get(s:, 'fold_manual_id', 0) + 1
    let b:fold_manual_augroup = 'vimtex_fold_' . s:fold_manual_id
    execute 'augroup' b:fold_manual_augroup
      autocmd!
      " vint: -ProhibitAutocmdWithNoGroup
      autocmd CursorMoved <buffer> call s:fold_manual_refresh()
      " vint: +ProhibitAutocmdWithNoGroup
    augroup END

    function! s:fold_manual_refresh()
      call vimtex#fold#refresh('zx')
      if exists('b:fold_manual_augroup')
        execute 'autocmd!' b:fold_manual_augroup
        execute 'augroup!' b:fold_manual_augroup
        unlet b:fold_manual_augroup
      endif
    endfunction
  endif
endfunction

" }}}1

function! vimtex#fold#refresh(map) " {{{1
  setlocal foldmethod=expr
  execute 'normal! ' . a:map
  setlocal foldmethod=manual
endfunction

" }}}1
function! vimtex#fold#level(lnum) " {{{1
  " Refresh fold levels for section commands
  call s:refresh_folded_sections()

  " Check for normal lines first (optimization)
  let line = getline(a:lnum)
  if line !~# s:folded | return '=' | endif

  " Fold preamble
  if g:vimtex_fold_preamble && line =~# '^\s*\\documentclass'
    return '>1'
  endif

  " Never fold \begin{document}
  if line =~# '^\s*\\begin\s*{\s*document\s*}'
    return '0'
  endif

  " Fold commands
  for l:cmd in s:cmds_types
    let l:value = l:cmd.level(line, a:lnum)
    if !empty(l:value) | return l:value | endif
  endfor

  " Fold chapters and sections
  for [part, level] in b:vimtex_fold.parts
    if line =~# part
      return '>' . level
    endif
  endfor

  " Fold markers
  if line =~# '\v\%.*\{\{\{'
    let s:fold_markers = 1
    return 'a1'
  elseif line =~# '\v\%\s*\}\}\}'
    let s:fold_markers = 0
    return 's1'
  endif

  " Fold long comments
  if g:vimtex_fold_comments && !get(s:, 'fold_markers')
    if line =~# '^\s*%'
      let l:next = getline(a:lnum-1) !~# '^\s*%'
      let l:prev = getline(a:lnum+1) !~# '^\s*%'
      if l:next && ! l:prev
        return 'a1'
      elseif l:prev && ! l:next
        return 's1'
      endif
    endif
  endif

  " Never fold \end{document}
  if line =~# '^\s*\\end{document}'
    return 0
  endif

  " Fold environments
  let l:value = s:fold_env.level(line, a:lnum)
  if !empty(l:value) | return l:value | endif

  " Fold environments with long options (if desired)
  let l:value = s:fold_env_options.level(line, a:lnum)
  if !empty(l:value) | return l:value | endif

  " Return foldlevel of previous line
  return '='
endfunction

" }}}1
function! vimtex#fold#text() " {{{1
  let line = getline(v:foldstart)

  " Text for marker folding
  if line =~# '\v\%\s*\{\{\{'
    return ' ' . matchstr(line, '\v\%\s*\{\{\{\s*\zs.*')
  elseif line =~# '\v\%.*\{\{\{'
    return ' ' . matchstr(line, '\v\%\s*\zs.*\ze\{\{\{')
  endif

  " Text for various folded commands
  for l:cmd in s:cmds_types
    if line =~# l:cmd.re.start
      return l:cmd.text(line)
    endif
  endfor

  " Set fold level
  let level = v:foldlevel > 1
        \ ? repeat('-', v:foldlevel-2) . g:vimtex_fold_levelmarker
        \ : ''

  if line =~# s:fold_env.re.start
    let l:value = s:fold_env.text(line, level)
    if !empty(l:value) | return l:value | endif
  endif

  if line =~# s:fold_env_options.re.start
    return s:fold_env_options.text(line)
  endif

  " Preamble, parts, sections, fakesections and comments
  let title = 'Not defined'
  let nt = 73
  let sections = '(%(sub)*%(section|paragraph)|part|chapter)'
  let secpat1 = '\v^\s*\\' . sections . '\*?\s*\{'
  let secpat2 = '\v^\s*\\' . sections . '\*?\s*\['
  if line =~# '\s*\\documentclass'
    let title = 'Preamble'
  elseif line =~# '\\frontmatter'
    let title = 'Frontmatter'
  elseif line =~# '\\mainmatter'
    let title = 'Mainmatter'
  elseif line =~# '\\backmatter'
    let title = 'Backmatter'
  elseif line =~# '\\appendix'
    let title = 'Appendix'
  elseif line =~# secpat1
    let title = s:parse_sec_title(matchstr(line, secpat1 . '\zs.*'), 0)
  elseif line =~# secpat2
    let title = s:parse_sec_title(matchstr(line, secpat2 . '\zs.*'), 1)
  elseif line =~# '\vFake' . sections
    let title = matchstr(line, '\vFake' . sections . '.*')
  elseif line =~# '^\s*%'
    let title = matchstr(line, '^\s*\zs%.*')
  endif

  " Combine level and title and return the trimmed fold text
  let text = printf('%-5s %-' . nt . 's', level, strpart(title, 0, nt))
  return substitute(text, '\s\+$', '', '') . ' '
endfunction

" }}}1

function! s:foldmethod_in_modeline() " {{{1
  let l:cursor_pos = vimtex#pos#get_cursor()
  let l:fdm_modeline = 'vim:.*\%(foldmethod\|fdm\)'

  call vimtex#pos#set_cursor(1, 1)
  let l:check_top = search(l:fdm_modeline, 'cn', &modelines)

  normal! G$
  let l:check_btm = search(l:fdm_modeline, 'b', line('$') + 1 - &modelines)

  call vimtex#pos#set_cursor(l:cursor_pos)
  return l:check_top || l:check_btm
endfunction

" }}}1
function! s:refresh_folded_sections() " {{{1
  "
  " Parse current buffer to find which sections to fold and their levels.  The
  " patterns are predefined to optimize the folding.
  "
  " We ignore top level parts such as \frontmatter, \appendix, \part, and
  " similar, unless there are at least two such commands in a document.
  "

  " Only refresh if file has been changed
  let l:time = getftime(expand('%'))
  if l:time == get(b:vimtex_fold, 'time', 0) | return | endif
  let b:vimtex_fold.time = l:time

  " Initialize
  let b:vimtex_fold.parts = []
  let buffer = getline(1,'$')

  " Parse part commands (frontmatter, appendix, part, etc)
  let lines = filter(copy(buffer), 'v:val =~ ''' . s:parts . '''')
  for part in g:vimtex_fold_parts
    let partpattern = '^\s*\%(\\\|% Fake\)' . part . ':\?\>'
    for line in lines
      if line =~# partpattern
        call insert(b:vimtex_fold.parts, [partpattern, 1])
        break
      endif
    endfor
  endfor

  " We want a minimum of two top level parts
  if len(b:vimtex_fold.parts) >= 2
    let level = 1
  else
    let level = 0
    let b:vimtex_fold.parts = []
  endif

  " Parse section commands (chapter, [sub...]section)
  let lines = filter(copy(buffer), 'v:val =~ ''' . s:secs . '''')
  for part in g:vimtex_fold_sections
    let partpattern = '^\s*\%(\\\|% Fake\)' . part . ':\?\>'
    for line in lines
      if line =~# partpattern
        let level += 1
        call insert(b:vimtex_fold.parts, [partpattern, level])
        break
      endif
    endfor
  endfor
endfunction

" }}}1

function! s:cmd_single(cmds) " {{{1
  let l:re = '\v^\s*\\%(' . join(a:cmds, '|') . ')\*?\s*%(\[.*\])?'

  let l:fold = {}
  let l:fold.re = {
        \ 'start' : l:re . '\s*\{\s*%($|\%)',
        \ 'end' : '^\s*}',
        \ 'text' : l:re,
        \}

  function! l:fold.level(line, lnum) dict
    if a:line =~# self.re.start
      let self.opened = 1
      return 'a1'
    elseif has_key(self, 'opened')
          \ && a:line =~# self.re.end
      unlet self.opened
      return 's1'
    endif
    return ''
  endfunction

  function! l:fold.text(line) dict
    return matchstr(a:line, self.re.text) . '{...}'
          \ . substitute(getline(v:foldend), self.re.end, '', '')
  endfunction

  return l:fold
endfunction

" }}}1
function! s:cmd_single_opt(cmds) " {{{1
  let l:re = '\v^\s*\\%(' . join(a:cmds, '|') . ')\*?'

  let l:fold = {}
  let l:fold.re = {
        \ 'start' : l:re . '\s*\[\s*%($|\%)',
        \ 'end' : '^\s*\]{',
        \ 'text' : l:re,
        \}

  function! l:fold.level(line, lnum) dict
    if a:line =~# self.re.start
      let self.opened = 1
      return 'a1'
    elseif has_key(self, 'opened')
          \ && a:line =~# self.re.end
      unlet self.opened
      return 's1'
    endif
    return ''
  endfunction

  function! l:fold.text(line) dict
    let l:col = strlen(matchstr(a:line, '^\s*')) + 1
    return matchstr(a:line, self.re.text) . '[...]{'
          \ . vimtex#cmd#get_at(v:foldstart, l:col).args[0].text . '}'
  endfunction

  return l:fold
endfunction

" }}}1
function! s:cmd_multi(cmds) " {{{1
  let l:re = '\v^\s*\\%(' . join(a:cmds, '|') . ')\*?'

  let l:fold = {}
  let l:fold.re = {
        \ 'start' : l:re . '.*(\{|\[)\s*(\%.*)?$',
        \ 'end' : '^\s*}\s*$',
        \ 'text' : l:re . '\{[^}]*\}',
        \}
  let l:fold.opened = 0

  function! l:fold.level(line, lnum) dict
    if a:line =~# self.re.start
      let self.opened += 1
      return 'a1'
    elseif self.opened > 0 && a:line =~# self.re.end
      let self.opened -= 1
      return 's1'
    endif
    return ''
  endfunction

  function! l:fold.text(line) dict
    return a:line
  endfunction

  return l:fold
endfunction

" }}}1
function! s:cmd_addplot(cmds) " {{{1
  let l:re = '\v^\s*\\%(' . join(a:cmds, '|') . ')\s*%(\[[^\]]*\])?'

  let l:fold = {}
  let l:fold.re = {
        \ 'start' : l:re . '\s*\w+\s*%(\[[^\]]*\])?\s*\ze\{\s*%($|\%)',
        \ 'end' : '^\s*}',
        \}

  function! l:fold.level(line, lnum) dict
    if a:line =~# self.re.start
      let self.opened = 1
      return 'a1'
    elseif has_key(self, 'opened')
          \ && a:line =~# self.re.end
      unlet self.opened
      return 's1'
    endif
    return ''
  endfunction

  function! l:fold.text(line) dict
    return matchstr(a:line, self.re.start) . '{...}'
          \ . substitute(getline(v:foldend), self.re.end, '', '')
  endfunction

  return l:fold
endfunction

" }}}1

let s:fold_env = {
      \ 're' : {
      \   'start' : g:vimtex#re#not_comment . g:vimtex#re#not_bslash . '\\begin\s*\{.{-}\}',
      \   'end' : g:vimtex#re#not_comment . g:vimtex#re#not_bslash . '\\end\s*\{.{-}\}',
      \   'name' : g:vimtex#re#not_comment . g:vimtex#re#not_bslash
      \            . '\\%(begin|end)\s*\{\zs.{-}\ze\}'
      \ }
      \}
function! s:fold_env.level(line, lnum) " {{{1
  if !g:vimtex_fold_envs | return | endif

  let l:env = matchstr(a:line, self.re.name)
  if !empty(l:env) && self.validate(l:env)
    if a:line =~# self.re.start
      if a:line !~# '\\end'
        return 'a1'
      endif
    elseif a:line =~# self.re.end
      if a:line !~# '\\begin'
        return 's1'
      endif
    endif
  endif
endfunction

" }}}1
function! s:fold_env.text(line, level) " {{{1
  let env = matchstr(a:line, self.re.name)
  if !self.validate(env) | return | endif

  let nt = 73
  let ne = 12

  " Set caption/label based on type of environment
  if env ==# 'frame'
    let label = ''
    let caption = self.parse_caption_frame(a:line)
  elseif env ==# 'table'
    let label = self.parse_label()
    let caption = self.parse_caption_table(a:line)
  else
    let label = self.parse_label()
    let caption = self.parse_caption(a:line)
  endif

  " Add parenthesis to label
  if label !=# ''
    let label = substitute(strpart(label,0,nt-ne-2), '\(.*\)', '(\1)','')
  endif

  " Set size of label and caption part of string
  let nl = len(label) > nt - ne ? nt - ne : len(label)
  let nc = nt - ne - nl - 1
  let caption = strpart(caption, 0, nc)

  " Create title based on env, caption and label
  let title = printf('%-' . ne . 's%-' . nc . 's %' . nl . 's',
        \ env, caption, label)

  " Combine level and title and return the trimmed fold text
  let text = printf('%-5s %-' . nt . 's', a:level, strpart(title, 0, nt))
  return substitute(text, '\s\+$', '', '') . ' '
endfunction

" }}}1
function! s:fold_env.validate(env) " {{{1
  return (empty(g:vimtex_fold_env_whitelist)
        \   || index(g:vimtex_fold_env_whitelist, a:env) >= 0)
        \ && index(g:vimtex_fold_env_blacklist, a:env) < 0
endfunction

" }}}1
function! s:fold_env.parse_label() " {{{1
  let i = v:foldend
  while i >= v:foldstart
    if getline(i) =~# '^\s*\\label'
      return matchstr(getline(i), '^\s*\\label\%(\[.*\]\)\?{\zs.*\ze}')
    end
    let i -= 1
  endwhile
  return ''
endfunction

" }}}1
function! s:fold_env.parse_caption(line) " {{{1
  let i = v:foldend
  while i >= v:foldstart
    if getline(i) =~# '^\s*\\caption'
      return matchstr(getline(i),
            \ '^\s*\\caption\(\[.*\]\)\?{\zs.\{-1,}\ze\(}\s*\)\?$')
    end
    let i -= 1
  endwhile

  " If no caption found, check for a caption comment
  return matchstr(a:line,'\\begin\*\?{.*}\s*%\s*\zs.*')
endfunction

" }}}1
function! s:fold_env.parse_caption_table(line) " {{{1
  let i = v:foldstart
  while i <= v:foldend
    if getline(i) =~# '^\s*\\caption'
      return matchstr(getline(i),
            \ '^\s*\\caption\s*\(\[.*\]\)\?\s*{\zs.\{-1,}\ze\(}\s*\)\?$')
    end
    let i += 1
  endwhile

  " If no caption found, check for a caption comment
  return matchstr(a:line,'\\begin\*\?{.*}\s*%\s*\zs.*')
endfunction

" }}}1
function! s:fold_env.parse_caption_frame(line) " {{{1
  " Test simple variants first
  let caption1 = matchstr(a:line,'\\begin\*\?{.*}{\zs.\+\ze}')
  let caption2 = matchstr(a:line,'\\begin\*\?{.*}{\zs.\+')

  if len(caption1) > 0
    return caption1
  elseif len(caption2) > 0
    return caption2
  else
    let i = v:foldstart
    while i <= v:foldend
      if getline(i) =~# '^\s*\\frametitle'
        return matchstr(getline(i),
              \ '^\s*\\frametitle\(\[.*\]\)\?{\zs.\{-1,}\ze\(}\s*\)\?$')
      end
      let i += 1
    endwhile

    " If no caption found, check for a caption comment
    return matchstr(a:line,'\\begin\*\?{.*}\s*%\s*\zs.*')
  endif
endfunction

" }}}1

let s:fold_env_options = {
      \ 'opened' : 0,
      \ 're' : {
      \   'start' : s:fold_env.re.start . '\[\s*($|\%)',
      \   'end' : '\s*\]\s*$',
      \ }
      \}
function! s:fold_env_options.level(line, lnum) dict " {{{1
  if !g:vimtex_fold_env_options | return | endif

  return self.opened
        \ ? self.fold_closed(a:line, a:lnum)
        \ : self.fold_opened(a:line, a:lnum)
endfunction
function! s:fold_env_options.fold_opened(line, lnum) dict " {{{1
  if a:line =~# self.re.start
    let self.opened = 1
    return 'a1'
  endif
endfunction

" }}}1
function! s:fold_env_options.fold_closed(line, lnum) dict " {{{1
  if a:line =~# self.re.end
    let self.opened = 0
    return 's1'
  endif
endfunction

" }}}1
function! s:fold_env_options.text(line) dict " {{{1
  return a:line . '...] '
endfunction

" }}}1

function! s:parse_sec_title(string, type) " {{{1
  let l:idx = 0
  let l:length = strlen(a:string)
  let l:level = 1
  while l:level >= 1
    let l:idx += 1
    if l:idx > l:length
      break
    elseif a:string[l:idx] ==# ['}',']'][a:type]
      let l:level -= 1
    elseif a:string[l:idx] ==# ['{','['][a:type]
      let l:level += 1
    endif
  endwhile
  return strpart(a:string, 0, l:idx)
endfunction

" }}}1


" {{{1 Initialize module

let s:parts = '\v^\s*(\\|\% Fake)(' . join(g:vimtex_fold_parts, '|') . ')>'
let s:secs  = '\v^\s*(\\|\% Fake)(' . join(g:vimtex_fold_sections,  '|') . ')>'

"
" Set up command fold structure
"
function! s:init_cmds() " {{{2
  let s:cmds = extend(g:vimtex_fold_commands_default,
        \ get(g:, 'vimtex_fold_commands', {}))
  let s:cmds_types = []
  let s:cmds_all = []

  for l:type in ['single', 'single_opt', 'multi', 'addplot']
    let l:cmds = keys(filter(copy(s:cmds), 'v:val ==# l:type'))
    if !empty(l:cmds)
      call extend(s:cmds_all, l:cmds)
      call add(s:cmds_types, s:cmd_{l:type}(l:cmds))
    endif
  endfor
endfunction

" }}}2

call s:init_cmds()

"
" List of identifiers for improving efficiency
"
let s:folded  = '\v'
let s:folded .=  '^\s*\%'
let s:folded .= '|^\s*\]\{'
let s:folded .= '|^\s*}'
let s:folded .= '|^\s*\]\s*$'
let s:folded .= '|\%%(.*\{\{\{|\s*\}\}\})'
let s:folded .= '|\\%(' . join([
      \   'begin',
      \   'end',
      \   '%(sub)*%(section|paragraph)',
      \   'chapter',
      \   'documentclass',
      \   '%(front|main|back)matter',
      \   'appendix',
      \   'part',
      \ ] + s:cmds_all, '|') . ')'

" }}}1

" vim: fdm=marker sw=2
