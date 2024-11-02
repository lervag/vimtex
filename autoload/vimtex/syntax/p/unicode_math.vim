" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#unicode_math#load(cfg) abort " {{{1
  syntax match texMathCmdStyle contained "\\symbb\>"
  syntax match texMathCmdStyle contained "\\symbf\>"
  syntax match texMathCmdStyle contained "\\symcal\>"
  syntax match texMathCmdStyle contained "\\symfrak\>"
  syntax match texMathCmdStyle contained "\\symit\>"
  syntax match texMathCmdStyle contained "\\symbfit\>"
  syntax match texMathCmdStyle contained "\\symnormal\>"
  syntax match texMathCmdStyle contained "\\symrm\>"
  syntax match texMathCmdStyle contained "\\symsf\>"
  syntax match texMathCmdStyle contained "\\symtt\>"
  syntax match texMathCmdStyle contained "\\symscr\>"

  let [l:conceal, l:concealends] =
        \ (g:vimtex_syntax_conceal.styles ? ['conceal', 'concealends'] : ['', ''])

  let l:map = {
        \ 'texMathCmdStyleBold': 'texMathStyleBold',
        \ 'texMathCmdStyleItal': 'texMathStyleItal',
        \ 'texMathCmdStyleBoth': 'texMathStyleBoth',
        \}

  for [l:group, l:pattern] in [
        \ ['texMathCmdStyleBold', 'symbf'],
        \ ['texMathCmdStyleItal', 'symit'],
        \ ['texMathCmdStyleBoth', 'symbfit'],
        \]
    execute 'syntax match' l:group '"\\' . l:pattern . '\>"'
          \ 'contained skipwhite nextgroup=' . l:map[l:group]
          \ l:conceal
  endfor

  if g:vimtex_syntax_conceal.styles
    syntax match texMathCmdStyle "\v\\sym%(rm|tt|normal|sf)>"
          \ contained conceal skipwhite nextgroup=texMathStyleConcArg
  endif

  if g:vimtex_syntax_conceal.math_symbols
    for [l:cmd, l:alphabet_map] in [
          \ ['sym\%(bb\%(b\|m\%(ss\|tt\)\?\)\?\|ds\)', 'double'],
          \ ['symfrak', 'fraktur'],
          \ ['sym\%(scr\|cal\)', 'script'],
          \ ['symbffrak', 'fraktur_bold'],
          \ ['symbf\%(scr\|cal\)', 'script_bold'],
          \]
      let l:pairs = vimtex#syntax#core#get_alphabet_map(l:alphabet_map)
      call vimtex#syntax#core#conceal_cmd_pairs(l:cmd, l:pairs)
    endfor

    syntax match texMathSymbol '\%#=1\\mathhyphen\>'        contained conceal cchar=‐
    syntax match texMathSymbol '\%#=1\\mathstraightquote\>' contained conceal cchar='
    syntax match texMathSymbol '\%#=1\\mathbacktick\>'      contained conceal cchar=`
    syntax match texMathSymbol '\%#=1\\slash\>'             contained conceal cchar=/
    syntax match texMathSymbol '\%#=1\\fracslash\>'         contained conceal cchar=⁄
    syntax match texMathSymbol '\%#=1\\divslash\>'          contained conceal cchar=∕
    syntax match texMathSymbol '\%#=1\\reversesolidus\>'    contained conceal cchar=⧵
    syntax match texMathSymbol '\%#=1\\cdotp\>'             contained conceal cchar=·
    syntax match texMathSymbol '\%#=1\\vysmblkcircle\>'     contained conceal cchar=∙
    syntax match texMathSymbol '\%#=1\\smblkcircle\>'       contained conceal cchar=•
    syntax match texMathSymbol '\%#=1\\mdsmblkcircle\>'     contained conceal cchar=⦁
    syntax match texMathSymbol '\%#=1\\mdblkcircle\>'       contained conceal cchar=⚫
    syntax match texMathSymbol '\%#=1\\mdlgblkcircle\>'     contained conceal cchar=●
    syntax match texMathSymbol '\%#=1\\lgblkcircle\>'       contained conceal cchar=⬤
    syntax match texMathSymbol '\%#=1\\vysmwhtcircle\>'     contained conceal cchar=∘
    syntax match texMathSymbol '\%#=1\\smwhtcircle\>'       contained conceal cchar=◦
    syntax match texMathSymbol '\%#=1\\mdsmwhtcircle\>'     contained conceal cchar=⚬
    syntax match texMathSymbol '\%#=1\\mdwhtcircle\>'       contained conceal cchar=⚪
    syntax match texMathSymbol '\%#=1\\mdlgwhtcircle\>'     contained conceal cchar=○
    syntax match texMathSymbol '\%#=1\\lgwhtcircle\>'       contained conceal cchar=◯
  endif
endfunction

" }}}1
