require_relative '../../../helpers/minitest_helper'
require_relative '../../../helpers/create_doe_prototype_helper'
require_relative '../../../helpers/compare_models_helper'
require_relative '../resources/regression_helper'

class Test_LargeOffice_BTAPPRE1980_ElectricityHPElecBackup < NECBRegressionHelper
def setup()
super()
end
def test_BTAPPRE1980_LargeOffice_regression_ElectricityHPElecBackup()
result, diff = create_model_and_regression_test(building_type: 'LargeOffice',primary_heating_fuel: 'ElectricityHPElecBackup', epw_file:  'CAN_AB_Calgary.Intl.AP.718770_CWEC2020.epw',template: 'BTAPPRE1980', run_simulation: false)
if result == false
puts "JSON terse listing of diff-errors."
puts diff
puts "Pretty listing of diff-errors for readability."
puts JSON.pretty_generate( diff )
puts "You can find the saved json diff file here test/necb/regression_models/LargeOffice-BTAPPRE1980-ElectricityHPElecBackup_CAN_AB_Calgary.Intl.AP.718770_CWEC2020_diffs.json"
puts "outputing errors here. "
puts diff["diffs-errors"] if result == false
end
assert(result, diff)
end
end