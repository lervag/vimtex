" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_fold_enabled', 1)
  if !g:vimtex_fold_enabled | return | endif

  call vimtex#util#set_default('g:vimtex_fold_automatic', 0)
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
endfunction

" }}}1
function! vimtex#fold#init_script() " {{{1
  if !g:vimtex_fold_enabled | return | endif

  " Define some script variables
  let s:parts = '\v^\s*(\\|\% Fake)(' . join(g:vimtex_fold_parts, '|') . ')>'
  let s:secs  = '\v^\s*(\\|\% Fake)(' . join(g:vimtex_fold_sections,  '|') . ')>'
endfunction

" }}}1
function! vimtex#fold#init_buffer() " {{{1
  if !g:vimtex_fold_enabled | return | endif

  " Don't apply fold settings during diff
  if &diff | return | endif

  " Don't override modeline settings
  if s:check_modeline() | return | endif

  " Set fold options
  setlocal foldmethod=expr
  setlocal foldexpr=vimtex#fold#level(v:lnum)
  setlocal foldtext=vimtex#fold#text()

  " Remap zx to refresh fold levels
  nnoremap <silent><buffer> zx :call vimtex#fold#refresh('zx')<cr>
  nnoremap <silent><buffer> zX :call vimtex#fold#refresh('zX')<cr>

  " Define commands
  command! -buffer VimtexRefreshFolds call vimtex#fold#refresh('zx')

  " Set options for automatic/manual folding mode
  if g:vimtex_fold_automatic
    nnoremap <silent><buffer> u :call FdmSave()<cr>u:call FdmRestore()<cr>

    " For automatic folding with foldmethod=expr:
    "   The foldexpr function returns "=" for most lines, which means it can
    "   become slow for large files.  The following is a hack that is based on
    "   this reply to a discussion on the Vim Developer list:
    "   http://permalink.gmane.org/gmane.editors.vim.devel/14100
    if g:vimtex_fold_automatic
      augroup vimtex_fold_automatic
        autocmd!
        autocmd InsertEnter <buffer> call FdmSave()
        autocmd InsertLeave <buffer> call FdmRestore()
      augroup END
    endif
  else
    let s:fold_manual_id = get(s:, 'fold_manual_id', 0) + 1
    let b:fold_manual_augroup = 'vimtex_fold_' . s:fold_manual_id
    execute 'augroup' b:fold_manual_augroup
      autocmd!
      autocmd CursorMoved <buffer> call s:fold_manual_refresh()
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
  " Parse tex file to dynamically set the sectioning fold levels
  let b:vimtex_fold_parts = s:parse_folded()

  " Refresh folds
  if g:vimtex_fold_automatic
    execute 'normal! ' . a:map
  else
    setl foldmethod=expr
    execute 'normal! ' . a:map
    setl foldmethod=manual
  endif
endfunction

function! vimtex#fold#level(lnum) " {{{1
  " Check for normal lines first (optimization)
  let line  = getline(a:lnum)
  if line !~ '\(% Fake\|\\\(document\|begin\|end\|'
        \ . 'front\|main\|back\|app\|sub\|section\|chapter\|part\)\)'
    return '='
  endif

  " Fold preamble
  if g:vimtex_fold_preamble
    if line =~# '^\s*\\documentclass'
      return '>1'
    elseif line =~# '^\s*\\begin\s*{\s*document\s*}'
      return '0'
    endif
  endif

  " Fold chapters and sections
  for [part, level] in b:vimtex_fold_parts
    if line =~# part
      return '>' . level
    endif
  endfor

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

function! vimtex#fold#text() " {{{1
  " Initialize
  let line = getline(v:foldstart)
  let level = v:foldlevel > 1 ? repeat('-', v:foldlevel-2) . '*' : ''
  let title = 'Not defined'
  let nt = 73

  " Preamble, parts, sections and fakesections
  let sections = '\(\(sub\)*section\|part\|chapter\)'
  let secpat1 = '^\s*\\' . sections . '\*\?\s*{'
  let secpat2 = '^\s*\\' . sections . '\*\?\s*\['
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
  elseif line =~ secpat1 . '.*}'
    let title =  matchstr(line, secpat1 . '\zs.*\ze}')
  elseif line =~ secpat1
    let title =  matchstr(line, secpat1 . '\zs.*')
  elseif line =~ secpat2 . '.*\]'
    let title =  matchstr(line, secpat2 . '\zs.*\ze\]')
  elseif line =~ secpat2
    let title =  matchstr(line, secpat2 . '\zs.*')
  elseif line =~ 'Fake' . sections . ':'
    let title =  matchstr(line,'Fake' . sections . ':\s*\zs.*')
  elseif line =~ 'Fake' . sections
    let title =  matchstr(line, 'Fake' . sections)
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
" }}}1

