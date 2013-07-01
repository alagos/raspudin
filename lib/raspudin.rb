require 'rest_client'
require 'nokogiri'
require 'settingslogic'
require 'raspudin/proxymanager'
require 'raspudin/settings'
require 'raspudin/version'

module Raspudin

	def self.start
    pm = ProxyManager.new(Settings.proxies)
    proxy = pm.random_proxy.address
    p "---PROXY: #{proxy}"
		RestClient.proxy = proxy
    params = ''
    params = '?' + Settings.scrap_param + '=' + (rand(20000) + 1000).to_s if Settings.scrap_param
    url = Settings.scrap_url + params
    begin
      p "url: #{url}"
      resp = RestClient.get(url)
      p resp.body
      doc = Nokogiri::HTML(resp.body)
      puts "-----ESCRAPEO ------"
      Settings.scrap_xpaths.each do |xpath|
        p "---- #{xpath}"
        scrap = doc.xpath(xpath)
        p scrap.last.content
      end
    rescue Exception => e
      puts e
    end
	end
end
