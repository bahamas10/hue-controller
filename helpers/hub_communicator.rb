require "net/http"
class HubCommunicator
  attr_writer :config

  def initialize(config=nil)
    @config = config
  end

  def apply_initial_effect(effect)
    data = {:on => true}
    data.merge!(effect[:start_color])

    states = []
    effect[:lights].each {|l| states.push(data.merge(:light => l))}
    effect[:groups].each {|g| states.push(data.merge(:group => g))}

    # Figure out which colors start on the end color.
    # this is a bit more generic than it needs to be so we can
    # add extra modes such as randomization later if we wanted, rather than straight alternating.
    if effect[:alternate]
      effect = effect.dup
      effect[:initial_state] = []

      id = 0
      states.each do |state|
        id += 1
        if (id % 2) == 0
          state.merge!(effect[:end_color])
          if state[:group]
            effect[:initial_state].push([:groups, state[:group], :end])
          else
            effect[:initial_state].push([:lights, state[:light], :end])
          end
        end
      end

      puts states.to_yaml
    end

    self.apply_states(states)
    effect
  end

  def apply_states(states)
    states.each do |state|
      self.state_request(state)
    end
  end

  def state_request(data)
    if data[:light]
      path = "lights/#{data.delete(:light)}/state"
    else
      path = "groups/#{data.delete(:group)}/action"
    end

    self.request(:put, path, data)
  end

  def request(type, path, data=nil)
    http = Net::HTTP.new(@config[:ip], 80)
    if data
      http.send("request_#{type}", "/api/#{@config[:apikey]}/#{path}", data.to_json)
    else
      http.send("request_#{type}", "/api/#{@config[:apikey]}/#{path}")
    end
  end
end