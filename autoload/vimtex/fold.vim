" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_fold_enabled', 0)
  call vimtex#util#set_default('g:vimtex_fold_manual', 0)
  call vimtex#util#set_default('g:vimtex_fold_comments', 0)
  call vimtex#util#set_default('g:vimtex_fold_levelmarker', '*')
  call vimtex#util#set_default('g:vimtex_fold_preamble', 1)
  call vimtex#util#set_default('g:vimtex_fold_envs', 1)
  call vimtex#util#set_default('g:vimtex_fold_parts',
        \ [
        \   'part',
        \   'appendix',
        \   'frontmatter',
        \   'mainmatter',
        \   'backmatter',
        \ ])
  call vimtex#util#set_default('g:vimtex_fold_sections',
        \ [
        \   'chapter',
        \   'section',
        \   'subsection',
        \   'subsubsection',
        \ ])
  call vimtex#util#set_default('g:vimtex_fold_documentclass', 0)
  call vimtex#util#set_default('g:vimtex_fold_usepackage', 1)
  call vimtex#util#set_default('g:vimtex_fold_newcommands', 1)

  " Disable manual mode in vimdiff
  let g:vimtex_fold_manual = &diff ? 0 : g:vimtex_fold_manual
endfunction

" }}}1
function! vimtex#fold#init_script() " {{{1
  let s:parts = '\v^\s*(\\|\% Fake)(' . join(g:vimtex_fold_parts, '|') . ')>'
  let s:secs  = '\v^\s*(\\|\% Fake)(' . join(g:vimtex_fold_sections,  '|') . ')>'
  let s:notbslash = '\%(\\\@<!\%(\\\\\)*\)\@<='
  let s:notcomment = '\%(\%(\\\@<!\%(\\\\\)*\)\@<=%.*\)\@<!'

  "
  " List of identifiers for improving efficiency
  "
  let s:folded  = '\v^\s*\%|^\s*\]\{'
  let s:folded .= '|^\s*}\s*$'
  let s:folded .= '|\\%(' . join([
        \   'begin',
        \   'end',
        \   '%(sub)*%(section|paragraph)',
        \   'chapter',
        \   'document',
        \   '%(front|main|back)matter',
        \   'appendix',
        \   'part',
        \   'usepackage',
        \   '%(re)?new%(command|environment)',
        \ ], '|') . ')'
endfunction

" }}}1
function! vimtex#fold#init_buffer() " {{{1
  " b:vimtex_fold is a dictionary used to store dynamic fold information
  " Note: We define this even if folding is disabled, because people might want
  "       to enable folding manually
  let b:vimtex_fold = {}

  if !g:vimtex_fold_enabled | return | endif
  if s:foldmethod_in_modeline() | return | endif

  " Sanity check
  if g:vimtex_fold_documentclass && g:vimtex_fold_preamble
    let g:vimtex_fold_documentclass = 0
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

function! s:foldmethod_in_modeline()
  let l:cursor_pos = getpos('.')
  let l:fdm_modeline = 'vim:.*\%(foldmethod\|fdm\)'

  call cursor(1, 1)
  let l:check_top = search(l:fdm_modeline, 'cn', &modelines)

  normal! G$
  let l:check_btm = search(l:fdm_modeline, 'b', line('$') + 1 - &modelines)

  call setpos('.', l:cursor_pos)
  return l:check_top || l:check_btm
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

  " Fold documentclass
  if g:vimtex_fold_documentclass
    if line =~# '^\s*\\documentclass\s*\[\s*\%($\|%\)'
      let s:documentclass = 1
      return 'a1'
    elseif get(s:, 'documentclass', 0) && line =~# '^\s*\]{'
      let s:documentclass = 0
      return 's1'
    endif
  endif

  " Never fold \begin{document}
  if line =~# '^\s*\\begin\s*{\s*document\s*}'
    return '0'
  endif

  " Fold usepackages
  if g:vimtex_fold_usepackage
    if line =~# '^\s*\\usepackage\s*\[\s*\%($\|%\)'
      let s:usepackage = 1
      return 'a1'
    elseif get(s:, 'usepackage', 0) && line =~# '^\s*\]{'
      let s:usepackage = 0
      return 's1'
    endif
  endif

  " Fold newcommands (and similar)
  if g:vimtex_fold_newcommands
    if line =~# '\v^\s*\\%(re)?new%(command|environment)\*?'
          \ && indent(a:lnum+1) > indent(a:lnum)
      let s:newcommand_indent = indent(a:lnum)
      return 'a1'
    elseif exists('s:newcommand_indent')
          \ && indent(a:lnum) == s:newcommand_indent
          \ && line =~# '^\s*}\s*$'
      unlet s:newcommand_indent
      return 's1'
    endif
  endif

  " Fold chapters and sections
  for [part, level] in b:vimtex_fold.parts
    if line =~# part
      return '>' . level
    endif
  endfor

  " Fold comments
  if g:vimtex_fold_comments
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
  if g:vimtex_fold_envs
    if line =~# s:notcomment . s:notbslash . '\\begin\s*{.\{-}}'
      if line !~# '\\end'
        return 'a1'
      endif
    elseif line =~# s:notcomment . s:notbslash . '\\end\s*{.\{-}}'
      if line !~# '\\begin'
        return 's1'
      endif
    endif
  endif

  " Return foldlevel of previous line
  return '='
