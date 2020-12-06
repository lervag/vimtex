" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#core#init() abort " {{{1
  syntax spell toplevel

  syntax sync maxlines=500
  syntax sync minlines=50
  syntax iskeyword 48-57,a-z,A-Z,192-255

  " {{{2 Define main syntax clusters

  syntax cluster texClusterOpt contains=
        \texCmd,
        \texComment,
        \texLength,
        \texOpt,
        \texOptEqual,
        \texOptSep,
        \@NoSpell

  syntax cluster texClusterMath contains=
        \texCmdEnv,
        \texCmdFootnote,
        \texCmdGreek,
        \texCmdMathText,
        \texCmdRef,
        \texCmdSize,
        \texCmdStyle,
        \texCmdTodo,
        \texCmdVerb,
        \texComment,
        \texGroupError,
        \texMathCmd,
        \texMathCmdEnv,
        \texMathDelim,
        \texMathDelimMod,
        \texMathGroup,
        \texMathOper,
        \texMathSub,
        \texMathSuper,
        \texMathSymbol,
        \texSpecialChar,
        \texTabularChar,
        \@NoSpell

  " }}}2

  " {{{2 Comments

  " * In documented TeX Format, actual comments are defined by leading "^^A".
  "   Almost all other lines start with one or more "%", which may be matched
  "   as comment characters. The remaining part of the line can be interpreted
  "   as TeX syntax.
  " * For more info on dtx files, see e.g.
  "   https://ctan.uib.no/info/dtxtut/dtxtut.pdf
  if expand('%:e') ==# 'dtx'
    syntax match texComment "\^\^A.*$"
    syntax match texComment "^%\+"
  else
    syntax match texComment "%.*$" contains=@Spell
  endif

  " Do not check URLs and acronyms in comments
  " Source: https://github.com/lervag/vimtex/issues/562
  syntax match texCommentURL "\w\+:\/\/[^[:space:]]\+"
        \ containedin=texComment contained contains=@NoSpell
  syntax match texCommentAcronym '\v<(\u|\d){3,}s?>'
        \ containedin=texComment contained contains=@NoSpell

  " Todo and similar within comments
  syntax case ignore
  syntax keyword texCommentTodo combak fixme todo xxx
        \ containedin=texComment contained
  syntax case match

  " }}}2
  " {{{2 TeX symbols and special characters

  syntax match texLigature "--"
  syntax match texLigature "---"
  syntax match texLigature "\v%(``|''|,,)"
  syntax match texTabularChar "&"
  syntax match texTabularChar "\\\\"

  " E.g.:  \$ \& \% \# \{ \} \_ \S \P
  syntax match texSpecialChar "\\[$&%#{}_]"
  syntax match texSpecialChar "\\[SP@]\ze[^a-zA-Z@]"
  syntax match texSpecialChar "\^\^\%(\S\|[0-9a-f]\{2}\)"
  syntax match texSpecialChar "\\[,;:!]"

  " }}}2
  " {{{2 Commands: general

  " Unspecified TeX groups
  " Note: This is necessary to keep track of all nested braces
  call vimtex#syntax#core#new_arg('texGroup', {'opts': ''})

  " Flag mismatching ending brace delimiter
  syntax match texGroupError "}"

  " Add generic option elements contained in common option groups
  syntax match texOptEqual contained "="
  syntax match texOptSep contained ",\s*"

  " TeX Lengths (matched in options and some arguments)
  syntax match texLength contained "\<\d\+\([.,]\d\+\)\?\s*\(true\)\?\s*\(bp\|cc\|cm\|dd\|em\|ex\|in\|mm\|pc\|pt\|sp\)\>"

  " Match general commands first
  syntax match texCmd nextgroup=texOpt,texArg skipwhite skipnl "\\[a-zA-Z@]\+"
  call vimtex#syntax#core#new_opt('texOpt', {'next': 'texArg'})
  call vimtex#syntax#core#new_arg('texArg', {'next': 'texArg', 'opts': 'contained transparent'})

  " Define separate "generic" commands inside math regions
  " Note: Defined here because order matters!
  syntax match texMathCmd contained nextgroup=texMathArg skipwhite skipnl "\\\a\+"
  call vimtex#syntax#core#new_arg('texMathArg', {'contains': '@texClusterMath'})

  " {{{2 Commands: core set

  " Accents and ligatures
  syntax match texCmdAccent "\\[bcdvuH]$"
  syntax match texCmdAccent "\\[bcdvuH]\ze[^a-zA-Z@]"
  syntax match texCmdAccent /\\[=^.~"`']/
  syntax match texCmdAccent /\\['=t'.c^ud"vb~Hr]{\a}/
  syntax match texCmdLigature "\v\\%([ijolL]|ae|oe|ss|AA|AE|OE)$"
  syntax match texCmdLigature "\v\\%([ijolL]|ae|oe|ss|AA|AE|OE)\ze[^a-zA-Z@]"

  " Spacecodes (TeX'isms)
  " * See e.g. https://en.wikibooks.org/wiki/TeX/catcode
  " * \mathcode`\^^@ = "2201
  " * \delcode`\( = "028300
  " * \sfcode`\) = 0
  " * \uccode`X = `X
  " * \lccode`x = `x
  syntax match texCmdSpaceCode "\v\\%(math|cat|del|lc|sf|uc)code`"me=e-1
        \ nextgroup=texCmdSpaceCodeChar
  syntax match texCmdSpaceCodeChar "\v`\\?.%(\^.)?\?%(\d|\"\x{1,6}|`.)" contained

  " Todo commands
  syntax match texCmdTodo '\\todo\w*'

  " \author
  syntax match texCmdAuthor nextgroup=texAuthorOpt,texAuthorArg skipwhite skipnl "\\author\>"
  call vimtex#syntax#core#new_opt('texAuthorOpt', {'next': 'texAuthorArg'})
  call vimtex#syntax#core#new_arg('texAuthorArg', {'contains': 'TOP,@Spell'})

  " \title
  syntax match texCmdTitle nextgroup=texTitleArg skipwhite skipnl "\\title\>"
  call vimtex#syntax#core#new_arg('texTitleArg')

  " \footnote
  syntax match texCmdFootnote nextgroup=texFootnoteArg skipwhite skipnl "\\footnote\>"
  call vimtex#syntax#core#new_arg('texFootnoteArg')

  " \if \else \fi
  syntax match texCmdConditional nextgroup=texConditionalArg skipwhite skipnl "\\\(if[a-zA-Z@]\+\|fi\|else\)\>"
  call vimtex#syntax#core#new_arg('texConditionalArg')

  " Various commands that take a file argument (or similar)
  syntax match texCmdInput   nextgroup=texFileArg              skipwhite skipnl "\\input\>"
  syntax match texCmdInput   nextgroup=texFileArg              skipwhite skipnl "\\include\>"
  syntax match texCmdInput   nextgroup=texFilesArg             skipwhite skipnl "\\includeonly\>"
  syntax match texCmdInput   nextgroup=texFileOpt,texFileArg   skipwhite skipnl "\\includegraphics\>"
  syntax match texCmdBib     nextgroup=texFilesArg             skipwhite skipnl "\\bibliography\>"
  syntax match texCmdBib     nextgroup=texFileArg              skipwhite skipnl "\\bibliographystyle\>"
  syntax match texCmdClass   nextgroup=texFileOpt,texFileArg   skipwhite skipnl "\\document\%(class\|style\)\>"
  syntax match texCmdPackage nextgroup=texFilesOpt,texFilesArg skipwhite skipnl "\\usepackage\>"
  syntax match texCmdPackage nextgroup=texFilesOpt,texFilesArg skipwhite skipnl "\\RequirePackage\>"
  syntax match texCmdPackage nextgroup=texFilesOpt,texFilesArg skipwhite skipnl "\\ProvidesPackage\>"
  call vimtex#syntax#core#new_arg('texFileArg', {'contains': '@NoSpell,texCmd,texComment'})
  call vimtex#syntax#core#new_arg('texFilesArg', {'contains': '@NoSpell,texCmd,texComment,texOptSep'})
  call vimtex#syntax#core#new_opt('texFileOpt', {'next': 'texFileArg'})
  call vimtex#syntax#core#new_opt('texFilesOpt', {'next': 'texFilesArg'})

  " LaTeX 2.09 type styles
  syntax match texCmdStyle "\\rm\>"
  syntax match texCmdStyle "\\em\>"
  syntax match texCmdStyle "\\bf\>"
  syntax match texCmdStyle "\\it\>"
  syntax match texCmdStyle "\\sl\>"
  syntax match texCmdStyle "\\sf\>"
  syntax match texCmdStyle "\\sc\>"
  syntax match texCmdStyle "\\tt\>"

  " LaTeX2E type styles
  syntax match texCmdStyle "\\textbf\>"
  syntax match texCmdStyle "\\textit\>"
  syntax match texCmdStyle "\\textmd\>"
  syntax match texCmdStyle "\\textrm\>"
  syntax match texCmdStyle "\\texts[cfl]\>"
  syntax match texCmdStyle "\\texttt\>"
  syntax match texCmdStyle "\\textup\>"
  syntax match texCmdStyle "\\emph\>"

  syntax match texCmdStyle "\\rmfamily\>"
  syntax match texCmdStyle "\\sffamily\>"
  syntax match texCmdStyle "\\ttfamily\>"

  syntax match texCmdStyle "\\itshape\>"
  syntax match texCmdStyle "\\scshape\>"
  syntax match texCmdStyle "\\slshape\>"
  syntax match texCmdStyle "\\upshape\>"

  syntax match texCmdStyle "\\bfseries\>"
  syntax match texCmdStyle "\\mdseries\>"

  " Bold and italic commands
  call s:match_bold_italic()

  " Type sizes
  syntax match texCmdSize "\\tiny\>"
  syntax match texCmdSize "\\scriptsize\>"
  syntax match texCmdSize "\\footnotesize\>"
  syntax match texCmdSize "\\small\>"
  syntax match texCmdSize "\\normalsize\>"
  syntax match texCmdSize "\\large\>"
  syntax match texCmdSize "\\Large\>"
  syntax match texCmdSize "\\LARGE\>"
  syntax match texCmdSize "\\huge\>"
  syntax match texCmdSize "\\Huge\>"

  " \newcommand
  syntax match texCmdNewcmd nextgroup=texNewcmdArgName skipwhite skipnl "\\\%(re\)\?newcommand\>\*\?"
  call vimtex#syntax#core#new_arg('texNewcmdArgName', {
        \ 'next': 'texNewcmdOpt,texNewcmdArgBody',
        \ 'contains': ''
        \})
  call vimtex#syntax#core#new_opt('texNewcmdOpt', {
        \ 'next': 'texNewcmdOpt,texNewcmdArgBody',
        \ 'opts': 'oneline',
        \})
  call vimtex#syntax#core#new_arg('texNewcmdArgBody')
  syntax match texNewcmdParm contained "#\+\d" containedin=texNewcmdArgBody

  " \newenvironment
  syntax match texCmdNewenv nextgroup=texNewenvArgName skipwhite skipnl "\\\%(re\)\?newenvironment\>"
  call vimtex#syntax#core#new_arg('texNewenvArgName', {'next': 'texNewenvArgBegin,texNewenvOpt'})
  call vimtex#syntax#core#new_opt('texNewenvOpt', {
        \ 'next': 'texNewenvArgBegin,texNewenvOpt',
        \ 'opts': 'oneline'
        \})
  call vimtex#syntax#core#new_arg('texNewenvArgBegin', {'next': 'texNewenvArgEnd'})
  call vimtex#syntax#core#new_arg('texNewenvArgEnd')
  syntax match texNewenvParm contained "#\+\d" containedin=texNewenvArgBegin,texNewenvArgEnd

  " Definitions/Commands
  " E.g. \def \foo #1#2 {foo #1 bar #2 baz}
  syntax match texCmdDef "\\def\>" nextgroup=texDefArgName skipwhite skipnl
  syntax match texDefArgName contained nextgroup=texDefParmPre,texDefArgBody skipwhite skipnl "\\[a-zA-Z@]\+"
  syntax match texDefArgName contained nextgroup=texDefParmPre,texDefArgBody skipwhite skipnl "\\[^a-zA-Z@]"
  syntax match texDefParmPre contained nextgroup=texDefArgBody skipwhite skipnl "#[^{]*"
  syntax match texDefParm contained "#\+\d" containedin=texDefParmPre,texDefArgBody
  call vimtex#syntax#core#new_arg('texDefArgBody')

  " \let
  syntax match texCmdLet "\\let\>" nextgroup=texLetArgName skipwhite skipnl
  syntax match texLetArgName  contained nextgroup=texLetArgBody,texLetArgEqual skipwhite skipnl "\\[a-zA-Z@]\+"
  syntax match texLetArgName  contained nextgroup=texLetArgBody,texLetArgEqual skipwhite skipnl "\\[^a-zA-Z@]"
  " Note: define texLetArgEqual after texLetArgBody; order matters
  " E.g. in '\let\eq==' we want: 1st = is texLetArgEqual, 2nd = is texLetArgBody
  " Reversing lines results in:  1st = is texLetArgBody,  2nd = is unmatched
  syntax match texLetArgBody  contained "\\[a-zA-Z@]\+\|\\[^a-zA-Z@]\|\S" contains=TOP,@Nospell
  syntax match texLetArgEqual contained nextgroup=texLetArgBody skipwhite skipnl "="

  " Reference and cite commands
  syntax match texCmdRef nextgroup=texRefArg           skipwhite skipnl "\\nocite\>"
  syntax match texCmdRef nextgroup=texRefArg           skipwhite skipnl "\\label\>"
  syntax match texCmdRef nextgroup=texRefArg           skipwhite skipnl "\\\(page\|eq\)ref\>"
  syntax match texCmdRef nextgroup=texRefArg           skipwhite skipnl "\\v\?ref\>"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\cite\>"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\cite[tp]\>\*\?"
  call vimtex#syntax#core#new_opt('texRefOpt', {'next': 'texRefOpt,texRefArg'})
  call vimtex#syntax#core#new_arg('texRefArg', {'contains': 'texComment,@NoSpell'})

  " Sections and parts
  syntax match texCmdPart "\\\(front\|main\|back\)matter\>"
  syntax match texCmdPart nextgroup=texPartArgTitle "\\part\>"
  syntax match texCmdPart nextgroup=texPartArgTitle "\\chapter\>\*\?"
  syntax match texCmdPart nextgroup=texPartArgTitle "\\\(sub\)*section\>\*\?"
  syntax match texCmdPart nextgroup=texPartArgTitle "\\\(sub\)\?paragraph\>"
  call vimtex#syntax#core#new_arg('texPartArgTitle')

  " Item elements in lists
  syntax match texCmdItem "\\item\>"

  " Add @NoSpell for commands per configuration (TOP,@Spell implies NoSpell!)
  for l:macro in g:vimtex_syntax_nospell_commands
    execute 'syntax match texCmdNoSpell nextgroup=texNoSpellArg skipwhite skipnl "\\' . l:macro . '"'
  endfor
  call vimtex#syntax#core#new_arg('texNoSpellArg', {'contains': 'TOP,@Spell'})

  " \begin \end environments
  syntax match texCmdEnv "\v\\%(begin|end)>" nextgroup=texEnvArgName
  call vimtex#syntax#core#new_arg('texEnvArgName', {
        \ 'contains': 'texComment,@NoSpell',
        \ 'next': 'texEnvOpt'
        \})
  call vimtex#syntax#core#new_opt('texEnvOpt',
        \ {'contains': 'texComment,@NoSpell'})

  " Tabular arguments
  syntax match texCmdEnv "\\begin{tabular}" contains=texCmdEnv nextgroup=texTabularArg skipwhite skipnl
  call vimtex#syntax#core#new_arg('texTabularArg', {'contains': ''})

  " }}}2
  " {{{2 Region: Verbatim

  " Verbatim environment
  call vimtex#syntax#core#new_region_env('texVerbRegion', '[vV]erbatim')

  " Verbatim inline
  syntax match texCmdVerb "\\verb\>\*\?" nextgroup=texVerbRegionInline
  call vimtex#syntax#core#new_arg('texVerbRegionInline', {
        \ 'contains': '',
        \ 'matcher': 'start="\z([^\ta-zA-Z]\)" end="\z1"'
        \})

  " }}}2
  " {{{2 Region: Expl3

  syntax region texE3Region matchgroup=texCmdE3
        \ start='\\\%(ExplSyntaxOn\|ProvidesExpl\%(Package\|Class\|File\)\)'
        \ end='\\ExplSyntaxOff\|\%$'
        \ transparent
        \ contains=TOP,@NoSpell

  call vimtex#syntax#core#new_arg('texE3Group', {'opts': 'contained containedin=@texClusterE3'})

  syntax match texE3Cmd  contained containedin=@texClusterE3 "\\\w\+" nextgroup=texE3Opt,texE3Arg skipwhite skipnl
  call vimtex#syntax#core#new_opt('texE3Opt', {'next': 'texE3Arg'})
  call vimtex#syntax#core#new_arg('texE3Arg', {'next': 'texE3Arg', 'opts': 'contained transparent'})

  syntax match texE3CmdNestedRegionEnd '\\\ExplSyntaxOff'
        \ contained containedin=texE3Arg,texE3Group

  syntax match texE3Var  contained containedin=@texClusterE3 "\\\a*\%(_\+[a-zA-Z]\+\)\+\>"
  syntax match texE3Func contained containedin=@texClusterE3 "\\\a*\%(_\+[a-zA-Z]\+\)\+:[a-zA-Z]*"
  syntax match texE3Parm contained containedin=@texClusterE3 "#\+\d"

  syntax cluster texClusterE3 contains=texE3Region,texE3Arg,texE3Group

  " }}}2
  " {{{2 Region: Math

  " Define math region group
  call vimtex#syntax#core#new_arg('texMathGroup', {'contains': '@texClusterMath'})

  " Define math environment boundaries
  syntax match texCmdMathEnv "\v\\%(begin|end)>" contained nextgroup=texMathEnvArgName
  call vimtex#syntax#core#new_arg('texMathEnvArgName',
        \ {'contains': 'texComment,@NoSpell'})

  " Math regions: environments
  call vimtex#syntax#core#new_region_math('displaymath')
  call vimtex#syntax#core#new_region_math('eqnarray')
  call vimtex#syntax#core#new_region_math('equation')
  call vimtex#syntax#core#new_region_math('math')

  " Math regions: Inline Math Zones
  if g:vimtex_syntax_conceal.math_bounds
    syntax region texMathRegion   matchgroup=texMathDelimRegion concealends contains=@texClusterMath keepend start="\\("  end="\\)"
    syntax region texMathRegion   matchgroup=texMathDelimRegion concealends contains=@texClusterMath keepend start="\\\[" end="\\]"
    syntax region texMathRegionX  matchgroup=texMathDelimRegion concealends contains=@texClusterMath         start="\$"   skip="\\\\\|\\\$"  end="\$"
    syntax region texMathRegionXX matchgroup=texMathDelimRegion concealends contains=@texClusterMath keepend start="\$\$" end="\$\$"
  else
    syntax region texMathRegion   matchgroup=texMathDelimRegion contains=@texClusterMath keepend start="\\("  end="\\)"
    syntax region texMathRegion   matchgroup=texMathDelimRegion contains=@texClusterMath keepend start="\\\[" end="\\]"
    syntax region texMathRegionX  matchgroup=texMathDelimRegion contains=@texClusterMath         start="\$"   skip="\\\\\|\\\$"  end="\$"
    syntax region texMathRegionXX matchgroup=texMathDelimRegion contains=@texClusterMath keepend start="\$\$" end="\$\$"
  endif

  " Math regions: \ensuremath{...}
  syntax match texCmdMath "\\ensuremath\>" nextgroup=texMathRegionEnsured
  call vimtex#syntax#core#new_arg('texMathRegionEnsured', {'contains': '@texClusterMath'})

  " Bad/Mismatched math
  syntax match texMathError "\\[\])]"
  syntax match texMathError "\\end\s*{\s*\(array\|[bBpvV]matrix\|split\|smallmatrix\)\s*}"

  " Operators and similar
  syntax match texMathOper "[_^=+-]" contained

  " Text Inside Math regions
  syntax match texCmdMathText "\\\(\(inter\)\?text\|mbox\)\>" nextgroup=texMathTextArg
  call vimtex#syntax#core#new_arg('texMathTextArg')

  " Math style commands
  syntax match texMathCmdStyle "\\mathbb\>"
  syntax match texMathCmdStyle "\\mathbf\>"
  syntax match texMathCmdStyle "\\mathcal\>"
  syntax match texMathCmdStyle "\\mathfrak\>"
  syntax match texMathCmdStyle "\\mathit\>"
  syntax match texMathCmdStyle "\\mathnormal\>"
  syntax match texMathCmdStyle "\\mathrm\>"
  syntax match texMathCmdStyle "\\mathsf\>"
  syntax match texMathCmdStyle "\\mathtt\>"

  " Support for array environment
  syntax match texMathCmdEnv contained contains=texCmdMathEnv "\\begin{array}" nextgroup=texMathArrayArg skipwhite skipnl
  syntax match texMathCmdEnv contained contains=texCmdMathEnv "\\end{array}"
  call vimtex#syntax#core#new_arg('texMathArrayArg', {'contains': ''})

  call s:match_math_sub_super()
  call s:match_math_symbols()
  call s:match_math_delims()
  call s:match_math_fracs()

  " }}}2
  " {{{2 Conceal mode support

  " Add support for conceal with custom replacement (conceallevel = 2)

  if &encoding ==# 'utf-8'
    " Conceal various commands - be fancy
    if g:vimtex_syntax_conceal.fancy
      call s:match_conceal_fancy()
    endif

    " Conceal replace greek letters
    if g:vimtex_syntax_conceal.greek
      call s:match_conceal_greek()
    endif

    " Conceal replace accented characters and ligatures
    if g:vimtex_syntax_conceal.accents
      call s:match_conceal_accents()
    endif
  endif

  " }}}2

  let b:current_syntax = 'tex'
