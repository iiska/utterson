require 'spec_helper'

describe Utterson do
  it "should go through all htm and html files in target dir" do
    u = Utterson.new(dir: "spec/fixtures/dir-structure")
    u.stub(:collect_uris_from) {[]}

    ["spec/fixtures/dir-structure/1.htm",
     "spec/fixtures/dir-structure/2.html",
     "spec/fixtures/dir-structure/a/3.htm",
     "spec/fixtures/dir-structure/a/b/4.html"].each do |file|
      u.should_receive(:collect_uris_from).with(file)
    end

    u.check
  end

  it "should check all urls which are found" do
    u = Utterson.new(dir: "spec/fixtures")
    u.stub(:check_uri) {}
    u.should_receive(:check_uri).exactly(4).times

    u.check
  end

  it "should find all uris from sample document" do
    u = Utterson.new
    uris = u.collect_uris_from("spec/fixtures/sample.html")
    uris.should include("script.js")
    uris.should include("style.css")
    uris.should include("http://example.com")
    uris.should include("image.jpg")
  end

  describe "#check_uri" do
    let(:u) {Utterson.new}
    let(:html_file) {"file.html"}

    it "should use remote checking for http protocol" do
      url = "http://example.com"
      u.stub(:check_remote_uri) {}
      u.should_receive(:check_remote_uri).with(url, html_file)
      u.check_uri(url, html_file)
    end

    it "should use remote checking for https protocol" do
      url = "https://example.com"
      u.stub(:check_remote_uri) {}
      u.should_receive(:check_remote_uri).with(url, html_file)
      u.check_uri(url, html_file)
    end

    it "should use remote checking when only // is specified" do
      url = "//example.com"
      u.stub(:check_remote_uri) {}
      u.should_receive(:check_remote_uri).with(url, html_file)
      u.check_uri(url, html_file)
    end

    it "should use local checking for relative uris" do
      url = "../file.html"
      u.stub(:check_local_uri) {}
      u.should_receive(:check_local_uri).with(url, html_file)
      u.check_uri(url, html_file)
    end
  end

  describe "#check_local_uri" do
    let(:u) {Utterson.new(dir: "spec/fixtures/dir-structure")}
    let(:html_file) {"spec/fixtures/dir-structure/1.htm"}

    it "should not assign error info if file exists" do
      u.check_local_uri("../sample.html", html_file)
      u.errors.should be_empty
    end

    it "should assign error info if file doesn't exist" do
      url = "../sample_not_found.html"
      u.check_local_uri(url, html_file)
      u.errors[html_file].should == {url => "File not found"}
    end

    it "should use root directory when urls start with /" do
      u2 = Utterson.new(dir: "spec/fixtures/dir-structure",
                        root: "spec/fixtures")
      u2.check_local_uri("/sample.html", html_file)
      u2.errors.should be_empty
    end

    it "should handle target directory as root for urls starting with / if root is no available" do
      u.check_local_uri("/2.html", html_file)
      u.errors.should be_empty
    end

    it "should ignore query string when checking local files" do
      u.check_local_uri("2.html?queryparam=value", html_file)
      u.errors.should be_empty
    end
  end

  describe "#check_remote_uri" do
    let(:u) {Utterson.new}
    let(:html_file) {"test.html"}
    let(:url) {"http://example.com/index.html"}

    it "should not assign error info if request is successfull" do
      stub_request(:head, url).
        with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "", :headers => {})
      u.check_remote_uri(url, html_file)
      u.errors.should be_empty
    end

    it "should assign error info if there is error response" do
      stub_request(:head, url).
        with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
        to_return(:status => 404, :body => "", :headers => {})
      u.check_remote_uri(url, html_file)
      puts u.errors.inspect
      u.errors[html_file].should_not be_empty
      u.errors[html_file][url].instance_of?(Net::HTTPNotFound).should be_true
    end

    it "should add error status from buffer timeouts" do
      stub_request(:head, url).to_timeout
      u.check_remote_uri(url, html_file)
      u.errors.should_not be_empty
    end

    it "should add error status from connection timeouts" do
      stub_request(:head, url).to_raise(Errno::ETIMEDOUT)
      u.check_remote_uri(url, html_file)
      u.errors.should_not be_empty
    end

    it "shoud add error status from name resolution errors" do
      stub_request(:head, url).
        to_raise(SocketError.new('getaddrinfo: Name or service not known'))
      u.check_remote_uri(url, html_file)
      u.errors.should_not be_empty
    end

    it "shoud add error status when invalid URI" do
      URI.stub(:new).and_raise(URI::InvalidURIError)
      u.check_remote_uri("http://invalid_uri", html_file)
      u.errors.should_not be_empty
    end
  end

  describe "#print_results" do
    it "should output only basic stats if no errors" do
      u = Utterson.new(dir: "spec/fixtures/dir-structure")
      output = capture_stdout do
        u.check
      end
      output.should match(/4 files with 0 urls checked/)
    end

    it "should output error information" do
      stub_request(:head, "http://example.com/").
        with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
        to_return(:status => 404, :body => "", :headers => {})
      u = Utterson.new(dir: "spec/fixtures")
      output = capture_stdout do
        u.check
      end
      output.should match("spec/fixtures/sample.html\n\tstyle.css\n\t\tFile not found")
      output.should match("script.js\n\t\tFile not found")
      output.should match("image.jpg\n\t\tFile not found")
      output.should match("http://example.com\n\t\tHTTP 404")
      output.should match("5 files with 4 urls checked and 4 errors found")
    end
  end
end
