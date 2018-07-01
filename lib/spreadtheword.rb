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
    logs = structure(fetchAllLogs)
    parseTopics(logs)
    writer = Spreadtheword::LaTeX.new(@title, @author, @topics)
    writer.write!
  end

  def fetchAllLogs
    [].tap do |ret|
      @projects.each do |project|
        @utils.say "Fetching git commit logs from #{project}"
        Dir.chdir(project) do
          ret.concat fetchLogs
          @utils.say "."
        end
        @utils.say "\n"
      end
    end
  end

  def fetchLogs
    cmd = %Q{git log --pretty=format:"%an__spreadtheword__%s"}
    if @since
      cmd = %Q{#{cmd} #{@since}..master}
    end
    logs = `#{cmd}`.to_s.split("\n")
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
        y.origMsg = contents[1]
        if y.origMsg
          y.msg = getTranslation(contents[1]).text
        else
          y.msg = y.origMsg
        end
      end
    end
  end

  def parseTopics(logs)
    logs.each do |x|
      title = 'Others'
      topic = {}
      if x.origMsg =~ /\{(.*)#(\d+)\}/
      elsif x.origMsg =~ /\{#(\d+)\}/
      elsif x.orgMsg = ~ /\{W#(\d+)\}/
        topic = getWrike($1)
      end
      @topics[title] ||= []
      @topics[title] << {
        commit: x,
        topic: topic,
      }
    end
  end

  def gitUserName
    `git config --get user.name`.to_s.strip
  end
end
