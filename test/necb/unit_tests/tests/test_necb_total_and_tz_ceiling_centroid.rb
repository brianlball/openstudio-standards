require_relative '../../../helpers/minitest_helper'
#require_relative '../../../helpers/create_doe_prototype_helper'
require_relative '../../../helpers/necb_helper'
include(NecbHelper)

# This class will perform tests to ensure that the centroid of the highest ceiling is being found and that the overall
# centroid of ceilings of spaces in a thermal zone in story is properly found.  It uses the Ceilingtest.osm which is
# a modified version of the initial HighriseApartement.osm geometry file.
class NECB_Ceiling_Centroid_Test < Minitest::Test

  # Set to true to run the standards in the test.
  PERFORM_STANDARDS = true

  def setup()
    define_folders(__dir__)
    define_std_ranges
  end

  # Additional constant ranges for tests.
  Epw_files = ['CAN_AB_Calgary.Intl.AP.718770_CWEC2016.epw']

  # @return [Bool] true if successful.
  def test_ceiling_centroid()
    output_array = []
    climate_zone = 'none'
    #Iterate through code versions. It shouldn't make a different but do it anyway. 
    @Templates.sort.each do |template|
      Epw_files.sort.each do |epw_file|
        model = nil
        standard = nil
        # Open the Outpatient model.
        model = BTAP::FileIO.load_osm(File.join(@resources_folder,"Ceilingtest.osm"))
        # Set the weather file.
        BTAP::Environment::WeatherFile.new(epw_file).set_weather_file(model)
        # Get access to the standards class
        standard = get_standard(template)
        # Find the centroid of the highest outside ceiling and add it to the output array
        output_array << standard.find_highest_roof_centre(model)
        # Go through the thermal zones and find all the conditioned, non-plenum, spaces in the thermal zore.  Sort by
        # story and find the overall centroid of all the ceilings in the thermal zone on that floor.  Add the result
        # to the output array.
        model.getThermalZones.sort.each do |tz|
          output_array << tz.nameString
          output_array << standard.thermal_zone_get_centroid_per_floor(tz) unless standard.thermal_zone_get_centroid_per_floor(tz).nil?
        end
      end #loop to the next epw_file
    end #loop to the next Template
    #Write test report file.
    test_result_file = File.join(@test_results_folder,'ceiling_test_results.json')
    File.open(test_result_file, 'w') {|f| f.write(JSON.pretty_generate(output_array)) }

    #Test that the values are correct by doing a file compare.
    expected_result_file = File.join(@expected_results_folder,'ceiling_test_expected_results.json')
    b_result = FileUtils.compare_file(expected_result_file , test_result_file )
    assert( b_result,
            "shw test results do not match expected results! Compare/diff the output with the stored values here #{expected_result_file} and #{test_result_file}"
    )
  end
end