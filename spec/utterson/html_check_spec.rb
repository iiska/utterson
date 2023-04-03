require 'spec_helper'

module Utterson
  describe HtmlCheck do
    before(:each) do
      HtmlCheck.class_variable_set(:@@checked_urls, {})
    end

    let(:sample_file) {"spec/fixtures/sample.html"}

    it "should check all urls which are found" do
      h = HtmlCheck.new(dir: "spec/fixtures", file: "spec/fixtures/sample.html")
      h.stub(:check_uri) {}
      h.should_receive(:check_uri).exactly(4).times
      h.run.join
    end

    it "should find all uris from sample document" do
      h = HtmlCheck.new(file: sample_file)
      uris = h.collect_uris_from(sample_file)
      expect(uris).to include("script.js")
      expect(uris).to include("style.css")
      expect(uris).to include("http://example.com")
      expect(uris).to include("image.jpg")
    end

    describe "#check_uri" do
      let(:h) {HtmlCheck.new}
      let(:html_file) {"file.html"}

      it "should check same url only once" do
        url = "http://example.com"
        h.stub(:check_remote_uri) {}
        h.should_receive(:check_remote_uri).once.with(url, html_file)
        h.check_uri(url, html_file)
        h.check_uri(url, html_file)
      end

      it "should use remote checking for http protocol" do
        url = "http://example.com"
        h.stub(:check_remote_uri) {}
        h.should_receive(:check_remote_uri).with(url, html_file)
        h.check_uri(url, html_file)
      end

      it "should use remote checking for https protocol" do
        url = "https://example.com"
        h.stub(:check_remote_uri) {}
        h.should_receive(:check_remote_uri).with(url, html_file)
        h.check_uri(url, html_file)
      end

      it "should use remote checking when only // is specified" do
        url = "//example.com"
        h.stub(:check_remote_uri) {}
        h.should_receive(:check_remote_uri).with(url, html_file)
        h.check_uri(url, html_file)
      end

      it "should use local checking for relative uris" do
        url = "../file.html"
        h.stub(:check_local_uri) {}
        h.should_receive(:check_local_uri).with(url, html_file)
        h.check_uri(url, html_file)
      end
    end

    describe "#check_relative_uri" do
      let(:h) {HtmlCheck.new(root: "spec/fixtures/dir-structure")}
      let(:html_file) {"spec/fixtures/dir-structure/1.htm"}

      it "should not assign error info if file exists" do
        h.check_local_uri("../sample.html", html_file)
        expect(h.errors).to be_empty
      end

      it "should assign error info if file doesn't exist" do
        url = "../sample_not_found.html"
        h.check_local_uri(url, html_file)
        expect(h.errors[html_file]).to eq({url => "File not found"})
      end

      it "should use root directory when urls start with /" do
        h2 = HtmlCheck.new(file: html_file,
                           root: "spec/fixtures")
        h2.check_local_uri("/sample.html", html_file)
        expect(h2.errors).to be_empty
      end

      it "uses target directory as root if undefined when url starts with /" do
        h.check_local_uri("/2.html", html_file)
        expect(h.errors).to be_empty
      end

      it "should ignore query string when checking local files" do
        h.check_local_uri("2.html?queryparam=value", html_file)
        expect(h.errors).to be_empty
      end
    end

    describe "#check_remote_uri" do
      let(:h) {HtmlCheck.new(file: "test.html")}
      let(:html_file) {"test.html"}
      let(:url) {"http://example.com/index.html"}

      it "should not assign error info if request is successfull" do
        stub_request(:head, url).
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "", :headers => {})
        h.check_remote_uri(url, html_file)
        expect(h.errors).to be_empty
      end

      it "should assign error info if there is error response" do
        stub_request(:head, url).
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 404, :body => "", :headers => {})
        h.check_remote_uri(url, html_file)
        expect(h.errors[html_file]).not_to be_empty
        expect(h.errors[html_file][url].instance_of?(Net::HTTPNotFound)).to be_truthy
      end

      it "should add error status from buffer timeouts" do
        stub_request(:head, url).to_timeout
        h.check_remote_uri(url, html_file)
        expect(h.errors).not_to be_empty
      end

      it "should add error status from connection timeouts" do
        stub_request(:head, url).to_raise(Errno::ETIMEDOUT)
        h.check_remote_uri(url, html_file)
        expect(h.errors).not_to be_empty
      end

      it "should add error status from 'No route to host' errors" do
        stub_request(:head, url).to_raise(Errno::EHOSTUNREACH)
        h.check_remote_uri(url, html_file)
        expect(h.errors).not_to be_empty
      end

      it "shoud add error status from name resolution errors" do
        stub_request(:head, url).
          to_raise(SocketError.new('getaddrinfo: Name or service not known'))
        h.check_remote_uri(url, html_file)
        expect(h.errors).not_to be_empty
      end

      it "shoud add error status when invalid URI" do
        h.check_remote_uri(":", html_file)
        expect(h.errors).not_to be_empty
      end
    end
  end
end
