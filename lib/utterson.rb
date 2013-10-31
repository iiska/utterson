require 'nokogiri'

class Utterson

  def initialize(opts={})
    @dir = opts[:dir] || './'
  end

  def check()
    uris = []
    files = 0
    Dir.glob(File.join(@dir, '**/*.{html,htm}')) do |f|
      uris += collect_uris_from(f)
      files += 1
    end
    puts "Found #{uris.count} urls from #{files} HTML files..."
    uris.each do |u|
      check_uri(u)
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

  def check_uri(u)
    if u =~ /^(https?:)?\/\//
      check_remote_uri u
    else
      check_local_uri u
    end
  end

  def check_remote_uri(u)
  end

  def check_local_uri(u)
  end


end
