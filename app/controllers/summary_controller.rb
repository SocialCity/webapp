class SummaryController < ApplicationController
	include ApplicationHelper


	def area
		gon.sentiment = true
		boro_code = "00AA"
		@input_boro = params[:borough]
		puts @input_boro
		boro_req_params = { :method => "oneFactor",
						:factor_number => 1,
						:get_wards => false,
						:combine => false,
						:get_all_factors => true,
						:year => 2012}


		#Sentiment data over the last 6 timestamps
		@timestamp_list = get_timestamp_list(BACKEND_URL)	
		factor_info_params = { :method => "factorList"}
		@factor_info = parse_factor_list(URL_requester(BACKEND_URL, factor_info_params))
		gon.factor_info = @factor_info

		#Check boros
		verif_boro = check_boro_input(@input_boro, BACKEND_URL)

		full_boro_list = verif_boro[:boro_list]
		query_boro = verif_boro[:boro]
		@boro_name = verif_boro[:boro_name]

		@boro_list = Hash.new
		full_boro_list.each do |boro|
			@boro_list[boro['code']] = boro['name']
		end
		#Gather boro data and label it
		boro_request_data = URL_requester(BACKEND_URL, boro_req_params)
		# ward_request_data = URL_requester(BACKEND_URL, ward_req_params)

		gon.feature_groups = Hash.new
		full_feature_list = map_feature_collater(true, @primary_factor, boro_request_data)
		full_feature_list.each do |feature|
			if feature['locations'][0] == query_boro
				gon.feature_groups[:borough] = feature
			end
		end




		sentiment_data = Array.new
		
		num_timestamps = 12
		if @timestamp_list.size < 12
			num_timestamps = @timestamp_list.size
		end
		puts "*"*100
		gon.num_timestamps = num_timestamps
		num_timestamps = -num_timestamps
		puts num_timestamps
		puts "*"*100
		@timestamp_list[-(num_timestamps-1)..-1].each do | time_window |
			puts "yis"
			req_params = {
				:method => "areaSentiment",
				:borough_code => query_boro,
				:time => time_window[:url]
			}
			request_data = URL_requester(BACKEND_URL, req_params)

			#We have to trim the newline off the end
			if '<h1>404 - There is nothing for you here</h1>' == request_data.string[0..-2] then
				puts "HERE"
			else
				request_data.each_line do |response|
					sentiment_data << JSON.parse(response)
				end
			end
		end
		output_senti_data = [
			{:type=>"activation",  :list => Array.new},
			{:type=>"imagery",  :list => Array.new},
			{:type=>"pleasantness",  :list => Array.new},
			{:type=>"frequency",  :list => Array.new}
		]
		sentiment_data.each do |row|
			output_senti_data[0][:list] << row['activation']
			output_senti_data[1][:list] << row['imagery']
			output_senti_data[2][:list] << row['pleasantness']
			output_senti_data[3][:list] << row['frequency']
		end
		gon.sentiment_data = output_senti_data

		#puts query_boro

		#--------------------------------------
		# Hashtags
		#--------------------------------------


		#Now we want to grab the hashtag data
		#We're going to do it for the past 24 hours by grabbing all of them and shoving them in one matrix

		#Then get the list of hashtags
		# @hashtag_list = Array.new
		parsed_data = Array.new
		@timestamp_list[-2..-1].each do |query_timestamp|
			hashtag_req_params = {
				:method => "hashTagList",
				:time 	=> query_timestamp[:url]
			}
			hashtag_request_data = URL_requester(BACKEND_URL, hashtag_req_params)

			#Now structure this data
			parsed_hashtags = nil
			hashtag_request_data.each_line do |response|
				parsed_hashtags = JSON.parse(response)
			end

			parsed_hashtags.each do | query_hashtag |
				#Get data for the chosen hashtag
				req_params = { :method => "hashtagSentiment",
								:tag => query_hashtag,
								:time => query_timestamp[:url]}
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
		end

		#Arrange into expected format
		dupe_list = Hash.new
		filtered_data = Array.new
		for i in 0...parsed_data.size
			for j in 0...parsed_data.size
				if parsed_data[i]['code'] == parsed_data[j]['code'] and i != j and !(dupe_list.key?(j)) 
					dupe_list[i] = j
				end
			end
		end

		for i in 0...parsed_data.size
			if dupe_list.key?(i)
				j = dupe_list[i]
				filtered_data << {
						:word => parsed_data[i]['code'],
						:freq => parsed_data[i]['frequency'].to_i + parsed_data[j]['frequency'].to_i
					}
			elsif !dupe_list.value?(i)
				filtered_data << {
						:word => parsed_data[i]['code'],
						:freq => parsed_data[i]['frequency'].to_i
					}
			end
		end
		gon.hashtag_data = filtered_data


		#--------------------------------------
		# Devices
		#--------------------------------------
		parsed_devices = Array.new
		@timestamp_list[-2..-1].each do |query_timestamp|
			device_req_params = {
				:method => "deviceList",
				:time 	=> query_timestamp[:url]
			}
			device_request_data = URL_requester(BACKEND_URL, device_req_params)

			#Now structure this data
			parsed_devices = nil
			device_request_data.each_line do |response|
				parsed_devices = JSON.parse(response)
			end

			parsed_devices.each do | query_device |
				#Get data for the chosen hashtag
				req_params = { :method => "deviceSentiment",
								:device => query_device,
								:time => query_timestamp[:url]}
				request_data = URL_requester(BACKEND_URL, req_params)

				#We have to trim the newline off the end
				if '<h1>404 - There is nothing for you here</h1>' == request_data.string[0..-2] then
					puts "HERE"
				else
					request_data.each_line do |response|
						parsed_devices << JSON.parse(response) 
					end
				end
			end
		end
		puts parsed_devices.to_s
		#Arrange into expected format
		dupe_devices = Hash.new
		filtered_devices = Array.new
		for i in 0...parsed_devices.size
			for j in 0...parsed_devices.size
				if parsed_devices[i]['code'] == parsed_devices[j]['code'] and i != j and !(dupe_devices.key?(j)) 
					dupe_devices[i] = j
				end
			end
		end

		for i in 0...parsed_devices.size
			if dupe_devices.key?(i)
				j = dupe_devices[i]
				dev = {
						:code => parsed_devices[i]['code'],
						:freq => parsed_devices[i]['frequency'].to_i + parsed_devices[j]['frequency'].to_i
					}
				if dev[:freq] > 100
					filtered_devices << dev
				end
			elsif !dupe_devices.value?(i)
				dev = {
						:code => parsed_devices[i]['code'],
						:freq => parsed_devices[i]['frequency'].to_i
					}
				if dev[:freq] > 100
					filtered_devices << dev
				end
			end
		end
		puts filtered_devices.size
		gon.device_data = filtered_devices
	end
end
