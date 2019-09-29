% vimtex - LaTeX plugin for Vim
%
% Maintainer: Karl Yngve Lervåg
% Email:      karl.yngve@gmail.com
%

ENTRY
  { address author booktitle chapter date doi edition editor eid howpublished institution isbn issn journal key month note number organization pages publisher school series title type volume year }
  {}
  { label }
STRINGS { s t}

FUNCTION {output}
{ 's :=
  %purify$
  %"}{" * write$
  "||" * write$
  s
}
FUNCTION {fin.entry}
%{ "}" * write$
{ write$
  newline$
}

FUNCTION {not}
{   { #0 }
    { #1 }
  if$
}
FUNCTION {and}
{   'skip$
    { pop$ #0 }
  if$
}
FUNCTION {or}
{   { pop$ #1 }
    'skip$
  if$
}
FUNCTION {field.or.null}
{ duplicate$ empty$
    { pop$ "" }
    'skip$
  if$
}

FUNCTION {capitalize}
{ "u" change.case$ "t" change.case$ }

FUNCTION {space.word}
{ " " swap$ * " " * }

FUNCTION {bbl.and}      { "&"}
FUNCTION {bbl.etal}     { "et al." }

INTEGERS { nameptr namesleft numnames }

STRINGS  { bibinfo}

FUNCTION {format.names}
{ duplicate$ empty$ 'skip$ {
  's :=
  "" 't :=
  #1 'nameptr :=
  s num.names$ 'numnames :=
  numnames 'namesleft :=
    { namesleft #0 > }
    { s nameptr
      %"{vv~}{ll}{, f.}{, jj}"
      "{vv }{ll}{}{}"
      format.name$
      't :=
      nameptr #1 >
        {
          namesleft #1 >
            { ", " * t * }
            {
              s nameptr "{ll}" format.name$ duplicate$ "others" =
                { 't := }
                { pop$ }
              if$
              t "others" =
                {
                  " " * bbl.etal *
                }
                {
                  bbl.and
                  space.word * t *
                }
              if$
            }
          if$
        }
        't
      if$
      nameptr #1 + 'nameptr :=
      namesleft #1 - 'namesleft :=
    }
  while$
  } if$
}

FUNCTION {format.authors}
{ author empty$
    {editor format.names} {author format.names}
  if$
}

FUNCTION {format.title}
{ title
  duplicate$ empty$ 'skip$
    { "t" change.case$ }
  if$
}

FUNCTION {output.label}
{ newline$
  %"{" cite$ * write$
  cite$ write$
  ""
}

FUNCTION {year.or.date}
{
    year empty$
    {date} 
    {year}
    if$    
}    

FUNCTION {format.date}
{
  ""
  duplicate$ empty$
  year.or.date duplicate$ empty$
    { swap$ 'skip$
        { "there's a month but no year in " cite$ * warning$ }
      if$
      *
    }
    { swap$ 'skip$
        {
          swap$
          " " * swap$
        }
      if$
      *
    }
  if$
}

FUNCTION {output.entry}
{ 's :=
  output.label
  s output
  format.authors output
  format.date output
  format.title output
  fin.entry
}

FUNCTION {default.type}     {"?" output.entry}

FUNCTION {article}          {"a" output.entry}
FUNCTION {book}             {"B" output.entry}
FUNCTION {booklet}          {"k" output.entry}
FUNCTION {conference}       {"f" output.entry}
FUNCTION {inbook}           {"b" output.entry}
FUNCTION {incollection}     {"c" output.entry}
FUNCTION {inproceedings}    {"p" output.entry}
FUNCTION {manual}           {"m" output.entry}
FUNCTION {mastersthesis}    {"Master" output.entry}
FUNCTION {misc}             {"-" output.entry}
FUNCTION {phdthesis}        {"PhD" output.entry}
FUNCTION {proceedings}      {"P" output.entry}
FUNCTION {techreport}       {"r" output.entry}
FUNCTION {unpublished}      {"u" output.entry}


READ
FUNCTION {sortify}
{ purify$
  "l" change.case$
}
INTEGERS { len }
FUNCTION {chop.word}
{ 's :=
  'len :=
  s #1 len substring$ =
    { s len #1 + global.max$ substring$ }
    's
  if$
}
FUNCTION {sort.format.names}
{ 's :=
  #1 'nameptr :=
  ""
  s num.names$ 'numnames :=
  numnames 'namesleft :=
    { namesleft #0 > }
    { s nameptr
      "{vv{ } }{ll{ }}{  f{ }}{  jj{ }}"
      format.name$ 't :=
      nameptr #1 >
        {
          "   "  *
          namesleft #1 = t "others" = and
            { "zzzzz" * }
            { t sortify * }
          if$
        }
        { t sortify * }
      if$
      nameptr #1 + 'nameptr :=
      namesleft #1 - 'namesleft :=
    }
  while$
}

FUNCTION {sort.format.title}
{ 't :=
  "A " #2
    "An " #3
      "The " #4 t chop.word
    chop.word
  chop.word
  sortify
  #1 global.max$ substring$
}
FUNCTION {author.sort}
{ author empty$
    { key empty$
        { "to sort, need author or key in " cite$ * warning$
          ""
        }
        { key sortify }
      if$
    }
    { author sort.format.names }
  if$
}
FUNCTION {author.editor.sort}
{ author empty$
    { editor empty$
        { key empty$
            { "to sort, need author, editor, or key in " cite$ * warning$
              ""
            }
            { key sortify }
          if$
        }
        { editor sort.format.names }
      if$
    }
    { author sort.format.names }
  if$
}
FUNCTION {author.organization.sort}
{ author empty$
    { organization empty$
        { key empty$
            { "to sort, need author, organization, or key in " cite$ * warning$
              ""
            }
            { key sortify }
          if$
        }
        { "The " #4 organization chop.word sortify }
      if$
    }
    { author sort.format.names }
  if$
}
FUNCTION {editor.organization.sort}
{ editor empty$
    { organization empty$
        { key empty$
            { "to sort, need editor, organization, or key in " cite$ * warning$
              ""
            }
            { key sortify }
          if$
        }
        { "The " #4 organization chop.word sortify }
      if$
    }
    { editor sort.format.names }
  if$
}
FUNCTION {presort}
{ type$ "book" =
  type$ "inbook" =
  or
    'author.editor.sort
    { type$ "proceedings" =
        'editor.organization.sort
        { type$ "manual" =
            'author.organization.sort
            'author.sort
          if$
        }
      if$
    }
  if$
  "    "
  *
  year field.or.null sortify
  *
  "    "
  *
  title field.or.null
  sort.format.title
  *
  #1 entry.max$ substring$
  'sort.key$ :=
}
ITERATE {presort}
SORT
ITERATE {call.type$}
