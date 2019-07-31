" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !get(g:, 'vimtex_syntax_enabled', 1) | finish | endif

" The following ensures that this syntax addon is not sourced until after the
" filetype plugin has been sourced. See e.g. #1428 for more info.
if !exists('b:vimtex')
  let s:file = expand('<sfile>')

  augroup vimtex_syntax
    autocmd!
    autocmd User VimtexEventInitPost execute 'source' s:file
  augroup END

  finish
endif

if !exists('b:current_syntax')
  let b:current_syntax = 'tex'
elseif b:current_syntax !=# 'tex'
  finish
endif

" Perform spell checking when there is no syntax
" - This will enable spell checking e.g. in toplevel of included files
syntax spell toplevel

" Increase default value of maxlines
syntax sync maxlines=500

scriptencoding utf-8

" {{{1 Improve handling of newcommand and newenvironment commands

" Allow arguments in newenvironments
syntax region texEnvName contained matchgroup=Delimiter
      \ start="{"rs=s+1  end="}"
      \ nextgroup=texEnvBgn,texEnvArgs contained skipwhite skipnl
syntax region texEnvArgs contained matchgroup=Delimiter
      \ start="\["rs=s+1 end="]"
      \ nextgroup=texEnvBgn,texEnvArgs
      \ skipwhite skipnl
syntax cluster texEnvGroup add=texDefParm,texNewEnv,texComment

" Add support for \renewcommand and \renewenvironment
syntax match texNewCmd "\\renewcommand\>"
      \ nextgroup=texCmdName skipwhite skipnl
syntax match texNewEnv "\\renewenvironment\>"
      \ nextgroup=texEnvName skipwhite skipnl

" Match nested DefParms
syntax match texDefParmNested contained "##\+\d\+"
highlight def link texDefParmNested Identifier
syntax cluster texEnvGroup add=texDefParmNested
syntax cluster texCmdGroup add=texDefParmNested

" }}}1
" {{{1 General match improvements

" More commands (e.g. from packages) take file arguments
syntax match texInputFile /\\includepdf\%(\[.\{-}\]\)\=\s*{.\{-}}/
      \ contains=texStatement,texInputCurlies,texInputFileOpt
syntax match texInputFile /\\subfile\s*\%(\[.\{-}\]\)\=\s*{.\{-}}/
      \ contains=texStatement,texInputCurlies,texInputFileOpt

" Allow subequations (fixes #1019)
" - This should be temporary, as it seems subequations is erroneously part of
"   texBadMath from Charles Campbell's syntax plugin.
syntax match texBeginEnd
      \ "\(\\begin\>\|\\end\>\)\ze{subequations}"
      \ nextgroup=texBeginEndName

" I don't quite see why we can't match Math zones in the MatchNMGroup
if !exists('g:tex_no_math')
  syntax cluster texMatchNMGroup add=@texMathZones
endif

" {{{1 Italic font, bold font and conceals

if get(g:, 'tex_fast', 'b') =~# 'b'
  let s:conceal = (has('conceal') && get(g:, 'tex_conceal', 'b') =~# 'b')
        \ ? 'concealends' : ''

  for [s:style, s:group, s:commands] in [
        \ ['texItalStyle', 'texItalGroup', ['emph', 'textit']],
        \ ['texBoldStyle', 'texBoldGroup', ['textbf']],
        \]
    for s:cmd in s:commands
      execute 'syntax region' s:style 'matchgroup=texTypeStyle'
            \ 'start="\\' . s:cmd . '\s*{" end="}"'
            \ 'contains=@Spell,@' . s:group
            \ s:conceal
    endfor
    execute 'syntax cluster texMatchGroup add=' . s:style
  endfor
endif

" }}}1
" {{{1 Add syntax highlighting for \todo

syntax match texStatement '\\todo\w*' contains=texTodo
syntax match texTodo '\\todo\w*'

" }}}1

call vimtex#syntax#load()