endfunction

" }}}1
function! vimtex#syntax#core#init_highlights() abort " {{{1
  " See :help group-name for list of conventional group names

  " Primitive TeX highlighting groups
  highlight def link texArg              Include
  highlight def link texCmd              Statement
  highlight def link texCmdSpaceCodeChar Special
  highlight def link texCmdTodo          Todo
  highlight def link texCmdType          Type
  highlight def link texComment          Comment
  highlight def link texCommentTodo      Todo
  highlight def link texDelim            Delimiter
  highlight def link texEnvArgName       PreCondit
  highlight def link texError            Error
  highlight def link texLength           Number
  highlight def link texMathDelim        Type
  highlight def link texMathEnvArgName   Delimiter
  highlight def link texMathOper         Operator
  highlight def link texMathRegion       Special
  highlight def link texOpt              Identifier
  highlight def link texOptSep           NormalNC
  highlight def link texParm             Special
  highlight def link texPartArgTitle     String
  highlight def link texRefArg           Special
  highlight def link texRegion           PreCondit
  highlight def link texSpecialChar      SpecialChar
  highlight def link texSymbol           SpecialChar
  highlight def link texTitleArg         Underlined
  highlight def texStyleBold gui=bold        cterm=bold
  highlight def texStyleBoth gui=bold,italic cterm=bold,italic
  highlight def texStyleItal gui=italic      cterm=italic

  " Inherited groups
  highlight def link texArgNew               texCmd
  highlight def link texAuthorOpt            texOpt
  highlight def link texCmdAccent            texCmd
  highlight def link texCmdAuthor            texCmd
  highlight def link texCmdBib               texCmd
  highlight def link texCmdClass             texCmd
  highlight def link texCmdConditional       texCmd
  highlight def link texCmdDef               texCmdNew
  highlight def link texCmdEnv               texCmd
  highlight def link texCmdE3                texCmd
  highlight def link texCmdFootnote          texCmd
  highlight def link texCmdGreek             texCmd
  highlight def link texCmdInput             texCmd
  highlight def link texCmdItem              texCmdEnv
  highlight def link texCmdLet               texCmdNew
  highlight def link texCmdLigature          texSpecialChar
  highlight def link texCmdMath              texCmd
  highlight def link texCmdMathEnv           texCmdEnv
  highlight def link texCmdMathText          texCmd
  highlight def link texCmdNew               texCmd
  highlight def link texCmdNewcmd            texCmdNew
  highlight def link texCmdNewenv            texCmd
  highlight def link texCmdNoSpell           texCmd
  highlight def link texCmdPackage           texCmd
  highlight def link texCmdPart              texCmd
  highlight def link texCmdRef               texCmd
  highlight def link texCmdSize              texCmdType
  highlight def link texCmdSpaceCode         texCmd
  highlight def link texCmdStyle             texCmd
  highlight def link texCmdStyle             texCmdType
  highlight def link texCmdStyleBold         texCmd
  highlight def link texCmdStyleBoldItal     texCmd
  highlight def link texCmdStyleItal         texCmd
  highlight def link texCmdStyleItalBold     texCmd
  highlight def link texCmdTitle             texCmd
  highlight def link texCmdVerb              texCmd
  highlight def link texCommentAcronym       texComment
  highlight def link texCommentURL           texComment
  highlight def link texConditionalArg       texArg
  highlight def link texDefArgName           texArgNew
  highlight def link texDefParm              texParm
  highlight def link texE3Cmd                texCmd
  highlight def link texE3Delim              texDelim
  highlight def link texE3Func               texCmdType
  highlight def link texE3Opt                texOpt
  highlight def link texE3Parm               texParm
  highlight def link texE3Var                texCmd
  highlight def link texEnvOpt               texOpt
  highlight def link texFileArg              texArg
  highlight def link texFileOpt              texOpt
  highlight def link texFilesArg             texFileArg
  highlight def link texFilesOpt             texFileOpt
  highlight def link texGroupError           texError
  highlight def link texLetArgEqual          texSymbol
  highlight def link texLetArgName           texArgNew
  highlight def link texLigature             texSymbol
  highlight def link texMathArg              texMathRegion
  highlight def link texMathArrayArg         texOpt
  highlight def link texMathCmd              texCmd
  highlight def link texMathCmdStyle         texMathCmd
  highlight def link texMathDelimMod         texMathDelim
  highlight def link texMathDelimRegion      texDelim
  highlight def link texMathError            texError
  highlight def link texMathErrorDelim       texError
  highlight def link texMathGroup            texMathRegion
  highlight def link texMathRegionEnsured    texMathRegion
  highlight def link texMathRegionEnv        texMathRegion
  highlight def link texMathRegionEnvStarred texMathRegion
  highlight def link texMathRegionX          texMathRegion
  highlight def link texMathRegionXX         texMathRegion
  highlight def link texMathSub              texMathRegion
  highlight def link texMathSuper            texMathRegion
  highlight def link texMathSymbol           texCmd
  highlight def link texNewcmdArgName        texArgNew
  highlight def link texNewcmdOpt            texOpt
  highlight def link texNewcmdParm           texParm
  highlight def link texNewenvArgName        texEnvArgName
  highlight def link texNewenvOpt            texOpt
  highlight def link texNewenvParm           texParm
  highlight def link texOptEqual             texSymbol
  highlight def link texRefOpt               texOpt
  highlight def link texTabularArg           texOpt
  highlight def link texTabularChar          texSymbol
  highlight def link texVerbRegion           texRegion
  highlight def link texVerbRegionInline     texVerbRegion
