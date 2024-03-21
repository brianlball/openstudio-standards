class ASHRAE901PRM2019 < ASHRAE901PRM

  # Apply the prm parameter to a water heater based on the
  # building area type.
  # @param water_heater_mixed [OpenStudio::Model::WaterHeaterMixed] water heater mixed object
  # @param building_type_swh [String] the swh building are type
  # @return [Boolean] returns true if successful, false if not
  def model_apply_water_heater_prm_parameter(water_heater_mixed, building_type_swh)
    water_heater_mixed_apply_prm_baseline_fuel_type(water_heater_mixed, building_type_swh)
    water_heater_mixed_apply_efficiency(water_heater_mixed)
    return true
  end
  # Apply the prm fuel type to a water heater based on the
  # building area type.
  # @param water_heater_mixed [OpenStudio::Model::WaterHeaterMixed] water heater mixed object
  # @param building_type [String] the building type (For consistency with the standard class, not used in the method)
  # @return [Boolean] returns true if successful, false if not
  def water_heater_mixed_apply_prm_baseline_fuel_type(water_heater_mixed, building_type)
    # Get the fuel type data
    heater_prop = model_find_object(standards_data['prm_swh_bldg_type'], {'swh_building_type' => building_type})
    new_fuel_data = heater_prop['baseline_heating_method']
    # There are only two water heater fuel type in the prm database:
    # ("Gas Storage" and "Electric Resistance Storage")
    # Change the prm fuel type to openstudio fuel type
    if new_fuel_data == "Gas Storage"
      new_fuel = "NaturalGas"
    else
      new_fuel = "Electricity"
    end
    # Change the fuel type if necessary
    old_fuel = water_heater_mixed.heaterFuelType
    unless new_fuel == old_fuel
      water_heater_mixed.setHeaterFuelType(new_fuel)
      OpenStudio.logFree(OpenStudio::Info, 'openstudio.standards.WaterHeaterMixed', "For #{water_heater_mixed.name}, changed baseline water heater fuel from #{old_fuel} to #{new_fuel}.")
    end
  end
end

