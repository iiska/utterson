require 'nokogiri'

require 'net/http'
require 'timeout'

module Utterson
  class HtmlCheck
    attr_reader :errors

    def initialize(opts={})
      @file = opts[:file]
      @root = opts[:root]
      @errors = {}
      @checked_urls = {}
    end

    def when_done(&handler)
      @result_handler = handler
    end

    def run
      collect_uris_from(@file).each do |u|
        check_uri(u, @file)
      end
      unless @result_handler.nil?
        @result_handler.call({
          errors: @errors,
          urls: @checked_urls.count
        })
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
      return if @checked_urls[url]

      if url =~ /^(https?:)?\/\//
        check_remote_uri url, file
      else
        check_local_uri url, file
      end
      @checked_urls[url] = true
    end

    def check_remote_uri(url, file)
      begin
        uri = URI(url.gsub(/^\/\//, 'http://'))
      rescue URI::InvalidURIError => e
        return add_error(file, uri.to_s, e.message)
      end
      begin
        response = Net::HTTP.start(uri.host, uri.port,
                                   :use_ssl => uri.scheme == 'https') do |http|
          p = uri.path.empty? ? "/" : uri.path
          http.head(p)
        end
        if response.code =~ /^[^23]/
          add_error(file, uri.to_s, response)
        end
      rescue Timeout::Error
        add_error(file, uri.to_s, "Reading buffer timed out")
      rescue Errno::ETIMEDOUT
        add_error(file, uri.to_s, "Connection timed out")
      rescue Errno::EHOSTUNREACH
        add_error(file, uri.to_s, "No route to host")
      rescue SocketError => e
        add_error(file, uri.to_s, e.message)
      end
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
