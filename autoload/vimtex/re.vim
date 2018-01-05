" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

let g:vimtex#re#not_bslash =  '\v%(\\@<!%(\\\\)*)@<='
let g:vimtex#re#not_comment = '\v%(' . g:vimtex#re#not_bslash . '\%.*)@<!'

let g:vimtex#re#tex_input_latex = '\v\\%(input|include|subfile)\s*\{'
let g:vimtex#re#tex_input_import = 
      \ '\v\\%(sub)?%(import|%(input|include)from)\*?\{[^\}]*\}\{'
let g:vimtex#re#tex_input = '\v%(' . join([
      \   g:vimtex#re#tex_input_latex,
      \   g:vimtex#re#tex_input_import,
      \ ], '|') . ')'

" {{{1 Completion regexes
let g:vimtex#re#neocomplete = 
      \ '\v\\%('
      \ .  '\a*cite\a*%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|%(text|block)cquote\*?%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|%(for|hy)\w*cquote\*?\{[^}]*}%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|\a*ref%(\s*\{[^}]*|range\s*\{[^,}]*%(}\{)?)'
      \ . '|hyperref\s*\[[^]]*'
      \ . '|includegraphics\*?%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|%(include%(only)?|input)\s*\{[^}]*'
      \ . '|\a*(gls|Gls|GLS)(pl)?\a*%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|includepdf%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|includestandalone%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|usepackage%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|documentclass%(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|\a*'
      \ . ')'

let g:vimtex#re#deoplete = '\\(?:'
      \ .  '\w*cite\w*(?:\s*\[[^]]*\]){0,2}\s*{[^}]*'
      \ . '|(text|block)cquote\*?(?:\s*\[[^]]*\]){0,2}\s*{[^}]*'
      \ . '|(for|hy)\w*cquote\*?{[^}]*}(?:\s*\[[^]]*\]){0,2}\s*{[^}]*'
      \ . '|\w*ref(?:\s*\{[^}]*|range\s*\{[^,}]*(?:}{)?)'
      \ . '|hyperref\s*\[[^]]*'
      \ . '|includegraphics\*?(?:\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|(?:include(?:only)?|input)\s*\{[^}]*'
      \ . '|\w*(gls|Gls|GLS)(pl)?\w*(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
      \ . '|includepdf(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|includestandalone(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|usepackage(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|documentclass(\s*\[[^]]*\])?\s*\{[^}]*'
      \ . '|\w*'
      \ .')'

let g:vimtex#re#ncm = [
      \ '\\[A-Za-z]*',
      \ '\\[A-Za-z]*cite[A-Za-z]*(\[[^]]*\]){0,2}{[^}]*',
      \ '\\(text|block)cquote\*?(\[[^]]*\]){0,2}{[^}]*',
      \ '\\(for|hy)[A-Za-z]*cquote\*?{[^}]*}(\[[^]]*\]){0,2}{[^}]*',
      \ '\\[A-Za-z]*ref({[^}]*|range{([^,{}]*(}{)?))',
      \ '\\hyperref\[[^]]*',
      \ '\\includegraphics\*?(\[[^]]*\]){0,2}{[^}]*',
      \ '\\(include(only)?|input){[^}]*',
      \ '\\\a*(gls|Gls|GLS)(pl)?\a*(\s*\[[^]]*\]){0,2}\s*\{[^}]*',
      \ '\\includepdf(\s*\[[^]]*\])?\s*\{[^}]*',
      \ '\\includestandalone(\s*\[[^]]*\])?\s*\{[^}]*',
      \ '\\usepackage(\s*\[[^]]*\])?\s*\{[^}]*',
      \ '\\documentclass(\s*\[[^]]*\])?\s*\{[^}]*',
      \]

let g:vimtex#re#youcompleteme = map(copy(g:vimtex#re#ncm), "'re!' . v:val")

" }}}1
