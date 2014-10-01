require 'spec_helper'
 
describe MossRuby do

	before :each do
    	@moss = MossRuby.new "myid"
	end

	describe "#new" do
    	it "takes the id parameter and returns a MossRuby object" do
        	expect(@moss).to be_an_instance_of MossRuby
    	end

    	it "creates an object with default server path" do
    		expect(@moss.server).to eql "moss.stanford.edu" 
    	end

    	it "creates an object with default port" do
    		expect(@moss.port).to eql 7690 
    	end

    	it "creates an object with the passed in userid" do
    		expect(@moss.userid).to eql "myid" 
    	end

    	it "creates an object with default options" do
    		expect(@moss.options.has_key? :max_matches).to eql true
    		expect(@moss.options.has_key? :directory_submission).to eql true
    		expect(@moss.options.has_key? :show_num_matches).to eql true
    		expect(@moss.options.has_key? :experimental_server).to eql true
    		expect(@moss.options.has_key? :comment).to eql true
    		expect(@moss.options.has_key? :language).to eql true
    		expect(@moss.options.length).to eql 6
    	end
	end

	describe "#check" do

		before :each do
    		@server = double('server')
    		allow(TCPSocket).to receive(:new).and_return(@server)
		end

		def file_hash
			result = MossRuby.empty_file_hash
			test_dir = File.join(File.dirname(__FILE__), 'test_files')
			MossRuby.add_file(result, "#{test_dir}/*.c")
			result
		end

		it "opens a TCP connection to the server and asks to confirm language and get results" do
			expect(@server).to receive(:write).at_least(:once)
			expect(@server).to receive(:gets) { "yes" }
			expect(@server).to receive(:gets) { "http://moss.stanford.edu/results/706783168\n" }
			expect(@server).to receive(:close)
			
			@moss.check file_hash
		end

		it "raises an exception if the language is not known" do
			expect(@server).to receive(:write).at_least(:once)
			expect(@server).to receive(:gets) { "no" }
			expect(@server).to receive(:close)
			
			expect { @moss.check file_hash }.to raise_error("Invalid language option.")
		end

		it "sends requests to the server using the default options" do
			expect(@server).to receive(:write).with("moss myid\n")
			expect(@server).to receive(:write).with("directory 0\n")
			expect(@server).to receive(:write).with("X 0\n")
			expect(@server).to receive(:write).with("maxmatches 10\n")
			expect(@server).to receive(:write).with("show 250\n")
			expect(@server).to receive(:gets) { "yes" }
			expect(@server).to receive(:write).with("language c\n")
			expect(@server).to receive(:write).with("query 0 \n")
			expect(@server).to receive(:gets) { "http://moss.stanford.edu/results/706783168\n" }
			expect(@server).to receive(:write).with("end\n")
			expect(@server).to receive(:close)

			allow(@server).to receive(:write)

			@moss.check file_hash
		end

		it "sends requests to the server using supplied options" do
			@moss.userid = "fred"
			@moss.options[:directory_submission] = true
			@moss.options[:experimental_server] = true
			@moss.options[:max_matches] = 100
			@moss.options[:show_num_matches] = 85
			@moss.options[:language] = "python"
			@moss.options[:comment] = "Hello World"

			expect(@server).to receive(:write).with("moss fred\n")
			expect(@server).to receive(:write).with("directory 1\n")
			expect(@server).to receive(:write).with("X 1\n")
			expect(@server).to receive(:write).with("maxmatches 100\n")
			expect(@server).to receive(:write).with("show 85\n")
			expect(@server).to receive(:gets) { "yes" }
			expect(@server).to receive(:write).with("language python\n")
			expect(@server).to receive(:write).with("query 0 Hello World\n")
			expect(@server).to receive(:gets) { "http://moss.stanford.edu/results/706783168\n" }
			expect(@server).to receive(:write).with("end\n")
			expect(@server).to receive(:close)

			allow(@server).to receive(:write)

			@moss.check file_hash
		end

		RSpec::Matchers.define :a_file_like do |filename, lang|
  			match { |actual| /file [0-9]+ c [0-9]+ .*#{filename}\n/.match(actual) }
		end

		RSpec::Matchers.define :text_starting_with do |line|
  			match { |actual| actual.start_with? line }
		end

		RSpec::Matchers.define :text_matching_pattern do |pattern|
			match { |actual| (actual =~ pattern) == 0 }
		end

		it "sends files it is provided" do
			expect(@server).to receive(:write).with("moss myid\n")
			expect(@server).to receive(:write).with("directory 0\n")
			expect(@server).to receive(:write).with("X 0\n")
			expect(@server).to receive(:write).with("maxmatches 10\n")
			expect(@server).to receive(:write).with("show 250\n")
			expect(@server).to receive(:gets) { "yes" }
			expect(@server).to receive(:write).with("language c\n")
			expect(@server).to receive(:write).with("query 0 \n")
			expect(@server).to receive(:gets) { "http://moss.stanford.edu/results/706783168\n" }

			expect(@server).to receive(:write).with(a_file_like("hello.c", "c"))
			expect(@server).to receive(:write).with(text_starting_with("#include <stdio.h>\n\nint main()")).at_least(:once)

			expect(@server).to receive(:write).with(a_file_like("hello2.c", "c"))
			allow(@server).to receive(:write).with(text_matching_pattern( /file\s+\d\s+c\s+\d+\s+.*\/moss-ruby\/spec\/test_files\/.*\.c\n/))

			expect(@server).to receive(:write).with("end\n")
			expect(@server).to receive(:close)

			@moss.check file_hash
		end

	end

end