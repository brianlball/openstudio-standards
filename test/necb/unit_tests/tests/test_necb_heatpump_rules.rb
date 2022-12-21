require_relative '../../../helpers/minitest_helper'
require_relative '../../../helpers/necb_helper'
include(NecbHelper)

class NECB_HVAC_Heat_Pump_Tests < MiniTest::Test

  # Set to true to run the standards in the test.
  PERFORM_STANDARDS = true

  def setup()
    define_folders(__dir__)
    define_std_ranges
  end

  # Test to validate the heating efficiency generated against expected values stored in the file:
  # 'compliance_heatpump_efficiencies_expected_results.csv
  def test_heatpump_efficiency

    # Set up remaining parameters for test.
    output_folder = method_output_folder

    templates = ['NECB2011', 'NECB2015', 'BTAPPRE1980']
    templates.each do |template|

      heatpump_expected_result_file = File.join(@expected_results_folder, "#{template.downcase}_compliance_heatpump_efficiencies_expected_results.csv")
      standard = get_standard(template)

      # Initialize hashes for storing expected heat pump efficiency data from file
      min_caps = []
      max_caps = []
      efficiency_type = []

      # read the file for the expected unitary efficiency values for different heating types and equipment capacity ranges
      num_cap_intv = 0
      CSV.foreach(heatpump_expected_result_file, headers: true) do |data|
        min_caps << data['Min Capacity (Btu per hr)']
        max_caps << data['Max Capacity (Btu per hr)']
        if data['Energy Efficiency Ratio (EER)'].to_f > 0.0
          efficiency_type << 'Energy Efficiency Ratio (EER)'
        end
        num_cap_intv += 1
      end

      # Use the expected heat pump efficiency data to generate suitable equipment capacities for the test to cover all
      # the relevant equipment capacity ranges
      test_caps = []
      for i in 0..num_cap_intv - 2
        test_caps << 0.5 * (OpenStudio.convert(min_caps[i].to_f, 'Btu/hr', 'W').to_f + OpenStudio.convert(min_caps[i + 1].to_f, 'Btu/h', 'W').to_f)
      end
      test_caps << (min_caps[num_cap_intv - 1].to_f + 10000.0)

      # Generate the osm files for all relevant cases to generate the test data for system 3
      actual_heatpump_cop = []
      heatpump_res_file_output_text = "Min Capacity (Btu per hr),Max Capacity (Btu per hr),Energy Efficiency Ratio (EER)\n"
      boiler_fueltype = 'Electricity'
      baseboard_type = 'Hot Water'
      heating_coil_type = 'DX'
      model = BTAP::FileIO.load_osm(File.join(@resources_folder,"5ZoneNoHVAC.osm"))
      BTAP::Environment::WeatherFile.new('CAN_ON_Toronto.Pearson.Intl.AP.716240_CWEC2016.epw').set_weather_file(model)
      # save baseline
      BTAP::FileIO.save_osm(model, "#{output_folder}/baseline.osm")
      test_caps.each do |cap|
        name = "#{template}_sys3_HtgDXCoilCap~#{cap}watts"
        puts "***************************************#{name}*******************************************************\n"
        model = BTAP::FileIO.load_osm(File.join(@resources_folder,"5ZoneNoHVAC.osm"))
        BTAP::Environment::WeatherFile.new('CAN_ON_Toronto.Pearson.Intl.AP.716240_CWEC2016.epw').set_weather_file(model)
        hw_loop = OpenStudio::Model::PlantLoop.new(model)
        always_on = model.alwaysOnDiscreteSchedule
        standard.setup_hw_loop_with_components(model, hw_loop, boiler_fueltype, always_on)
        standard.add_sys3and8_single_zone_packaged_rooftop_unit_with_baseboard_heating_single_speed(model: model,
                                                                                                    zones: model.getThermalZones,
                                                                                                    heating_coil_type: heating_coil_type,
                                                                                                    baseboard_type: baseboard_type,
                                                                                                    hw_loop: hw_loop,
                                                                                                    new_auto_zoner: false)
        # Save the model after btap hvac.
        BTAP::FileIO.save_osm(model, "#{output_folder}/#{name}.hvacrb")
        dx_clg_coils = model.getCoilCoolingDXSingleSpeeds
        dx_clg_coils.each do |coil|
          coil.setRatedTotalCoolingCapacity(cap)
          flow_rate = cap * 5.0e-5
          coil.setRatedAirFlowRate(flow_rate)
        end

            # Run the measure.
            run_the_measure(model: model, test_name: name) if PERFORM_STANDARDS
        actual_heatpump_cop << model.getCoilHeatingDXSingleSpeeds[0].ratedCOP.to_f
      end

      # Generate table of test heat pump efficiencies
      actual_heatpump_eff = []
      output_line_text = ''
      for int in 0..num_cap_intv - 1
        output_line_text += "#{min_caps[int]},#{max_caps[int]},"
        if efficiency_type[int] == 'Energy Efficiency Ratio (EER)'
          actual_heatpump_eff[int] = (standard.cop_to_eer(actual_heatpump_cop[int].to_f, test_caps[int]) + 0.001).round(1)
          output_line_text += "#{actual_heatpump_eff[int]}\n"
        end
      end
      heatpump_res_file_output_text += output_line_text

      # Write test results file.
      test_result_file = File.join(@test_results_folder, "#{template.downcase}_compliance_heatpump_efficiencies_test_results.csv")

      File.open(test_result_file, 'w') { |f| f.write(heatpump_res_file_output_text.chomp) }

      # Test that the values are correct by doing a file compare.
      expected_result_file = File.join(@expected_results_folder, "#{template.downcase}_compliance_heatpump_efficiencies_expected_results.csv")

      # Check if test results match expected.
      msg = "Heat pump efficiency test results do not match what is expected in test"
      file_compare(expected_results_file: expected_result_file, test_results_file: test_result_file, msg: msg)
    end
  end

  # Test to validate the heat pump performance curves
  def test_heatpump_curves

    # Set up remaining parameters for test.
    output_folder = method_output_folder
    standard = get_standard('NECB2011')

    heatpump_expected_result_file = File.join(@expected_results_folder, "#{template.downcase}_compliance_heatpump_curves_expected_results.csv")
    heatpump_curve_names = []
    CSV.foreach(heatpump_expected_result_file, headers: true) do |data|
      heatpump_curve_names << data['Curve Name']
    end
    # Generate the osm files for all relevant cases to generate the test data for system 3
    heatpump_res_file_output_text = "Curve Name,Curve Type,coeff1,coeff2,coeff3,coeff4,coeff5,coeff6,min_x,max_x\n"
    boiler_fueltype = 'Electricity'
    baseboard_type = 'Hot Water'
    heating_coil_type = 'DX'
    model = BTAP::FileIO.load_osm(File.join(@resources_folder,"5ZoneNoHVAC.osm"))
    BTAP::Environment::WeatherFile.new('CAN_ON_Toronto.Pearson.Intl.AP.716240_CWEC2016.epw').set_weather_file(model)
    # save baseline
    BTAP::FileIO.save_osm(model, "#{output_folder}/baseline.osm")
    name = "sys3"
    puts "***************************************#{name}*******************************************************\n"
    hw_loop = OpenStudio::Model::PlantLoop.new(model)
    always_on = model.alwaysOnDiscreteSchedule
    standard.setup_hw_loop_with_components(model, hw_loop, boiler_fueltype, always_on)
    standard.add_sys3and8_single_zone_packaged_rooftop_unit_with_baseboard_heating_single_speed(model: model,
                                                                                                zones: model.getThermalZones,
                                                                                                heating_coil_type: heating_coil_type,
                                                                                                baseboard_type: baseboard_type,
                                                                                                hw_loop: hw_loop,
                                                                                                new_auto_zoner: false)
    # Save the model after btap hvac.
    BTAP::FileIO.save_osm(model, "#{output_folder}/#{name}.hvacrb")

            # Run the measure.
            run_the_measure(model: model, test_name: name) if PERFORM_STANDARDS

    dx_units = model.getCoilHeatingDXSingleSpeeds
    heatpump_cap_ft_curve = dx_units[0].totalHeatingCapacityFunctionofTemperatureCurve.to_CurveCubic.get
    heatpump_res_file_output_text +=
        "#{heatpump_curve_names[0]},cubic,#{'%.5E' % heatpump_cap_ft_curve.coefficient1Constant},#{'%.5E' % heatpump_cap_ft_curve.coefficient2x}," +
            "#{'%.5E' % heatpump_cap_ft_curve.coefficient3xPOW2},#{'%.5E' % heatpump_cap_ft_curve.coefficient4xPOW3},#{'%.5E' % heatpump_cap_ft_curve.minimumValueofx}," +
            "#{'%.5E' % heatpump_cap_ft_curve.maximumValueofx}\n"
    heatpump_eir_ft_curve = dx_units[0].energyInputRatioFunctionofTemperatureCurve.to_CurveCubic.get
    heatpump_res_file_output_text +=
        "#{heatpump_curve_names[1]},cubic,#{'%.5E' % heatpump_eir_ft_curve.coefficient1Constant},#{'%.5E' % heatpump_eir_ft_curve.coefficient2x}," +
            "#{'%.5E' % heatpump_eir_ft_curve.coefficient3xPOW2},#{'%.5E' % heatpump_eir_ft_curve.coefficient4xPOW3},#{'%.5E' % heatpump_eir_ft_curve.minimumValueofx}," +
            "#{'%.5E' % heatpump_eir_ft_curve.maximumValueofx}\n"
    heatpump_cap_flow_curve = dx_units[0].totalHeatingCapacityFunctionofFlowFractionCurve.to_CurveCubic.get
    heatpump_res_file_output_text +=
        "#{heatpump_curve_names[2]},cubic,#{'%.5E' % heatpump_cap_flow_curve.coefficient1Constant},#{'%.5E' % heatpump_cap_flow_curve.coefficient2x}," +
            "#{'%.5E' % heatpump_cap_flow_curve.coefficient3xPOW2},#{'%.5E' % heatpump_cap_flow_curve.coefficient4xPOW3},#{'%.5E' % heatpump_cap_flow_curve.minimumValueofx}," +
            "#{'%.5E' % heatpump_cap_flow_curve.maximumValueofx}\n"
    heatpump_eir_flow_curve = dx_units[0].energyInputRatioFunctionofFlowFractionCurve.to_CurveQuadratic.get
    heatpump_res_file_output_text +=
        "#{heatpump_curve_names[3]},quadratic,#{'%.5E' % heatpump_eir_flow_curve.coefficient1Constant},#{'%.5E' % heatpump_eir_flow_curve.coefficient2x}," +
            "#{'%.5E' % heatpump_eir_flow_curve.coefficient3xPOW2},#{'%.5E' % heatpump_eir_flow_curve.minimumValueofx},#{'%.5E' % heatpump_eir_flow_curve.maximumValueofx}\n"
    heatpump_plfvsplr__curve = dx_units[0].partLoadFractionCorrelationCurve.to_CurveCubic.get
    heatpump_res_file_output_text +=
        "#{heatpump_curve_names[4]},cubic,#{'%.5E' % heatpump_plfvsplr__curve.coefficient1Constant},#{'%.5E' % heatpump_plfvsplr__curve.coefficient2x}," +
            "#{'%.5E' % heatpump_plfvsplr__curve.coefficient3xPOW2},#{'%.5E' % heatpump_plfvsplr__curve.coefficient4xPOW3}," +
            "#{'%.5E' % heatpump_plfvsplr__curve.minimumValueofx},#{'%.5E' % heatpump_plfvsplr__curve.maximumValueofx}\n"

    # Write test results file.
    test_result_file = File.join(@test_results_folder, "#{template.downcase}_compliance_heatpump_curves_test_results.csv")

    File.open(test_result_file, 'w') { |f| f.write(heatpump_res_file_output_text.chomp) }

    # Test that the values are correct by doing a file compare.
    expected_result_file = File.join(@expected_results_folder, "#{template.downcase}_compliance_heatpump_curves_expected_results.csv")

    # Check if test results match expected.
    msg = "Heat pump performance curve coeffs test results do not match what is expected in test"
    file_compare(expected_results_file: expected_result_file, test_results_file: test_result_file, msg: msg)
  end
end
