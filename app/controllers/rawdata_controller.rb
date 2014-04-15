class RawdataController < ApplicationController
	include ApplicationHelper

	def area_factors
		input_year = params[:year]

		gon.rawdata = true

		@primary_factor = 0
		@year = 2012

		#, grab the factor information
		
		factor_info_params = { :method => "factorList"}
		@factor_info = parse_factor_list(URL_requester(BACKEND_URL, factor_info_params))


		if [2008, 2009, 2010, 2011, 2012].include?(input_year.to_i)
			@year = input_year.to_i
		else
			@year = 2012
		end


		boro_req_params = { :method => "oneFactor",
						:factor_number => 1,
						:get_wards => false,
						:combine => false,
						:get_all_factors => true,
						:year => @year}
		# ward_req_params = { :method => "oneFactor",
		# 				:factor_number => @primary_factor,
		# 				:get_wards => true,
		# 				:combine => true,
		# 				:get_all_factors => true}

		#--------------------------------------------------
		#          		BOROUGH DATA COLLATION
		#--------------------------------------------------

		boro_request_data = URL_requester(BACKEND_URL, boro_req_params)

		@boroughs = map_feature_collater(true, @primary_factor, boro_request_data)
		boro_list = load_boros()

		@boroughs.each do |boro|
			boro_list.each do |bl|
				if bl['code'] == boro['locations'][0]
					boro['name'] = bl['name']
				end
			end
		end
	end

	def device_factors
		base_factor_url = "http://localhost:9113"
		max_ranks = 10
		gon.rawdata = true
		#We should, technically, url encode/decode however 
		#We can assume that hashtags are safe
		#I'd never do this on a non-research system :P
		@input_timestamp = params[:timestamp]

		@timestamp = nil

		factor_info_params = { :method => "factorList"}
		@factor_info = parse_factor_list(URL_requester(BACKEND_URL, factor_info_params))


		#FIRST, we get timestamps
		#Get timestamp list
		verif_timestamp = check_timestamp_input(@input_timestamp, BACKEND_URL)
		@timestamp = verif_timestamp[:timestamp]
		@timestamp_list = verif_timestamp[:timestamp_list]
		query_timestamp = @timestamp[:url]

		#===================================
		
		#Then get the list of hashtags
		@device_list = get_device_list(query_timestamp, BACKEND_URL)

		parsed_data = Array.new
		@device_list.each do | query_device |
			#Get data for the chosen hashtag
			req_params = { :method => "deviceFactor",
							:device => query_device,
							:time => query_timestamp}
			request_data = URL_requester(BACKEND_URL, req_params)
			str = request_data.string[1, request_data.string.size-3].tr('\\', '')

			#We have to trim the newline off the end
			if '<h1>404 - There is nothing for you here</h1>' == request_data.string[0..-2] then
				puts "HERE"
			else
				str.each_line do |response|
					parsed_data << JSON.parse(response)
				end
			end
		end
		@device_data = non_map_collator(parsed_data, true)

	end

	def hashtag_factors
		base_factor_url = "http://localhost:9113"
		max_ranks = 10
		gon.rawdata = true
		#We should, technically, url encode/decode however 
		#We can assume that hashtags are safe
		#I'd never do this on a non-research system :P
		@input_timestamp = params[:timestamp]

		@timestamp = nil

		factor_info_params = { :method => "factorList"}
		@factor_info = parse_factor_list(URL_requester(BACKEND_URL, factor_info_params))


		#FIRST, we get timestamps
		#Get timestamp list
		verif_timestamp = check_timestamp_input(@input_timestamp, BACKEND_URL)
		@timestamp = verif_timestamp[:timestamp]
		@timestamp_list = verif_timestamp[:timestamp_list]
		query_timestamp = @timestamp[:url]

		#===================================
		
		#Then get the list of hashtags
		@hashtag_list = get_hashtag_list(query_timestamp, BACKEND_URL)
		puts @hashtag_list
		parsed_data = Array.new
		@hashtag_list.each do | query_tag |
			#Get data for the chosen hashtag
			req_params = { :method => "hashTagFactors",
							:tag_1 => query_tag,
							:time => query_timestamp}
			request_data = URL_requester(BACKEND_URL, req_params)

			str = request_data.string[1, request_data.string.size-3].tr('\\', '')

			#We have to trim the newline off the end
			if '<h1>404 - There is nothing for you here</h1>' == request_data.string[0..-2] then
				puts "HERE"
			else
				str.each_line do |response|
					parsed_data << JSON.parse(response)
				end
			end
		end
		@hashtag_data = non_map_collator(parsed_data, false)

	end

	def area_sentiment
		base_factor_url = "http://localhost:9113"
		max_ranks = 10

		#We should, technically, url encode/decode however 
		#We can assume that hashtags are safe
		#I'd never do this on a non-research system :P
		@input_timestamp = params[:timestamp]
		gon.rawdata = true
		@hashtag = ""
		@hashtag_list = nil
		@timestamp = nil

		
		@input_scale = params[:full_scale]

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
		full_boro_list = load_boros()
		boro_codes = Hash.new
		full_boro_list.each do |boro|
			boro_codes[boro['code']] = boro['name']
		end

		puts boro_codes
		parsed_data = Array.new
		boro_codes.each do | code, name |
			#Get data for the chosen hashtag
			req_params = { :method => "areaSentiment",
							:borough_code => code,
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

		puts parsed_data


		#WHERE IS THE FREQUENCY?

		#Arrange into expected format
		associated_words = Array.new
		parsed_data.each do | boro |
			puts boro
			word_data_hash = {
				:word => boro_codes[boro['code']],
				:activ => boro['activation'].to_f.round(3),
				:pleas => boro['pleasantness'].to_f.round(3),
				:image => boro['imagery'].to_f.round(3),
				:freq => boro['frequency']
			}
			associated_words << word_data_hash
		end
		@word_data = associated_words
	end

	def device_sentiment
				base_factor_url = "http://localhost:9113"
		max_ranks = 10

		#We should, technically, url encode/decode however 
		#We can assume that hashtags are safe
		#I'd never do this on a non-research system :P

		@input_timestamp = params[:timestamp]
		gon.rawdata = true

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
		device_req_params = {
			:method => "deviceList",
			:time 	=> query_timestamp
		}
		device_request_data = URL_requester(BACKEND_URL, device_req_params)

		#Now structure this data
		parsed_devices = nil
		device_request_data.each_line do |response|
			parsed_devices = JSON.parse(response)
		end
		@device_list = parsed_devices


		parsed_data = Array.new
		@device_list.each do | query_device |
			#Get data for the chosen hashtag
			req_params = { :method => "deviceSentiment",
							:device => query_device,
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
		@word_data = associated_words
	end

	def hashtag_sentiment
				base_factor_url = "http://localhost:9113"
		max_ranks = 10

		#We should, technically, url encode/decode however 
		#We can assume that hashtags are safe
		#I'd never do this on a non-research system :P
		@input_timestamp = params[:timestamp]
		gon.rawdata = true
		@hashtag = ""
		@hashtag_list = nil
		@timestamp = nil

		#FIRST, we get timestamps
		#Get timestamp list
		verif_timestamp = check_timestamp_input(@input_timestamp, BACKEND_URL)
		@timestamp = verif_timestamp[:timestamp]
		@timestamp_list = verif_timestamp[:timestamp_list]
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
				:freq => word['frequency'].to_f.round(3)
			}
			associated_words << word_data_hash
		end
		@word_data = associated_words
	end

	def device_assoc
		base_factor_url = "http://localhost:9113"
		max_ranks = 10

		#We should, technically, url encode/decode however 
		#We can assume that hashtags are safe
		#I'd never do this on a non-research system :P
		@input_device = params[:device]
		@input_timestamp = params[:timestamp]


		gon.rawdata = true

		@device = ""
		@device_list = nil
		@timestamp = nil

		verif_timestamp = check_timestamp_input(@input_timestamp, BACKEND_URL)
		@timestamp = verif_timestamp[:timestamp]
		@timestamp_list = verif_timestamp[:timestamp_list]
		query_timestamp = @timestamp[:url]

		#==========================================

		verif_device = check_device_input(@input_device, query_timestamp, BACKEND_URL)
		query_device = verif_device[:device]
		@device_list = verif_device[:device_list]

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
		@word_data = associated_words
	end

	def area_assoc
		base_factor_url = "http://localhost:9113"
		max_ranks = 10

		#We should, technically, url encode/decode however 
		#We can assume that hashtags are safe
		#I'd never do this on a non-research system :P
		@input_boro = params[:code]
		@input_timestamp = params[:timestamp]

		gon.rawdata = true
		@boro_code = ""
		@boro_name = ""

		@timestamp = nil


		verif_timestamp = check_timestamp_input(@input_timestamp, BACKEND_URL)
		@timestamp = verif_timestamp[:timestamp]
		@timestamp_list = verif_timestamp[:timestamp_list]
		query_timestamp = @timestamp[:url]
		

		#==========================================
		verif_boro = check_boro_input(@input_boro, BACKEND_URL)
		@boro_list = verif_boro[:boro_list]
		query_boro = verif_boro[:boro]
		@boro_name = verif_boro[:boro_name]


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
		@word_data = associated_words
	end

	def hashtag_assoc
		base_factor_url = "http://localhost:9113"
		max_ranks = 10

		#We should, technically, url encode/decode however 
		#We can assume that hashtags are safe
		#I'd never do this on a non-research system :P
		@input_hashtag = params[:tag]
		@input_timestamp = params[:timestamp]

		gon.rawdata = true

		@hashtag = ""
		@hashtag_list = nil
		@timestamp = nil

		verif_timestamp = check_timestamp_input(@input_timestamp, BACKEND_URL)
		@timestamp = verif_timestamp[:timestamp]
		@timestamp_list = verif_timestamp[:timestamp_list]
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
		@word_data = associated_words
	end


end
