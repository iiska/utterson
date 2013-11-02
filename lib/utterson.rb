require 'nokogiri'

require 'net/http'

class Utterson
  attr_reader :errors

  def initialize(opts={})
    @dir = opts[:dir] || './'
    @errors = {}
    @stats = {errors: 0, files: 0, urls: 0}
  end

  def check
    Dir.glob(File.join(@dir, '**/*.{html,htm}')) do |f|
      @stats[:files] += 1
      collect_uris_from(f).each do |u|
        @stats[:urls] += 1
        check_uri(u, f)
      end
    end
    print_results
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
    if url =~ /^(https?:)?\/\//
      check_remote_uri url, file
    else
      check_local_uri url, file
    end
  end

  def check_remote_uri(url, file)
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      p = uri.path.empty? ? "/" : uri.path
      response = http.head(p)
      if response.code =~ /^[^23]/
        add_error(file, url, response)
      end
    end
  end

  def check_local_uri(url, file)
    path = File.expand_path(url, File.dirname(file))
    add_error(file, url, "File not found") unless File.exists? path
  end

  def add_error(file, url, response)
    @stats[:errors] += 1
    @errors[file] = {} if @errors[file].nil?
    @errors[file][url] = response
  end

  def print_results
    @errors.each do |file, info|
      puts file
      info.each do |url, response|
        puts "\t#{url}\n\t\t#{response}"
      end
    end
    puts "#{@stats[:files]} files with #{@stats[:urls]} urls checked."
  end

end
