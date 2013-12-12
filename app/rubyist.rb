
class Rubyist
  DATA_API_ENDPOINT = "https://raw.github.com/darashi/rubyistokei/master/data/"
  class << self
    def load_by_name(name, &block)
      BW::HTTP.get("#{DATA_API_ENDPOINT}#{name}") do |response|
        error = false
        if response.ok?
          begin
            rubyist = Rubyist.new YAML.load(response.body.to_s)
          rescue Exception => e
            puts "rubyist load error:  #{name} - #{e}"
            puts response.body
            error = true
          end
        else
          puts 'rubyist load response error..'
          error = true
        end

        if error
          block.call :error
        else
          block.call rubyist
        end
      end
    end
  end

  attr_reader :image_url, :name, :title, :bio, :taken_by, :top, :left, :color
  def initialize(data)
    self.data = data
  end

  def data=(data)
    @image_url = data['url']
    @name = data['name']
    @title = data['title']
    @bio = data['bio']
    @taken_by = data['taken_by']

    tokei = data['tokei']
    if tokei.kind_of? Hash
      # XXX: rubykaigi2013_indirect.yaml
      # XXX raise error: rubytaiwan.yaml
      # XXX: rubyist load error:  josevalim.yaml - undefined method `[]' for nil:NilClass
      # ToDo: https://raw.github.com/darashi/rubyistokei/master/data/josevalim.yaml
      @top = [tokei['top'].to_i, 0].max
      @left = [tokei['left'].to_i, 0].max
      @color = tokei['color']
      @font = tokei['font']
    end

    data
  end
end

class RubyistManager
  API_ENDPOINT = "https://api.github.com/repos/darashi/rubyistokei/contents/data"
  attr_accessor :error

  class << self
    def load(&block)
      manager = self.new
      BW::HTTP.get(API_ENDPOINT) do |response|
        if response.ok?
          begin
            BW::JSON.parse(response.body.to_s).each do |h|
              manager.rubyists[h['name']] = nil
            end
            manager.orderd!
          rescue Exception => e
            log_p "json error:  #{response.body} - #{e}"
            manager.error = "json error #{response.body}"
          end
        else
          log_p "response error #{response.error}"
          manager.error = 'response error'
        end
        block.call manager
      end
      manager
    end
  end

  attr_reader :rubyists
  def initialize
    @rubyists = {}
    @rubyist_cache = {}
    @ordered_rubyist_names = []
    @index = 0
  end

  def next_rubyist(&block)
    name = next_rubyist_name
    log "next_rubyist_load: #{name}"

    if rubyists[name]
      block.call rubyists[name]
      return
    end

    Rubyist.load_by_name(name) do |rubyist|
      if rubyist == :error
        rubyists.delete(name)
        log "rubylist load error: #{name} - call next_rubyist"
        next_rubyist(&block)
      else
        rubyists[name] = rubyist
        block.call rubyist
      end
    end
  end

  def next_rubyist_name
    name = @ordered_rubyist_names[@index]
    @index += 1
    if @index > @ordered_rubyist_names.size
      @index = 0
    end
    name
  end

  def orderd!
    # XXX: shohei_urabe 's tokei layout
    # XXX: stolt45.yaml layout
    # XXX: The regend
    @ordered_rubyist_names = ['legends.yaml'] + @rubyists.keys.shuffle
    #@ordered_rubyist_names = @rubyists.keys.shuffle
  end
end