endfunction

" }}}1

function! vimtex#syntax#core#new_arg(grp, ...) abort " {{{1
  let l:cfg = extend({
        \ 'contains': 'TOP,@NoSpell',
        \ 'matcher': 'start="{" skip="\\\\\|\\}" end="}"',
        \ 'next': '',
        \ 'opts': 'contained',
        \}, a:0 > 0 ? a:1 : {})

  execute 'syntax region' a:grp
        \ 'matchgroup=texDelim'
        \ l:cfg.matcher
        \ l:cfg.opts
        \ (empty(l:cfg.contains) ? '' : 'contains=' . l:cfg.contains)
        \ (empty(l:cfg.next) ? '' : 'nextgroup=' . l:cfg.next . ' skipwhite skipnl')
endfunction

" }}}1
function! vimtex#syntax#core#new_opt(grp, ...) abort " {{{1
  let l:cfg = extend({
        \ 'opts': '',
        \ 'next': '',
        \ 'contains': '@texClusterOpt',
        \}, a:0 > 0 ? a:1 : {})

  execute 'syntax region' a:grp
        \ 'contained matchgroup=texDelim'
        \ 'start="\[" skip="\\\\\|\\\]" end="\]"'
        \ l:cfg.opts
        \ (empty(l:cfg.contains) ? '' : 'contains=' . l:cfg.contains)
        \ (empty(l:cfg.next) ? '' : 'nextgroup=' . l:cfg.next . ' skipwhite skipnl')
endfunction

" }}}1

function! vimtex#syntax#core#new_region_env(grp, envname, ...) abort " {{{1
  let l:cfg = extend({
        \ 'contains': '',
        \ 'opts': '',
        \ 'transparent': 0,
        \}, a:0 > 0 ? a:1 : {})

  let l:contains = 'contains=texCmdEnv'
  if !empty(l:cfg.contains)
    let l:contains .= ',' . l:cfg.contains
  endif

  let l:options = 'keepend'
  if l:cfg.transparent
    let l:options .= ' transparent'
  endif
  if !empty(l:cfg.opts)
    let l:options .= ' ' . l:cfg.opts
  endif

  execute 'syntax region' a:grp
        \ 'start="\\begin{' . a:envname .'}"'
        \ 'end="\\end{' . a:envname .'}"'
        \ l:contains
        \ l:options
endfunction

" }}}1
function! vimtex#syntax#core#new_region_math(mathzone, ...) abort " {{{1
  let l:cfg = extend({
        \ 'starred': 1,
        \ 'next': '',
        \}, a:0 > 0 ? a:1 : {})

  let l:envname = a:mathzone . (l:cfg.starred ? '\*\?' : '')

  execute 'syntax match texMathEnvBgnEnd "\\\%(begin\|end\)\>{' . l:envname . '}"'
        \ 'contained contains=texCmdMathEnv'
        \ (empty(l:cfg.next) ? '' : 'nextgroup=' . l:cfg.next . ' skipwhite skipnl')
  execute 'syntax match texMathError "\\end{' . l:envname . '}"'
  execute 'syntax region texMathRegionEnv'
        \ 'start="\\begin{\z(' . l:envname . '\)}"'
        \ 'end="\\end{\z1}"'
        \ 'contains=texMathEnvBgnEnd,@texClusterMath'
        \ 'keepend'
endfunction

" }}}1


function! s:match_bold_italic() abort " {{{1
  let [l:conceal, l:concealends] =
        \ (g:vimtex_syntax_conceal.styles ? ['conceal', 'concealends'] : ['', ''])

  syntax cluster texClusterBold     contains=TOP,@NoSpell,texCmdStyleItal,texCmdStyleBold,texCmdStyleItalBold
  syntax cluster texClusterItal     contains=TOP,@NoSpell,texCmdStyleItal,texCmdStyleBold,texCmdStyleBoldItal
  syntax cluster texClusterItalBold contains=TOP,@NoSpell,texCmdStyleItal,texCmdStyleBold,texCmdStyleItalBold,texCmdStyleBoldItal

  let l:map = {
        \ 'texCmdStyleBold': 'texStyleBold',
        \ 'texCmdStyleBoldItal': 'texStyleBoth',
        \ 'texCmdStyleItal': 'texStyleItal',
        \ 'texCmdStyleItalBold': 'texStyleBoth',
        \}

  for [l:group, l:pattern] in [
        \ ['texCmdStyleBoldItal', 'emph'],
        \ ['texCmdStyleBoldItal', 'textit'],
        \ ['texCmdStyleItalBold', 'textbf'],
        \ ['texCmdStyleBold', 'textbf'],
        \ ['texCmdStyleItal', 'emph'],
        \ ['texCmdStyleItal', 'textit'],
        \]
    execute 'syntax match' l:group '"\\' . l:pattern . '\>\s*" skipwhite skipnl nextgroup=' . l:map[l:group] l:conceal
  endfor

  execute 'syntax region texStyleBold matchgroup=texDelim start=/{/ end=/}/ contained contains=@texClusterBold' l:concealends
  execute 'syntax region texStyleItal matchgroup=texDelim start=/{/ end=/}/ contained contains=@texClusterItal' l:concealends
  execute 'syntax region texStyleBoth matchgroup=texDelim start=/{/ end=/}/ contained contains=@texClusterItalBold' l:concealends
