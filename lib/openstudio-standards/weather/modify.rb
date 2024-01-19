# methods to modify model weather/location information
module OpenstudioStandards
  module Weather
    # @!group Weather

    # Set the model WeatherFile object from a parsed .epw file
    #
    # @param model [OpenStudio::Model::Model] OpenStudio model object
    # @param epw_file [OpenstudioStandards::Weather::EpwFile] parsed epw file object
    # @return [OpenStudio::Model::WeatherFile] OpenStudio WeatherFile object
    def self.model_set_weather_file(model, epw_file)
      weather_file = model.getWeatherFile
      weather_file.setCity(epw_file.city)
      weather_file.setStateProvinceRegion(epw_file.state)
      weather_file.setCountry(epw_file.country)
      weather_file.setDataSource(epw_file.data_type)
      weather_file.setWMONumber(epw_file.wmo.to_s)
      weather_file.setLatitude(epw_file.lat)
      weather_file.setLongitude(epw_file.lon)
      weather_file.setTimeZone(epw_file.gmt)
      weather_file.setElevation(epw_file.elevation)
      if model.version < OpenStudio::VersionString.new('3.0.0')
        weather_file.setString(10, "file:///#{epw_file.filename}")
      else
        weather_file.setString(10, epw_file.filename.to_s)
      end

      return weather_file
    end

    # Set the model Site object from a parsed .epw file
    #
    # @param model [OpenStudio::Model::Model] OpenStudio model object
    # @param epw_file [OpenstudioStandards::Weather::EpwFile] parsed epw file object
    # @return [OpenStudio::Model::Site] OpenStudio Site object
    def self.model_set_site_information(model, epw_file)
      weather_name = "#{epw_file.city}_#{epw_file.state}_#{epw_file.country}"
      site = model.getSite
      site.setName(weather_name)
      site.setLatitude(epw_file.lat)
      site.setLongitude(epw_file.lon)
      site.setTimeZone(epw_file.gmt)
      site.setElevation(epw_file.elevation)
      OpenStudio.logFree(OpenStudio::Info, 'openstudio.standards.Weather.modify', "Set Site information to #{weather_name}.")

      return site
    end

    # Set the model SiteWaterMainsTemperature object from a parsed .stat file
    #
    # @param model [OpenStudio::Model::Model] OpenStudio model object
    # @param stat_file [OpenstudioStandards::Weather::StatFile] parsed .stat file object
    # @return [OpenStudio::Model::SiteWaterMainsTemperature] OpenStudio SiteWaterMainsTemperature object
    def self.model_set_site_water_mains_temperature(model, stat_file: nil)
      # get .stat file from model if none provided
      if stat_file.nil?
        weather_file_path = model.getWeatherFile.path.get.to_s
        stat_file = OpenstudioStandards::Weather::StatFile.load(weather_file_path.sub('.epw', '.stat'))
      end

      # set site water mains temperature
      water_temp = model.getSiteWaterMainsTemperature
      water_temp.setAnnualAverageOutdoorAirTemperature(stat_file.mean_dry_bulb)
      water_temp.setMaximumDifferenceInMonthlyAverageOutdoorAirTemperatures(stat_file.delta_dry_bulb)
      OpenStudio.logFree(OpenStudio::Info, 'openstudio.standards.Weather.modify', "Site Water Mains Temperature mean OA dry bulb is #{stat_file.mean_dry_bulb}. Delta OA dry bulb is #{stat_file.delta_dry_bulb}.")

      return water_temp
    end

    # Set the SiteGroundTemperatureShallow object based on undisturbed ground temperatures at 0.5m depth from the .stat file
    #
    # @param model [OpenStudio::Model::Model] OpenStudio model object
    # @param stat_file [OpenstudioStandards::Weather::StatFile] parsed .stat file object
    # @return [OpenStudio::Model::SiteGroundTemperatureShallow] OpenStudio SiteGroundTemperatureShallow object
    def self.model_set_undisturbed_ground_temperature_shallow(model, stat_file: nil)
      # get .stat file from model if none provided
      if stat_file.nil?
        weather_file_path = model.getWeatherFile.path.get.to_s
        stat_file = OpenstudioStandards::Weather::StatFile.load(weather_file_path.sub('.epw', '.stat'))
      end

      # set ground temperature shallow values based on .stat file
      ground_temperature_shallow = OpenStudio::Model::SiteGroundTemperatureShallow.new(model)
      ground_temperature_shallow.setJanuarySurfaceGroundTemperature(stat_file.monthly_undis_ground_temps_0p5m[0])
      ground_temperature_shallow.setFebruarySurfaceGroundTemperature(stat_file.monthly_undis_ground_temps_0p5m[1])
      ground_temperature_shallow.setMarchSurfaceGroundTemperature(stat_file.monthly_undis_ground_temps_0p5m[2])
      ground_temperature_shallow.setAprilSurfaceGroundTemperature(stat_file.monthly_undis_ground_temps_0p5m[3])
      ground_temperature_shallow.setMaySurfaceGroundTemperature(stat_file.monthly_undis_ground_temps_0p5m[4])
      ground_temperature_shallow.setJuneSurfaceGroundTemperature(stat_file.monthly_undis_ground_temps_0p5m[5])
      ground_temperature_shallow.setJulySurfaceGroundTemperature(stat_file.monthly_undis_ground_temps_0p5m[6])
      ground_temperature_shallow.setAugustSurfaceGroundTemperature(stat_file.monthly_undis_ground_temps_0p5m[7])
      ground_temperature_shallow.setSeptemberSurfaceGroundTemperature(stat_file.monthly_undis_ground_temps_0p5m[8])
      ground_temperature_shallow.setOctoberSurfaceGroundTemperature(stat_file.monthly_undis_ground_temps_0p5m[9])
      ground_temperature_shallow.setNovemberSurfaceGroundTemperature(stat_file.monthly_undis_ground_temps_0p5m[10])
      ground_temperature_shallow.setDecemberSurfaceGroundTemperature(stat_file.monthly_undis_ground_temps_0p5m[11])

      return ground_temperature_shallow
    end

    # Set the SiteGroundTemperatureDeep object based on undisturbed ground temperatures at 4.0m depth from the .stat file
    #
    # @param model [OpenStudio::Model::Model] OpenStudio model object
    # @param stat_file [OpenstudioStandards::Weather::StatFile] parsed .stat file object
    # @return [OpenStudio::Model::SiteGroundTemperatureDeep] OpenStudio SiteGroundTemperatureDeep object
    def self.model_set_undisturbed_ground_temperature_deep(model, stat_file: nil)
      # get .stat file from model if none provided
      if stat_file.nil?
        weather_file_path = model.getWeatherFile.path.get.to_s
        stat_file = OpenstudioStandards::Weather::StatFile.load(weather_file_path.sub('.epw', '.stat'))
      end

      # set ground temperature deep values based on .stat file
      ground_temperature_deep = OpenStudio::Model::SiteGroundTemperatureDeep.new(model)
      ground_temperature_deep.setJanuaryDeepGroundTemperature(stat_file.monthly_undis_ground_temps_4p0m[0])
      ground_temperature_deep.setFebruaryDeepGroundTemperature(stat_file.monthly_undis_ground_temps_4p0m[1])
      ground_temperature_deep.setMarchDeepGroundTemperature(stat_file.monthly_undis_ground_temps_4p0m[2])
      ground_temperature_deep.setAprilDeepGroundTemperature(stat_file.monthly_undis_ground_temps_4p0m[3])
      ground_temperature_deep.setMayDeepGroundTemperature(stat_file.monthly_undis_ground_temps_4p0m[4])
      ground_temperature_deep.setJuneDeepGroundTemperature(stat_file.monthly_undis_ground_temps_4p0m[5])
      ground_temperature_deep.setJulyDeepGroundTemperature(stat_file.monthly_undis_ground_temps_4p0m[6])
      ground_temperature_deep.setAugustDeepGroundTemperature(stat_file.monthly_undis_ground_temps_4p0m[7])
      ground_temperature_deep.setSeptemberDeepGroundTemperature(stat_file.monthly_undis_ground_temps_4p0m[8])
      ground_temperature_deep.setOctoberDeepGroundTemperature(stat_file.monthly_undis_ground_temps_4p0m[9])
      ground_temperature_deep.setNovemberDeepGroundTemperature(stat_file.monthly_undis_ground_temps_4p0m[10])
      ground_temperature_deep.setDecemberDeepGroundTemperature(stat_file.monthly_undis_ground_temps_4p0m[11])

      return ground_temperature_deep
    end

    # Sets the model ClimateZone object
    # Clears out any climate zones previously added to the model.
    #
    # @param model [OpenStudio::Model::Model] OpenStudio model object
    # @param climate_zone [String] full climate zone string, e.g. "ASHRAE 169-2013-1A"
    # @return [Boolean] returns true if successful, false if not
    def self.model_set_climate_zone(model, climate_zone)
      # Remove previous climate zones from the model
      climate_zones = model.getClimateZones
      climate_zones.clear

      # Split the string into the correct institution and value
      if climate_zone.include?('CEC')
        climate_zones.setClimateZone('CEC', climate_zone.gsub('CEC T24-CEC', '').gsub('T24-CEC', ''))
        OpenStudio.logFree(OpenStudio::Info, 'openstudio.standards.Weather.modify', "Setting Climate Zone to #{climate_zones.getClimateZones('CEC').first.value}")
      elsif climate_zone.include?('ASHRAE')
        climate_zones.setClimateZone('ASHRAE', climate_zone.gsub(/ASHRAE .*-.*-/, ''))
        OpenStudio.logFree(OpenStudio::Info, 'openstudio.standards.Weather.modify', "Setting Climate Zone to #{climate_zones.getClimateZones('ASHRAE').first.value}")
      else
        OpenStudio.logFree(OpenStudio::Error, 'openstudio.standards.Weather.modify', "Unknown climate zone #{climate_zone}. Climate Zone will not be set.")
      end

      return true
    end

    # Set the model DesignDays from a .ddy file
    #
    # @param model [OpenStudio::Model::Model] OpenStudio model object
    # @param ddy_file_path [String] path to .ddy file
    # @param ddy_list [Array<String>] list of regular expressions matching design day names to import.
    #   Default is set to nil, which will import all design day objects.
    # @return [Boolean] returns true if successful, false if not
    def self.model_set_design_days(model, ddy_file_path: nil, ddy_list: nil)
      # remove any existing design day objects
      model.getDesignDays.each(&:remove)

      # get .ddy file from model if none provided
      if ddy_file_path.nil?
        weather_file_path = model.getWeatherFile.path.get.to_s
        ddy_file_path = weather_file_path.sub('.epw', '.ddy')
      end

      unless File.file?(ddy_file_path)
        OpenStudio.logFree(OpenStudio::Error, 'openstudio.standards.Weather.modify', "Could not find design day file: #{ddy_file_path}")
        return false
      end

      ddy_model = OpenStudio::EnergyPlus.loadAndTranslateIdf(ddy_file_path).get

      # warn if no design days in file
      if ddy_model.getDesignDays.size.zero?
        OpenStudio.logFree(OpenStudio::Warn, 'openstudio.standards.Weather.modify', 'No design days were found in the design day file.')
        return false
      end

      objs_to_add = []
      ddy_model.getDesignDays.sort.each do |d|
        if ddy_list.nil? || ddy_list.empty?
          # add all design days
          ddy_model.getDesignDays.each { |dd| objs_to_add << dd }
        else
          # add design days that match ddy_list regexes
          ddy_list.each do |ddy_name_regex|
            if d.name.get.to_s =~ ddy_name_regex
              objs_to_add << d
            end
          end
        end
      end

      objs_to_add.each do |o|
        OpenStudio.logFree(OpenStudio::Info, 'openstudio.standards.Weather.modify', "Adding design day #{o.name.get}.")
        model.addObject(o)
      end
    end

    # Set the model weather file, site, ground temperatures, and design days based on a weather file or climate zone
    # At least one of the weather_file_path or climate_zone must be specified.
    #
    # @param model [OpenStudio::Model::Model] OpenStudio model object
    # @param weather_file_path [String] absolute path to the .epw file. For weather files included in OpenStudio-standards, can be found using OpenstudioStandards::Weather::get_standards_weather_file_path(weather_file_name)
    # @param climate_zone [String] full climate zone string, e.g. 'ASHRAE 169-2013-4A'
    # @param ddy_list [Array] list of regexes to match design day names to add to model, e.g. /Clg 1. Condns DB=>MWB/
    # @return [Boolean] returns true if successful, false if not
    def self.model_set_building_location(model, weather_file_path: nil, climate_zone: nil, ddy_list: nil)
      # check that either weather_file_path or climate_zone provided
      if weather_file_path.nil? && climate_zone.nil?
        OpenStudio.logFree(OpenStudio::Warn, 'openstudio.standards.Weather.modify', 'model_set_building_location must be called with either the weather_file_path or climate_zone argument specified.')
        return false
      end

      # load weather file if specified
      if !weather_file_path.nil?
        epw_file = OpenstudioStandards::Weather::Epw.load(weather_file_path)
      else
        # look up the standard weather file for the climate zone
        weather_file_path = OpenstudioStandards::Weather.climate_zone_representative_weather_file_path(climate_zone)
        epw_file = OpenstudioStandards::Weather::Epw.load(weather_file_path)
      end

      # set weather file and site information
      OpenstudioStandards::Weather.model_set_weather_file(model, epw_file)
      OpenstudioStandards::Weather.model_set_site_information(model, epw_file)

      # set site water mains and undisturbed ground tempreatures from the .stat file
      stat_file_climate_zone = nil
      stat_file_path = weather_file_path.gsub('.epw', '.stat')
      if File.file?(stat_file_path)
        stat_file = OpenstudioStandards::Weather::StatFile.load(stat_file_path)
        OpenstudioStandards::Weather.model_set_site_water_mains_temperature(model, stat_file: stat_file)
        OpenstudioStandards::Weather.model_set_undisturbed_ground_temperature_shallow(model, stat_file: stat_file)
        OpenstudioStandards::Weather.model_set_undisturbed_ground_temperature_deep(model, stat_file: stat_file)
        stat_file_climate_zone = stat_file.climate_zone
      else
        OpenStudio.logFree(OpenStudio::Warn, 'openstudio.standards.Weather.modify', "Could not find .stat file at #{stat_file_path}. Unable to set site water mains temperature and undisturbed ground temperatures.")
      end

      # set design days from the .ddy file
      ddy_file_path = weather_file_path.gsub('.epw', '.ddy')
      OpenstudioStandards::Weather.model_set_design_days(model, ddy_file_path: ddy_file_path, ddy_list: ddy_list)

      # set the climate zone
      if climate_zone.nil? || climate_zone.empty?
        # attempt to use the climate zone from the stat file
        if stat_file_climate_zone.nil?
          OpenStudio.logFree(OpenStudio::Warn, 'openstudio.standards.Weather.modify', 'Could not determine and set the climate zone.')
        else
          climate_zone = "ASHRAE 169-2013-#{stat_file_climate_zone}"
          OpenstudioStandards::Weather.model_set_climate_zone(model, climate_zone)
        end
      else
        OpenstudioStandards::Weather.model_set_climate_zone(model, climate_zone)
      end
    end
  end
end
