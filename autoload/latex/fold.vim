" {{{1 latex#fold#init
function! latex#fold#init(initialized)
  if g:latex_fold_enabled
    setl foldmethod=expr
    setl foldexpr=latex#fold#level(v:lnum)
    setl foldtext=latex#fold#text()
    call latex#fold#refresh()

    if g:latex_default_mappings
      nnoremap <silent><buffer> zx :call latex#fold#refresh()<cr>zx
    endif

    "
    " The foldexpr function returns "=" for most lines, which means it can
    " become slow for large files.  The following is a hack that is based on
    " this reply to a discussion on the Vim Developer list:
    " http://permalink.gmane.org/gmane.editors.vim.devel/14100
    "
    if !a:initialized
      augroup latex_fold
        autocmd!
        autocmd InsertEnter *.tex setlocal foldmethod=manual
        autocmd InsertLeave *.tex setlocal foldmethod=expr
      augroup END
    endif
  endif
endfunction

" {{{1 latex#fold#refresh
function! latex#fold#refresh()
  " Parse tex file to dynamically set the sectioning fold levels
  let b:latex.fold_sections = s:find_fold_sections()
endfunction

" {{{1 latex#fold#level
function! latex#fold#level(lnum)
  " Check for normal lines first (optimization)
  let line  = getline(a:lnum)
  if line !~ '\(% Fake\|\\\(document\|begin\|end\|'
        \ . 'front\|main\|back\|app\|sub\|section\|chapter\|part\)\)'
    return "="
  endif

  " Fold preamble
  if g:latex_fold_preamble
    if line =~# '\s*\\documentclass'
      return ">1"
    elseif line =~# '^\s*\\begin\s*{\s*document\s*}'
      return "0"
    endif
  endif

  " Fold parts (\frontmatter, \mainmatter, \backmatter, and \appendix)
  if line =~# '^\s*\\\%(' . join(g:latex_fold_parts, '\|') . '\)'
    return ">1"
  endif

  " Fold chapters and sections
  for [part, level] in b:latex.fold_sections
    if line =~# part
      return ">" . level
    endif
  endfor

  " Never fold \end{document}
  if line =~# '^\s*\\end{document}'
    return 0
  endif

  " Fold environments
  if g:latex_fold_envs
    if line =~# b:notcomment . b:notbslash . '\\begin\s*{.\{-}}'
      return "a1"
    elseif line =~# b:notcomment . b:notbslash . '\\end\s*{.\{-}}'
      return "s1"
    endif
  endif

  " Return foldlevel of previous line
  return "="
endfunction

" {{{1 latex#fold#text
function! latex#fold#text()
  " Initialize
  let line = getline(v:foldstart)
  let nlines = v:foldend - v:foldstart + 1
  let level = ''
  let title = 'Not defined'

  " Fold level
  let level = strpart(repeat('-', v:foldlevel-1) . '*',0,3)
  if v:foldlevel > 3
    let level = strpart(level, 1) . v:foldlevel
  endif
  let level = printf('%-3s', level)

  " Preamble
  if line =~ '\s*\\documentclass'
    let title = "Preamble"
  endif

  " Parts, sections and fakesections
  let sections = '\(\(sub\)*section\|part\|chapter\)'
  let secpat1 = '^\s*\\' . sections . '\*\?\s*{'
  let secpat2 = '^\s*\\' . sections . '\*\?\s*\['
  if line =~ '\\frontmatter'
    let title = "Frontmatter"
  elseif line =~ '\\mainmatter'
    let title = "Mainmatter"
  elseif line =~ '\\backmatter'
    let title = "Backmatter"
  elseif line =~ '\\appendix'
    let title = "Appendix"
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
  if line =~ '\\begin'
    " Capture environment name
    let env = matchstr(line,'\\begin\*\?{\zs\w*\*\?\ze}')

    " Set caption/label based on type of environment
    if env == 'frame'
      let label = ''
      let caption = s:parse_caption_frame(line)
    elseif env == 'table'
      let label = s:parse_label()
      let caption = s:parse_caption_table(line)
    else
      let label = s:parse_label()
      let caption = s:parse_caption(line)
    endif

    " Add paranthesis to label
    if label != ''
      let label = substitute(strpart(label,0,54), '\(.*\)', '(\1)','')
    endif

    " Set size of label and caption part of string
    let nl = len(label) > 56 ? 56 : len(label)
    let nc = 56 - (nl + 1)
    let caption = strpart(caption, 0, nc)

    " Create title based on env, caption and label
    let title = printf('%-12s%-' . nc . 's %' . nl . 's',
          \ env, caption, label)
  endif

  let title = strpart(title, 0, 68)
  return printf('%-3s %-68S #%5d', level, title, nlines)
