require 'nokogiri'

class Spreadtheword::LaTeX
  def initialize title, author, topics, getTranslation, gitlab
    @title = title
    @author = author
    @topics = topics
    @getTranslation = getTranslation
    @gitlab = gitlab
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
    @topics.each do |topic|
      k=topic[0]
      v=topic[1]
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
        url = first[:payload][:spreadthewordPermalink]
      end
      ret += %Q_
\\section{#{escape title.titleize}}

\\subsection{Background}

\\url{#{escape url}}
_

      if description.present?
        description.strip!
        description[0] = description[0].upcase
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
    topicNil = @topics.find{|x| x[0].nil?}
    if topicNil
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
    devArr = developers.map do |k,v|
      [
        v.size, %Q_
\\item #{escape k.titleize} ($#{format('%.2f', v.size*100.0 / values.size)}\\%$)
        _, k, v
      ]
    end
    devArr.sort! do |x,y|
      y[0] <=> x[0]
    end
    devArr.each do |x|
      ret += x[1]
    end
    ret += %Q_
\\end{enumerate}
    _
    devArr.each do |dev|
      k = dev[2]
      v = dev[3]
      ret += %Q_
\\subsection{#{escape k.titleize}'s Commit Messages}
\\begin{enumerate}
      _
      reverseH = {}
      uniqM = v.map do |x|
        msg = x[:commit].msg.to_s.strip.humanize
        reverseH[msg] = x
        msg
      end.uniq.sort
      uniqM.each do |msg|
        x = reverseH[msg]
        if @gitlab
          ret += %Q_
\\item \\href{#{@gitlab.scheme}://#{@gitlab.host}/#{x[:commit].gitlabProject[:namespace]}/#{x[:commit].gitlabProject[:project]}/commit/#{x[:commit].shaHash}}{#{escape msg}}
          _
        else
          ret += %Q_
\\item #{escape msg}
          _
        end
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