require "spec_helper"

RSpec.describe Welcomedog do
  it "has a version number" do
    expect(Welcomedog::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
