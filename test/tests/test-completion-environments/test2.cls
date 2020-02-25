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

\newenvironment{test2Simple}{a}{b}

\newenvironment{test2Boxed}
{\begin{center}
    \begin{tabular}{|p{0.9\textwidth}|}
      \hline\\
    }
    {
      \\\\\hline
    \end{tabular}
  \end{center}
}
