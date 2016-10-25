module Hermaeus
	# Public: Describes an error with the configuration file.
	class ConfigurationError < Exception
		# Public: Describes a configuraton error with a given message.
		#
		# message - an optional String describing what went wrong. Default value is
		# "Hermaeus is incorrectly configured."
		def initialize message
			@message = message || "Hermaeus is incorrectly configured."
		end

		# Public: Serializes the error to a String.
		#
		# Returns a String representing the error.
		def to_s
			"\n" + @message
		end
	end
end
