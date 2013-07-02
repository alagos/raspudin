require 'rest_client'
require 'sequel'
require 'settingslogic'

class DbConn
  
  def initialize(dbname = 'raspudin.sqlite3')
    @db = Sequel.connect('sqlite://' + File.join(File.dirname(__FILE__), '../../db/' + dbname))
    init_tables
  end

  #### OTHERS ####
  def last_param_value
    param = @db[:others][key: 'last_param_value']
    param.nil? ? 0 : param[:value].to_i
  end

  def set_last_param_value(value)
    rec = @db[:others].where(key: 'last_param_value')
    @db[:others].insert(key: 'last_param_value', value: value) if rec.update(value: value) != 1
  end

  #### RECORDS ####
  def record_data(data,ip,seq)
    @db[:records].insert(data: data, ip: ip, seq: seq)
    set_last_param_value(seq)
  end

  def record_error(ip,seq,error)
    @db[:records].insert(seq: seq, ip: ip, error: error)
    set_last_param_value(seq)
  end

  #### PROXIES ####
  def all_proxies
    @db[:proxies].all
  end

  def all_alive_proxies
    @db[:proxies][alive: true]
  end

  def insert_new_proxies(tmp)
    diff = tmp - all_proxies.map { |e| e[:url] }
    diff.each do |prx|
      @db[:proxies].insert(url: prx)
    end if diff.any?
  end

  def ping_used_proxy(proxy)
    prx = @db[:proxies].where(id: proxy[:id])
    prx.update(last_used: Time.now, count_times_used: (prx.first[:count_times_used] || 0 ) + 1)
  end

  def random_proxy
    proxy = nil
    proxy = random_alive_proxy while proxy.nil? || !is_alive?(proxy)
    proxy
  end

  private

    def random_alive_proxy
      @db["SELECT * FROM proxies WHERE alive = 't' ORDER BY RANDOM() LIMIT 1;"].first
    end

    def is_alive?(proxy)
      if !proxy.nil? && proxy[:alive]
        RestClient.proxy = proxy[:url]
        begin
          body = RestClient.get(Settings.ip_url).body
          alive = proxy[:url].include? body
          set_dead(proxy, body) unless alive
          alive
        rescue Exception => e
          puts "error para #{proxy[:url]}: #{e.message}\n#{e.backtrace.join("\n\t")}"
          set_dead(proxy, e.message)
          false
        end
      end
    end

    def set_dead(proxy, error = nil)
      @db[:proxies].where(id: proxy[:id]).update(alive: false, error: error, last_used: Time.now)
    end

    def init_tables
      @db.create_table? :records do
        primary_key :id
        String :data, text: true
        String :ip
        Fixnum :seq
        String :error, text: true
      end
      
      @db.create_table? :others do
        primary_key :id
        String :key
        String :value
      end

      @db.create_table? :proxies do
        primary_key :id
        String :url
        DateTime :last_used
        Fixnum :count_times_used
        TrueClass :alive, default: true
        String :error, text: true
      end
    end

end
