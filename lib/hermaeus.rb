require "hermaeus/config"
require "hermaeus/error"
require "hermaeus/version"

# Public: Root module for Hermaeus.
module Hermaeus
	# Public: Initializes Hermaeus for use.
	#
	# Raises a ConfigurationError if Hermaeus’ config file does not exist, and
	# creates a sample configuration file for modification.
	def self.init
		FileUtils.mkdir_p(Config::DIR)
		if File.exist? Config::FILE
			@cfg = Config.load
			Config.validate @cfg
		else
			File.open Config::FILE, "w+" do |file|
				File.open File.expand_path Config::SOURCE, "r", "0600" do |cfg|
					file << cfg.read
				end
			end
			raise ConfigurationError.new <<-EOS
You must put your reddit credentials in #{File.join Config::DIR,"config.toml"} \
for Hermaeus to function.
			EOS
		end
	end
end
