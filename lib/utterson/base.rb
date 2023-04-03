require "ruby-progressbar"

require "utterson/html_check"

module Utterson
  # Base implements initialization of the checking process and handles
  # outputting final results.
  class Base
    attr_reader :errors

    def initialize(opts = {})
      @dir = opts[:dir] || "./"
      @root = opts[:root] || @dir
      @errors = {}
      @checked_urls = {}
      @stats = {errors: 0, files: 0, urls: 0}
    end

    def check
      bar = ProgressBar.create
      threads = []
      Dir.glob(File.join(@dir, "**/*.{html,htm}")) do |f|
        @stats[:files] += 1
        bar.total = @stats[:files]
        c = HtmlCheck.new(file: f, root: @root)
        c.when_done do |r|
          bar.increment
          @stats[:urls] = r[:urls]
          @errors.merge! r[:errors]
        end
        threads << c.run
      end
      threads.each { |t| t.join }
      print_results
    end

    def print_results
      count = 0
      @errors.each do |file, info|
        puts file
        info.each do |url, response|
          s = response.respond_to?(:code) ? "HTTP #{response.code}" : response
          puts "\t#{url}\n\t\t#{s}"
          count += 1
        end
      end
      if count == 0
        puts "#{@stats[:files]} files with #{@stats[:urls]} urls checked."
      else
        puts "Q{#{@stats[:files]} files with #{@stats[:urls]} urls checked " \
          "and #{count} errors found."
      end
    end
  end
end
