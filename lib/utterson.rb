class Utterson

  def initialize(opts={})
    @dir = opts[:dir] || './'
  end

  def check()
    @uris = []
    Dir.glob(File.join(@dir, '**/*.{html,htm}')) do |f|
      @uris += collect_uris_from(f)
    end
  end

  def collect_uris_from(f)
  end


end
