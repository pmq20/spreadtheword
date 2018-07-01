require 'nokogiri'

class Spreadtheword::LaTeX
  def initialize title, author, topics, getTranslation
    @title = title
    @author = author
    @topics = topics
    @getTranslation = getTranslation
  end

  def write!
    puts %Q_
% !TEX TS-program = pdflatex
% !TEX encoding = UTF-8 Unicode

\\documentclass[11pt]{article} % use larger type; default would be 10pt
\\usepackage{hyperref}
\\usepackage[utf8]{inputenc} % set input encoding (not needed with XeLaTeX)
\\usepackage{geometry} % to change the page dimensions
\\geometry{a4paper} % or letterpaper (US) or a5paper or....
\\usepackage{graphicx} % support the \\includegraphics command and options
\\usepackage{booktabs} % for much better looking tables
\\usepackage{array} % for better arrays (eg matrices) in maths
\\usepackage{paralist} % very flexible & customisable lists (eg. enumerate/itemize, etc.)
\\usepackage{verbatim} % adds environment for commenting out blocks of text & for better verbatim
\\usepackage{subfig} % make it possible to include more than one captioned figure/table in a single float
\\usepackage{fancyhdr} % This should be set AFTER setting up the page geometry
\\pagestyle{fancy} % options: empty , plain , fancy
\\renewcommand{\\headrulewidth}{0pt} % customise the layout...
\\lhead{}\\chead{}\\rhead{}
\\lfoot{}\\cfoot{\\thepage}\\rfoot{}
\\usepackage[nottoc,notlof,notlot]{tocbibind} % Put the bibliography in the ToC
\\usepackage[titles,subfigure]{tocloft} % Alter the style of the Table of Contents
\\renewcommand{\\cftsecfont}{\\rmfamily\\mdseries\\upshape}
\\renewcommand{\\cftsecpagefont}{\\rmfamily\\mdseries\\upshape} % No bold!
\\title{#{@title}}
\\author{#{@author}}
\\begin{document}
\\maketitle
\\setcounter{tocdepth}{1}
\\tableofcontents
\\newpage
#{sections}
\\end{document}
    _
  end

  def sections
    ret = ''
    @topics.each do |k,v|
      next if k.nil?
      first = v[0]
      title = k
      description = ''
      url = ''
      if :gitlab == first[:origin]
        title = first[:title]
        description = first[:payload].description
        url = first[:payload].web_url
      elsif :wrike == first[:origin]
        title = first[:title]
        description = Nokogiri::HTML(first[:payload]['description'].gsub('<br />', "\n\n")).text
        url = first[:payload].spreadthewordPermalink
      end
      ret += %Q_
\\section{#{escape title}}

\\subsection{Background}

\\url{#{escape url}}
_

      if description.present?
        ret += %Q_
\\subsection{Description}

#{escape description}

_
      end

      ret += printDevelopers(v)
      ret += %Q_
\\newpage
      _
    end
    if @topics[nil]
      ret += %Q_
\\section{Others}
      _
      ret += printDevelopers(@topics[nil])
    end
    ret
  end

  def printDevelopers(values)
    developers = {}
    values.each do |x|
      developers[x[:commit].author] ||= []
      developers[x[:commit].author] << x
    end
    ret = %Q_
\\subsection{Developers}

\\begin{enumerate}
_
    developers.each do |k,v|
      ret += %Q_
      \\item #{escape k} ($#{v.size*100 / values.size}\\%$)
      _
    end
    ret += %Q_
\\end{enumerate}
    _
    developers.each do |k,v|
      ret += %Q_
\\subsection{#{escape k}'s Commit Messages}
\\begin{enumerate}
      _
      uniqM = v.map do |x|
        x[:commit].msg
      end.uniq
      uniqM.each do |x|
        ret += %Q_
\\item #{escape x}
        _
      end      
      ret += %Q_
\\end{enumerate}
      _
    end
    ret
  end

  def escape str
    return 'N/A' unless str.present?
    if @getTranslation && str =~ Spreadtheword::NONASCII
      str = @getTranslation.call(str)
    end
    str.gsub(Spreadtheword::NONASCII, '').gsub('\\', '\\textbackslash ').gsub('&', '\\\&').gsub('%', '\\%').gsub('$', '\\$').gsub('#', '\\#').gsub('_', '\\_').gsub('{', '\\{').gsub('}', '\\}').gsub('~', '\\textasciitilde ').gsub('^', '\\textasciicircum ')
  end
end