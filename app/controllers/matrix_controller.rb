class MatrixController < ApplicationController
	include ApplicationHelper
	def hashtag
		base_factor_url = "http://localhost:9113"
		max_ranks = 10

		#We should, technically, url encode/decode however 
		#We can assume that hashtags are safe
		#I'd never do this on a non-research system :P
		@input_hashtag = params[:tag]
		@input_timestamp = params[:timestamp]
		@input_scale = params[:full_scale]
		gon.matrix = true
		gon.word_assoc = true

		@hashtag = ""
		@hashtag_list = nil
		@timestamp = nil

		gon.full_scale = false
		@full_scale = false

		if @input_scale == 'true' then
			gon.full_scale = true
			@full_scale = true
		end

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
						:tag => query_hashtag,
						:time => query_timestamp}
		request_data = URL_requester(BACKEND_URL, req_params)

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

	def area
		base_factor_url = "http://localhost:9113"
		max_ranks = 10

		#We should, technically, url encode/decode however 
		#We can assume that hashtags are safe
		#I'd never do this on a non-research system :P
		@input_boro = params[:code]
		@input_timestamp = params[:timestamp]
		@input_scale = params[:full_scale]
		gon.matrix = true
		gon.word_assoc = true
		@boro_code = ""
		@boro_name = ""

		@timestamp = nil

		gon.full_scale = false
		@full_scale = false

		if @input_scale == 'true' then
			gon.full_scale = true
			@full_scale = true
		end

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
		

		#==========================================
		#Now handle boros
		@boro_list = load_boros()

	 	query_boro = nil
	 	boro_check = false
		#Check the boro is valid here
		@boro_list.each do | boro |
			puts boro
			if boro['code'] == @input_boro then
				boro_check = true
				@boro_name = boro['name']
			end
		end
		if boro_check then
			query_boro = @input_boro
		else
			query_boro = @boro_list[0]['code']
			@boro_name = @boro_list[0]['name']
		end


		#Get data for the chosen hashtag
		req_params = { :method => "areaWords",
						:word_code_num => 0,
						:borough_code => query_boro,
						:time => query_timestamp}
		request_data = URL_requester(BACKEND_URL, req_params)

		#Now structure this data
		parsed_data = nil
		request_data.each_line do |response|
			parsed_data = JSON.parse(response)
		end

		#Arrange into expected format
		associated_words = Array.new
		parsed_data.each do | cat, word_data |
			if cat == "locations" then
				@boro_code = word_data
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
	 end

	 def device
	 	base_factor_url = "http://localhost:9113"
		max_ranks = 10

		#We should, technically, url encode/decode however 
		#We can assume that hashtags are safe
		#I'd never do this on a non-research system :P
		@input_device = params[:device]
		@input_timestamp = params[:timestamp]
		@input_scale = params[:full_scale]

		gon.matrix = true
		gon.word_assoc = true
		@device = ""
		@device_list = nil
		@timestamp = nil

		gon.full_scale = false
		@full_scale = false

		if @input_scale == 'true' then
			gon.full_scale = true
			@full_scale = true
		end

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
		

		#==========================================
		#Now get the list of hashtags
		device_req_params = {
			:method => "deviceList",
			:time => query_timestamp
			}
		device_request_data = URL_requester(BACKEND_URL, device_req_params)

		#Now structure this data
		parsed_devices = nil
		device_request_data.each_line do |response|
			parsed_devices = JSON.parse(response)
		end
		@device_list = parsed_devices

		query_device = nil

		#Check the hashtag is valid here
		if parsed_devices.include?(@input_device) then
			query_device = @input_device
		else
			query_device = parsed_devices[0]
		end

		#Get data for the chosen hashtag
		req_params = { :method => "deviceWords",
						:word_code_num => 0,
						:device => query_device,
						:time => query_timestamp}
		request_data = URL_requester(BACKEND_URL, req_params)

		#Now structure this data
		parsed_data = nil
		request_data.each_line do |response|
			parsed_data = JSON.parse(response)
		end

		#Arrange into expected format
		associated_words = Array.new
		parsed_data.each do | cat, word_data |
			if cat == "locations" then
				@device = word_data
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
	 end

	def aggr_hashtag
		base_factor_url = "http://localhost:9113"
		max_ranks = 10

		#We should, technically, url encode/decode however 
		#We can assume that hashtags are safe
		#I'd never do this on a non-research system :P
		@input_hashtag = params[:tag]
		@input_timestamp = params[:timestamp]
		gon.matrix = true
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

		#Arrange into expected format
		associated_words = Array.new
		parsed_data.each do | word |
			puts word
			word_data_hash = {
				:word => word['code'],
				:activ => word['activation'].to_f.round(3),
				:pleas => word['pleasantness'].to_f.round(3),
				:image => word['imagery'].to_f.round(3),
			}
			associated_words << word_data_hash
		end
		gon.word_data = associated_words
		# gon.feature_groups = Hash.new
		# gon.feature_groups[:boroughs] = map_feature_collater(true, 1, request_data)
	end

end
