class ACM179dASHRAE9012007
  def self.__model_get_primary_building_type(model)

    building_types = {}

    building = model.getBuilding
    building_level_bt = nil
    if building.standardsBuildingType.is_initialized
      building_level_bt =building.standardsBuildingType.get
      OpenStudio.logFree(OpenStudio::Debug, "openstudio.standards.Model", "found Building level standardsBuildingType = #{building_level_bt}")
    end


    model.getSpaceTypes.sort.each do |space_type|
      # populate hash of building types
      if !space_type.standardsBuildingType.is_initialized
        next
      end
      bldg_type = space_type.standardsBuildingType.get
      OpenStudio.logFree(OpenStudio::Debug, "openstudio.standards.Model", "found building type for #{space_type.name} = #{bldg_type}")
      if building_types.key?(bldg_type)
        building_types[bldg_type] += space_type.floorArea
      else
        building_types[bldg_type] = space_type.floorArea
      end
    end

    if building_types.empty?
      if building_level_bt.nil?
        OpenStudio.logFree(OpenStudio::Error, "openstudio.standards.Model", "Cannot identify a single building type in model, none of your #{model.getSpaceTypes.size} SpaceTypes have a standardsBuildingType assigned and neither does the Building")
        raise "No Primary Building Type found"
      else
        OpenStudio.logFree(OpenStudio::Info, "openstudio.standards.Model", "No area determination based on space types found, using Building level standardsBuildingType = #{building_level_bt}")
        return building_level_bt
      end
    end

    space_type_level_bt = building_types.max_by{|k, v| v}.first
    if !building_level_bt.nil?
      if building_level_bt != space_type_level_bt
        OpenStudio.logFree(OpenStudio::Warn, "openstudio.standards.Model", "The Building has standardsBuildingType #{building_level_bt} while the area determination based on space types has #{space_type_level_bt}. Preferring the Space Type one.")
      end
      return space_type_level_bt
    end

    OpenStudio.logFree(OpenStudio::Info, "openstudio.standards.Model", "Building doesn't have a standardsBuildingType #{building_level_bt}, using the area determination based on space types = #{space_type_level_bt}.")
    return space_type_level_bt
  end

  def model_get_primary_building_type(model)
    # Maybe this is a premature optimization, but memoize the computation
    @primary_building_types_memoized ||= Hash.new do |h, key|
      h[key] = ACM179dASHRAE9012007.__model_get_primary_building_type(model)
    end
    @primary_building_types_memoized[model]
  end

  # Patched to prefer the space area method above instead of just relying on
  # Building object
  def model_get_building_properties(model, remap_office = true)
    # get climate zone from model
    climate_zone = model_standards_climate_zone(model)

    # get building type from model
    building_type = model_get_primary_building_type(model)

    # map office building type to small medium or large
    if building_type == 'Office' && remap_office
      open_studio_area = model.getBuilding.floorArea
      building_type = model_remap_office(model, open_studio_area)
    end

    # get standards template
    if model.getBuilding.standardsTemplate.is_initialized
      standards_template = model.getBuilding.standardsTemplate.get
    end

    results = {}
    results['climate_zone'] = climate_zone
    results['building_type'] = building_type
    results['standards_template'] = standards_template

    return results
  end
end
