require "spec_helper"

module Utterson
  describe Base do
    it "goes through all htm and html files in target dir" do
      dir = "spec/fixtures/dir-structure"
      u = described_class.new(dir: dir)
      allow(HtmlCheck).to receive(:new) { instance_double(HtmlCheck, when_done: {}, run: instance_double(Thread, join: {})) }

      u.check
      ["spec/fixtures/dir-structure/1.htm",
        "spec/fixtures/dir-structure/2.html",
        "spec/fixtures/dir-structure/a/3.htm",
        "spec/fixtures/dir-structure/a/b/4.html"].each do |file|
        expect(HtmlCheck).to have_received(:new).with(file: file, root: dir)
      end
    end

    describe "#print_results" do
      it "outputs only basic stats if no errors" do
        u = described_class.new(dir: "spec/fixtures/dir-structure")
        output = capture_stdout do
          u.check
        end
        expect(output).to match(/4 files with 0 urls checked/)
      end

      it "outputs error information" do
        stub_request(:head, "http://example.com/")
          .with(headers: {"Accept" => "*/*", "User-Agent" => "Ruby"})
          .to_return(status: 404, body: "", headers: {})
        u = described_class.new(dir: "spec/fixtures")
        output = capture_stdout do
          u.check
        end
        expect(output).to include(
          "spec/fixtures/sample.html\n\tstyle.css\n" \
      "\t\tFile not found",
          "script.js\n\t\tFile not found",
          "image.jpg\n\t\tFile not found",
          "http://example.com\n\t\tHTTP 404",
          "5 files with 4 urls checked and 4 errors found"
        )
      end
    end
  end
end
