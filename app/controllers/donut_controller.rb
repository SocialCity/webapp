class DonutController < ApplicationController
	include ApplicationHelper
	def boro_devices
		gon.donut = true
		gon.boro_devices = true
		@boro = ""


		@input_boro = params[:code]
		@input_timestamp = params[:timestamp]

		@boro_code = ""
		@boro_name = ""

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

		#FIRST, we get timestamps
		#Get timestamp list
		req_params = {
			:method => "devicesForBorough",
			:borough_code => query_boro,
			:time => query_timestamp
			}
		request_data = URL_requester(BACKEND_URL, req_params)
		str = request_data.string[1, request_data.string.size-3].tr('\\', '')

		#Now structure this data
		parsed_devices = nil
		str.each_line do |response|
			parsed_devices = JSON.parse(response)
		end
		
		gon.vis_device_data = []
		parsed_devices['sources'].each do |source, value|
			gon.vis_device_data << {
				:device => source,
				:split => value
			}
		end
	end
end
