% Package info
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{custom}[2020/01/01 v1.0 Custom class]

% Class dependencies
\LoadClass[12pt, a4paper]{report}
\RequirePackage[hyperref]{xcolor}
\RequirePackage[pdfusetitle]{hyperref}

% Graphics
\RequirePackage{graphicx}

% Language
\RequirePackage{polyglossia}
\RequirePackage{csquotes}
\setmainlanguage{english}

% Layout
\RequirePackage[nomarginpar]{geometry}

% Mathematics
\RequirePackage{amssymb, amsmath, amsthm}
\RequirePackage[cmintegrals]{newtxmath}
\newcommand{\true}{\mkern1mu\top\mkern1mu}
\newcommand{\false}{\mkern1mu\bot\mkern1mu}
\renewcommand{\emptyset}{\varnothing}
\newcommand{\eps}{\varepsilon}
\newcommand{\cd}{\cdot}
\newcommand{\dd}{\,\mathrm{d}}
\newcommand{\pd}{\partial}

% Fonts
\RequirePackage{fontspec}
\setmainfont{Ubuntu}

% Layout
\RequirePackage[parfill]{parskip}
\frenchspacing

% Tables
\RequirePackage{array}
\RequirePackage{booktabs}
\RequirePackage{makecell}
\RequirePackage{colortbl}
\RequirePackage{setspace}
\setlength{\abovetopsep}{0pt}
\setlength{\belowrulesep}{0pt}
\setlength{\arrayrulewidth}{1pt}
\setlength{\tabcolsep}{0.5em}
\newcolumntype{^}{>{\global\let\currentrowstyle\relax}}
\newcolumntype{+}{>{\currentrowstyle}}
\newcommand{\rowstyle}[1]{\gdef\currentrowstyle{#1}#1\ignorespaces}
\let\@bottomrule\bottomrule\renewcommand{\bottomrule}{\@bottomrule\rowstyle{\bfseries}}

% Contents
\newlength{\halfline}\setlength{\halfline}{0.5\baselineskip}
\newcommand{\justify}[1]{\makebox[\linewidth][s]{#1}}
\newcommand{\addindent}{\hspace{\parindent}}
\newcommand{\addline}{\vspace{\baselineskip}}
\newcommand{\image}[2][]{\includegraphics[#1]{\string#2}}
