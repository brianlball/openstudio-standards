require_relative '../../../helpers/minitest_helper'
require_relative '../../../helpers/create_doe_prototype_helper'
require_relative '../../../helpers/compare_models_helper'
require_relative '../resources/regression_helper'

class Test_MidriseApartment_NECB2020_NaturalGasHPGasBackup < NECBRegressionHelper
def setup()
super()
end
def test_NECB2020_MidriseApartment_regression_NaturalGasHPGasBackup()
result, diff = create_model_and_regression_test(building_type: 'MidriseApartment',primary_heating_fuel: 'NaturalGasHPGasBackup', epw_file:  'CAN_AB_Calgary.Intl.AP.718770_CWEC2020.epw',template: 'NECB2020', run_simulation: false)
if result == false
puts "JSON terse listing of diff-errors."
puts diff
puts "Pretty listing of diff-errors for readability."
puts JSON.pretty_generate( diff )
puts "You can find the saved json diff file here test/necb/regression_models/MidriseApartment-NECB2020-NaturalGasHPGasBackup_CAN_AB_Calgary.Intl.AP.718770_CWEC2020_diffs.json"
puts "outputing errors here. "
puts diff["diffs-errors"] if result == false
end
assert(result, diff)
end
end