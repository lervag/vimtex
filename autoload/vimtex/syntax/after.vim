" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#after#load() abort " {{{1
  if s:is_loaded() | return | endif

  " Initialize project cache (used e.g. for the minted package)
  if !has_key(b:vimtex, 'syntax')
    let b:vimtex.syntax = {}
  endif

  " Initialize b:vimtex_syntax
  let b:vimtex_syntax = {}

  " Reset included syntaxes (necessary e.g. when doing :e)
  call vimtex#syntax#misc#include_reset()

  " Set some better defaults
  syntax spell toplevel
  syntax sync maxlines=500

  " Load some general syntax improvements
  call vimtex#syntax#after#general()

  " Load syntax for documentclass and packages
  call vimtex#syntax#packages#init()

  " Hack to make it possible to determine if vimtex syntax was loaded
  syntax match texVimtexLoaded 'dummyVimtexLoadedText' contained
endfunction

" }}}1
function! vimtex#syntax#after#general() abort " {{{1
  if !exists('b:vimtex_syntax') | return | endif

  " I don't see why we can't match Math zones in the MatchNMGroup
  if !exists('g:tex_no_math')
    syntax cluster texMatchNMGroup add=@texMathZones
  endif

  " Todo elements
  syntax match texStatement '\\todo\w*' contains=texTodo
  syntax match texTodo '\\todo\w*'

  " Fix strange mistake in main syntax file where \usepackage is added to the
  " texInputFile group
  syntax match texDocType /\\usepackage\>/
        \ nextgroup=texBeginEndName,texDocTypeArgs

  " Improve support for italic and bold fonts
  " Note: This essentially fixes a couple of bugs in the main syntax script
  if get(g:, 'tex_fast', 'b') =~# 'b'
    let l:spell = get(g:, 'tex_nospell') ? '' : ',@Spell'
    if empty(l:spell)
      syntax cluster texMatchGroup add=texBoldStyle,texBoldItalStyle,texItalStyle,texItalBoldStyle
      syntax cluster texMatchNMGroup add=texBoldStyle,texBoldItalStyle,texItalStyle,texItalBoldStyle
      syntax cluster texStyleGroup add=texBoldStyle,texBoldItalStyle,texItalStyle,texItalBoldStyle
    endif

    let l:conceal = get(g:, 'tex_conceal', 'b') =~# 'b' ? 'concealends' : ''
    if empty(l:conceal)
      let l:matrix = [
            \ ['texBoldStyle', 'texBoldGroup', ['textbf']],
            \ ['texBoldItalStyle', 'texItalGroup', ['textit']],
            \ ['texItalStyle', 'texItalGroup', ['textit']],
            \ ['texItalBoldStyle', 'texBoldGroup', ['textbf']],
            \ ['texEmphStyle', 'texItalGroup', ['emph']],
            \ ['texEmphStyle', 'texBoldGroup', ['texts[cfl]', 'textup', 'texttt']],
            \]
    else
      let l:matrix = empty(l:spell)
            \ ? [['texEmphStyle', 'texBoldGroup', ['texts[cfl]', 'textup', 'texttt']]]
            \ : []
    endif

    for [l:style, l:group, l:commands] in l:matrix
      for l:cmd in l:commands
        execute 'syntax region' l:style 'matchgroup=texTypeStyle'
              \ 'start="\\' . l:cmd . '\s*{" end="}"'
              \ l:conceal
              \ 'contains=@' . l:group . l:spell
      endfor
    endfor
  endif

  " Allow arguments in newenvironments
  syntax region texEnvName contained matchgroup=Delimiter
        \ start="{"rs=s+1  end="}"
        \ nextgroup=texEnvBgn,texEnvArgs contained skipwhite skipnl
  syntax region texEnvArgs contained matchgroup=Delimiter
        \ start="\["rs=s+1 end="]"
        \ nextgroup=texEnvBgn,texEnvArgs skipwhite skipnl
  syntax cluster texEnvGroup add=texDefParm,texNewEnv,texComment

  " Add support for \renewenvironment and \renewcommand
  syntax match texNewEnv "\\renewenvironment\>"
        \ nextgroup=texEnvName skipwhite skipnl
  syntax match texNewCmd "\\renewcommand\>"
        \ nextgroup=texCmdName skipwhite skipnl

  " Match nested DefParms
  syntax match texDefParmNested contained "##\+\d\+"
  highlight def link texDefParmNested Identifier
  syntax cluster texEnvGroup add=texDefParmNested
  syntax cluster texCmdGroup add=texDefParmNested

  " Do not check URLs and acronyms in comments
  " Source: https://github.com/lervag/vimtex/issues/562
  syntax match texCommentURL "\w\+:\/\/[^[:space:]]\+"
        \ contains=@NoSpell containedin=texComment contained
  syntax match texCommentAcronym '\v<(\u|\d){3,}s?>'
        \ contains=@NoSpell containedin=texComment contained
  highlight def link texCommentURL Comment
  highlight def link texCommentAcronym Comment

  " Add nospell for commands per configuration
  syntax region texVimtexNoSpell matchgroup=Delimiter
        \ start='{' end='}'
        \ contained contains=@NoSpell
  for l:macro in g:vimtex_syntax_nospell_commands
    execute 'syntax match texStatement /\\' . l:macro . '/'
          \ 'nextgroup=texVimtexNospell'
  endfor
endfunction

" }}}1

function! s:is_loaded() abort " {{{1
  let l:result = vimtex#util#command('syntax')
  return !empty(filter(l:result, 'v:val =~# "texVimtexLoaded"'))
endfunction

" }}}1