endfunction

"
" Parse current buffer to find which sections to fold and their levels.  The
" patterns are predefined to optimize the folding.
"
" We ignore top level parts such as \frontmatter, \appendix, \part, and
" similar, unless there are at least two such commands in a document.
"
function! s:refresh_folded_sections()
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
function! vimtex#fold#text() " {{{1
  let line = getline(v:foldstart)

  " Text for usepackage
  if g:vimtex_fold_usepackage && line =~# '^\s*\\usepackage'
    return '\usepackage[...]{'
          \ . vimtex#cmd#get_at(v:foldstart, 1).args[0].text
          \ . '}'
  endif

  " Text for newcommand (and similar)
  if g:vimtex_fold_newcommands
        \ && line =~# '\v^\s*\\%(re)?new%(command|environment)'
    return matchstr(line,
          \ '\v^\s*\\%(re)?new%(command|environment)\*?\{[^}]*\}') . ' ...'
  endif

  " Text for documentclass
  if g:vimtex_fold_documentclass && line =~# '^\s*\\documentclass'
    return '\documentclass[...]{'
          \ . vimtex#cmd#get_at(v:foldstart, 1).args[0].text
          \ . '}'
  endif

  let level = v:foldlevel > 1
        \ ? repeat('-', v:foldlevel-2) . g:vimtex_fold_levelmarker
        \ : ''
  let title = 'Not defined'
  let nt = 73

  " Preamble, parts, sections, fakesections and comments
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

  " Environments
  if line =~# '\\begin'
    " Capture environment name
    let env = matchstr(line,'\\begin\*\?{\zs\w*\*\?\ze}')
    let ne = 12

    " Set caption/label based on type of environment
    if env ==# 'frame'
      let label = ''
      let caption = s:parse_caption_frame(line)
    elseif env ==# 'table'
      let label = s:parse_label()
      let caption = s:parse_caption_table(line)
    else
      let label = s:parse_label()
      let caption = s:parse_caption(line)
    endif

    " Add paranthesis to label
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
  endif

  " Combine level and title and return the trimmed fold text
  let text = printf('%-5s %-' . nt . 's', level, strpart(title, 0, nt))
  return substitute(text, '\s\+$', '', '') . ' '
endfunction

"
" Functions for setting fold text
"

function! s:parse_label() " {{{2
  let i = v:foldend
  while i >= v:foldstart
    if getline(i) =~# '^\s*\\label'
      return matchstr(getline(i), '^\s*\\label{\zs.*\ze}')
    end
    let i -= 1
  endwhile
  return ''
endfunction

" }}}2
function! s:parse_caption(line) " {{{2
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

" }}}2
function! s:parse_caption_table(line) " {{{2
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

" }}}2
function! s:parse_caption_frame(line) " {{{2
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

" }}}2
function! s:parse_sec_title(string, type) " {{{2
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

" }}}2

" }}}1

" vim: fdm=marker sw=2
