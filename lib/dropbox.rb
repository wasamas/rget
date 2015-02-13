require "dropbox-api"
require "dropbox-api/tasks"
require 'pit'

module DropboxAuth
	def self.client
		token = Pit::get('rget-dropbox')
		unless token[:api_key]
			print "Enter dropbox app key: "
			token[:api_key] = $stdin.gets.chomp
			print "Enter dropbox app secret: "
			token[:api_secret] = $stdin.gets.chomp
			Pit::set('rget-dropbox', data: token)
		end
		Dropbox::API::Config.app_key    = token[:api_key]
		Dropbox::API::Config.app_secret = token[:api_secret]
		Dropbox::API::Config.mode       = 'dropbox'

		unless token[:access_token]
			consumer = Dropbox::API::OAuth.consumer(:authorize)
			request_token = consumer.get_request_token
			puts "\nGo to this url and click 'Authorize' to get the token:"
			puts request_token.authorize_url
			query = request_token.authorize_url.split('?').last
			verifier, = CGI.parse(query)['oauth_token']
			print "\nOnce you authorize the app on Dropbox, press enter... "
			$stdin.gets
			access_token = request_token.get_access_token(oauth_verifier: verifier)
			token[:access_token]  = access_token.token
			token[:access_secret] = access_token.secret
			Pit::set('rget-dropbox', data: token)
		end

		Dropbox::API::Client.new(token: token[:access_token], secret: token[:access_secret])
	end
end
