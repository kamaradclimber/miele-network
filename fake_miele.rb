#!/usr/bin/env ruby

require 'sinatra'

get '/' do
  "This is a fake server for the MIELE washing machine. See https://github.com/kamaradclimber/miele-network"
end

get '/V2/NTP/' do
  content_type 'application/vnd.miele.v1+json;charset=UTF-8'
  {time: Time.now.to_i}.to_json
end