endfunction

" }}}1

function! s:match_math_sub_super() abort " {{{1
  if !g:vimtex_syntax_conceal.math_super_sub | return | endif

  for [l:from, l:to] in filter(copy(s:map_super),
        \ {_, x -> x[0][0] ==# '\' || x[0] =~# '[0-9a-zA-W.,:;+-<>/()=]'})
    execute 'syntax match texMathSuper "\^' . l:from . '" contained conceal cchar=' . l:to 'contains=texMathOper'
  endfor

  for [l:from, l:to] in filter(copy(s:map_sub),
        \ {_, x -> x[0][0] ==# '\' || x[0] =~# '[0-9aehijklmnoprstuvx,+-/().]'})
    execute 'syntax match texMathSub "_' . l:from . '" contained conceal cchar=' . l:to 'contains=texMathOper'
  endfor
endfunction

let s:map_sub = [
      \ ['0',         '₀'],
      \ ['1',         '₁'],
      \ ['2',         '₂'],
      \ ['3',         '₃'],
      \ ['4',         '₄'],
      \ ['5',         '₅'],
      \ ['6',         '₆'],
      \ ['7',         '₇'],
      \ ['8',         '₈'],
      \ ['9',         '₉'],
      \ ['a',         'ₐ'],
      \ ['e',         'ₑ'],
      \ ['h',         'ₕ'],
      \ ['i',         'ᵢ'],
      \ ['j',         'ⱼ'],
      \ ['k',         'ₖ'],
      \ ['l',         'ₗ'],
      \ ['m',         'ₘ'],
      \ ['n',         'ₙ'],
      \ ['o',         'ₒ'],
      \ ['p',         'ₚ'],
      \ ['r',         'ᵣ'],
      \ ['s',         'ₛ'],
      \ ['t',         'ₜ'],
      \ ['u',         'ᵤ'],
      \ ['v',         'ᵥ'],
      \ ['x',         'ₓ'],
      \ [',',         '︐'],
      \ ['+',         '₊'],
      \ ['-',         '₋'],
      \ ['\/',         'ˏ'],
      \ ['(',         '₍'],
      \ [')',         '₎'],
      \ ['\.',        '‸'],
      \ ['r',         'ᵣ'],
      \ ['v',         'ᵥ'],
      \ ['x',         'ₓ'],
      \ ['\\beta\>',  'ᵦ'],
      \ ['\\delta\>', 'ᵨ'],
      \ ['\\phi\>',   'ᵩ'],
      \ ['\\gamma\>', 'ᵧ'],
      \ ['\\chi\>',   'ᵪ'],
      \]

let s:map_super = [
      \ ['0',  '⁰'],
      \ ['1',  '¹'],
      \ ['2',  '²'],
      \ ['3',  '³'],
      \ ['4',  '⁴'],
      \ ['5',  '⁵'],
      \ ['6',  '⁶'],
      \ ['7',  '⁷'],
      \ ['8',  '⁸'],
      \ ['9',  '⁹'],
      \ ['a',  'ᵃ'],
      \ ['b',  'ᵇ'],
      \ ['c',  'ᶜ'],
      \ ['d',  'ᵈ'],
      \ ['e',  'ᵉ'],
      \ ['f',  'ᶠ'],
      \ ['g',  'ᵍ'],
      \ ['h',  'ʰ'],
      \ ['i',  'ⁱ'],
      \ ['j',  'ʲ'],
      \ ['k',  'ᵏ'],
      \ ['l',  'ˡ'],
      \ ['m',  'ᵐ'],
      \ ['n',  'ⁿ'],
      \ ['o',  'ᵒ'],
      \ ['p',  'ᵖ'],
      \ ['r',  'ʳ'],
      \ ['s',  'ˢ'],
      \ ['t',  'ᵗ'],
      \ ['u',  'ᵘ'],
      \ ['v',  'ᵛ'],
      \ ['w',  'ʷ'],
      \ ['x',  'ˣ'],
      \ ['y',  'ʸ'],
      \ ['z',  'ᶻ'],
      \ ['A',  'ᴬ'],
      \ ['B',  'ᴮ'],
      \ ['D',  'ᴰ'],
      \ ['E',  'ᴱ'],
      \ ['G',  'ᴳ'],
      \ ['H',  'ᴴ'],
      \ ['I',  'ᴵ'],
      \ ['J',  'ᴶ'],
      \ ['K',  'ᴷ'],
      \ ['L',  'ᴸ'],
      \ ['M',  'ᴹ'],
      \ ['N',  'ᴺ'],
      \ ['O',  'ᴼ'],
      \ ['P',  'ᴾ'],
      \ ['R',  'ᴿ'],
      \ ['T',  'ᵀ'],
      \ ['U',  'ᵁ'],
      \ ['V',  'ⱽ'],
      \ ['W',  'ᵂ'],
      \ [',',  '︐'],
      \ [':',  '︓'],
      \ [';',  '︔'],
      \ ['+',  '⁺'],
      \ ['-',  '⁻'],
      \ ['<',  '˂'],
      \ ['>',  '˃'],
      \ ['\/',  'ˊ'],
      \ ['(',  '⁽'],
      \ [')',  '⁾'],
      \ ['\.', '˙'],
      \ ['=',  '˭'],
      \]

" }}}1
function! s:match_math_symbols() abort " {{{1
  " Many of these symbols were contributed by Björn Winckler
  if !g:vimtex_syntax_conceal.math_symbols | return | endif

  syntax match texMathSymbol "\\|"                   contained conceal cchar=‖
  syntax match texMathSymbol "\\aleph\>"             contained conceal cchar=ℵ
  syntax match texMathSymbol "\\amalg\>"             contained conceal cchar=∐
  syntax match texMathSymbol "\\angle\>"             contained conceal cchar=∠
  syntax match texMathSymbol "\\approx\>"            contained conceal cchar=≈
  syntax match texMathSymbol "\\ast\>"               contained conceal cchar=∗
  syntax match texMathSymbol "\\asymp\>"             contained conceal cchar=≍
  syntax match texMathSymbol "\\backslash\>"         contained conceal cchar=∖
  syntax match texMathSymbol "\\bigcap\>"            contained conceal cchar=∩
  syntax match texMathSymbol "\\bigcirc\>"           contained conceal cchar=○
  syntax match texMathSymbol "\\bigcup\>"            contained conceal cchar=∪
  syntax match texMathSymbol "\\bigodot\>"           contained conceal cchar=⊙
  syntax match texMathSymbol "\\bigoplus\>"          contained conceal cchar=⊕
  syntax match texMathSymbol "\\bigotimes\>"         contained conceal cchar=⊗
  syntax match texMathSymbol "\\bigsqcup\>"          contained conceal cchar=⊔
  syntax match texMathSymbol "\\bigtriangledown\>"   contained conceal cchar=∇
  syntax match texMathSymbol "\\bigtriangleup\>"     contained conceal cchar=∆
  syntax match texMathSymbol "\\bigvee\>"            contained conceal cchar=⋁
  syntax match texMathSymbol "\\bigwedge\>"          contained conceal cchar=⋀
  syntax match texMathSymbol "\\bot\>"               contained conceal cchar=⊥
  syntax match texMathSymbol "\\bowtie\>"            contained conceal cchar=⋈
  syntax match texMathSymbol "\\bullet\>"            contained conceal cchar=•
  syntax match texMathSymbol "\\cap\>"               contained conceal cchar=∩
  syntax match texMathSymbol "\\cdot\>"              contained conceal cchar=·
  syntax match texMathSymbol "\\cdots\>"             contained conceal cchar=⋯
  syntax match texMathSymbol "\\circ\>"              contained conceal cchar=∘
  syntax match texMathSymbol "\\clubsuit\>"          contained conceal cchar=♣
  syntax match texMathSymbol "\\cong\>"              contained conceal cchar=≅
  syntax match texMathSymbol "\\coprod\>"            contained conceal cchar=∐
  syntax match texMathSymbol "\\copyright\>"         contained conceal cchar=©
  syntax match texMathSymbol "\\cup\>"               contained conceal cchar=∪
  syntax match texMathSymbol "\\dagger\>"            contained conceal cchar=†
  syntax match texMathSymbol "\\dashv\>"             contained conceal cchar=⊣
  syntax match texMathSymbol "\\ddagger\>"           contained conceal cchar=‡
  syntax match texMathSymbol "\\ddots\>"             contained conceal cchar=⋱
  syntax match texMathSymbol "\\diamond\>"           contained conceal cchar=⋄
  syntax match texMathSymbol "\\diamondsuit\>"       contained conceal cchar=♢
  syntax match texMathSymbol "\\div\>"               contained conceal cchar=÷
  syntax match texMathSymbol "\\doteq\>"             contained conceal cchar=≐
  syntax match texMathSymbol "\\dots\>"              contained conceal cchar=…
  syntax match texMathSymbol "\\downarrow\>"         contained conceal cchar=↓
  syntax match texMathSymbol "\\Downarrow\>"         contained conceal cchar=⇓
  syntax match texMathSymbol "\\ell\>"               contained conceal cchar=ℓ
  syntax match texMathSymbol "\\emptyset\>"          contained conceal cchar=Ø
  syntax match texMathSymbol "\\equiv\>"             contained conceal cchar=≡
  syntax match texMathSymbol "\\exists\>"            contained conceal cchar=∃
  syntax match texMathSymbol "\\flat\>"              contained conceal cchar=♭
  syntax match texMathSymbol "\\forall\>"            contained conceal cchar=∀
  syntax match texMathSymbol "\\frown\>"             contained conceal cchar=⁔
  syntax match texMathSymbol "\\ge\>"                contained conceal cchar=≥
  syntax match texMathSymbol "\\geq\>"               contained conceal cchar=≥
  syntax match texMathSymbol "\\gets\>"              contained conceal cchar=←
  syntax match texMathSymbol "\\gg\>"                contained conceal cchar=⟫
  syntax match texMathSymbol "\\hbar\>"              contained conceal cchar=ℏ
  syntax match texMathSymbol "\\heartsuit\>"         contained conceal cchar=♡
  syntax match texMathSymbol "\\hookleftarrow\>"     contained conceal cchar=↩
  syntax match texMathSymbol "\\hookrightarrow\>"    contained conceal cchar=↪
  syntax match texMathSymbol "\\iff\>"               contained conceal cchar=⇔
  syntax match texMathSymbol "\\Im\>"                contained conceal cchar=ℑ
  syntax match texMathSymbol "\\imath\>"             contained conceal cchar=ɩ
  syntax match texMathSymbol "\\in\>"                contained conceal cchar=∈
  syntax match texMathSymbol "\\infty\>"             contained conceal cchar=∞
  syntax match texMathSymbol "\\int\>"               contained conceal cchar=∫
  syntax match texMathSymbol "\\jmath\>"             contained conceal cchar=𝚥
  syntax match texMathSymbol "\\land\>"              contained conceal cchar=∧
  syntax match texMathSymbol '\\lnot\>'              contained conceal cchar=¬
  syntax match texMathSymbol "\\lceil\>"             contained conceal cchar=⌈
  syntax match texMathSymbol "\\ldots\>"             contained conceal cchar=…
  syntax match texMathSymbol "\\le\>"                contained conceal cchar=≤
  syntax match texMathSymbol "\\left|"               contained conceal cchar=|
  syntax match texMathSymbol "\\left\\|"             contained conceal cchar=‖
  syntax match texMathSymbol "\\left("               contained conceal cchar=(
  syntax match texMathSymbol "\\left\["              contained conceal cchar=[
  syntax match texMathSymbol "\\left\\{"             contained conceal cchar={
  syntax match texMathSymbol "\\leftarrow\>"         contained conceal cchar=←
  syntax match texMathSymbol "\\Leftarrow\>"         contained conceal cchar=⇐
  syntax match texMathSymbol '\\langle\>'            contained conceal cchar=⟨
  syntax match texMathSymbol '\\rangle\>'            contained conceal cchar=⟩
  syntax match texMathSymbol "\\leftharpoondown\>"   contained conceal cchar=↽
  syntax match texMathSymbol "\\leftharpoonup\>"     contained conceal cchar=↼
  syntax match texMathSymbol "\\leftrightarrow\>"    contained conceal cchar=↔
  syntax match texMathSymbol "\\Leftrightarrow\>"    contained conceal cchar=⇔
  syntax match texMathSymbol "\\leq\>"               contained conceal cchar=≤
  syntax match texMathSymbol "\\lfloor\>"            contained conceal cchar=⌊
  syntax match texMathSymbol "\\ll\>"                contained conceal cchar=≪
  syntax match texMathSymbol "\\lmoustache\>"        contained conceal cchar=╭
  syntax match texMathSymbol "\\lor\>"               contained conceal cchar=∨
  syntax match texMathSymbol "\\mapsto\>"            contained conceal cchar=↦
  syntax match texMathSymbol "\\mid\>"               contained conceal cchar=∣
  syntax match texMathSymbol "\\models\>"            contained conceal cchar=⊨
  syntax match texMathSymbol "\\mp\>"                contained conceal cchar=∓
  syntax match texMathSymbol "\\nabla\>"             contained conceal cchar=∇
  syntax match texMathSymbol "\\natural\>"           contained conceal cchar=♮
  syntax match texMathSymbol "\\ne\>"                contained conceal cchar=≠
  syntax match texMathSymbol "\\nearrow\>"           contained conceal cchar=↗
  syntax match texMathSymbol "\\neg\>"               contained conceal cchar=¬
  syntax match texMathSymbol "\\neq\>"               contained conceal cchar=≠
  syntax match texMathSymbol "\\ni\>"                contained conceal cchar=∋
  syntax match texMathSymbol "\\notin\>"             contained conceal cchar=∉
  syntax match texMathSymbol "\\nwarrow\>"           contained conceal cchar=↖
  syntax match texMathSymbol "\\odot\>"              contained conceal cchar=⊙
  syntax match texMathSymbol "\\oint\>"              contained conceal cchar=∮
  syntax match texMathSymbol "\\ominus\>"            contained conceal cchar=⊖
  syntax match texMathSymbol "\\oplus\>"             contained conceal cchar=⊕
  syntax match texMathSymbol "\\oslash\>"            contained conceal cchar=⊘
  syntax match texMathSymbol "\\otimes\>"            contained conceal cchar=⊗
  syntax match texMathSymbol "\\owns\>"              contained conceal cchar=∋
  syntax match texMathSymbol "\\P\>"                 contained conceal cchar=¶
  syntax match texMathSymbol "\\parallel\>"          contained conceal cchar=║
  syntax match texMathSymbol "\\partial\>"           contained conceal cchar=∂
  syntax match texMathSymbol "\\perp\>"              contained conceal cchar=⊥
  syntax match texMathSymbol "\\pm\>"                contained conceal cchar=±
  syntax match texMathSymbol "\\prec\>"              contained conceal cchar=≺
  syntax match texMathSymbol "\\preceq\>"            contained conceal cchar=⪯
  syntax match texMathSymbol "\\prime\>"             contained conceal cchar=′
  syntax match texMathSymbol "\\prod\>"              contained conceal cchar=∏
  syntax match texMathSymbol "\\propto\>"            contained conceal cchar=∝
  syntax match texMathSymbol "\\rceil\>"             contained conceal cchar=⌉
  syntax match texMathSymbol "\\Re\>"                contained conceal cchar=ℜ
  syntax match texMathSymbol "\\quad\>"              contained conceal cchar= 
  syntax match texMathSymbol "\\qquad\>"             contained conceal cchar= 
  syntax match texMathSymbol "\\rfloor\>"            contained conceal cchar=⌋
  syntax match texMathSymbol "\\right|"              contained conceal cchar=|
  syntax match texMathSymbol "\\right\\|"            contained conceal cchar=‖
  syntax match texMathSymbol "\\right)"              contained conceal cchar=)
  syntax match texMathSymbol "\\right]"              contained conceal cchar=]
  syntax match texMathSymbol "\\right\\}"            contained conceal cchar=}
  syntax match texMathSymbol "\\rightarrow\>"        contained conceal cchar=→
  syntax match texMathSymbol "\\Rightarrow\>"        contained conceal cchar=⇒
  syntax match texMathSymbol '\\leftarrow\>'         contained conceal cchar=←
  syntax match texMathSymbol '\\Leftarrow\>'         contained conceal cchar=⇐
  syntax match texMathSymbol "\\rightleftharpoons\>" contained conceal cchar=⇌
  syntax match texMathSymbol "\\rmoustache\>"        contained conceal cchar=╮
  syntax match texMathSymbol "\\S\>"                 contained conceal cchar=§
  syntax match texMathSymbol "\\searrow\>"           contained conceal cchar=↘
  syntax match texMathSymbol "\\setminus\>"          contained conceal cchar=⧵
  syntax match texMathSymbol "\\sharp\>"             contained conceal cchar=♯
  syntax match texMathSymbol "\\sim\>"               contained conceal cchar=∼
  syntax match texMathSymbol "\\simeq\>"             contained conceal cchar=⋍
  syntax match texMathSymbol "\\smile\>"             contained conceal cchar=‿
  syntax match texMathSymbol "\\spadesuit\>"         contained conceal cchar=♠
  syntax match texMathSymbol "\\sqcap\>"             contained conceal cchar=⊓
  syntax match texMathSymbol "\\sqcup\>"             contained conceal cchar=⊔
  syntax match texMathSymbol "\\sqsubset\>"          contained conceal cchar=⊏
  syntax match texMathSymbol "\\sqsubseteq\>"        contained conceal cchar=⊑
  syntax match texMathSymbol "\\sqsupset\>"          contained conceal cchar=⊐
  syntax match texMathSymbol "\\sqsupseteq\>"        contained conceal cchar=⊒
  syntax match texMathSymbol "\\star\>"              contained conceal cchar=✫
  syntax match texMathSymbol "\\subset\>"            contained conceal cchar=⊂
  syntax match texMathSymbol "\\subseteq\>"          contained conceal cchar=⊆
  syntax match texMathSymbol "\\succ\>"              contained conceal cchar=≻
  syntax match texMathSymbol "\\succeq\>"            contained conceal cchar=⪰
  syntax match texMathSymbol "\\sum\>"               contained conceal cchar=∑
  syntax match texMathSymbol "\\supset\>"            contained conceal cchar=⊃
  syntax match texMathSymbol "\\supseteq\>"          contained conceal cchar=⊇
  syntax match texMathSymbol "\\surd\>"              contained conceal cchar=√
  syntax match texMathSymbol "\\swarrow\>"           contained conceal cchar=↙
  syntax match texMathSymbol "\\times\>"             contained conceal cchar=x
  syntax match texMathSymbol "\\to\>"                contained conceal cchar=→
  syntax match texMathSymbol "\\top\>"               contained conceal cchar=⊤
  syntax match texMathSymbol "\\triangle\>"          contained conceal cchar=∆
  syntax match texMathSymbol "\\triangleleft\>"      contained conceal cchar=⊲
  syntax match texMathSymbol "\\triangleright\>"     contained conceal cchar=⊳
  syntax match texMathSymbol "\\uparrow\>"           contained conceal cchar=↑
  syntax match texMathSymbol "\\Uparrow\>"           contained conceal cchar=⇑
  syntax match texMathSymbol "\\updownarrow\>"       contained conceal cchar=↕
  syntax match texMathSymbol "\\Updownarrow\>"       contained conceal cchar=⇕
  syntax match texMathSymbol "\\vdash\>"             contained conceal cchar=⊢
  syntax match texMathSymbol "\\vdots\>"             contained conceal cchar=⋮
  syntax match texMathSymbol "\\vee\>"               contained conceal cchar=∨
  syntax match texMathSymbol "\\wedge\>"             contained conceal cchar=∧
  syntax match texMathSymbol "\\wp\>"                contained conceal cchar=℘
  syntax match texMathSymbol "\\wr\>"                contained conceal cchar=≀
  syntax match texMathSymbol '\\implies\>'           contained conceal cchar=⇒
  syntax match texMathSymbol '\\geqslant\>'          contained conceal cchar=⩾
  syntax match texMathSymbol '\\leqslant\>'          contained conceal cchar=⩽
  syntax match texMathSymbol '\\choose\>'            contained conceal cchar=C
  syntax match texMathSymbol '\\sqrt\>'              contained conceal cchar=√
  syntax match texMathSymbol '\\sqrt\[3]'            contained conceal cchar=∛
  syntax match texMathSymbol '\\sqrt\[4]'            contained conceal cchar=∜
  syntax match texMathSymbol '\\coloneqq\>'          contained conceal cchar=≔

  if &ambiwidth ==# 'double'
    syntax match texMathSymbol '\\gg\>'          contained conceal cchar=≫
    syntax match texMathSymbol '\\ll\>'          contained conceal cchar=≪
  else
    syntax match texMathSymbol '\\gg\>'          contained conceal cchar=⟫
    syntax match texMathSymbol '\\ll\>'          contained conceal cchar=⟪
  endif

  syntax match texMathSymbol '\\bar{a}' contained conceal cchar=a̅

  syntax match texMathSymbol '\\dot{A}' contained conceal cchar=Ȧ
  syntax match texMathSymbol '\\dot{a}' contained conceal cchar=ȧ
  syntax match texMathSymbol '\\dot{B}' contained conceal cchar=Ḃ
  syntax match texMathSymbol '\\dot{b}' contained conceal cchar=ḃ
  syntax match texMathSymbol '\\dot{C}' contained conceal cchar=Ċ
  syntax match texMathSymbol '\\dot{c}' contained conceal cchar=ċ
  syntax match texMathSymbol '\\dot{D}' contained conceal cchar=Ḋ
  syntax match texMathSymbol '\\dot{d}' contained conceal cchar=ḋ
  syntax match texMathSymbol '\\dot{E}' contained conceal cchar=Ė
  syntax match texMathSymbol '\\dot{e}' contained conceal cchar=ė
  syntax match texMathSymbol '\\dot{F}' contained conceal cchar=Ḟ
  syntax match texMathSymbol '\\dot{f}' contained conceal cchar=ḟ
  syntax match texMathSymbol '\\dot{G}' contained conceal cchar=Ġ
  syntax match texMathSymbol '\\dot{g}' contained conceal cchar=ġ
  syntax match texMathSymbol '\\dot{H}' contained conceal cchar=Ḣ
  syntax match texMathSymbol '\\dot{h}' contained conceal cchar=ḣ
  syntax match texMathSymbol '\\dot{I}' contained conceal cchar=İ
  syntax match texMathSymbol '\\dot{M}' contained conceal cchar=Ṁ
  syntax match texMathSymbol '\\dot{m}' contained conceal cchar=ṁ
  syntax match texMathSymbol '\\dot{N}' contained conceal cchar=Ṅ
  syntax match texMathSymbol '\\dot{n}' contained conceal cchar=ṅ
  syntax match texMathSymbol '\\dot{O}' contained conceal cchar=Ȯ
  syntax match texMathSymbol '\\dot{o}' contained conceal cchar=ȯ
  syntax match texMathSymbol '\\dot{P}' contained conceal cchar=Ṗ
  syntax match texMathSymbol '\\dot{p}' contained conceal cchar=ṗ
  syntax match texMathSymbol '\\dot{R}' contained conceal cchar=Ṙ
  syntax match texMathSymbol '\\dot{r}' contained conceal cchar=ṙ
  syntax match texMathSymbol '\\dot{S}' contained conceal cchar=Ṡ
  syntax match texMathSymbol '\\dot{s}' contained conceal cchar=ṡ
  syntax match texMathSymbol '\\dot{T}' contained conceal cchar=Ṫ
  syntax match texMathSymbol '\\dot{t}' contained conceal cchar=ṫ
  syntax match texMathSymbol '\\dot{W}' contained conceal cchar=Ẇ
  syntax match texMathSymbol '\\dot{w}' contained conceal cchar=ẇ
  syntax match texMathSymbol '\\dot{X}' contained conceal cchar=Ẋ
  syntax match texMathSymbol '\\dot{x}' contained conceal cchar=ẋ
  syntax match texMathSymbol '\\dot{Y}' contained conceal cchar=Ẏ
  syntax match texMathSymbol '\\dot{y}' contained conceal cchar=ẏ
  syntax match texMathSymbol '\\dot{Z}' contained conceal cchar=Ż
  syntax match texMathSymbol '\\dot{z}' contained conceal cchar=ż

  syntax match texMathSymbol '\\hat{a}' contained conceal cchar=â
  syntax match texMathSymbol '\\hat{A}' contained conceal cchar=Â
  syntax match texMathSymbol '\\hat{c}' contained conceal cchar=ĉ
  syntax match texMathSymbol '\\hat{C}' contained conceal cchar=Ĉ
  syntax match texMathSymbol '\\hat{e}' contained conceal cchar=ê
  syntax match texMathSymbol '\\hat{E}' contained conceal cchar=Ê
  syntax match texMathSymbol '\\hat{g}' contained conceal cchar=ĝ
  syntax match texMathSymbol '\\hat{G}' contained conceal cchar=Ĝ
  syntax match texMathSymbol '\\hat{i}' contained conceal cchar=î
  syntax match texMathSymbol '\\hat{I}' contained conceal cchar=Î
  syntax match texMathSymbol '\\hat{o}' contained conceal cchar=ô
  syntax match texMathSymbol '\\hat{O}' contained conceal cchar=Ô
  syntax match texMathSymbol '\\hat{s}' contained conceal cchar=ŝ
  syntax match texMathSymbol '\\hat{S}' contained conceal cchar=Ŝ
  syntax match texMathSymbol '\\hat{u}' contained conceal cchar=û
  syntax match texMathSymbol '\\hat{U}' contained conceal cchar=Û
  syntax match texMathSymbol '\\hat{w}' contained conceal cchar=ŵ
  syntax match texMathSymbol '\\hat{W}' contained conceal cchar=Ŵ
  syntax match texMathSymbol '\\hat{y}' contained conceal cchar=ŷ
  syntax match texMathSymbol '\\hat{Y}' contained conceal cchar=Ŷ

  " \mathbb characters
  syntax match texMathSymbol '\\mathbb{\s*A\s*}' contained conceal cchar=𝔸
  syntax match texMathSymbol '\\mathbb{\s*B\s*}' contained conceal cchar=𝔹
  syntax match texMathSymbol '\\mathbb{\s*C\s*}' contained conceal cchar=ℂ
  syntax match texMathSymbol '\\mathbb{\s*D\s*}' contained conceal cchar=𝔻
  syntax match texMathSymbol '\\mathbb{\s*E\s*}' contained conceal cchar=𝔼
  syntax match texMathSymbol '\\mathbb{\s*F\s*}' contained conceal cchar=𝔽
  syntax match texMathSymbol '\\mathbb{\s*G\s*}' contained conceal cchar=𝔾
  syntax match texMathSymbol '\\mathbb{\s*H\s*}' contained conceal cchar=ℍ
  syntax match texMathSymbol '\\mathbb{\s*I\s*}' contained conceal cchar=𝕀
  syntax match texMathSymbol '\\mathbb{\s*J\s*}' contained conceal cchar=𝕁
  syntax match texMathSymbol '\\mathbb{\s*K\s*}' contained conceal cchar=𝕂
  syntax match texMathSymbol '\\mathbb{\s*L\s*}' contained conceal cchar=𝕃
  syntax match texMathSymbol '\\mathbb{\s*M\s*}' contained conceal cchar=𝕄
  syntax match texMathSymbol '\\mathbb{\s*N\s*}' contained conceal cchar=ℕ
  syntax match texMathSymbol '\\mathbb{\s*O\s*}' contained conceal cchar=𝕆
  syntax match texMathSymbol '\\mathbb{\s*P\s*}' contained conceal cchar=ℙ
  syntax match texMathSymbol '\\mathbb{\s*Q\s*}' contained conceal cchar=ℚ
  syntax match texMathSymbol '\\mathbb{\s*R\s*}' contained conceal cchar=ℝ
  syntax match texMathSymbol '\\mathbb{\s*S\s*}' contained conceal cchar=𝕊
  syntax match texMathSymbol '\\mathbb{\s*T\s*}' contained conceal cchar=𝕋
  syntax match texMathSymbol '\\mathbb{\s*U\s*}' contained conceal cchar=𝕌
  syntax match texMathSymbol '\\mathbb{\s*V\s*}' contained conceal cchar=𝕍
  syntax match texMathSymbol '\\mathbb{\s*W\s*}' contained conceal cchar=𝕎
  syntax match texMathSymbol '\\mathbb{\s*X\s*}' contained conceal cchar=𝕏
  syntax match texMathSymbol '\\mathbb{\s*Y\s*}' contained conceal cchar=𝕐
  syntax match texMathSymbol '\\mathbb{\s*Z\s*}' contained conceal cchar=ℤ

  " \mathfrak characters
  syntax match texMathSymbol '\\mathfrak{\s*a\s*}' contained conceal cchar=𝔞
  syntax match texMathSymbol '\\mathfrak{\s*b\s*}' contained conceal cchar=𝔟
  syntax match texMathSymbol '\\mathfrak{\s*c\s*}' contained conceal cchar=𝔠
  syntax match texMathSymbol '\\mathfrak{\s*d\s*}' contained conceal cchar=𝔡
  syntax match texMathSymbol '\\mathfrak{\s*e\s*}' contained conceal cchar=𝔢
  syntax match texMathSymbol '\\mathfrak{\s*f\s*}' contained conceal cchar=𝔣
  syntax match texMathSymbol '\\mathfrak{\s*g\s*}' contained conceal cchar=𝔤
  syntax match texMathSymbol '\\mathfrak{\s*h\s*}' contained conceal cchar=𝔥
  syntax match texMathSymbol '\\mathfrak{\s*i\s*}' contained conceal cchar=𝔦
  syntax match texMathSymbol '\\mathfrak{\s*j\s*}' contained conceal cchar=𝔧
  syntax match texMathSymbol '\\mathfrak{\s*k\s*}' contained conceal cchar=𝔨
  syntax match texMathSymbol '\\mathfrak{\s*l\s*}' contained conceal cchar=𝔩
  syntax match texMathSymbol '\\mathfrak{\s*m\s*}' contained conceal cchar=𝔪
  syntax match texMathSymbol '\\mathfrak{\s*n\s*}' contained conceal cchar=𝔫
  syntax match texMathSymbol '\\mathfrak{\s*o\s*}' contained conceal cchar=𝔬
  syntax match texMathSymbol '\\mathfrak{\s*p\s*}' contained conceal cchar=𝔭
  syntax match texMathSymbol '\\mathfrak{\s*q\s*}' contained conceal cchar=𝔮
  syntax match texMathSymbol '\\mathfrak{\s*r\s*}' contained conceal cchar=𝔯
  syntax match texMathSymbol '\\mathfrak{\s*s\s*}' contained conceal cchar=𝔰
  syntax match texMathSymbol '\\mathfrak{\s*t\s*}' contained conceal cchar=𝔱
  syntax match texMathSymbol '\\mathfrak{\s*u\s*}' contained conceal cchar=𝔲
  syntax match texMathSymbol '\\mathfrak{\s*v\s*}' contained conceal cchar=𝔳
  syntax match texMathSymbol '\\mathfrak{\s*w\s*}' contained conceal cchar=𝔴
  syntax match texMathSymbol '\\mathfrak{\s*x\s*}' contained conceal cchar=𝔵
  syntax match texMathSymbol '\\mathfrak{\s*y\s*}' contained conceal cchar=𝔶
  syntax match texMathSymbol '\\mathfrak{\s*z\s*}' contained conceal cchar=𝔷
  syntax match texMathSymbol '\\mathfrak{\s*A\s*}' contained conceal cchar=𝔄
  syntax match texMathSymbol '\\mathfrak{\s*B\s*}' contained conceal cchar=𝔅
  syntax match texMathSymbol '\\mathfrak{\s*C\s*}' contained conceal cchar=ℭ
  syntax match texMathSymbol '\\mathfrak{\s*D\s*}' contained conceal cchar=𝔇
  syntax match texMathSymbol '\\mathfrak{\s*E\s*}' contained conceal cchar=𝔈
  syntax match texMathSymbol '\\mathfrak{\s*F\s*}' contained conceal cchar=𝔉
  syntax match texMathSymbol '\\mathfrak{\s*G\s*}' contained conceal cchar=𝔊
  syntax match texMathSymbol '\\mathfrak{\s*H\s*}' contained conceal cchar=ℌ
  syntax match texMathSymbol '\\mathfrak{\s*I\s*}' contained conceal cchar=ℑ
  syntax match texMathSymbol '\\mathfrak{\s*J\s*}' contained conceal cchar=𝔍
  syntax match texMathSymbol '\\mathfrak{\s*K\s*}' contained conceal cchar=𝔎
  syntax match texMathSymbol '\\mathfrak{\s*L\s*}' contained conceal cchar=𝔏
  syntax match texMathSymbol '\\mathfrak{\s*M\s*}' contained conceal cchar=𝔐
  syntax match texMathSymbol '\\mathfrak{\s*N\s*}' contained conceal cchar=𝔑
  syntax match texMathSymbol '\\mathfrak{\s*O\s*}' contained conceal cchar=𝔒
  syntax match texMathSymbol '\\mathfrak{\s*P\s*}' contained conceal cchar=𝔓
  syntax match texMathSymbol '\\mathfrak{\s*Q\s*}' contained conceal cchar=𝔔
  syntax match texMathSymbol '\\mathfrak{\s*R\s*}' contained conceal cchar=ℜ
  syntax match texMathSymbol '\\mathfrak{\s*S\s*}' contained conceal cchar=𝔖
  syntax match texMathSymbol '\\mathfrak{\s*T\s*}' contained conceal cchar=𝔗
  syntax match texMathSymbol '\\mathfrak{\s*U\s*}' contained conceal cchar=𝔘
  syntax match texMathSymbol '\\mathfrak{\s*V\s*}' contained conceal cchar=𝔙
  syntax match texMathSymbol '\\mathfrak{\s*W\s*}' contained conceal cchar=𝔚
  syntax match texMathSymbol '\\mathfrak{\s*X\s*}' contained conceal cchar=𝔛
  syntax match texMathSymbol '\\mathfrak{\s*Y\s*}' contained conceal cchar=𝔜
  syntax match texMathSymbol '\\mathfrak{\s*Z\s*}' contained conceal cchar=ℨ

  " \mathcal characters
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*A\s*}' contained conceal cchar=𝓐
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*B\s*}' contained conceal cchar=𝓑
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*C\s*}' contained conceal cchar=𝓒
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*D\s*}' contained conceal cchar=𝓓
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*E\s*}' contained conceal cchar=𝓔
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*F\s*}' contained conceal cchar=𝓕
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*G\s*}' contained conceal cchar=𝓖
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*H\s*}' contained conceal cchar=𝓗
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*I\s*}' contained conceal cchar=𝓘
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*J\s*}' contained conceal cchar=𝓙
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*K\s*}' contained conceal cchar=𝓚
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*L\s*}' contained conceal cchar=𝓛
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*M\s*}' contained conceal cchar=𝓜
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*N\s*}' contained conceal cchar=𝓝
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*O\s*}' contained conceal cchar=𝓞
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*P\s*}' contained conceal cchar=𝓟
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*Q\s*}' contained conceal cchar=𝓠
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*R\s*}' contained conceal cchar=𝓡
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*S\s*}' contained conceal cchar=𝓢
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*T\s*}' contained conceal cchar=𝓣
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*U\s*}' contained conceal cchar=𝓤
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*V\s*}' contained conceal cchar=𝓥
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*W\s*}' contained conceal cchar=𝓦
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*X\s*}' contained conceal cchar=𝓧
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*Y\s*}' contained conceal cchar=𝓨
  syntax match texMathSymbol '\\math\%(scr\|cal\){\s*Z\s*}' contained conceal cchar=𝓩
