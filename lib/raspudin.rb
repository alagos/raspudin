require 'rest_client'
require 'nokogiri'
require 'settingslogic'
require 'raspudin/dbconn'
require 'raspudin/proxymanager'
require 'raspudin/settings'
require 'raspudin/version'

module Raspudin

	def self.start
    pm = ProxyManager.new(Settings.proxies)
    db = DbConn.new
    max = Settings.scrap_param_max_value
    min = db.last_param_value + 1

    (min..max).each do |num|
      proxy = pm.random_proxy.address
      p "---PROXY: #{proxy}"
      RestClient.proxy = proxy
      url = Settings.scrap_url + '?' + Settings.scrap_param + '=' + num.to_s
      begin
        p "url: #{url}"
        resp = RestClient.get(url)
        doc = Nokogiri::HTML(resp.body)
        Settings.scrap_xpaths.each do |xpath|
          scrap = doc.xpath(xpath)
          db.record_data(scrap.last.content, proxy, num) if scrap.any?
        end
      rescue Exception => e
        p "excepcion: #{e.message}\n#{e.backtrace.join("\n\t")}"
        db.record_error(proxy, num, "#{e.message}\n#{e.backtrace.join("\n\t")}")
      end
    end
	end
end
