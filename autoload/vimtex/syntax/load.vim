" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#load#general() abort " {{{1
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

  " Improve support for italic font, bold font and some conceals
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
endfunction

" }}}1