endfunction

" }}}1
function! s:match_math_fracs() abort " {{{1
  if !g:vimtex_syntax_conceal.math_fracs | return | endif

  syntax match texMathSymbol '\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(2\|{2}\)' contained conceal cchar=½
  syntax match texMathSymbol '\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(3\|{3}\)' contained conceal cchar=⅓
  syntax match texMathSymbol '\\[dt]\?frac\s*\%(2\|{2}\)\s*\%(3\|{3}\)' contained conceal cchar=⅔
  syntax match texMathSymbol '\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(4\|{4}\)' contained conceal cchar=¼
  syntax match texMathSymbol '\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(5\|{5}\)' contained conceal cchar=⅕
  syntax match texMathSymbol '\\[dt]\?frac\s*\%(2\|{2}\)\s*\%(5\|{5}\)' contained conceal cchar=⅖
  syntax match texMathSymbol '\\[dt]\?frac\s*\%(3\|{3}\)\s*\%(5\|{5}\)' contained conceal cchar=⅗
  syntax match texMathSymbol '\\[dt]\?frac\s*\%(4\|{4}\)\s*\%(5\|{5}\)' contained conceal cchar=⅘
  syntax match texMathSymbol '\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(6\|{6}\)' contained conceal cchar=⅙
  syntax match texMathSymbol '\\[dt]\?frac\s*\%(5\|{5}\)\s*\%(6\|{6}\)' contained conceal cchar=⅚
  syntax match texMathSymbol '\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(8\|{8}\)' contained conceal cchar=⅛
  syntax match texMathSymbol '\\[dt]\?frac\s*\%(3\|{3}\)\s*\%(8\|{8}\)' contained conceal cchar=⅜
  syntax match texMathSymbol '\\[dt]\?frac\s*\%(5\|{5}\)\s*\%(8\|{8}\)' contained conceal cchar=⅝
  syntax match texMathSymbol '\\[dt]\?frac\s*\%(7\|{7}\)\s*\%(8\|{8}\)' contained conceal cchar=⅞
