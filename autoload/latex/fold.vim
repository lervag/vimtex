" {{{1 latex#fold#init
function! latex#fold#init(initialized)
  if g:latex_fold_enabled
    setl foldmethod=expr
    setl foldexpr=latex#fold#level(v:lnum)
    setl foldtext=latex#fold#text()
    call latex#fold#refresh()

    if g:latex_mappings_enabled
      nnoremap <silent><buffer> zx :call latex#fold#refresh()<cr>zx
    endif

    "
    " For some reason, foldmethod=expr makes undo slow (at least in some cases)
    "
    nnoremap <silent><buffer> u :call FdmSave()<cr>u:call FdmRestore()<cr>

    "
    " The foldexpr function returns "=" for most lines, which means it can
    " become slow for large files.  The following is a hack that is based on
    " this reply to a discussion on the Vim Developer list:
    " http://permalink.gmane.org/gmane.editors.vim.devel/14100
    "
    if !a:initialized
      augroup latex_fold
        autocmd!
        autocmd InsertEnter *.tex call FdmSave()
        autocmd InsertLeave *.tex call FdmRestore()
      augroup END
    endif
  endif
endfunction

" {{{1 latex#fold#refresh
function! latex#fold#refresh()
  " Parse tex file to dynamically set the sectioning fold levels
  let b:latex.fold_parts = s:find_fold_parts()
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

  " Fold chapters and sections
  for [part, level] in b:latex.fold_parts
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
    if line =~# s:notcomment . s:notbslash . '\\begin\s*{.\{-}}'
      return "a1"
    elseif line =~# s:notcomment . s:notbslash . '\\end\s*{.\{-}}'
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
  let level = v:foldlevel > 1 ? repeat('-', v:foldlevel-2) . '*' : ''
  let title = 'Not defined'
  let nt = 73

  " Preamble, parts, sections and fakesections
  let sections = '\(\(sub\)*section\|part\|chapter\)'
  let secpat1 = '^\s*\\' . sections . '\*\?\s*{'
  let secpat2 = '^\s*\\' . sections . '\*\?\s*\['
  if line =~ '\s*\\documentclass'
    let title = "Preamble"
  elseif line =~ '\\frontmatter'
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
    let ne = 12

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

  let title = strpart(title, 0, nt)
  return printf('%-5s %-' . nt . 's', level, title)
endfunction
" }}}1

" {{{1 FdmRestore
function! FdmRestore()
  let &l:foldmethod = s:fdm
endfunction

" {{{1 FdmSave
let s:fdm=''
function! FdmSave()
  let s:fdm = &l:foldmethod
  setlocal foldmethod=manual
endfunction
" }}}1

" {{{1 s:notbslash and s:notcomment
let s:notbslash = '\%(\\\@<!\%(\\\\\)*\)\@<='
let s:notcomment = '\%(\%(\\\@<!\%(\\\\\)*\)\@<=%.*\)\@<!'

" {{{1 s:find_fold_parts
function! s:find_fold_parts()
  "
  " This function parses the tex file to find the sections that are to be
  " folded and their levels, and then predefines the patterns for optimized
  " folding.
  "
  " Initialize
  let level = 0
  let foldsections = []

  " Combine sections and levels, but ignore unused section commands:  If we
  " don't use the part command, then chapter should have the highest
  " level.  If we don't use the chapter command, then section should be the
  " highest level.  And so on.
  for [part, inc] in g:latex_fold_parts
    " For each part, check if it is used in the file.  We start adding the
    " part patterns to the fold sections array whenever we find one.
    let partpattern = '^\s*\(\\\|% Fake\)' . part . '\>'
    let nline  = 1
    while nline < line("$")
      if getline(nline) =~# partpattern
        let level = level == 0 ? 1 : level + inc
        call insert(foldsections, [partpattern, level])
        break
      endif
      let nline += 1
    endwhile
  endfor

  if len(filter(copy(foldsections), 'v:val[1] <= 1')) < 2
    call filter(foldsections, 'v:val[1] > 1')
  endif

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

" vim: fdm=marker
