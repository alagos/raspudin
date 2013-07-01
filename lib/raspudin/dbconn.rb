require 'sequel'

class DbConn
  
  def initialize(dbname = 'raspudin.sqlite3')
    # Open a database
    # @db = SQLite3::Database.new File.join(File.dirname(__FILE__), '../../db/' + dbname)
    @db = Sequel.connect('sqlite://' + File.join(File.dirname(__FILE__), '../../db/' + dbname))
    init_tables
  end

  def last_param_value
    param = @db[:others][key: 'last_param_value']
    param.nil? ? 0 : param[:value].to_i
  end

  def set_last_param_value(value)
    rec = @db[:others].where(key: 'last_param_value')
    @db[:others].insert(key: 'last_param_value', value: value) if rec.update(value: value) != 1
  end

  def record_data(data,ip,seq)
    @db[:records].insert(data: data, ip: ip, seq: seq)
    set_last_param_value(seq)
  end

  def record_error(ip,seq,error)
    @db[:records].insert(seq: seq, ip: ip, error: error)
    set_last_param_value(seq)
  end

  private

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
  end
end
