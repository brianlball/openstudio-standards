class ECMS

  def apply_pv_ground(model:, pv_ground_type:, pv_ground_total_area_pv_panels_m2:, pv_ground_tilt_angle:, pv_ground_azimuth_angle:, pv_ground_module_description:)

    ##### If any of users' inputs are nil/false do nothing.
    return if pv_ground_type.nil? || pv_ground_type == FALSE
    return if pv_ground_total_area_pv_panels_m2.nil? || pv_ground_total_area_pv_panels_m2 == FALSE
    return if pv_ground_tilt_angle.nil? || pv_ground_tilt_angle == FALSE
    return if pv_ground_azimuth_angle.nil? || pv_ground_azimuth_angle == FALSE
    return if pv_ground_module_description.nil? || pv_ground_module_description == FALSE

    ##### Set default PV panels' tilt angle as the latitude
    if pv_ground_tilt_angle == 'NECB_Default'
      epw = BTAP::Environment::WeatherFile.new(model.weatherFile.get.path.get)
      pv_ground_tilt_angle = epw.latitude.to_f
    end

    ##### Set default PV panels' azimuth angle as south-facing arrays
    if pv_ground_azimuth_angle == 'NECB_Default'
      pv_ground_azimuth_angle = 180 # EnergyPlus I/O Reference: "An azimuth angle of 180° is for a south-facing array, and an azimuth angle of 0° is for a north-facing array."
    end

    ##### Set default PV module type as the the below one
    if pv_ground_module_description == 'NECB_Default'
      pv_ground_module_description = 'HES-160-36PV 26.6  x 58.3 x 1.38' # Note: As per Mike Lubun's comment, assuming a typical panel is 5 ft x 2 ft, the closest standard type PV panel in the spreadsheet would be the 160W HES.
    end

    ##### Calculate number of PV panels
    # Note: assuming 5 ft x 2 ft as PV panel's size since it seems to fit the racking system used for ground mounts as per Mike Lubun's comment.
    pv_area_each_ft2 = 5.0 * 2.0
    pv_area_each_m2 = (OpenStudio.convert(pv_area_each_ft2, 'ft^2', 'm^2').get) #convert pv_area_each_ft2 to m2
    pv_number_panels = pv_ground_total_area_pv_panels_m2/pv_area_each_m2

    ##### Get data of the PV panel from the json file
    pv_info = @standards_data['tables']['pv']['table'].detect { |item| item['pv_module_description'] == pv_ground_module_description }
    pv_ground_module_type = pv_info['pv_module_type']
    pv_watt = pv_info['pv_module_wattage']

    ##### Create the generator
    # Assuming one PVWatts generator in E+ as per Mike Lubun's comment for simplification, however exact number of PVWatts generators (and inverters) are calculated for costing.
    dc_system_capacity = pv_number_panels * pv_watt
    generator = OpenStudio::Model::GeneratorPVWatts.new(model,dc_system_capacity)
    generator.setModuleType(pv_ground_module_type)
    generator.setArrayType('OneAxis')   # Note: "tilt and azimuth are fixed" for this array type (see E+ I/O Reference). This array type has been chosen as per Mike Lubun's costing spec.
    generator.setTiltAngle(pv_ground_tilt_angle)
    generator.setAzimuthAngle(pv_ground_azimuth_angle)

    ##### Create the inverter
    inverter = OpenStudio::Model::ElectricLoadCenterInverterPVWatts.new(model)
    inverter.setDCToACSizeRatio(1.1) # Note: This is EnergyPlus' default value; This default value has been chosen for ground-mounted PV, assuming no storage as per Mike Lubun's costing spec.
    inverter.setInverterEfficiency(0.96) # Note: This is EnergyPlus' default value; This default value has been chosen as per Mike Lubun's costing spec.

    ##### Get distribution systems and set relevant parameters
    model.getElectricLoadCenterDistributions.sort.each  do |elc_distribution|
      elc_distribution.setInverter(inverter)
      elc_distribution.setGeneratorOperationSchemeType('Baseload')  # E+ I/O Reference: "The Baseload scheme requests all generators scheduled ON (available) to operate, even if the amount of electric power generated exceeds the total facility electric power demand." This scheme type has been chosen as per Mike Lubun's costing spec.
    end

  end

end
