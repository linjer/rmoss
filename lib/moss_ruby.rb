# The MIT License (MIT)
#
# Copyright (c) 2014 Andrew Cain
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'socket'

#
#
#
class MossRuby

	def initialize(userid, server = "moss.stanford.edu", port = 7690)
		@options = {
			max_times: { key: "m", value: 10 },
			directory_submission: { key: "d", value: false },
			show_num_matches: { key: "n", value: 250 },
			experimental_server: { key: "x", value: false },
			comment: { key: "c", value:"" },
			language: { key: "l", value:"c" }
		}
		@server = server
		@port = port
		@userid = userid
	end

	def check(files_dict)
		# Connect to the server
		moss_server = TCPSocket.new @server, @port
		begin
			# Send header details
			moss_server.puts "moss #{@userid}\n"
			moss_server.puts "directory #{@options[:directory_submission][:value] ? 1 : 0 }\n"
			moss_server.puts "X #{@options[:experimental_server][:value] ? 1 : 0}\n"
			moss_server.puts "maxmatches #{@options[:max_times][:value]}\n"
			moss_server.puts "show #{@options[:show_num_matches][:value]}\n"

			# Send language option
			moss_server.puts "language #{@options[:language][:value]}\n"

			line = moss_server.gets
			if line.strip() != "yes"
				raise "Invalid language option."
			end

			moss_server.puts "end\n"
		ensure
			moss_server.close
		end
	end
end