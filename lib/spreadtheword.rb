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
    configureGoogleTranslate(options) if options.googleTranslate

    @utils = Utils.new(options)
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
    @translate = Google::Cloud::Translate.new
    @translateCache = {}
  end

  def getGitlab(projectId, issueNumber)
    unless @gitlabCache[projectId] && @gitlabCache[projectId][issueNumber]
      @gitlabCache[projectId] ||= {}
      @gitlabCache[projectId][issueNumber] = Gitlab.issue(projectId, issueNumber)
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
      @utils.say "\n"
    end
    return @wrikeCache[wId]
  end

  def getTranslation(sentence)
    unless @wrikeCache[sentence]
      @utils.say "Translating #{sentence} to"
      @wrikeCache[sentence] = @translate.translate sentence, to: "en"
      @utils.say "#{@wrikeCache[sentence].text}\n"
    end
    return @wrikeCache[sentence]
  end

  def run!
    fetchAllLogs
    parseTopics
    writer = Spreadtheword::LaTeX.new(@title, @author, @topics)
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
      end
    end
  end

  def fetchAllLogs
    @logs = []
    @projects.each do |project|
      if @gitlab
        gitlabSetCurrentProject
      end
      @utils.say "Fetching git commit logs from #{project}"
      Dir.chdir(project) do
        fetchLogs
        @utils.say "."
      end
      @utils.say "\n"
    end
  end

  def structureLogs
    cmd = %Q{git log --pretty=format:"%an__spreadtheword__%s"}
    if @since
      cmd = %Q{#{cmd} #{@since}..master}
    end
    logs = `#{cmd}`.to_s.split("\n")
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
        y.origMsg = contents[1]
        if y.origMsg =~ NONASCII
          y.msg = getTranslation(contents[1]).text
        else
          y.msg = y.origMsg
        end
        if @gitlab
          y.gitlabProject = @gitlabCurrentProject
        end
      end
    end
  end

  def parseTopics(logs)
    logs.each do |x|
      origin = :plain
      identifier = nil
      payload = nil
      title = 'Others'
      if x.origMsg =~ /\{(.*)#(\d+)\}/
        origin = :gitlab
        if $1.include?('/')
          targetProjectId = $1.dup
        else
          targetProjectId = "#{@gitlabCurrentProject[:namespace]}/#{$1}"
        end
        identifier = "#{targetProjectId}##{$2}"
        payload = getGitlab(targetProjectId, $2)
        title = payload.title
      elsif x.origMsg =~ /\{#(\d+)\}/
        origin = :gitlab
        targetProjectId = "#{@gitlabCurrentProject[:namespace]}/#{@gitlabCurrentProject[:project]}"
        identifier = "#{targetProjectId}##{$1}"
        payload = getGitlab(targetProjectId, $1)
        title = payload.title
      elsif x.orgMsg = ~ /\{W#(\d+)\}/
        origin = :wrike
        identifier = "W#{$1}"
        payload = getWrike($1)
        title = payload['title']
      end
      if @translate && title =~ NONASCII
        title = getTranslation(title).text
      end
      @topics[identifier] ||= []
      @topics[identifier] << {
        origin: origin
        commit: x,
        payload: payload,
        title: title,
      }
    end
  end

  def gitUserName
    `git config --get user.name`.to_s.strip
  end
end
