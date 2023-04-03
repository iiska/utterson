require "spec_helper"

module Utterson
  describe HtmlCheck do
    before do
      described_class.class_variable_set(:@@checked_urls, {})
    end

    let(:sample_file) { "spec/fixtures/sample.html" }

    it "checks all urls which are found" do
      h = described_class.new(dir: "spec/fixtures", file: "spec/fixtures/sample.html")
      allow(h).to receive(:check_uri)
      h.run.join
      expect(h).to have_received(:check_uri).exactly(4).times
    end

    it "finds all uris from sample document" do
      h = described_class.new(file: sample_file)
      uris = h.collect_uris_from(sample_file)
      expect(uris).to include("script.js", "style.css", "http://example.com", "image.jpg")
    end

    describe "#check_uri" do
      let(:h) { described_class.new }
      let(:html_file) { "file.html" }

      it "checks same url only once" do
        url = "http://example.com"
        allow(h).to receive(:check_remote_uri)
        h.check_uri(url, html_file)
        h.check_uri(url, html_file)
        expect(h).to have_received(:check_remote_uri).once.with(url, html_file)
      end

      it "uses remote checking for http protocol" do
        url = "http://example.com"
        allow(h).to receive(:check_remote_uri)
        h.check_uri(url, html_file)
        expect(h).to have_received(:check_remote_uri).with(url, html_file)
      end

      it "uses remote checking for https protocol" do
        url = "https://example.com"
        allow(h).to receive(:check_remote_uri)
        h.check_uri(url, html_file)
        expect(h).to have_received(:check_remote_uri).with(url, html_file)
      end

      it "uses remote checking when only // is specified" do
        url = "//example.com"
        allow(h).to receive(:check_remote_uri)
        h.check_uri(url, html_file)
        expect(h).to have_received(:check_remote_uri).with(url, html_file)
      end

      it "uses local checking for relative uris" do
        url = "../file.html"
        allow(h).to receive(:check_local_uri)
        h.check_uri(url, html_file)
        expect(h).to have_received(:check_local_uri).with(url, html_file)
      end
    end

    describe "#check_relative_uri" do
      let(:h) { described_class.new(root: "spec/fixtures/dir-structure") }
      let(:html_file) { "spec/fixtures/dir-structure/1.htm" }

      it "does not assign error info if file exists" do
        h.check_local_uri("../sample.html", html_file)
        expect(h.errors).to be_empty
      end

      it "assigns error info if file doesn't exist" do
        url = "../sample_not_found.html"
        h.check_local_uri(url, html_file)
        expect(h.errors[html_file]).to eq({url => "File not found"})
      end

      it "uses root directory when urls start with /" do
        h2 = described_class.new(file: html_file,
          root: "spec/fixtures")
        h2.check_local_uri("/sample.html", html_file)
        expect(h2.errors).to be_empty
      end

      it "uses target directory as root if undefined when url starts with /" do
        h.check_local_uri("/2.html", html_file)
        expect(h.errors).to be_empty
      end

      it "ignores query string when checking local files" do
        h.check_local_uri("2.html?queryparam=value", html_file)
        expect(h.errors).to be_empty
      end
    end

    describe "#check_remote_uri" do
      let(:h) { described_class.new(file: "test.html") }
      let(:html_file) { "test.html" }
      let(:url) { "http://example.com/index.html" }

      it "does not assign error info if request is successfull" do
        stub_request(:head, url)
          .with(headers: {"Accept" => "*/*", "User-Agent" => "Ruby"})
          .to_return(status: 200, body: "", headers: {})
        h.check_remote_uri(url, html_file)
        expect(h.errors).to be_empty
      end

      it "assigns error info if there is error response" do
        stub_request(:head, url)
          .with(headers: {"Accept" => "*/*", "User-Agent" => "Ruby"})
          .to_return(status: 404, body: "", headers: {})
        h.check_remote_uri(url, html_file)
        expect(h.errors[html_file][url]).to be_an_instance_of(Net::HTTPNotFound)
      end

      it "adds error status from buffer timeouts" do
        stub_request(:head, url).to_timeout
        h.check_remote_uri(url, html_file)
        expect(h.errors).not_to be_empty
      end

      it "adds error status from connection timeouts" do
        stub_request(:head, url).to_raise(Errno::ETIMEDOUT)
        h.check_remote_uri(url, html_file)
        expect(h.errors).not_to be_empty
      end

      it "adds error status from 'No route to host' errors" do
        stub_request(:head, url).to_raise(Errno::EHOSTUNREACH)
        h.check_remote_uri(url, html_file)
        expect(h.errors).not_to be_empty
      end

      it "shoud add error status from name resolution errors" do
        stub_request(:head, url)
          .to_raise(SocketError.new("getaddrinfo: Name or service not known"))
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
