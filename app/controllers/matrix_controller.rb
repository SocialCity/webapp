class MatrixController < ApplicationController
	include ApplicationHelper
	def hashtag
		base_factor_url = "http://localhost:9113"
		max_ranks = 10

		#We should, technically, url encode/decode however 
		#We can assume that hashtags are safe
		#I'd never do this on a non-research system :P
		@input_hashtag = params[:tag]
		gon.matrix = true
		@hashtag = ""
		@hashtag_list = nil
		

		#First get the list of hashtags
		hashtag_req_params = {:method => "hashTagList"}
		hashtag_request_data = URL_requester(base_factor_url, hashtag_req_params)

		#Now structure this data
		parsed_hashtags = nil
		hashtag_request_data.each_line do |response|
			parsed_hashtags = JSON.parse(response)
		end
		@hashtag_list = parsed_hashtags

		query_hashtag = nil

		#Check the hashtag is valid here
		if parsed_hashtags.include?(@input_hashtag) then
			query_hashtag = @input_hashtag
		else
			query_hashtag = parsed_hashtags[0]
		end

		#Get data for the chosen hashtag
		req_params = { :method => "hashtagWords",
						:word_code_num => 0,
						:tag => query_hashtag}
		request_data = URL_requester(base_factor_url, req_params)

		#Now structure this data
		parsed_data = nil
		request_data.each_line do |response|
			parsed_data = JSON.parse(response)
		end

		#Arrange into expected format
		associated_words = Array.new
		parsed_data.each do | cat, word_data |
			if cat == "locations" then
				@hashtag = word_data
			else
				word_data.each do | word |
					word_data_hash = {
						:word => word['word'],
						:type => cat,
						:activ => word['activation'].to_f.round(3),
						:pleas => word['pleasantness'].to_f.round(3),
						:image => word['imagery'].to_f.round(3),
						:freq  => word['frequency']
					}
					associated_words << word_data_hash
				end
				#word_data[:type] = cat
			end	
		end
		gon.word_data = associated_words
		# gon.feature_groups = Hash.new
		# gon.feature_groups[:boroughs] = map_feature_collater(true, 1, request_data)
	end

end
