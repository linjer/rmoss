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
require 'open-uri'

#
#
#
class MossRuby
	attr_accessor   :userid
	attr_accessor   :server
	attr_accessor   :port
	attr_reader     :options

	def self.empty_file_hash
		{ base_files: Array.new, files: Array.new }
	end

	def self.add_base_file ( hash, file )
		hash[:base_files] << file
		hash
	end

	def self.add_file ( hash, file )
		hash[:files] << file
		hash
	end

	def initialize(userid, server = "moss.stanford.edu", port = 7690)
		@options = {
			max_matches:            10,
			directory_submission:   false,
			show_num_matches:       250,
			experimental_server:    false,
			comment:                "",
			language:               "c"
		}
		@server = server
		@port = port
		@userid = userid
	end

	def upload_file (moss_server, file, id = 0)
		filename = file.strip.tap do |name|
			name.gsub! /[^\w\-\/.]/, '_'
		end

		content = IO.read(filename)
		size = content.length

		moss_server.write "file #{id} #{@options[:language]} #{size} #{file}\n"
		moss_server.write content
	end

	def check(files_dict)
		# Chech that the files_dict contains valid filenames
		files_dict[:base_files].each do |file_search|
			if Dir[file_search].length == 0
				raise "Unable to locate base file(s) matching #{file_search}"
			end
		end

		if files_dict[:files].length == 0
			return
		end

		files_dict[:files].each do |file_search|
			if Dir[file_search].length == 0
				raise "Unable to locate base file(s) matching #{file_search}"
			end
		end

		# Connect to the server
		moss_server = TCPSocket.new @server, @port
		begin
			# Send header details
			moss_server.write "moss #{@userid}\n"
			moss_server.write "directory #{@options[:directory_submission] ? 1 : 0 }\n"
			moss_server.write "X #{@options[:experimental_server] ? 1 : 0}\n"
			moss_server.write "maxmatches #{@options[:max_matches]}\n"
			moss_server.write "show #{@options[:show_num_matches]}\n"

			# Send language option
			moss_server.write "language #{@options[:language]}\n"

			line = moss_server.gets
			if line.strip() != "yes"
				moss_server.write "end\n"
				raise "Invalid language option."
			end

			files_dict[:base_files].each do |file_search|
				Dir[file_search].each do |file|
					upload_file moss_server, file
				end
			end

			idx = 1
			files_dict[:files].each do |file_search|
				Dir[file_search].each do |file|
					upload_file moss_server, file, idx
					idx += 1
				end
			end

			moss_server.write "query 0 #{@options[:comment]}\n"

			result = moss_server.gets

			moss_server.write "end\n"
			return result
		ensure
			moss_server.close
		end
	end

	def extract_results(uri)
		result = Array.new
		begin
			match = 0
			match_file = Array.new
			data = Array.new
			while true
				# read the two match files
				match_top = open("#{uri}/match#{match}-top.html").read
				match_file[0] = open("#{uri}/match#{match}-0.html").read
				match_file[1] = open("#{uri}/match#{match}-1.html").read

				data[0] = read_data match_file[0]
				data[1] = read_data match_file[1]
				top = read_pcts match_top

				result << { 
					files: 	[ data[0][:filename], data[1][:filename] ], 
					html:  	[ "<PRE>#{data[0][:html]}</PRE>", "<PRE>#{data[0][:html]}</PRE>" ],
					pct:  	[ top[:pct0], top[:pct1] ]
				}

				match += 1
			end
		rescue OpenURI::HTTPError
		end

		result
	end

	private

	def read_data(match_file)
		regex = /<HR>\s+(?<filename>\S+)<p><PRE>\n(?<html>.*)<\/PRE>\n<\/PRE>\n<\/BODY>\n<\/HTML>/xm
		match_file.match(regex)
	end

	def read_pcts(top_file)
		regex = /<TH>(?<filename0>\S+)\s\((?<pct0>\d+)%\).*<TH>(?<filename1>\S+)\s\((?<pct1>\d+)%\)/xm
		top_file.match(regex)
	end
end