
class Rubyist
  attr_accessor :error # XXX
  attr_reader :image_url, :name, :title, :bio, :taken_by, :top, :left
  def initialize
    @error = false
  end

  def data=(data)
    @data = data

    @image_url = data['url']
    @name = data['name']
    @title = data['title']
    @bio = data['bio']
    @taken_by = data['taken_by']

    tokei = data['tokei']
    if tokei.kind_of? Hash
      # XXX: rubykaigi2013_indirect.yaml
      # XXX raise error: rubytaiwan.yaml
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
  DATA_API_ENDPOINT = "https://raw.github.com/darashi/rubyistokei/master/data/"

  class << self
    def load(&block)
      manager = self.new
      BW::HTTP.get(API_ENDPOINT) do |response|
        if response.ok?
          begin
            manager.data = BW::JSON.parse(response.body.to_s)
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

  def endpoint(name)
    "#{DATA_API_ENDPOINT}#{name}.yaml"
  end

  def next_rubyist(&block)
    member = @queue.pop || set_queue.pop
    puts "next_rubyist: #{member['name']}"

    BW::HTTP.get("#{DATA_API_ENDPOINT}#{member['name']}") do |response|
      rubyist = Rubyist.new
      if response.ok?
        begin
          rubyist.data = YAML.load(response.body.to_s)
        rescue Exception => e
          p "yaml error:  #{response.body} - #{e}"
          rubyist.error = "yaml error #{response.body}"
        end
      else
        p "response error #{response.error}"
        rubyist.error = 'response error'
      end
      block.call rubyist
    end
  end

  def data=(data)
    @data = data
    set_queue
    data
  end

  def set_queue
    @queue = @data.shuffle
  end
end