function! FdmRestore() " {{{1
  let &l:foldmethod = s:fdm
endfunction

function! FdmSave() " {{{1
  let s:fdm = &l:foldmethod
  setlocal foldmethod=manual
endfunction

let s:fdm=''
" }}}1

" Define common regexps
let s:notbslash = '\%(\\\@<!\%(\\\\\)*\)\@<='
let s:notcomment = '\%(\%(\\\@<!\%(\\\\\)*\)\@<=%.*\)\@<!'

function! s:parse_folded() " {{{1
  "
  " Parse current buffer to find which sections to fold and their levels.  The
  " patterns are predefined to optimize the folding.
  "
  " We ignore top level parts such as \frontmatter, \appendix, \part, and
  " similar, unless there are at least two such commands in a document.
  "

  " Initialize
  let folded = []
  try
    let buffer = readfile(expand('%'))
  catch
    return []
  endtry

  " Parse part commands (frontmatter, appendix, part, etc)
  let lines = filter(copy(buffer), 'v:val =~ ''' . s:parts . '''')
  for part in g:vimtex_fold_parts
    let partpattern = '^\s*\(\\\|% Fake\)' . part . ':\?\>'
    for line in lines
      if line =~# partpattern
        call insert(folded, [partpattern, 1])
        break
      endif
    endfor
  endfor

  " We want a minimum of two top level parts
  if len(folded) >= 2
    let level = 1
  else
    let level = 0
    let folded = []
  endif

  " Parse section commands (chapter, [sub...]section)
  let lines = filter(copy(buffer), 'v:val =~ ''' . s:secs . '''')
  for part in g:vimtex_fold_sections
    let partpattern = '^\s*\(\\\|% Fake\)' . part . ':\?\>'
    for line in lines
      if line =~# partpattern
        let level += 1
        call insert(folded, [partpattern, level])
        break
      endif
    endfor
  endfor

  return folded
endfunction

" }}}1
function! s:parse_label() " {{{1
  let i = v:foldend
  while i >= v:foldstart
    if getline(i) =~# '^\s*\\label'
      return matchstr(getline(i), '^\s*\\label{\zs.*\ze}')
    end
    let i -= 1
  endwhile
  return ''
endfunction

function! s:parse_caption(line) " {{{1
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

function! s:parse_caption_table(line) " {{{1
  let i = v:foldstart
  while i <= v:foldend
    if getline(i) =~# '^\s*\\caption'
      return matchstr(getline(i),
            \ '^\s*\\caption\(\[.*\]\)\?{\zs.\{-1,}\ze\(}\s*\)\?$')
    end
    let i += 1
  endwhile

  " If no caption found, check for a caption comment
  return matchstr(a:line,'\\begin\*\?{.*}\s*%\s*\zs.*')
endfunction

function! s:parse_caption_frame(line) " {{{1
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

function! s:check_modeline() " {{{1
  "
  " Check if foldmethod is set in modeline
  "

  let l:search_string = 'vim:.*\(foldmethod\|fdm\)'
  
  " Preserve current cursor position
  let l:save_cursor = getpos('.')

  " Check for modeline at the top
  call cursor(1, 1)
  let l:check_modeline_top = search(l:search_string, 'cn', &modelines)

  " Check for modeline at bottom
  normal! G$
  let l:check_modeline_bottom = search(l:search_string, 'b',
        \ line('.') - 1 - &modelines)

  " Reset original cursor position
  call setpos('.', l:save_cursor)

  return l:check_modeline_top || l:check_modeline_bottom
endfunction

" }}}1

" vim: fdm=marker sw=2
