require "dropbox_api"
require 'pit'

module DropboxAuth
	def self.client
		token = Pit::get('rget-dropbox')
		unless token[:api_token]
			if token[:api_key]
				api_key = token[:api_key]
			else
				print "Enter dropbox app key: "
				api_key = $stdin.gets.chomp
			end

			if token[:api_secret]
				api_secret = token[:api_secret]
			else
				print "Enter dropbox app secret: "
				api_secret = $stdin.gets.chomp
			end

			authenticator = DropboxApi::Authenticator.new(api_key, api_secret)
			puts "\nGo to this url and click 'Authorize' to get the token:"
			puts authenticator.authorize_url

			token.clear # delete all old settings
			print "Enter the token: "
			code = $stdin.gets.chomp
			token[:api_token] = authenticator.get_token(code).token
			Pit::set('rget-dropbox', data: token)
		end
		DropboxApi::Client.new(token[:api_token])
	end

	def self.upload(client, dropbox_path)
		info = DropboxApi::Metadata::CommitInfo.new('path'=>dropbox_path, 'mode'=>:add)
		cursor = client.upload_session_start('')
		while data = yield
			client.upload_session_append_v2(cursor, data)
		end
		client.upload_session_finish(cursor, info)
	end
end

