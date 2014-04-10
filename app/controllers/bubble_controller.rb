class BubbleController < ApplicationController
	include ApplicationHelper

	def hashtag
		base_factor_url = "http://localhost:9113"
		max_ranks = 10

		#We should, technically, url encode/decode however 
		#We can assume that hashtags are safe
		#I'd never do this on a non-research system :P
		@input_hashtag = params[:tag]
		@input_timestamp = params[:timestamp]
		gon.bubble = true
		gon.aggregation = true
		@hashtag = ""
		@hashtag_list = nil
		@timestamp = nil

		#FIRST, we get timestamps
		#Get timestamp list
		timestamp_req_params = {:method => "timestamps"}
		timestamp_request_data = URL_requester(BACKEND_URL, timestamp_req_params)

		#Now structure this data
		parsed_timestamps = nil
		timestamp_request_data.each_line do |response|
			parsed_timestamps = JSON.parse(response)
		end
		
		@timestamp_list = parse_server_timestamps(parsed_timestamps)
		
		ts_found = false
		@timestamp_list.each do | ts |
			if ts[:url] == @input_timestamp then
				ts_found = true
				@timestamp = ts
			end
		end

		if ts_found == false then
			#MAY NOT BE CORRECT
			@timestamp = @timestamp_list[-1]
		end

		query_timestamp = @timestamp[:url]

		#===================================
		
		#Then get the list of hashtags
		hashtag_req_params = {
			:method => "hashTagList",
			:time 	=> query_timestamp
		}
		hashtag_request_data = URL_requester(BACKEND_URL, hashtag_req_params)

		#Now structure this data
		parsed_hashtags = nil
		hashtag_request_data.each_line do |response|
			parsed_hashtags = JSON.parse(response)
		end
		@hashtag_list = parsed_hashtags


		parsed_data = Array.new
		@hashtag_list.each do | query_hashtag |
			#Get data for the chosen hashtag
			req_params = { :method => "hashtagSentiment",
							:tag => query_hashtag,
							:time => query_timestamp}
			request_data = URL_requester(BACKEND_URL, req_params)

			#We have to trim the newline off the end
			if '<h1>404 - There is nothing for you here</h1>' == request_data.string[0..-2] then
				puts "HERE"
			else
				request_data.each_line do |response|
					parsed_data << JSON.parse(response)
				end
			end
		end


		#WHERE IS THE FREQUENCY?

		#Arrange into expected format
		associated_words = Array.new
		parsed_data.each do | word |
			puts word
			word_data_hash = {
				:word => word['code'],
				:activ => word['activation'].to_f.round(3),
				:pleas => word['pleasantness'].to_f.round(3),
				:image => word['imagery'].to_f.round(3),
				:freq => word['frequency']
			}
			associated_words << word_data_hash
		end
		gon.word_data = associated_words
	end


end
