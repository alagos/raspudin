require "raspudin/version"
require 'rest_client'
require 'nokogiri'

module Raspudin

	def self.start
		# RestClient.proxy = 'http://115.85.73.92:8080'
	  resp = RestClient.get 'http://whatismyipaddress.com'
	  doc = Nokogiri::HTML(resp.body)
	  p '-----MI IP -------------------'
	  doc.xpath('//*[@id="wrap"]/div/table/tr/td[2]/div').each do |link|
	  	p link.xpath('//h2/span').children[2].content
		end

	end
end
