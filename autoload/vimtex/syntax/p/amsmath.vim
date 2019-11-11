" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#amsmath#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'amsmath') | return | endif
  let b:vimtex_syntax.amsmath = 1

  " Allow subequations (fixes #1019)
  " - This should be temporary, as it seems subequations is erroneously part of
  "   texBadMath from Charles Campbell's syntax plugin.
  syntax match texBeginEnd
        \ "\(\\begin\>\|\\end\>\)\ze{subequations}"
        \ nextgroup=texBeginEndName

  call VimtexNewMathZone('E', 'align', 1)
  call VimtexNewMathZone('F', 'alignat', 1)
  call VimtexNewMathZone('H', 'flalign', 1)
  call VimtexNewMathZone('I', 'gather', 1)
  call VimtexNewMathZone('J', 'multline', 1)
  call VimtexNewMathZone('K', 'xalignat', 1)
  call VimtexNewMathZone('L', 'xxalignat', 0)
  call VimtexNewMathZone('M', 'mathpar', 1)

  " Amsmath [lr][vV]ert  (Holger Mitschke)
  if has('conceal') && &enc ==# 'utf-8' && get(g:, 'tex_conceal', 'd') =~# 'd'
    for l:texmath in [
          \ ['\\lvert', '|'] ,
          \ ['\\rvert', '|'] ,
          \ ['\\lVert', '‖'] ,
          \ ['\\rVert', '‖'] ,
          \ ]
        execute "syntax match texMathDelim '\\\\[bB]igg\\=[lr]\\="
              \ . l:texmath[0] . "' contained conceal cchar=" . l:texmath[1]
    endfor
  endif
endfunction

" }}}1

function! VimtexNewMathZone(sfx, mathzone, starred) abort " {{{1
  " This function is based on Charles E. Campbell's amsmath.vba file 2018-06-29

  if get(g:, 'tex_fast', 'M') !~# 'M' | return | endif

  let foldcmd = get(g:, 'tex_fold_enabled') ? ' fold' : ''

  let grp = 'texMathZone' . a:sfx
  execute 'syntax cluster texMathZones add=' . grp
  execute 'syntax region ' . grp
        \ . ' start=''\\begin\s*{\s*' . a:mathzone . '\s*}'''
        \ . ' end=''\\end\s*{\s*' . a:mathzone . '\s*}'''
        \ . foldcmd . ' keepend contains=@texMathZoneGroup'
  execute 'highlight def link '.grp.' texMath'

  if a:starred
    let grp .= 'S'
    execute 'syntax cluster texMathZones add=' . grp
    execute 'syntax region ' . grp
          \ . ' start=''\\begin\s*{\s*' . a:mathzone . '\*\s*}'''
          \ . ' end=''\\end\s*{\s*' . a:mathzone . '\*\s*}'''
          \ . foldcmd . ' keepend contains=@texMathZoneGroup'
    execute 'highlight def link '.grp.' texMath'
  endif

  execute 'syntax match texBadMath ''\\end\s*{\s*' . a:mathzone . '\*\=\s*}'''
endfunction

