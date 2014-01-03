require 'nokogiri'

require 'net/http'
require 'timeout'
require 'thread'

module Utterson
  # Handle collecting URIs from HTML documents and both remote and
  # local checking of them.
  class HtmlCheck
    attr_reader :errors

    @@semaphore = Mutex.new
    @@checked_urls = {}

    def initialize(opts={})
      @file = opts[:file]
      @root = opts[:root]
      @errors = {}
    end

    def when_done(&handler)
      @result_handler = handler
    end

    def run
      Thread.new do
        collect_uris_from(@file).each do |u|
          check_uri(u, @file)
        end
        unless @result_handler.nil?
          @@semaphore.synchronize do
            @result_handler.call(errors: @errors, urls: @@checked_urls.count)
          end
        end
      end
    end

    def collect_uris_from(f)
      ret = []
      doc = Nokogiri::HTML(File.read(f))
      doc.traverse do |el|
        ret << el['src'] unless el['src'].nil?
        ret << el['href'] unless el['href'].nil?
      end
      ret
    end

    def check_uri(url, file)
      @@semaphore.synchronize do
        if @@checked_urls[url]
          return
        else
          @@checked_urls[url] = true
        end
      end

      if url =~ /^(https?:)?\/\//
        check_remote_uri url, file
      else
        check_local_uri url, file
      end
    end

    def check_remote_uri(url, file)
      uri = URI(url.gsub(/^\/\//, 'http://'))

      response = Net::HTTP.start(uri.host, uri.port,
                                 :use_ssl => uri.scheme == 'https') do |http|
        http.head uri.path.empty? ? "/" : uri.path
      end
      if response.code =~ /^[^23]/
        add_error(file, uri.to_s, response)
      end

    rescue => e
      add_error(file, uri.to_s, e.message)
    end

    def check_local_uri(url, file)
      url.gsub!(/\?.*$/, '')
      if url =~ /^\//
        path = File.expand_path(".#{url}", @root)
      else
        path = File.expand_path(url, File.dirname(file))
      end
      add_error(file, url, "File not found") unless File.exists? path
    end

    def add_error(file, url, response)
      @errors[file] = {} if @errors[file].nil?
      @errors[file][url] = response
    end
  end
end
