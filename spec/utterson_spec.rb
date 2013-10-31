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

    it "should use remote checking for http protocol" do
      u.stub(:check_remote_uri) {}
      u.should_receive(:check_remote_uri).with("http://example.com")
      u.check_uri("http://example.com")
    end

    it "should use remote checking for https protocol" do
      u.stub(:check_remote_uri) {}
      u.should_receive(:check_remote_uri).with("https://example.com")
      u.check_uri("https://example.com")
    end

    it "should use remote checking when only // is specified" do
      u.stub(:check_remote_uri) {}
      u.should_receive(:check_remote_uri).with("//example.com")
      u.check_uri("//example.com")
    end

    it "should use local checking for relative uris" do
      u.stub(:check_local_uri) {}
      u.should_receive(:check_local_uri).with("../file.html")
      u.check_uri("../file.html")
    end
  end
end
