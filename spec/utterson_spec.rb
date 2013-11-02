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
      u.should_receive(:check_remote_uri).with("http://example.com", "file.html")
      u.check_uri("http://example.com", "file.html")
    end

    it "should use remote checking for https protocol" do
      u.stub(:check_remote_uri) {}
      u.should_receive(:check_remote_uri).with("https://example.com", "file.html")
      u.check_uri("https://example.com", "file.html")
    end

    it "should use remote checking when only // is specified" do
      u.stub(:check_remote_uri) {}
      u.should_receive(:check_remote_uri).with("//example.com", "file.html")
      u.check_uri("//example.com", "file.html")
    end

    it "should use local checking for relative uris" do
      u.stub(:check_local_uri) {}
      u.should_receive(:check_local_uri).with("../file.html", "file.html")
      u.check_uri("../file.html", "file.html")
    end
  end

  describe "#check_local_uri" do
    let(:u) {Utterson.new}

    it "should not assign error info if file exists" do
      u.check_local_uri("../sample.html", "spec/fixtures/dir-structure/1.htm")
      u.errors.should be_empty
    end

    it "should assign error info if file doesn't exist" do
      u.check_local_uri("../sample_not_found.html", "spec/fixtures/dir-structure/1.htm")
      u.errors["spec/fixtures/dir-structure/1.htm"].should == {"../sample_not_found.html" => "File not found"}
    end
  end

  describe "#check_remote_uri" do
    let(:u) {Utterson.new}

    it "should not assign error info if request is successfull" do
      u.check_remote_uri("http://example.com/index.html", "test.html")
      u.errors.should be_empty
    end

    it "should assign error info if there is error response" do
      u.check_remote_uri("http://example.com/file_which_wont_exist.html", "test.html")
      puts u.errors.inspect
      u.errors["test.html"].should_not be_empty
      u.errors["test.html"]["http://example.com/file_which_wont_exist.html"].instance_of?(Net::HTTPNotFound).should be_true
    end
  end

  describe "#print_results" do
    it "should output only basic stats if no errors" do
      u = Utterson.new(dir: "spec/fixtures/dir-structure")
      output = capture_stdout do
        u.check
      end
      output.should == "4 files with 0 urls checked.\n"
    end

    it "should output error information" do
      u = Utterson.new(dir: "spec/fixtures")
      output = capture_stdout do
        u.check
      end
      output.should == "spec/fixtures/sample.html\n\tstyle.css\n\t\tFile not found\n\tscript.js\n\t\tFile not found\n\timage.jpg\n\t\tFile not found\n5 files with 4 urls checked.\n"
    end
  end
end