endfunction

" }}}1
function! s:match_math_delims() abort " {{{1
  syntax match texMathDelimMod contained "\\\(left\|right\)\>"
  syntax match texMathDelimMod contained "\\[bB]igg\?[lr]\?\>"
  syntax match texMathDelim contained "[<>()[\]|/.]\|\\[{}|]"
  syntax match texMathDelim contained "\\backslash"
  syntax match texMathDelim contained "\\downarrow"
  syntax match texMathDelim contained "\\Downarrow"
  syntax match texMathDelim contained "\\lVert"
  syntax match texMathDelim contained "\\langle"
  syntax match texMathDelim contained "\\lbrace"
  syntax match texMathDelim contained "\\lceil"
  syntax match texMathDelim contained "\\lfloor"
  syntax match texMathDelim contained "\\lgroup"
  syntax match texMathDelim contained "\\lmoustache"
  syntax match texMathDelim contained "\\lvert"
  syntax match texMathDelim contained "\\rVert"
  syntax match texMathDelim contained "\\rangle"
  syntax match texMathDelim contained "\\rbrace"
  syntax match texMathDelim contained "\\rceil"
  syntax match texMathDelim contained "\\rfloor"
  syntax match texMathDelim contained "\\rgroup"
  syntax match texMathDelim contained "\\rmoustache"
  syntax match texMathDelim contained "\\rvert"
  syntax match texMathDelim contained "\\uparrow"
  syntax match texMathDelim contained "\\Uparrow"
  syntax match texMathDelim contained "\\updownarrow"
  syntax match texMathDelim contained "\\Updownarrow"

  if !g:vimtex_syntax_conceal.math_delimiters || &encoding !=# 'utf-8'
    return
  endif

  syntax match texMathDelim contained conceal cchar=< "\\\%([bB]igg\?l\|left\)<"
  syntax match texMathDelim contained conceal cchar=> "\\\%([bB]igg\?r\|right\)>"
  syntax match texMathDelim contained conceal cchar=( "\\\%([bB]igg\?l\|left\)("
  syntax match texMathDelim contained conceal cchar=) "\\\%([bB]igg\?r\|right\))"
  syntax match texMathDelim contained conceal cchar=[ "\\\%([bB]igg\?l\|left\)\["
  syntax match texMathDelim contained conceal cchar=] "\\\%([bB]igg\?r\|right\)]"
  syntax match texMathDelim contained conceal cchar={ "\\\%([bB]igg\?l\|left\)\\{"
  syntax match texMathDelim contained conceal cchar=} "\\\%([bB]igg\?r\|right\)\\}"
  syntax match texMathDelim contained conceal cchar=[ "\\\%([bB]igg\?l\|left\)\\lbrace"
  syntax match texMathDelim contained conceal cchar=⌈ "\\\%([bB]igg\?l\|left\)\\lceil"
  syntax match texMathDelim contained conceal cchar=⌊ "\\\%([bB]igg\?l\|left\)\\lfloor"
  syntax match texMathDelim contained conceal cchar=⌊ "\\\%([bB]igg\?l\|left\)\\lgroup"
  syntax match texMathDelim contained conceal cchar=⎛ "\\\%([bB]igg\?l\|left\)\\lmoustache"
  syntax match texMathDelim contained conceal cchar=] "\\\%([bB]igg\?r\|right\)\\rbrace"
  syntax match texMathDelim contained conceal cchar=⌉ "\\\%([bB]igg\?r\|right\)\\rceil"
  syntax match texMathDelim contained conceal cchar=⌋ "\\\%([bB]igg\?r\|right\)\\rfloor"
  syntax match texMathDelim contained conceal cchar=⌋ "\\\%([bB]igg\?r\|right\)\\rgroup"
  syntax match texMathDelim contained conceal cchar=⎞ "\\\%([bB]igg\?r\|right\)\\rmoustache"
  syntax match texMathDelim contained conceal cchar=| "\\\%([bB]igg\?[lr]\?\|left\|right\)|"
  syntax match texMathDelim contained conceal cchar=‖ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\|"
  syntax match texMathDelim contained conceal cchar=↓ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\downarrow"
  syntax match texMathDelim contained conceal cchar=⇓ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\Downarrow"
  syntax match texMathDelim contained conceal cchar=↑ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\uparrow"
  syntax match texMathDelim contained conceal cchar=↑ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\Uparrow"
  syntax match texMathDelim contained conceal cchar=↕ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\updownarrow"
  syntax match texMathDelim contained conceal cchar=⇕ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\Updownarrow"

  if &ambiwidth ==# 'double'
    syntax match texMathDelim contained conceal cchar=〈 "\\\%([bB]igg\?l\|left\)\\langle"
    syntax match texMathDelim contained conceal cchar=〉 "\\\%([bB]igg\?r\|right\)\\rangle"
  else
    syntax match texMathDelim contained conceal cchar=⟨ "\\\%([bB]igg\?l\|left\)\\langle"
    syntax match texMathDelim contained conceal cchar=⟩ "\\\%([bB]igg\?r\|right\)\\rangle"
  endif
