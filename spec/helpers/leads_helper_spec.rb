require 'rails_helper'
include ApplicationHelper

RSpec.describe LeadsHelper, type: :helper do
  describe "titles_for_select" do
    it "should return an array of strings" do
      out = titles_for_select
      expect(out).to match('Mr.')
    end
  end

  describe "display_preference_option" do
    it "should return the attribute for Strings" do
      expect(display_preference_option("hello")).to eq("hello")
    end

    it "should return the attribute for Numbers" do
      expect(display_preference_option(1.2)).to eq(1.2)
      expect(display_preference_option(1)).to eq(1)
      expect(display_preference_option(0)).to eq(0)
    end

    it "should return the short_date for Date" do
      val = Date.today
      expect(display_preference_option(val)).to be_a(String)
    end

    it "should return the short_date for DateTime" do
      val = DateTime.now
      expect(display_preference_option(val)).to be_a(String)
    end

    it "should return the short_date for TimeWithZone" do
      val = Time.zone.now
      expect(display_preference_option(val)).to be_a(String)
    end

    it "should return 'No preference' if no value is present" do
      expect(display_preference_option(nil)).to eq('No preference')
      expect(display_preference_option(false)).to eq('No preference')
    end
  end
end
