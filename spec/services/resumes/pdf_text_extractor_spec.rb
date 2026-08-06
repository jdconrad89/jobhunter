# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resumes::PdfTextExtractor do
  def stub_page_runs(runs)
    page = instance_double(PDF::Reader::Page)
    allow(page).to receive(:runs).with(merge: false).and_return(runs)
    allow(PDF::Reader).to receive(:new).and_return(instance_double(PDF::Reader, pages: [ page ]))
  end

  it "inserts spaces between words when gaps form a separate cluster" do
    # Character gaps ~0.5, word gaps ~3.0, font size 12
    runs = [
      PDF::Reader::TextRun.new(10, 100, 6, 12, "w"),
      PDF::Reader::TextRun.new(16.5, 100, 6, 12, "i"),
      PDF::Reader::TextRun.new(23, 100, 6, 12, "t"),
      PDF::Reader::TextRun.new(29.5, 100, 6, 12, "h"),
      PDF::Reader::TextRun.new(38.5, 100, 6, 12, "n"),
      PDF::Reader::TextRun.new(45, 100, 6, 12, "e"),
      PDF::Reader::TextRun.new(51.5, 100, 6, 12, "a"),
      PDF::Reader::TextRun.new(58, 100, 6, 12, "r"),
      PDF::Reader::TextRun.new(64.5, 100, 6, 12, "l"),
      PDF::Reader::TextRun.new(71, 100, 6, 12, "y")
    ]
    stub_page_runs(runs)

    expect(described_class.call("fake-pdf-data")).to eq("with nearly")
  end

  it "does not insert mid-word spaces for tight character gaps" do
    runs = [
      PDF::Reader::TextRun.new(10, 100, 6, 12, "S"),
      PDF::Reader::TextRun.new(16.2, 100, 6, 12, "o"),
      PDF::Reader::TextRun.new(22.4, 100, 6, 12, "f"),
      PDF::Reader::TextRun.new(28.6, 100, 6, 12, "t"),
      PDF::Reader::TextRun.new(34.8, 100, 6, 12, "w"),
      PDF::Reader::TextRun.new(41.0, 100, 6, 12, "a"),
      PDF::Reader::TextRun.new(47.2, 100, 6, 12, "r"),
      PDF::Reader::TextRun.new(53.4, 100, 6, 12, "e")
    ]
    stub_page_runs(runs)

    expect(described_class.call("fake-pdf-data")).to eq("Software")
  end

  it "preserves line breaks for runs on different vertical positions" do
    stub_page_runs(
      [
        PDF::Reader::TextRun.new(10, 200, 30, 12, "JASON"),
        PDF::Reader::TextRun.new(50, 200, 40, 12, "CONRAD"),
        PDF::Reader::TextRun.new(10, 180, 35, 12, "Senior"),
        PDF::Reader::TextRun.new(55, 180, 40, 12, "Engineer")
      ]
    )

    expect(described_class.call("fake-pdf-data")).to eq("JASON CONRAD\nSenior Engineer")
  end
end
