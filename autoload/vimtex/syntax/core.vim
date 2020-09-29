" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#core#init() abort " {{{1
  let l:extension = expand('%:e')
  let l:cfg = extend({
        \ 'is_style_document': index(
        \       ['sty', 'cls', 'clo', 'dtx', 'ltx'],
        \       l:extension) >= 0,
        \}, g:vimtex_syntax_config)

  call s:init_clusters()

  " {{{2 Try to flag {}, [], and () mismatches

  syntax region texMatcher matchgroup=Delimiter start="{" skip="\\\\\|\\[{}]" end="}" transparent contains=@texMatchGroup,texError
  syntax region texMatcher matchgroup=Delimiter start="\["                    end="]" transparent contains=@texMatchGroup,texError,@NoSpell
  syntax region texParen start="(" end=")" transparent contains=@texMatchGroup,@Spell
  syntax match texError "[}\]]"

  syntax match texMathError "}" contained
  syntax region texMathMatcher matchgroup=Delimiter start="{" skip="\(\\\\\)*\\}" end="}" end="%stopzone\>" contained contains=@texMathMatchGroup

  " {{{2 TeX/LaTeX keywords and delimiters

  if l:cfg.is_style_document
    syntax match texStatement "\\[a-zA-Z@]\+"
  else
    syntax match texStatement "\\\a\+"
    syntax match texError "\\\a*@[a-zA-Z@]*"
  endif

  syntax match texDelimiter "&"
  syntax match texDelimiter "\\\\"

  syntax match texOption "[^\\]\zs#\d\+\|^#\d\+"

  if l:cfg.is_style_document
    syntax match texAccent "\\[bcdvuH][^a-zA-Z@]"me=e-1
    syntax match texLigature "\\\([ijolL]\|ae\|oe\|ss\|AA\|AE\|OE\)[^a-zA-Z@]"me=e-1
  else
    syntax match texAccent "\\[bcdvuH]\A"me=e-1
    syntax match texLigature "\\\([ijolL]\|ae\|oe\|ss\|AA\|AE\|OE\)\A"me=e-1
  endif
  syntax match texAccent "\\[bcdvuH]$"
  syntax match texAccent +\\[=^.\~"`']+
  syntax match texAccent +\\['=t'.c^ud"vb~Hr]{\a}+
  syntax match texLigature "\\\([ijolL]\|ae\|oe\|ss\|AA\|AE\|OE\)$"

  " {{{2 \begin{}/\end{} section markers

  syntax match  texBeginEnd "\\begin\>\|\\end\>" nextgroup=texBeginEndName
  syntax region texBeginEndName     matchgroup=Delimiter start="{"  end="}" contained nextgroup=texBeginEndModifier   contains=texComment
  syntax region texBeginEndModifier matchgroup=Delimiter start="\[" end="]" contained contains=texComment,@texMathZones,@NoSpell

  " {{{2 \documentclass, \documentstyle, \usepackage

  syntax match texDocType "\\documentclass\>\|\\documentstyle\>\|\\usepackage\>" nextgroup=texBeginEndName,texDocTypeArgs
  syntax region texDocTypeArgs matchgroup=Delimiter start="\[" end="]" contained nextgroup=texBeginEndName contains=texComment,@NoSpell

  " {{{2 TeX input

  syntax match texInput           "\\input\s\+[a-zA-Z/.0-9_^]\+"hs=s+7                      contains=texStatement
  syntax match texInputFile       "\\include\(graphics\|list\)\=\(\[.\{-}\]\)\=\s*{.\{-}}"  contains=texStatement,texInputCurlies,texInputFileOpt
  syntax match texInputFile       "\\\(epsfig\|input\|usepackage\)\s*\(\[.*\]\)\={.\{-}}"   contains=texStatement,texInputCurlies,texInputFileOpt
  syntax match texInputCurlies    "[{}]"                                                    contained
  syntax region texInputFileOpt  matchgroup=Delimiter start="\[" end="\]"                   contained       contains=texComment

  " {{{2 Type Styles

  " LaTeX 2.09:
  syntax match texTypeStyle "\\rm\>"
  syntax match texTypeStyle "\\em\>"
  syntax match texTypeStyle "\\bf\>"
  syntax match texTypeStyle "\\it\>"
  syntax match texTypeStyle "\\sl\>"
  syntax match texTypeStyle "\\sf\>"
  syntax match texTypeStyle "\\sc\>"
  syntax match texTypeStyle "\\tt\>"

  " Attributes, commands, families, etc (LaTeX2E):
  if l:cfg.conceal !~# 'b'
    syntax match texTypeStyle "\\textbf\>"
    syntax match texTypeStyle "\\textit\>"
    syntax match texTypeStyle "\\emph\>"
  endif
  syntax match texTypeStyle "\\textmd\>"
  syntax match texTypeStyle "\\textrm\>"

  syntax match texTypeStyle "\\mathbb\>"
  syntax match texTypeStyle "\\mathbf\>"
  syntax match texTypeStyle "\\mathcal\>"
  syntax match texTypeStyle "\\mathfrak\>"
  syntax match texTypeStyle "\\mathit\>"
  syntax match texTypeStyle "\\mathnormal\>"
  syntax match texTypeStyle "\\mathrm\>"
  syntax match texTypeStyle "\\mathsf\>"
  syntax match texTypeStyle "\\mathtt\>"

  syntax match texTypeStyle "\\rmfamily\>"
  syntax match texTypeStyle "\\sffamily\>"
  syntax match texTypeStyle "\\ttfamily\>"

  syntax match texTypeStyle "\\itshape\>"
  syntax match texTypeStyle "\\scshape\>"
  syntax match texTypeStyle "\\slshape\>"
  syntax match texTypeStyle "\\upshape\>"

  syntax match texTypeStyle "\\bfseries\>"
  syntax match texTypeStyle "\\mdseries\>"

  " {{{2 Type sizes

  syntax match texTypeSize "\\tiny\>"
  syntax match texTypeSize "\\scriptsize\>"
  syntax match texTypeSize "\\footnotesize\>"
  syntax match texTypeSize "\\small\>"
  syntax match texTypeSize "\\normalsize\>"
  syntax match texTypeSize "\\large\>"
  syntax match texTypeSize "\\Large\>"
  syntax match texTypeSize "\\LARGE\>"
  syntax match texTypeSize "\\huge\>"
  syntax match texTypeSize "\\Huge\>"

  " {{{2 Spacecodes (TeX'isms):

  " \mathcode`\^^@ = "2201
  " \delcode`\( = "028300
  " \sfcode`\) = 0
  " \uccode`X = `X
  " \lccode`x = `x

  syntax match texSpaceCode /\\\(math\|cat\|del\|lc\|sf\|uc\)code`/me=e-1 nextgroup=texSpaceCodeChar
  syntax match texSpaceCodeChar "`\\\=.\(\^.\)\==\(\d\|\"\x\{1,6}\|`.\)"  contained

  " {{{2 Sections, subsections, etc

  syntax region texDocZone matchgroup=texSection start='\\begin\s*{\s*document\s*}' end='\\end\s*{\s*document\s*}' contains=@texZoneGroup,@texDocGroup,@Spell
  syntax region texPartZone matchgroup=texSection start='\\part\>' end='\ze\s*\\\%(part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texPartGroup,@Spell
  syntax region texChapterZone matchgroup=texSection start='\\chapter\>' end='\ze\s*\\\%(chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texChapterGroup,@Spell
  syntax region texSectionZone matchgroup=texSection start='\\section\>' end='\ze\s*\\\%(section\>\|chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texSectionGroup,@Spell
  syntax region texSubSectionZone matchgroup=texSection start='\\subsection\>' end='\ze\s*\\\%(\%(sub\)\=section\>\|chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texSubSectionGroup,@Spell
  syntax region texSubSubSectionZone matchgroup=texSection start='\\subsubsection\>' end='\ze\s*\\\%(\%(sub\)\{,2}section\>\|chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texSubSubSectionGroup,@Spell
  syntax region texParaZone matchgroup=texSection start='\\paragraph\>' end='\ze\s*\\\%(paragraph\>\|\%(sub\)*section\>\|chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@texParaGroup,@Spell
  syntax region texSubParaZone matchgroup=texSection start='\\subparagraph\>' end='\ze\s*\\\%(\%(sub\)\=paragraph\>\|\%(sub\)*section\>\|chapter\>\|part\>\|end\s*{\s*document\s*}\)' contains=@texZoneGroup,@Spell
  syntax region texTitle matchgroup=texSection start='\\\%(author\|title\)\>\s*{' end='}' contains=@texZoneGroup,@Spell
  syntax region texAbstract matchgroup=texSection start='\\begin\s*{\s*abstract\s*}' end='\\end\s*{\s*abstract\s*}' contains=@texZoneGroup,@Spell

  " {{{2 Bold and italic

  if l:cfg.conceal =~# 'b'
    syntax region texBoldStyle     matchgroup=texTypeStyle start="\\textbf\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texBoldGroup,@Spell
    syntax region texBoldItalStyle matchgroup=texTypeStyle start="\\textit\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texItalGroup,@Spell
    syntax region texItalStyle     matchgroup=texTypeStyle start="\\textit\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texItalGroup,@Spell
    syntax region texItalBoldStyle matchgroup=texTypeStyle start="\\textbf\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texBoldGroup,@Spell
    syntax region texEmphStyle     matchgroup=texTypeStyle start="\\emph\s*{"   matchgroup=texTypeStyle  end="}" concealends contains=@texItalGroup,@Spell
    syntax region texEmphStyle     matchgroup=texTypeStyle start="\\texts[cfl]\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texBoldGroup,@Spell
    syntax region texEmphStyle     matchgroup=texTypeStyle start="\\textup\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texBoldGroup,@Spell
    syntax region texEmphStyle     matchgroup=texTypeStyle start="\\texttt\s*{" matchgroup=texTypeStyle  end="}" concealends contains=@texBoldGroup,@Spell
  endif

  " {{{2 Bad/Mismatched math

  syntax match texBadMath "\\end\s*{\s*\(array\|[bBpvV]matrix\|split\|smallmatrix\)\s*}"
  syntax match texBadMath "\\[\])]"

  " {{{2 Math Zones

  call vimtex#syntax#misc#new_math_zone('A', 'displaymath', 1)
  call vimtex#syntax#misc#new_math_zone('B', 'eqnarray', 1)
  call vimtex#syntax#misc#new_math_zone('C', 'equation', 1)
  call vimtex#syntax#misc#new_math_zone('D', 'math', 1)

  " {{{2 Inline Math Zones

  if l:cfg.conceal =~# 'd' && &encoding ==# 'utf-8'
    syntax region texMathZoneV matchgroup=Delimiter start="\\("                      matchgroup=Delimiter end="\\)\|%stopzone\>"             keepend concealends contains=@texMathZoneGroup
    syntax region texMathZoneW matchgroup=Delimiter start="\\\["                     matchgroup=Delimiter end="\\]\|%stopzone\>"             keepend concealends contains=@texMathZoneGroup
    syntax region texMathZoneX matchgroup=Delimiter start="\$" skip="\\\\\|\\\$"     matchgroup=Delimiter end="\$"        end="%stopzone\>"          concealends contains=@texMathZoneGroup
    syntax region texMathZoneY matchgroup=Delimiter start="\$\$"                     matchgroup=Delimiter end="\$\$"      end="%stopzone\>"  keepend concealends contains=@texMathZoneGroup
  else
    syntax region texMathZoneV matchgroup=Delimiter start="\\("                      matchgroup=Delimiter end="\\)\|%stopzone\>"             keepend contains=@texMathZoneGroup
    syntax region texMathZoneW matchgroup=Delimiter start="\\\["                     matchgroup=Delimiter end="\\]\|%stopzone\>"             keepend contains=@texMathZoneGroup
    syntax region texMathZoneX matchgroup=Delimiter start="\$" skip="\%(\\\\\)*\\\$" matchgroup=Delimiter end="\$"        end="%stopzone\>"          contains=@texMathZoneGroup
    syntax region texMathZoneY matchgroup=Delimiter start="\$\$"                     matchgroup=Delimiter end="\$\$"      end="%stopzone\>"  keepend contains=@texMathZoneGroup
  endif
  syntax region texMathZoneZ matchgroup=texStatement start="\\ensuremath\s*{" matchgroup=texStatement end="}" end="%stopzone\>" contains=@texMathZoneGroup

  syntax match texMathOper "[_^=]" contained

  " {{{2 Text Inside Math Zones

  syntax region texMathText matchgroup=texStatement start='\\\(\(inter\)\=text\|mbox\)\s*{' end='}' contains=@texZoneGroup,@Spell

  " {{{2 Math: \left... and \right...

  syntax match texMathDelimBad contained "\S"
  if l:cfg.conceal !~# 'm' || &encoding !=# 'utf-8'
    syntax match   texMathDelim      contained "\\\(left\|right\)\>"   skipwhite nextgroup=texMathDelimSet1,texMathDelimSet2,texMathDelimBad
    syntax match   texMathDelim      contained "\\[bB]igg\=[lr]\=\>"   skipwhite nextgroup=texMathDelimSet1,texMathDelimSet2,texMathDelimBad
    syntax match   texMathDelimSet2  contained "\\"            nextgroup=texMathDelimKey,texMathDelimBad
    syntax match   texMathDelimSet1  contained "[<>()[\]|/.]\|\\[{}|]"
    syntax keyword texMathDelimKey   contained backslash lceil      lVert    rgroup      uparrow
    syntax keyword texMathDelimKey   contained downarrow lfloor     rangle   rmoustache  Uparrow
    syntax keyword texMathDelimKey   contained Downarrow lgroup     rbrace   rvert       updownarrow
    syntax keyword texMathDelimKey   contained langle    lmoustache rceil    rVert       Updownarrow
    syntax keyword texMathDelimKey   contained lbrace    lvert      rfloor
  else
    syntax match texMathDelim contained "\\left\["
    syntax match texMathDelim contained "\\left\\{"  skipwhite nextgroup=texMathDelimSet1,texMathDelimSet2,texMathDelimBad contains=texMathSymbol cchar={
    syntax match texMathDelim contained "\\right\\}" skipwhite nextgroup=texMathDelimSet1,texMathDelimSet2,texMathDelimBad contains=texMathSymbol cchar=}
    let l:texMathDelimList = [
          \ ['<',             '<'],
          \ ['>',             '>'],
          \ ['(',             '('],
          \ [')',             ')'],
          \ ['\[',            '['],
          \ [']',             ']'],
          \ ['\\{',           '{'],
          \ ['\\}',           '}'],
          \ ['|',             '|'],
          \ ['\\|',           '‖'],
          \ ['\\backslash',   '\'],
          \ ['\\downarrow',   '↓'],
          \ ['\\Downarrow',   '⇓'],
          \ ['\\lbrace',      '['],
          \ ['\\lceil',       '⌈'],
          \ ['\\lfloor',      '⌊'],
          \ ['\\lgroup',      '⌊'],
          \ ['\\lmoustache',  '⎛'],
          \ ['\\rbrace',      ']'],
          \ ['\\rceil',       '⌉'],
          \ ['\\rfloor',      '⌋'],
          \ ['\\rgroup',      '⌋'],
          \ ['\\rmoustache',  '⎞'],
          \ ['\\uparrow',     '↑'],
          \ ['\\Uparrow',     '↑'],
          \ ['\\updownarrow', '↕'],
          \ ['\\Updownarrow', '⇕']]
    if &ambiwidth ==# 'double'
      let l:texMathDelimList += [
            \ ['\\langle', '〈'] ,
            \ ['\\rangle', '〉']]
    else
      let l:texMathDelimList += [
            \ ['\\langle', '<'] ,
            \ ['\\rangle', '>']]
    endif
    syntax match texMathDelim '\\[bB]igg\=[lr]' contained nextgroup=texMathDelimBad
    for texmath in l:texMathDelimList
      execute "syntax match texMathDelim  '\\\\[bB]igg\\=[lr]\\=" . texmath[0] . "'   contained conceal cchar=" . texmath[1]
    endfor
  endif
  syntax match texMathDelim contained "\\\(left\|right\)arrow\>\|\<\([aA]rrow\|brace\)\=vert\>"
  syntax match texMathDelim contained "\\lefteqn\>"

  " {{{2 Special TeX characters

  " E.g.:  \$ \& \% \# \{ \} \_ \S \P

  syntax match texSpecialChar "\\[$&%#{}_]"
  if l:cfg.is_style_document
    syntax match texSpecialChar "\\[SP@][^a-zA-Z@]"me=e-1
  else
    syntax match texSpecialChar "\\[SP@]\A"me=e-1
  endif
  syntax match texSpecialChar "\\\\"
  syntax match texOnlyMath "[_^]"
  syntax match texSpecialChar "\^\^[0-9a-f]\{2}\|\^\^\S"
  if l:cfg.conceal =~# 'S'
    syntax match texSpecialChar '\\glq\>' contained conceal cchar=‚
    syntax match texSpecialChar '\\grq\>' contained conceal cchar=‘
    syntax match texSpecialChar '\\glqq\>' contained conceal cchar=„
    syntax match texSpecialChar '\\grqq\>' contained conceal cchar=“
    syntax match texSpecialChar '\\hyp\>' contained conceal cchar=-
  endif

  " {{{2 Comments

  " Normal TeX LaTeX: %....
  " Documented TeX Format: ^^A... -and- leading %s (only)

  syntax case ignore
  syntax keyword texTodo contained combak fixme todo xxx
  syntax case match
  if l:extension ==# 'dtx'
    syntax match texComment "\^\^A.*$" contains=@texCommentGroup
    syntax match texComment "^%\+"     contains=@texCommentGroup
  else
    syntax match texComment "%.*$" contains=@texCommentGroup
    syntax region texNoSpell contained matchgroup=texComment start="%\s*nospell\s*{" end="%\s*nospell\s*}" contains=@texZoneGroup,@NoSpell
  endif

  " {{{2 Verbatim

  " Separate lines used for verb` and verb# so that the end conditions will
  " appropriately terminate.
  syntax   region texZone start="\\begin{[vV]erbatim}"        end="\\end{[vV]erbatim}\|%stopzone\>"
  if l:cfg.is_style_document
    syntax region texZone start="\\verb\*\=\z([^\ta-zA-Z@]\)" end="\z1\|%stopzone\>"
  else
    syntax region texZone start="\\verb\*\=\z([^\ta-zA-Z]\)"  end="\z1\|%stopzone\>"
  endif

  " {{{2 Tex Reference Zones

  syntax region texZone      matchgroup=texStatement start="@samp{"             end="}\|%stopzone\>"  contains=@texRefGroup
  syntax region texRefZone   matchgroup=texStatement start="\\nocite{"          end="}\|%stopzone\>"  contains=@texRefGroup
  syntax region texRefZone   matchgroup=texStatement start="\\bibliography{"    end="}\|%stopzone\>"  contains=@texRefGroup
  syntax region texRefZone   matchgroup=texStatement start="\\label{"           end="}\|%stopzone\>"  contains=@texRefGroup
  syntax region texRefZone   matchgroup=texStatement start="\\\(page\|eq\)ref{" end="}\|%stopzone\>"  contains=@texRefGroup
  syntax region texRefZone   matchgroup=texStatement start="\\v\=ref{"          end="}\|%stopzone\>"  contains=@texRefGroup
  syntax region texRefOption contained matchgroup=Delimiter start='\[' end=']' contains=@texRefGroup,texRefZone        nextgroup=texRefOption,texCite
  syntax region texCite      contained matchgroup=Delimiter start='{' end='}'  contains=@texRefGroup,texRefZone,texCite
  syntax match  texRefZone '\\cite\%([tp]\*\=\)\=\>' nextgroup=texRefOption,texCite

  " {{{2 Handle new(command|environment)

  syntax match  texNewCmd "\\newcommand\>" nextgroup=texCmdName skipwhite skipnl
  syntax region texCmdName contained matchgroup=Delimiter start="{"rs=s+1 end="}" nextgroup=texCmdArgs,texCmdBody skipwhite skipnl
  syntax region texCmdArgs contained matchgroup=Delimiter start="\["rs=s+1 end="]" nextgroup=texCmdBody skipwhite skipnl
  syntax region texCmdBody contained matchgroup=Delimiter start="{"rs=s+1 skip="\\\\\|\\[{}]" matchgroup=Delimiter end="}" contains=@texCmdGroup
  syntax match texNewEnv "\\newenvironment\>" nextgroup=texEnvName skipwhite skipnl
  syntax region texEnvName contained matchgroup=Delimiter start="{"rs=s+1 end="}" nextgroup=texEnvBgn skipwhite skipnl
  syntax region texEnvBgn contained matchgroup=Delimiter start="{"rs=s+1 end="}" nextgroup=texEnvEnd skipwhite skipnl contains=@texEnvGroup
  syntax region texEnvEnd contained matchgroup=Delimiter start="{"rs=s+1 end="}" skipwhite skipnl contains=@texEnvGroup

  " {{{2 Definitions/Commands

  syntax match texDefCmd              "\\def\>"       nextgroup=texDefName skipwhite skipnl
  if l:cfg.is_style_document
    syntax match texDefName contained "\\[a-zA-Z@]\+" nextgroup=texDefParms,texCmdBody skipwhite skipnl
    syntax match texDefName contained "\\[^a-zA-Z@]"  nextgroup=texDefParms,texCmdBody skipwhite skipnl
  else
    syntax match texDefName contained "\\\a\+"        nextgroup=texDefParms,texCmdBody skipwhite skipnl
    syntax match texDefName contained "\\\A"          nextgroup=texDefParms,texCmdBody skipwhite skipnl
  endif
  syntax match texDefParms  contained "#[^{]*"        contains=texDefParm nextgroup=texCmdBody skipwhite skipnl
  syntax match  texDefParm  contained "#\d\+"

  " {{{2 TeX Lengths

  syntax match texLength "\<\d\+\([.,]\d\+\)\=\s*\(true\)\=\s*\(bp\|cc\|cm\|dd\|em\|ex\|in\|mm\|pc\|pt\|sp\)\>"

  " {{{2 TeX String Delimiters

  syntax match texString "\(``\|''\|,,\)"

  " makeatletter -- makeatother sections
  syntax region texStyle matchgroup=texStatement start='\\makeatletter' end='\\makeatother' contains=@texStyleGroup contained
  syntax match texStyleStatement "\\[a-zA-Z@]\+" contained
  syntax region texStyleMatcher matchgroup=Delimiter start="{" skip="\\\\\|\\[{}]" end="}" contains=@texStyleGroup,texError contained
  syntax region texStyleMatcher matchgroup=Delimiter start="\[" end="]" contains=@texStyleGroup,texError contained

  " {{{2 Conceal mode support

  " Add support for conceal with custom replacement (conceallevel = 2)

  if &encoding ==# 'utf-8'

    " Many of these symbols were contributed by Björn Winckler
    if l:cfg.conceal =~# 'm'
      let l:texMathList = [
            \ ['|'              , '‖'],
            \ ['aleph'          , 'ℵ'],
            \ ['amalg'          , '∐'],
            \ ['angle'          , '∠'],
            \ ['approx'         , '≈'],
            \ ['ast'            , '∗'],
            \ ['asymp'          , '≍'],
            \ ['backslash'      , '∖'],
            \ ['bigcap'         , '∩'],
            \ ['bigcirc'        , '○'],
            \ ['bigcup'         , '∪'],
            \ ['bigodot'        , '⊙'],
            \ ['bigoplus'       , '⊕'],
            \ ['bigotimes'      , '⊗'],
            \ ['bigsqcup'       , '⊔'],
            \ ['bigtriangledown', '∇'],
            \ ['bigtriangleup'  , '∆'],
            \ ['bigvee'         , '⋁'],
            \ ['bigwedge'       , '⋀'],
            \ ['bot'            , '⊥'],
            \ ['bowtie'         , '⋈'],
            \ ['bullet'         , '•'],
            \ ['cap'            , '∩'],
            \ ['cdot'           , '·'],
            \ ['cdots'          , '⋯'],
            \ ['circ'           , '∘'],
            \ ['clubsuit'       , '♣'],
            \ ['cong'           , '≅'],
            \ ['coprod'         , '∐'],
            \ ['copyright'      , '©'],
            \ ['cup'            , '∪'],
            \ ['dagger'         , '†'],
            \ ['dashv'          , '⊣'],
            \ ['ddagger'        , '‡'],
            \ ['ddots'          , '⋱'],
            \ ['diamond'        , '⋄'],
            \ ['diamondsuit'    , '♢'],
            \ ['div'            , '÷'],
            \ ['doteq'          , '≐'],
            \ ['dots'           , '…'],
            \ ['downarrow'      , '↓'],
            \ ['Downarrow'      , '⇓'],
            \ ['ell'            , 'ℓ'],
            \ ['emptyset'       , '∅'],
            \ ['equiv'          , '≡'],
            \ ['exists'         , '∃'],
            \ ['flat'           , '♭'],
            \ ['forall'         , '∀'],
            \ ['frown'          , '⁔'],
            \ ['ge'             , '≥'],
            \ ['geq'            , '≥'],
            \ ['gets'           , '←'],
            \ ['gg'             , '⟫'],
            \ ['hbar'           , 'ℏ'],
            \ ['heartsuit'      , '♡'],
            \ ['hookleftarrow'  , '↩'],
            \ ['hookrightarrow' , '↪'],
            \ ['iff'            , '⇔'],
            \ ['Im'             , 'ℑ'],
            \ ['imath'          , 'ɩ'],
            \ ['in'             , '∈'],
            \ ['infty'          , '∞'],
            \ ['int'            , '∫'],
            \ ['jmath'          , '𝚥'],
            \ ['land'           , '∧'],
            \ ['lceil'          , '⌈'],
            \ ['ldots'          , '…'],
            \ ['le'             , '≤'],
            \ ['left|'          , '|'],
            \ ['left\\|'        , '‖'],
            \ ['left('          , '('],
            \ ['left\['         , '['],
            \ ['left\\{'        , '{'],
            \ ['leftarrow'      , '←'],
            \ ['Leftarrow'      , '⇐'],
            \ ['leftharpoondown', '↽'],
            \ ['leftharpoonup'  , '↼'],
            \ ['leftrightarrow' , '↔'],
            \ ['Leftrightarrow' , '⇔'],
            \ ['leq'            , '≤'],
            \ ['leq'            , '≤'],
            \ ['lfloor'         , '⌊'],
            \ ['ll'             , '≪'],
            \ ['lmoustache'     , '╭'],
            \ ['lor'            , '∨'],
            \ ['mapsto'         , '↦'],
            \ ['mid'            , '∣'],
            \ ['models'         , '╞'],
            \ ['mp'             , '∓'],
            \ ['nabla'          , '∇'],
            \ ['natural'        , '♮'],
            \ ['ne'             , '≠'],
            \ ['nearrow'        , '↗'],
            \ ['neg'            , '¬'],
            \ ['neq'            , '≠'],
            \ ['ni'             , '∋'],
            \ ['notin'          , '∉'],
            \ ['nwarrow'        , '↖'],
            \ ['odot'           , '⊙'],
            \ ['oint'           , '∮'],
            \ ['ominus'         , '⊖'],
            \ ['oplus'          , '⊕'],
            \ ['oslash'         , '⊘'],
            \ ['otimes'         , '⊗'],
            \ ['owns'           , '∋'],
            \ ['P'              , '¶'],
            \ ['parallel'       , '║'],
            \ ['partial'        , '∂'],
            \ ['perp'           , '⊥'],
            \ ['pm'             , '±'],
            \ ['prec'           , '≺'],
            \ ['preceq'         , '⪯'],
            \ ['prime'          , '′'],
            \ ['prod'           , '∏'],
            \ ['propto'         , '∝'],
            \ ['rceil'          , '⌉'],
            \ ['Re'             , 'ℜ'],
            \ ['quad'           , ' '],
            \ ['qquad'          , ' '],
            \ ['rfloor'         , '⌋'],
            \ ['right|'         , '|'],
            \ ['right\\|'       , '‖'],
            \ ['right)'         , ')'],
            \ ['right]'         , ']'],
            \ ['right\\}'       , '}'],
            \ ['rightarrow'     , '→'],
            \ ['Rightarrow'     , '⇒'],
            \ ['rightleftharpoons', '⇌'],
            \ ['rmoustache'     , '╮'],
            \ ['S'              , '§'],
            \ ['searrow'        , '↘'],
            \ ['setminus'       , '∖'],
            \ ['sharp'          , '♯'],
            \ ['sim'            , '∼'],
            \ ['simeq'          , '⋍'],
            \ ['smile'          , '‿'],
            \ ['spadesuit'      , '♠'],
            \ ['sqcap'          , '⊓'],
            \ ['sqcup'          , '⊔'],
            \ ['sqsubset'       , '⊏'],
            \ ['sqsubseteq'     , '⊑'],
            \ ['sqsupset'       , '⊐'],
            \ ['sqsupseteq'     , '⊒'],
            \ ['star'           , '✫'],
            \ ['subset'         , '⊂'],
            \ ['subseteq'       , '⊆'],
            \ ['succ'           , '≻'],
            \ ['succeq'         , '⪰'],
            \ ['sum'            , '∑'],
            \ ['supset'         , '⊃'],
            \ ['supseteq'       , '⊇'],
            \ ['surd'           , '√'],
            \ ['swarrow'        , '↙'],
            \ ['times'          , '×'],
            \ ['to'             , '→'],
            \ ['top'            , '⊤'],
            \ ['triangle'       , '∆'],
            \ ['triangleleft'   , '⊲'],
            \ ['triangleright'  , '⊳'],
            \ ['uparrow'        , '↑'],
            \ ['Uparrow'        , '⇑'],
            \ ['updownarrow'    , '↕'],
            \ ['Updownarrow'    , '⇕'],
            \ ['vdash'          , '⊢'],
            \ ['vdots'          , '⋮'],
            \ ['vee'            , '∨'],
            \ ['wedge'          , '∧'],
            \ ['wp'             , '℘'],
            \ ['wr'             , '≀']]
      if &ambiwidth ==# 'double'
        let l:texMathList += [
              \ ['right\\rangle', '〉'],
              \ ['left\\langle', '〈']]
      else
        let l:texMathList += [
              \ ['right\\rangle', '>'],
              \ ['left\\langle', '<']]
      endif
      for texmath in l:texMathList
        if texmath[0] =~# '\w$'
          exe "syn match texMathSymbol '\\\\".texmath[0]."\\>' contained conceal cchar=".texmath[1]
        else
          exe "syn match texMathSymbol '\\\\".texmath[0]."' contained conceal cchar=".texmath[1]
        endif
      endfor

      if &ambw ==# 'double'
        syntax match texMathSymbol '\\gg\>' contained conceal cchar=≫
        syntax match texMathSymbol '\\ll\>' contained conceal cchar=≪
      else
        syntax match texMathSymbol '\\gg\>' contained conceal cchar=⟫
        syntax match texMathSymbol '\\ll\>' contained conceal cchar=⟪
      endif

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
      "  syn match texMathSymbol '\\bar{a}' contained conceal cchar=a̅

      syntax match texMathSymbol '\\dot{B}' contained conceal cchar=Ḃ
      syntax match texMathSymbol '\\dot{b}' contained conceal cchar=ḃ
      syntax match texMathSymbol '\\dot{D}' contained conceal cchar=Ḋ
      syntax match texMathSymbol '\\dot{d}' contained conceal cchar=ḋ
      syntax match texMathSymbol '\\dot{F}' contained conceal cchar=Ḟ
      syntax match texMathSymbol '\\dot{f}' contained conceal cchar=ḟ
      syntax match texMathSymbol '\\dot{H}' contained conceal cchar=Ḣ
      syntax match texMathSymbol '\\dot{h}' contained conceal cchar=ḣ
      syntax match texMathSymbol '\\dot{M}' contained conceal cchar=Ṁ
      syntax match texMathSymbol '\\dot{m}' contained conceal cchar=ṁ
      syntax match texMathSymbol '\\dot{N}' contained conceal cchar=Ṅ
      syntax match texMathSymbol '\\dot{n}' contained conceal cchar=ṅ
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

      syntax match texMathSymbol '\\dot{C}' contained conceal cchar=Ċ
      syntax match texMathSymbol '\\dot{c}' contained conceal cchar=ċ
      syntax match texMathSymbol '\\dot{E}' contained conceal cchar=Ė
      syntax match texMathSymbol '\\dot{e}' contained conceal cchar=ė
      syntax match texMathSymbol '\\dot{G}' contained conceal cchar=Ġ
      syntax match texMathSymbol '\\dot{g}' contained conceal cchar=ġ
      syntax match texMathSymbol '\\dot{I}' contained conceal cchar=İ

      syntax match texMathSymbol '\\dot{A}' contained conceal cchar=Ȧ
      syntax match texMathSymbol '\\dot{a}' contained conceal cchar=ȧ
      syntax match texMathSymbol '\\dot{O}' contained conceal cchar=Ȯ
      syntax match texMathSymbol '\\dot{o}' contained conceal cchar=ȯ
    endif

    " Conceal replace greek letters
    if l:cfg.conceal =~# 'g'
      call s:match_conceal_greek()
    endif

    " Conceal replace superscripts and subscripts
    if l:cfg.conceal =~# 's'
      call s:match_conceal_super_sub(l:cfg)
    endif

    " Conceal replace accented characters and ligatures
    if l:cfg.conceal =~# 'a'
      if l:cfg.is_style_document
        syntax match texAccent   "\\[bcdvuH][^a-zA-Z@]"me=e-1
        syntax match texLigature "\\\([ijolL]\|ae\|oe\|ss\|AA\|AE\|OE\)[^a-zA-Z@]"me=e-1
        syntax match texLigature '--'
        syntax match texLigature '---'
      else
        call s:match_conceal_accents()

        syntax match texAccent   '\\aa\>' conceal cchar=å
        syntax match texAccent   '\\AA\>' conceal cchar=Å
        syntax match texAccent   '\\o\>'  conceal cchar=ø
        syntax match texAccent   '\\O\>'  conceal cchar=Ø
        syntax match texLigature '\\AE\>' conceal cchar=Æ
        syntax match texLigature '\\ae\>' conceal cchar=æ
        syntax match texLigature '\\oe\>' conceal cchar=œ
        syntax match texLigature '\\OE\>' conceal cchar=Œ
        syntax match texLigature '\\ss\>' conceal cchar=ß
        syntax match texLigature '--'     conceal cchar=–
        syntax match texLigature '---'    conceal cchar=—
      endif
    endif
  endif

  " {{{2 Synchronization

  syntax sync maxlines=200
  syntax sync minlines=50
  syntax sync match texSyncStop groupthere NONE "%stopzone\>"

  " The $..$ and $$..$$ make for impossible sync patterns (one can't tell if
  " a "$$" starts or stops a math zone by itself) The following grouptheres
  " coupled with minlines above help improve the odds of good syncing.
  syntax sync match texSyncMathZoneA groupthere NONE "\\end{abstract}"
  syntax sync match texSyncMathZoneA groupthere NONE "\\end{center}"
  syntax sync match texSyncMathZoneA groupthere NONE "\\end{description}"
  syntax sync match texSyncMathZoneA groupthere NONE "\\end{enumerate}"
  syntax sync match texSyncMathZoneA groupthere NONE "\\end{itemize}"
  syntax sync match texSyncMathZoneA groupthere NONE "\\end{table}"
  syntax sync match texSyncMathZoneA groupthere NONE "\\end{tabular}"
  syntax sync match texSyncMathZoneA groupthere NONE "\\\(sub\)*section\>"

  " }}}2

  call s:init_highlights(l:cfg)

  let b:current_syntax = 'tex'

  call vimtex#syntax#init_post()
endfunction

" }}}1

function! s:init_clusters() abort " {{{1
  syntax cluster texCmdGroup contains=texCmdBody,texComment,texDefParm,texDelimiter,texDocType,texInput,texLength,texLigature,texMathDelim,texMathOper,texNewCmd,texNewEnv,texRefZone,texSection,texBeginEnd,texBeginEndName,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,@texMathZones,texMathError

  syntax cluster texEnvGroup contains=texMatcher,texMathDelim,texSpecialChar,texStatement
  syntax cluster texZoneGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texInputFile,texLength,texLigature,texMatcher,texMathZoneV,texMathZoneW,texMathZoneX,texMathZoneY,texMathZoneZ,texNewCmd,texNewEnv,texOnlyMath,texOption,texParen,texRefZone,texSection,texBeginEnd,texSectionZone,texSpaceCode,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texZone,@texMathZones,texTitle,texAbstract,texBoldStyle,texItalStyle,texEmphStyle,texNoSpell
  syntax cluster texBoldGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texInputFile,texLength,texLigature,texMathZoneV,texMathZoneW,texMathZoneX,texMathZoneY,texMathZoneZ,texNewCmd,texNewEnv,texOnlyMath,texOption,texParen,texRefZone,texSection,texBeginEnd,texSectionZone,texSpaceCode,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texZone,@texMathZones,texTitle,texAbstract,texBoldStyle,texBoldItalStyle,texNoSpell,texMatcher
  syntax cluster texItalGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texInputFile,texLength,texLigature,texMathZoneV,texMathZoneW,texMathZoneX,texMathZoneY,texMathZoneZ,texNewCmd,texNewEnv,texOnlyMath,texOption,texParen,texRefZone,texSection,texBeginEnd,texSectionZone,texSpaceCode,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texZone,@texMathZones,texTitle,texAbstract,texItalStyle,texEmphStyle,texItalBoldStyle,texNoSpell,texMatcher

  syntax cluster texStyleGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texLength,texLigature,texNewCmd,texNewEnv,texOnlyMath,texParen,texRefZone,texSection,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texBoldStyle,texBoldItalStyle,texItalStyle,texItalBoldStyle,texZone,texInputFile,texOption,texStyleStatement,texStyleMatcher,@Spell

  syntax cluster texRefGroup contains=texMatcher,texComment,texDelimiter

  syntax cluster texMathZones contains=texMathZoneV,texMathZoneW,texMathZoneX,texMathZoneY,texMathZoneZ
  syntax cluster texMatchGroup contains=texAccent,texBadMath,texComment,texDefCmd,texDelimiter,texDocType,texInput,texLength,texLigature,texMatcher,texNewCmd,texNewEnv,texOnlyMath,texParen,texRefZone,texSection,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texBoldStyle,texBoldItalStyle,texItalStyle,texItalBoldStyle,texZone,texInputFile,texOption,@Spell,@texMathZones
  syntax cluster texMathDelimGroup contains=texMathDelimBad,texMathDelimKey,texMathDelimSet1,texMathDelimSet2
  syntax cluster texMathMatchGroup contains=@texMathZones,texComment,texDefCmd,texDelimiter,texDocType,texInput,texLength,texLigature,texMathDelim,texMathMatcher,texMathOper,texNewCmd,texNewEnv,texRefZone,texSection,texSpecialChar,texStatement,texString,texTypeSize,texTypeStyle,texZone,texMathError
  syntax cluster texMathZoneGroup contains=texComment,texDelimiter,texLength,texMathDelim,texMathMatcher,texMathOper,texMathSymbol,texMathText,texRefZone,texSpecialChar,texStatement,texTypeSize,texTypeStyle,texMathError,@NoSpell

  syntax cluster texDocGroup contains=texPartZone,@texPartGroup
  syntax cluster texPartGroup contains=texChapterZone,texSectionZone,texParaZone
  syntax cluster texChapterGroup contains=texSectionZone,texParaZone
  syntax cluster texSectionGroup contains=texSubSectionZone,texParaZone
  syntax cluster texSubSectionGroup contains=texSubSubSectionZone,texParaZone
  syntax cluster texSubSubSectionGroup contains=texParaZone
  syntax cluster texParaGroup contains=texSubParaZone

  syntax cluster texMathZoneGroup add=texGreek,texSuperscript,texSubscript,texMathSymbol
  syntax cluster texMathMatchGroup add=texGreek,texSuperscript,texSubscript,texMathSymbol

  syntax cluster texCommentGroup contains=texTodo,@Spell
endfunction

" }}}1
function! s:init_highlights(cfg) abort " {{{1
  " TeX highlighting groups which should share similar highlighting
  highlight def link texBadMath              texError
  highlight def link texMathDelimBad         texError
  highlight def link texMathError            texError
  highlight def link texError                 Error
  if a:cfg.is_style_document
    highlight def link texOnlyMath           texError
  endif

  highlight texBoldStyle               gui=bold        cterm=bold
  highlight texItalStyle               gui=italic      cterm=italic
  highlight texBoldItalStyle           gui=bold,italic cterm=bold,italic
  highlight texItalBoldStyle           gui=bold,italic cterm=bold,italic
  highlight def link texEmphStyle      texItalStyle
  highlight def link texCite           texRefZone
  highlight def link texDefCmd         texDef
  highlight def link texDefName        texDef
  highlight def link texDocType        texCmdName
  highlight def link texDocTypeArgs    texCmdArgs
  highlight def link texInputFileOpt   texCmdArgs
  highlight def link texInputCurlies   texDelimiter
  highlight def link texLigature       texSpecialChar
  highlight def link texMathDelimSet1 texMathDelim
  highlight def link texMathDelimSet2 texMathDelim
  highlight def link texMathDelimKey  texMathDelim
  highlight def link texMathMatcher   texMath
  highlight def link texAccent        texStatement
  highlight def link texGreek         texStatement
  highlight def link texSuperscript   texStatement
  highlight def link texSubscript     texStatement
  highlight def link texSuperscripts  texSuperscript
  highlight def link texSubscripts    texSubscript
  highlight def link texMathSymbol    texStatement
  highlight def link texMathZoneV     texMath
  highlight def link texMathZoneW     texMath
  highlight def link texMathZoneX     texMath
  highlight def link texMathZoneY     texMath
  highlight def link texMathZoneV     texMath
  highlight def link texMathZoneZ     texMath
  highlight def link texBeginEnd       texCmdName
  highlight def link texBeginEndName   texSection
  highlight def link texSpaceCode      texStatement
  highlight def link texStyleStatement texStatement
  highlight def link texTypeSize       texType
  highlight def link texTypeStyle      texType

  " Basic TeX highlighting groups
  highlight def link texCmdArgs        Number
  highlight def link texCmdName        Statement
  highlight def link texComment        Comment
  highlight def link texDef            Statement
  highlight def link texDefParm        Special
  highlight def link texDelimiter      Delimiter
  highlight def link texInput          Special
  highlight def link texInputFile      Special
  highlight def link texLength         Number
  highlight def link texMath           Special
  highlight def link texMathDelim      Statement
  highlight def link texMathOper       Operator
  highlight def link texNewCmd         Statement
  highlight def link texNewEnv         Statement
  highlight def link texOption         Number
  highlight def link texRefZone        Special
  highlight def link texSection        PreCondit
  highlight def link texSpaceCodeChar  Special
  highlight def link texSpecialChar    SpecialChar
  highlight def link texStatement      Statement
  highlight def link texString         String
  highlight def link texTodo           Todo
  highlight def link texType           Type
  highlight def link texZone           PreCondit
endfunction

" }}}1

function! s:match_conceal_accents() " {{{1
  for [l:chr; l:targets] in s:map_accents
    for i in range(13)
      if empty(l:targets[i]) | continue | endif
        let l:accent = s:key_accents[i]
        let l:target = l:targets[i]
        if l:accent =~# '\a'
          execute 'syntax match texAccent /' . l:accent . '\%(\s*{' . l:chr . '}\|\s\+' . l:chr . '\)' . '/ conceal cchar=' . l:target
        else
          execute 'syntax match texAccent /' . l:accent . '\s*\%({' . l:chr . '}\|' . l:chr . '\)' . '/ conceal cchar=' . l:target
        endif
    endfor
  endfor
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
function! s:match_conceal_greek() " {{{1
  for [l:from, l:to] in s:map_greek
    execute 'syntax match texGreek /' . l:from . '/ contained conceal cchar=' . l:to
  endfor
endfunction

let s:map_greek = [
      \ ['\\alpha\>',           'α'],
      \ ['\\beta\>',            'β'],
      \ ['\\gamma\>',           'γ'],
      \ ['\\delta\>',           'δ'],
      \ ['\\epsilon\>',         'ϵ'],
      \ ['\\varepsilon\>',      'ε'],
      \ ['\\zeta\>',            'ζ'],
      \ ['\\eta\>',             'η'],
      \ ['\\theta\>',           'θ'],
      \ ['\\vartheta\>',        'ϑ'],
      \ ['\\iota\>',            'ι'],
      \ ['\\kappa\>',           'κ'],
      \ ['\\lambda\>',          'λ'],
      \ ['\\mu\>',              'μ'],
      \ ['\\nu\>',              'ν'],
      \ ['\\xi\>',              'ξ'],
      \ ['\\pi\>',              'π'],
      \ ['\\varpi\>',           'ϖ'],
      \ ['\\rho\>',             'ρ'],
      \ ['\\varrho\>',          'ϱ'],
      \ ['\\sigma\>',           'σ'],
      \ ['\\varsigma\>',        'ς'],
      \ ['\\tau\>',             'τ'],
      \ ['\\upsilon\>',         'υ'],
      \ ['\\phi\>',             'ϕ'],
      \ ['\\varphi\>',          'φ'],
      \ ['\\chi\>',             'χ'],
      \ ['\\psi\>',             'ψ'],
      \ ['\\omega\>',           'ω'],
      \ ['\\Gamma\>',           'Γ'],
      \ ['\\Delta\>',           'Δ'],
      \ ['\\Theta\>',           'Θ'],
      \ ['\\Lambda\>',          'Λ'],
      \ ['\\Xi\>',              'Ξ'],
      \ ['\\Pi\>',              'Π'],
      \ ['\\Sigma\>',           'Σ'],
      \ ['\\Upsilon\>',         'Υ'],
      \ ['\\Phi\>',             'Φ'],
      \ ['\\Chi\>',             'Χ'],
      \ ['\\Psi\>',             'Ψ'],
      \ ['\\Omega\>',           'Ω'],
      \]

" }}}1
function! s:match_conceal_super_sub(cfg) " {{{1
  syntax region texSuperscript matchgroup=Delimiter start='\^{' skip="\\\\\|\\[{}]" end='}' contained concealends contains=texSpecialChar,texSuperscripts,texStatement,texSubscript,texSuperscript,texMathMatcher
  syntax region texSubscript   matchgroup=Delimiter start='_{'  skip="\\\\\|\\[{}]" end='}' contained concealends contains=texSpecialChar,texSubscripts,texStatement,texSubscript,texSuperscript,texMathMatcher

  for [l:from, l:to] in filter(copy(s:map_super),
        \ {_, x -> x[0][0] ==# '\' || x[0] =~# a:cfg.conceal_set_super})
    execute 'syntax match texSuperscript /\^' . l:from . '/ contained conceal cchar=' . l:to
    execute 'syntax match texSuperscripts /'  . l:from . '/ contained conceal cchar=' . l:to 'nextgroup=texSuperscripts'
  endfor

  for [l:from, l:to] in filter(copy(s:map_sub),
        \ {_, x -> x[0][0] ==# '\' || x[0] =~# a:cfg.conceal_set_sub})
    execute 'syntax match texSubscript /_' . l:from . '/ contained conceal cchar=' . l:to
    execute 'syntax match texSubscripts /' . l:from . '/ contained conceal cchar=' . l:to . ' nextgroup=texSubscripts'
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
