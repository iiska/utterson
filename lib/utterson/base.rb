
require 'utterson/html_check'

module Utterson
  class Base
    attr_reader :errors

    def initialize(opts={})
      @dir = opts[:dir] || './'
      @root = opts[:root] || @dir
      @errors = {}
      @checked_urls = {}
      @stats = {errors: 0, files: 0, urls: 0}
    end

    def check
      Dir.glob(File.join(@dir, '**/*.{html,htm}')) do |f|
        @stats[:files] += 1
        c = HtmlCheck.new(file: f, root: @root)
        c.when_done do |r|
          @stats[:urls] += r[:urls]
          @errors.merge! r[:errors]
        end
        c.run
      end
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
        puts "#{@stats[:files]} files with #{@stats[:urls]} urls checked and #{count} errors found."
      end
    end
  end
end
