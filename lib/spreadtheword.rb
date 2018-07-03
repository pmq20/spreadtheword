require 'cgi'
require 'uri'
require 'ostruct'
require 'active_support/all'
require 'wrike3'
require 'gitlab'
require 'spreadtheword/version'
require 'spreadtheword/utils'
require 'spreadtheword/latex'
require 'google/cloud/translate'

class Spreadtheword
  CONNECTOR = '__spreadtheword__'
  NONASCII = /[^\u0000-\u007F]+/

  def initialize(projects, options)
    @projects = projects.any? ? projects : [Dir.pwd]
    @title = options.title ? options.title : 'Relase Notes'
    @author = options.author ? options.author : gitUserName
    @since = options.since

    configureGitlab(options) if options.gitlabToken
    configureWrike(options) if options.wrikeToken
    configureGoogleTranslate(options) if options.googleTranslateKey

    @utils = Utils.new(options)
    @logs = []
    @topics = {}
  end

  def configureGitlab(options)
    Gitlab.configure do |config|
      config.endpoint       = options.gitlabEndpoint
      config.private_token  = options.gitlabToken
    end
    @gitlab = URI(options.gitlabEndpoint)
    @gitlabCurrentProject = nil
    @gilabProjects = {}
    @gitlabCache = {}
  end

  def configureWrike(options)
    Wrike3.configure do |config|
      config.access_token  = options.wrikeToken
    end
    @wrike = Wrike3()
    @wrikeCache = {}
  end

  def configureGoogleTranslate(options)
    @translate = Google::Cloud::Translate.new(key: options.googleTranslateKey)
    translateCache = {}
    @getTranslation = lambda { |sentence|
    unless translateCache[sentence]
      @utils.say "Translating\n-> #{sentence}\n"
      translateCache[sentence] = CGI.unescapeHTML(@translate.translate(sentence, to: "en").text)
      @utils.say "<- #{translateCache[sentence]}\n"
    end
    translateCache[sentence]
  }
  end

  def getGitlab(projectId, issueNumber)
    unless @gitlabCache[projectId] && @gitlabCache[projectId][issueNumber]
      @gitlabCache[projectId] ||= {}
      @gitlabCache[projectId][issueNumber] = [
        Gitlab.issue(projectId, issueNumber),
        Gitlab.issue_notes(projectId, issueNumber, per_page: 1000),
      ]
    end
    return @gitlabCache[projectId][issueNumber]
  end

  def getWrike(wId)
    unless @wrikeCache[wId]
      permalink = "https://www.wrike.com/open.htm?id=#{wId}"
      @utils.say "Fetching Wrike task #{permalink}"
      tasks = @wrike.task.list nil, nil, permalink: permalink
      @utils.say "."
      taskId = tasks['data'][0]['id']
      task = @wrike.task.details taskId
      @utils.say "."
      @wrikeCache[wId] = task['data'][0]

      comments = @wrike.execute(:get, "https://www.wrike.com/api/v3/tasks/#{taskId}/comments?plainText=true")['data']
      usersH = {}; comments.map{|x| x['authorId']}.uniq.each{|x| usersH[x] = @wrike.user.details(x)['data'][0]}

      @wrikeCache[wId][:spreadthewordPermalink] = permalink
      @wrikeCache[wId][:spreadthewordComments] = comments
      @wrikeCache[wId][:spreadthewordusersH] = usersH
      
      @utils.say "\n"
    end
    return @wrikeCache[wId]
  end

  def run!
    fetchAllLogs
    parseTopics
    sortTopics
    writer = Spreadtheword::LaTeX.new(@title, @author, @topics, @getTranslation, @gitlab)
    writer.write!
  end

  def gitlabSetCurrentProject
    remotes = `git remote -v`
    remotes.to_s.split("\n").each do |line|
      if line.include?(@gitlab.host)
        lines = line.split(@gitlab.host)
        liness = lines[1].split('/')
        @gitlabCurrentProject = {
          namespace: liness[1],
          project: liness[2].split('.git')[0],
        }
        return
      end
    end
  end

  def fetchAllLogs
    @projects.each do |project|
      @utils.say "Fetching git commit logs from #{project}\n"
      Dir.chdir(project) do
        gitlabSetCurrentProject if @gitlab
        fetchLogs
      end
    end
  end

  def fetchLogs
    cmd = %Q{git log --pretty=format:"%an#{CONNECTOR}%s#{CONNECTOR}%H"}
    if @since
      cmd = %Q{#{cmd} #{@since}..master}
    end
    logs = `#{cmd}`.to_s.split("\n")
    logs.delete_if do |x|
      x.nil? || '' == x.to_s.strip
    end
    logs.map! do |x|
      contents = x.split(CONNECTOR)
      if contents[1].nil? || '' == contents[1].to_s.strip
        contents[1] = ''
      end
      OpenStruct.new.tap do |y|
        y.author = contents[0]
        y.origMsg = contents[1]
        y.shaHash = contents[2]
        if @translate && y.origMsg =~ NONASCII
          y.msg = @getTranslation.call(contents[1])
        else
          y.msg = y.origMsg
        end
        if @gitlab
          y.gitlabProject = @gitlabCurrentProject
        end
      end
    end
    @logs.concat logs
  end

  def parseTopics
    @logs.each do |x|
      origin = :plain
      identifier = nil
      payload = nil
      title = 'Others'
      begin
        if x.origMsg =~ /\{W(\d+)\}/
          origin = :wrike
          identifier = "W#{$1}"
          payload = getWrike($1)
          title = payload['title']
          x.msg = x.msg.gsub(/\{W\d+\}/, '')
        elsif x.origMsg =~ /\{*#(\d+)\}*/
          origin = :gitlab
          targetProjectId = "#{x.gitlabProject[:namespace]}/#{x.gitlabProject[:project]}"
          identifier = "#{targetProjectId}##{$1}"
          payload = getGitlab(targetProjectId, $1)
          title = payload[0].title
          x.msg = x.msg.gsub(/\{*#\d+\}*/, '')
        elsif x.origMsg =~ /\{*(\w+)#(\d+)\}*/
          origin = :gitlab
          if $1.include?('/')
            targetProjectId = $1.dup
          else
            targetProjectId = "#{x.gitlabProject[:namespace]}/#{$1}"
          end
          identifier = "#{targetProjectId}##{$2}"
          payload = getGitlab(targetProjectId, $2)
          title = payload[0].title
          x.msg = x.msg.gsub(/\{*\w+#\d+\}*/, '')
        end
      rescue => e
        STDERR.puts "!!! Exception when parsing topic !!! #{e}"
        origin = :plain
        identifier = nil
        payload = nil
        title = 'Others'
      end
      if @translate && title =~ NONASCII
        title = @getTranslation.call(title)
      end
      @topics[identifier] ||= []
      @topics[identifier] << {
        origin: origin,
        commit: x,
        payload: payload,
        title: title,
      }
    end
  end

  def sortTopics
    topicsH = @topics
    @topics = []
    topicsH.each do |k,v|
      @topics << [k,v]
    end
    @topics.sort! do |x,y|
      y[1].size <=> x[1].size
    end
  end

  def gitUserName
    `git config --get user.name`.to_s.strip
  end
end
