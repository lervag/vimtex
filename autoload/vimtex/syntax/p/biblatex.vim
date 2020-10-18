" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#biblatex#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'biblatex') | return | endif
  let b:vimtex_syntax.biblatex = 1

  if get(g:, 'tex_fast', 'r') !~# 'r' | return | endif

  for l:pattern in [
        \ 'bibentry',
        \ 'cite[pt]?\*?',
        \ 'citeal[tp]\*?',
        \ 'cite(num|text|url)',
        \ '[Cc]ite%(title|author|year(par)?|date)\*?',
        \ '[Pp]arencite\*?',
        \ 'foot%(full)?cite%(text)?',
        \ 'fullcite',
        \ '[Tt]extcite',
        \ '[Ss]martcite',
        \ 'supercite',
        \ '[Aa]utocite\*?',
        \ '[Ppf]?[Nn]otecite',
        \ '%(text|block)cquote\*?',
        \]
    execute 'syntax match texStatement'
          \ '/\v\\' . l:pattern . '\ze\s*%(\[|\{)/'
          \ 'nextgroup=texRefOption,texRefCite'
  endfor

  for l:pattern in [
        \ '[Cc]ites',
        \ '[Pp]arencites',
        \ 'footcite%(s|texts)',
        \ '[Tt]extcites',
        \ '[Ss]martcites',
        \ 'supercites',
        \ '[Aa]utocites',
        \ '[pPfFsStTaA]?[Vv]olcites?',
        \ 'cite%(field|list|name)',
        \]
    execute 'syntax match texStatement'
          \ '/\v\\' . l:pattern . '\ze\s*%(\[|\{)/'
          \ 'nextgroup=texRefOptions,texRefCites'
  endfor

  for l:pattern in [
        \ '%(foreign|hyphen)textcquote\*?',
        \ '%(foreign|hyphen)blockcquote',
        \ 'hybridblockcquote',
        \]
    execute 'syntax match texStatement'
          \ '/\v\\' . l:pattern . '\ze\s*%(\[|\{)/'
          \ 'nextgroup=texQuoteLang'
  endfor

  syntax region texRefOptions contained matchgroup=Delimiter
        \ start='\[' end=']'
        \ contains=@texClusterRef,texRegionRef
        \ nextgroup=texRefOptions,texRefCites

  syntax region texRefCites contained matchgroup=Delimiter
        \ start='{' end='}'
        \ contains=@texClusterRef,texRegionRef,texRefCites
        \ nextgroup=texRefOptions,texRefCites

  syntax region texQuoteLang contained matchgroup=Delimiter
        \ start='{' end='}'
        \ transparent
        \ contains=@texClusterMG
        \ nextgroup=texRefOption,texRefCite

  highlight def link texRefOptions texRefOption
  highlight def link texRefCites texRefCite
endfunction

" }}}1
