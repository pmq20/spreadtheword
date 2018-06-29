require "spreadtheword/version"
require "spreadtheword/latex"
require "ostruct"

class Spreadtheword
  CONNECTOR = '__spreadtheword__'

  def initialize(options)
    @root = options.root ? options.root : Dir.pwd
    @title = options.title ? options.title : 'Relase Notes'
    @author = options.author ? options.author : gitUserName
    @topics = {}
  end

  def run!
    Dir.chdir(@root) do
      cmd = %Q{git log --pretty=format:"%an__spreadtheword__%s"}
      logs = `#{cmd}`.to_s.split("\n")
      logs = structure(logs)
      parseTopics(logs)
      writer = Spreadtheword::LaTeX.new(@title, @author, @topics)
      writer.write!
    end
  end

  def structure(logs)
    logs.delete_if do |x|
      x.nil? || '' == x.to_s.strip
    end
    logs.map do |x|
      contents = x.split(CONNECTOR)
      if contents[1].nil? || '' == contents[1].to_s.strip
        contents[1] = ''
      end
      OpenStruct.new.tap do |y|
        y.author = contents[0]
        y.msg = contents[1]
        y.topic = y.msg
      end
    end
  end

  def parseTopics(logs)
    logs.each do |x|
      @topics[x.topic] = x
    end
  end

  def gitUserName
    `git config --get user.name`.to_s.strip
  end
end
