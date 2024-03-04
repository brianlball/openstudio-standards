require_relative '../../helpers/minitest_helper'

class TestWeatherStatFile < Minitest::Test
  def setup
    @weather = OpenstudioStandards::Weather
  end

  def test_stat_file
    model = OpenStudio::Model::Model.new

    weather_file_names = [
      # "ALTURAS_725958_CZ2010",
      # "LIVERMORE_724927_CZ2010",
      # "USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3",
      "USA_WA_Seattle-Tacoma.Intl.AP.727930_TMY3"
    ]

    require 'json'
    require 'pp'
    weather_file_names.each do |weather_file_name|
      weather_file_path = @weather.get_standards_weather_file_path(weather_file_name + '.epw')
      assert(weather_file_path)
      puts weather_file_path
      stat_file_path = weather_file_path.gsub('.epw', '.stat')
      assert(File.exist?(stat_file_path))
      stat_file = OpenstudioStandards::Weather::StatFile.new(stat_file_path)
      # json = stat_file.to_json
      # pp JSON.parse(json)
      assert_in_delta(stat_file.lat, 47.46, 0.01)
      assert_in_delta(stat_file.lon, -122.31, 0.01)
      assert_equal(stat_file.gmt, -8.0)
      assert_equal(stat_file.heating_design_info.size, 15)
      assert_equal(stat_file.cooling_design_info.size, 32)
      assert_equal(stat_file.extremes_design_info.size, 16)
      assert_equal(stat_file.monthly_dry_bulb.size, 12)
    end
  end
end
