require 'rest_client'

class ProxyManager

  class Proxy
    attr_reader   :address, :alive
    attr_accessor :last_used

    def initialize(address, last_used=nil)
      @address    = address
      @last_used  = last_used
      @alive      = nil
    end

    def used_since?(time)
      @last_used && @last_used > time
    end

    def to_s
      @address
    end

    def alive?
      if @alive == nil
        RestClient.proxy = @address
        begin
          @alive = @address.include? RestClient.get(Settings.ip_url).body
        rescue Exception => e
          puts "error para #{@address}: #{e}"
          @alive = false
        end
      end
      @alive
    end
  end

  def initialize(proxies, delay=10)
    raise ArgumentError, "Debe contener al menos un proxy" if proxies.empty?

    @addresses  = proxies.uniq
    @delay      = delay
    @proxies    = @addresses.map { |address| Proxy.new(address) }
  end

  def random_proxy
    temp_proxies = @proxies
    proxy = temp_proxies.delete_at(rand(temp_proxies.size))
    proxy = temp_proxies.delete_at(rand(temp_proxies.size)) until proxy.nil? || proxy.alive?
    proxy
  end

end
