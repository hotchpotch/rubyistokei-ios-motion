
class Rubyist
  DATA_API_ENDPOINT = "https://raw.github.com/darashi/rubyistokei/master/data/"
  class << self
    def load_by_name(name, &block)
      BW::HTTP.get("#{DATA_API_ENDPOINT}#{name}") do |response|
        if response.ok?
          begin
            rubyist = Rubyist.new YAML.load(response.body.to_s)
          rescue Exception => e
            puts "rubyist load error:  #{name} - #{e}"
            puts response.body
            raise e
          end
          block.call rubyist
        else
          raise 'rubyist load response error..'
        end
      end
    end
  end

  attr_reader :image_url, :name, :title, :bio, :taken_by, :top, :left
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
            p "json error:  #{response.body} - #{e}"
            manager.error = "json error #{response.body}"
          end
        else
          p "response error #{response.error}"
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

  def next_rubyist_loaded(&block)
    name = next_rubyist_name
    puts "next_rubyist_load: #{name}"

    if rubyists[name]
      block.call rubyists[name]
      return
    end

    Rubyist.load_by_name(name) do |rubyist|
      rubyists[name] = rubyist
      block.call rubyist
    end
  end

  def next_rubyist_preload
    # XXX
    name = @ordered_rubyist_names[@index]
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
    @ordered_rubyist_names = @rubyists.keys.shuffle
  end
end

