require 'json'

class Course

	attr_accessor :book_name ,:author ,:publisher ,:publish_date ,:isbn ,:agent ,:price, :url
	def initialize(h)
		@attributes = [:book_name ,:author ,:publisher ,:publish_date ,:isbn ,:agent ,:price, :url]
    h.each {|k, v| send("#{k}=",v)}
	end

	def to_hash
		@data = Hash[ @attributes.map {|d| [d.to_s, self.instance_variable_get('@'+d.to_s)]} ]
	end

	def to_json
		JSON.pretty_generate @data
	end
end