endfunction

" }}}1

function! s:match_conceal_accents() abort " {{{1
  for [l:chr; l:targets] in s:map_accents
    for i in range(13)
      let l:target = l:targets[i]
      let l:accent = s:key_accents[i]
      if empty(l:target) | continue | endif

      let l:re = l:accent . '\%(\s*{' . l:chr . '}\|'
            \ . (l:accent =~# '\a' ? '\s\+' : '\s*') . l:chr . '\)'
      execute 'syntax match texCmdAccent /' . l:re . '/ conceal cchar=' . l:target
    endfor
  endfor

  syntax match texCmdAccent   "\\aa\>" conceal cchar=å
  syntax match texCmdAccent   "\\AA\>" conceal cchar=Å
  syntax match texCmdAccent   "\\o\>"  conceal cchar=ø
  syntax match texCmdAccent   "\\O\>"  conceal cchar=Ø
  syntax match texCmdLigature "\\AE\>" conceal cchar=Æ
  syntax match texCmdLigature "\\ae\>" conceal cchar=æ
  syntax match texCmdLigature "\\oe\>" conceal cchar=œ
  syntax match texCmdLigature "\\OE\>" conceal cchar=Œ
  syntax match texCmdLigature "\\ss\>" conceal cchar=ß
  syntax match texLigature    "--"     conceal cchar=–
  syntax match texLigature    "---"    conceal cchar=—
  syntax match texLigature    "``"     conceal cchar=“
  syntax match texLigature    "''"     conceal cchar=”
  syntax match texLigature    ",,"     conceal cchar=„
endfunction

let s:key_accents = [
      \ '\\`',
      \ '\\''',
      \ '\\^',
      \ '\\"',
      \ '\\\~',
      \ '\\\.',
      \ '\\=',
      \ '\\c',
      \ '\\H',
      \ '\\k',
      \ '\\r',
      \ '\\u',
      \ '\\v'
      \]

let s:map_accents = [
      \ ['a',  'à','á','â','ä','ã','ȧ','ā','' ,'' ,'ą','å','ă','ǎ'],
      \ ['A',  'À','Á','Â','Ä','Ã','Ȧ','Ā','' ,'' ,'Ą','Å','Ă','Ǎ'],
      \ ['c',  '' ,'ć','ĉ','' ,'' ,'ċ','' ,'ç','' ,'' ,'' ,'' ,'č'],
      \ ['C',  '' ,'Ć','Ĉ','' ,'' ,'Ċ','' ,'Ç','' ,'' ,'' ,'' ,'Č'],
      \ ['d',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'ď'],
      \ ['D',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ď'],
      \ ['e',  'è','é','ê','ë','ẽ','ė','ē','ȩ','' ,'ę','' ,'ĕ','ě'],
      \ ['E',  'È','É','Ê','Ë','Ẽ','Ė','Ē','Ȩ','' ,'Ę','' ,'Ĕ','Ě'],
      \ ['g',  '' ,'ǵ','ĝ','' ,'' ,'ġ','' ,'ģ','' ,'' ,'' ,'ğ','ǧ'],
      \ ['G',  '' ,'Ǵ','Ĝ','' ,'' ,'Ġ','' ,'Ģ','' ,'' ,'' ,'Ğ','Ǧ'],
      \ ['h',  '' ,'' ,'ĥ','' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'ȟ'],
      \ ['H',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ȟ'],
      \ ['i',  'ì','í','î','ï','ĩ','į','ī','' ,'' ,'į','' ,'ĭ','ǐ'],
      \ ['I',  'Ì','Í','Î','Ï','Ĩ','İ','Ī','' ,'' ,'Į','' ,'Ĭ','Ǐ'],
      \ ['J',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'ǰ'],
      \ ['k',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'ķ','' ,'' ,'' ,'' ,'ǩ'],
      \ ['K',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ķ','' ,'' ,'' ,'' ,'Ǩ'],
      \ ['l',  '' ,'ĺ','ľ','' ,'' ,'' ,'' ,'ļ','' ,'' ,'' ,'' ,'ľ'],
      \ ['L',  '' ,'Ĺ','Ľ','' ,'' ,'' ,'' ,'Ļ','' ,'' ,'' ,'' ,'Ľ'],
      \ ['n',  '' ,'ń','' ,'' ,'ñ','' ,'' ,'ņ','' ,'' ,'' ,'' ,'ň'],
      \ ['N',  '' ,'Ń','' ,'' ,'Ñ','' ,'' ,'Ņ','' ,'' ,'' ,'' ,'Ň'],
      \ ['o',  'ò','ó','ô','ö','õ','ȯ','ō','' ,'ő','ǫ','' ,'ŏ','ǒ'],
      \ ['O',  'Ò','Ó','Ô','Ö','Õ','Ȯ','Ō','' ,'Ő','Ǫ','' ,'Ŏ','Ǒ'],
      \ ['r',  '' ,'ŕ','' ,'' ,'' ,'' ,'' ,'ŗ','' ,'' ,'' ,'' ,'ř'],
      \ ['R',  '' ,'Ŕ','' ,'' ,'' ,'' ,'' ,'Ŗ','' ,'' ,'' ,'' ,'Ř'],
      \ ['s',  '' ,'ś','ŝ','' ,'' ,'' ,'' ,'ş','' ,'ȿ','' ,'' ,'š'],
      \ ['S',  '' ,'Ś','Ŝ','' ,'' ,'' ,'' ,'Ş','' ,'' ,'' ,'' ,'Š'],
      \ ['t',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'ţ','' ,'' ,'' ,'' ,'ť'],
      \ ['T',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ţ','' ,'' ,'' ,'' ,'Ť'],
      \ ['u',  'ù','ú','û','ü','ũ','' ,'ū','' ,'ű','ų','ů','ŭ','ǔ'],
      \ ['U',  'Ù','Ú','Û','Ü','Ũ','' ,'Ū','' ,'Ű','Ų','Ů','Ŭ','Ǔ'],
      \ ['w',  '' ,'' ,'ŵ','' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
      \ ['W',  '' ,'' ,'Ŵ','' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
      \ ['y',  'ỳ','ý','ŷ','ÿ','ỹ','' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
      \ ['Y',  'Ỳ','Ý','Ŷ','Ÿ','Ỹ','' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
      \ ['z',  '' ,'ź','' ,'' ,'' ,'ż','' ,'' ,'' ,'' ,'' ,'' ,'ž'],
      \ ['Z',  '' ,'Ź','' ,'' ,'' ,'Ż','' ,'' ,'' ,'' ,'' ,'' ,'Ž'],
      \ ['\\i','ì','í','î','ï','ĩ','į','' ,'' ,'' ,'' ,'' ,'ĭ',''],
      \]

" }}}1
function! s:match_conceal_fancy() abort " {{{1
  syntax match texCmd         '\\colon\>' conceal cchar=:
  syntax match texCmd         '\\dots'    conceal cchar=…
  syntax match texCmd         '\\ldots'   conceal cchar=…
  syntax match texCmdItem     '\\item\>'  conceal cchar=○
  syntax match texTabularChar '\\\\'      conceal cchar=⏎
endfunction

" }}}1
function! s:match_conceal_greek() abort " {{{1
  syntax match texCmdGreek "\\alpha\>"      contained conceal cchar=α
  syntax match texCmdGreek "\\beta\>"       contained conceal cchar=β
  syntax match texCmdGreek "\\gamma\>"      contained conceal cchar=γ
  syntax match texCmdGreek "\\delta\>"      contained conceal cchar=δ
  syntax match texCmdGreek "\\epsilon\>"    contained conceal cchar=ϵ
  syntax match texCmdGreek "\\varepsilon\>" contained conceal cchar=ε
  syntax match texCmdGreek "\\zeta\>"       contained conceal cchar=ζ
  syntax match texCmdGreek "\\eta\>"        contained conceal cchar=η
  syntax match texCmdGreek "\\theta\>"      contained conceal cchar=θ
  syntax match texCmdGreek "\\vartheta\>"   contained conceal cchar=ϑ
  syntax match texCmdGreek "\\iota\>"       contained conceal cchar=ι
  syntax match texCmdGreek "\\kappa\>"      contained conceal cchar=κ
  syntax match texCmdGreek "\\lambda\>"     contained conceal cchar=λ
  syntax match texCmdGreek "\\mu\>"         contained conceal cchar=μ
  syntax match texCmdGreek "\\nu\>"         contained conceal cchar=ν
  syntax match texCmdGreek "\\xi\>"         contained conceal cchar=ξ
  syntax match texCmdGreek "\\pi\>"         contained conceal cchar=π
  syntax match texCmdGreek "\\varpi\>"      contained conceal cchar=ϖ
  syntax match texCmdGreek "\\rho\>"        contained conceal cchar=ρ
  syntax match texCmdGreek "\\varrho\>"     contained conceal cchar=ϱ
  syntax match texCmdGreek "\\sigma\>"      contained conceal cchar=σ
  syntax match texCmdGreek "\\varsigma\>"   contained conceal cchar=ς
  syntax match texCmdGreek "\\tau\>"        contained conceal cchar=τ
  syntax match texCmdGreek "\\upsilon\>"    contained conceal cchar=υ
  syntax match texCmdGreek "\\phi\>"        contained conceal cchar=ϕ
  syntax match texCmdGreek "\\varphi\>"     contained conceal cchar=φ
  syntax match texCmdGreek "\\chi\>"        contained conceal cchar=χ
  syntax match texCmdGreek "\\psi\>"        contained conceal cchar=ψ
  syntax match texCmdGreek "\\omega\>"      contained conceal cchar=ω
  syntax match texCmdGreek "\\Gamma\>"      contained conceal cchar=Γ
  syntax match texCmdGreek "\\Delta\>"      contained conceal cchar=Δ
  syntax match texCmdGreek "\\Theta\>"      contained conceal cchar=Θ
  syntax match texCmdGreek "\\Lambda\>"     contained conceal cchar=Λ
  syntax match texCmdGreek "\\Xi\>"         contained conceal cchar=Ξ
  syntax match texCmdGreek "\\Pi\>"         contained conceal cchar=Π
  syntax match texCmdGreek "\\Sigma\>"      contained conceal cchar=Σ
  syntax match texCmdGreek "\\Upsilon\>"    contained conceal cchar=Υ
  syntax match texCmdGreek "\\Phi\>"        contained conceal cchar=Φ
  syntax match texCmdGreek "\\Chi\>"        contained conceal cchar=Χ
  syntax match texCmdGreek "\\Psi\>"        contained conceal cchar=Ψ
  syntax match texCmdGreek "\\Omega\>"      contained conceal cchar=Ω
endfunction

" }}}1