endfunction
" }}}1

" {{{1 s:find_fold_sections
function! s:find_fold_sections()
  "
  " This function parses the tex file to find the sections that are to be
  " folded and their levels, and then predefines the patterns for optimized
  " folding.
  "
  " Initialize
  let level = 1
  let foldsections = []

  " If we use two or more of the *matter commands, we need one more foldlevel
  let nparts = 0
  for part in g:latex_fold_parts
    let i = 1
    while i < line("$")
      if getline(i) =~ '^\s*\\' . part . '\>'
        let nparts += 1
        break
      endif
      let i += 1
    endwhile
    if nparts > 1
      let level = 2
      break
    endif
  endfor

  " Combine sections and levels, but ignore unused section commands:  If we
  " don't use the part command, then chapter should have the highest
  " level.  If we don't use the chapter command, then section should be the
  " highest level.  And so on.
  let ignore = 1
  for part in g:latex_fold_sections
    " For each part, check if it is used in the file.  We start adding the
    " part patterns to the fold sections array whenever we find one.
    let partpattern = '^\s*\(\\\|% Fake\)' . part . '\>'
    if ignore
      let i = 1
      while i < line("$")
        if getline(i) =~# partpattern
          call insert(foldsections, [partpattern, level])
          let level += 1
          let ignore = 0
          break
        endif
        let i += 1
      endwhile
    else
      call insert(foldsections, [partpattern, level])
      let level += 1
    endif
  endfor

  return foldsections
endfunction

" {{{1 s:parse_label
function! s:parse_label()
  let i = v:foldend
  while i >= v:foldstart
    if getline(i) =~ '^\s*\\label'
      return matchstr(getline(i), '^\s*\\label{\zs.*\ze}')
    end
    let i -= 1
  endwhile
  return ""
endfunction

" {{{1 s:parse_caption
function! s:parse_caption(line)
  let i = v:foldend
  while i >= v:foldstart
    if getline(i) =~ '^\s*\\caption'
      return matchstr(getline(i),
            \ '^\s*\\caption\(\[.*\]\)\?{\zs.\{-1,}\ze\(}\s*\)\?$')
    end
    let i -= 1
  endwhile

  " If no caption found, check for a caption comment
  return matchstr(a:line,'\\begin\*\?{.*}\s*%\s*\zs.*')
endfunction

" {{{1 s:parse_caption_table
function! s:parse_caption_table(line)
  let i = v:foldstart
  while i <= v:foldend
    if getline(i) =~ '^\s*\\caption'
      return matchstr(getline(i),
            \ '^\s*\\caption\(\[.*\]\)\?{\zs.\{-1,}\ze\(}\s*\)\?$')
    end
    let i += 1
  endwhile

  " If no caption found, check for a caption comment
  return matchstr(a:line,'\\begin\*\?{.*}\s*%\s*\zs.*')
endfunction

" {{{1 s:parse_caption_frame
function! s:parse_caption_frame(line)
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
      if getline(i) =~ '^\s*\\frametitle'
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

" vim:fdm=marker:ff=unix
