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
\\documentclass{amsbook}

\\usepackage{hyperref}

\\newtheorem{theorem}{Theorem}[chapter]
\\newtheorem{lemma}[theorem]{Lemma}
\\newtheorem{problem}[theorem]{Problem}
\\theoremstyle{definition}
\\newtheorem{definition}[theorem]{Definition}
\\newtheorem{example}[theorem]{Example}
\\newtheorem{xca}[theorem]{Exercise}
\\theoremstyle{remark}
\\newtheorem{remark}[theorem]{Remark}
\\newtheorem{question}[theorem]{Question}
\\numberwithin{section}{chapter}
\\numberwithin{equation}{chapter}

\\begin{document}
\\frontmatter
\\title{#{@title}}
\\author{#{@author}}
\\maketitle
\\setcounter{page}{4}
\\setcounter{tocdepth}{0}
\\tableofcontents
\\mainmatter
#{sections}
\\backmatter
\\appendix
\\chapter{Document Version}
\begin{center}
\today
\end{center}
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
        description = first[:payload][0].description
        url = first[:payload][0].web_url
      elsif :wrike == first[:origin]
        title = first[:title]
        description = Nokogiri::HTML(first[:payload]['description'].gsub('<br />', "\n\n")).text
        url = first[:payload][:spreadthewordPermalink]
      end
      ret += %Q_
\\chapter{#{escape title.titleize}}

\\section{Background}

\begin{center}
\\url{#{escape url}}
\end{center}

_

      if description.present?
        description.strip!
        description[0] = description[0].upcase
        ret += %Q_
\\section{Description}

#{escape description}

_
      end

      if :gitlab == first[:origin]
        first[:payload][1].reverse.each do |x|
          next if x.system
          msg = x.body      
          if @getTranslation && msg =~ Spreadtheword::NONASCII
            msg = @getTranslation.call(msg)
          end
          ret += %Q_
\\subsection{#{escape x.author.name}}

#{escape msg}

_
        end
      elsif :wrike == first[:origin]
        first[:payload][:spreadthewordComments].reverse.each do |x|
          user = first[:payload][:spreadthewordusersH][x['authorId']]
          msg = x['text']          
          if @getTranslation && msg =~ Spreadtheword::NONASCII
            msg = @getTranslation.call(msg)
          end
          ret += %Q_
\\subsection{#{escape user['firstName']} #{escape user['lastName']}}

#{escape msg}

_
        end
      end

      ret += printDevelopers(v)
    end
    topicNil = @topics.find{|x| x[0].nil?}
    if topicNil
      ret += %Q_
\\chapter{Others}
      _
      ret += printDevelopers(topicNil[1])
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
\\section{Developers}

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
\\section{#{escape k.titleize}'s Commit Messages}
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
    str.gsub(Spreadtheword::NONASCII, '').gsub('\\', '\\textbackslash ').gsub('&', '\\\&').gsub('%', '\\%').gsub('$', '\\$').gsub('#', '\\#').gsub('_', '\\_').gsub('{', '\\{').gsub('}', '\\}').gsub('~', '\\textasciitilde ').gsub('^', '\\textasciicircum ').gsub('<', '\\textless ').gsub('>', '\\textgreater ')
  end
end