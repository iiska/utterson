require 'spec_helper'

module Utterson
  describe Base do
    it "should go through all htm and html files in target dir" do
      dir = "spec/fixtures/dir-structure"
      u = Base.new(dir: dir)
      HtmlCheck.stub(:new) {double(when_done: {}, run: double(join: {}))}

      ["spec/fixtures/dir-structure/1.htm",
       "spec/fixtures/dir-structure/2.html",
       "spec/fixtures/dir-structure/a/3.htm",
       "spec/fixtures/dir-structure/a/b/4.html"].each do |file|
        expect(HtmlCheck).to receive(:new).with(file: file, root: dir)
      end

      u.check
    end

    describe "#print_results" do
      it "should output only basic stats if no errors" do
        u = Base.new(dir: "spec/fixtures/dir-structure")
        output = capture_stdout do
          u.check
        end
        expect(output).to match(/4 files with 0 urls checked/)
      end

      it "should output error information" do
        stub_request(:head, "http://example.com/").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 404, :body => "", :headers => {})
        u = Base.new(dir: "spec/fixtures")
        output = capture_stdout do
          u.check
        end
        expect(output).to match("spec/fixtures/sample.html\n\tstyle.css\n"+
                            "\t\tFile not found")
        expect(output).to match("script.js\n\t\tFile not found")
        expect(output).to match("image.jpg\n\t\tFile not found")
        expect(output).to match("http://example.com\n\t\tHTTP 404")
        expect(output).to match("5 files with 4 urls checked and 4 errors found")
      end
    end
  end
end
