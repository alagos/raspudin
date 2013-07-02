require 'nokogiri'
require 'rest_client'
require 'settingslogic'
require 'raspudin/dbconn'
require 'raspudin/settings'
require 'raspudin/version'

module Raspudin

  def self.start
    db = DbConn.new
    db.insert_new_proxies(Settings.proxies)
    max = Settings.scrap_param_max_value
    min = db.last_param_value + 1

    (min..max).each do |num|
      proxy = db.random_proxy
      p "-PROXY: #{proxy[:url]}"
      RestClient.proxy = proxy[:url]
      url = Settings.scrap_url + '?' + Settings.scrap_param + '=' + num.to_s
      begin
        p "---URL: #{url}"
        resp = RestClient.get(url)
        doc = Nokogiri::HTML(resp.body)
        db.ping_used_proxy(proxy)
        Settings.scrap_xpaths.each do |xpath|
          scrap = doc.xpath(xpath)
          db.record_data(scrap.last.content, proxy[:url], num) if scrap.any?
        end
      rescue Exception => e
        p "excepcion: #{e.message}\n#{e.backtrace.join("\n\t")}"
        db.record_error(proxy[:url], num, e.message)
      end
    end
  end
end
