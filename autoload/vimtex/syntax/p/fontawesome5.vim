" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#fontawesome5#load(cfg) abort " {{{1
  if !a:cfg.conceal | return | endif

  call vimtex#syntax#core#new_opt('texFontawesomeOpt', {
        \ 'contains': '',
        \ 'opts': 'conceal contained containedin=texCmdFontawesome',
        \})
  call vimtex#syntax#core#new_arg('texFontawesomeArg', {
        \ 'contains': '',
        \ 'opts': 'conceal contained containedin=texCmdFontawesome',
        \})

  for [l:name, l:symbol] in items(s:fontawesome.regular)
    let l:nameCased = substitute(l:name, '\v%(^|-)(.)', '\u\1', 'g')
    let l:re =
          \ '\v\\fa' . l:nameCased . '>%(\[\w*\])?|'
          \ . '\\faIcon%(\[\w*\])?\{' . l:name . '\}'

    execute printf(
          \ 'syntax match texCmdFontawesome "%s" conceal cchar=%s',
          \ l:re, l:symbol)
  endfor

  for [l:name, l:symbol] in items(s:fontawesome.starred)
    let l:nameCased = substitute(l:name, '\v%(^|-)(.)', '\u\1', 'g')
    let l:re =
          \ '\v\\fa' . l:nameCased . '\*%(\[\w*\])?|'
          \ . '\\faIcon\*%(\[\w*\])?\{' . l:name . '\}'

    execute printf(
          \ 'syntax match texCmdFontawesome "%s" conceal cchar=%s',
          \ l:re, l:symbol)
  endfor

  " This case does not have the \faNameCased variant
  syntax match texCmdFontawesome "\v\\faIcon%(\[\w*\])?\s*\{500px\}" conceal cchar=

  highlight def link texCmdFontawesome texCmd
  highlight def link texFontawesomeArg texArg
  highlight def link texFontawesomeOpt texOpt
endfunction

" }}}1

let s:fontawesome = json_decode(join(
      \ readfile(vimtex#paths#asset('json/fontawesome.json'))
      \))
