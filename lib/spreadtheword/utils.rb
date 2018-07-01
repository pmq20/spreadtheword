class Spreadtheword::Utils
  def initialize(options)
    @options = options
  end

  def say(something)
    unless @options.quiet
      STDERR.print something
      STDERR.flush
    end
  end
end