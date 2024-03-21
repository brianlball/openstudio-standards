module OpenstudioStandards
  # The Constructions module provides methods create, modify, and get information about model Constructions
  module Constructions
    # @!group Modify
    # Methods to modify Constructions

    # add new material layer to a construction
    #
    # @param construction [OpenStudio::Model::Construction] OpenStudio Construction object
    # @param layer_index [Integer] the layer index, default is 0
    # @param name [String] name of the new material layer
    # @param roughness [String] surface roughness of the new material layer.
    #   Options are 'VeryRough', 'Rough', 'MediumRough', 'MediumSmooth', 'Smooth', and 'VerySmooth'
    # @param thickness [Double] thickness of the new material layer in meters
    # @param conductivity [Double] thermal conductivity of new material layer in W/m*K
    # @param density [Double] density of the new material layer in kg/m^3
    # @param specific_heat [Double] specific heat of the new material layer in J/kg*K
    # @param thermal_absorptance [Double] target thermal absorptance
    # @param solar_absorptance [Double] target solar absorptance
    # @param visible_absorptance [Double] target visible absorptance
    # @return [OpenStudio::Model::StandardOpaqueMaterial] The new material layer, a OpenStudio StandardOpaqueMaterial object
    def self.construction_add_new_opaque_material(construction,
                                                  layer_index: 0,
                                                  name: nil,
                                                  roughness: nil,
                                                  thickness: nil,
                                                  conductivity: nil,
                                                  density: nil,
                                                  specific_heat: nil,
                                                  thermal_absorptance: nil,
                                                  solar_absorptance: nil,
                                                  visible_absorptance: nil)

      # make new material
      new_material = OpenStudio::Model::StandardOpaqueMaterial.new(construction.model)
      if name.nil?
        new_material.setName("#{construction.name} New Material")
      else
        new_material.setName(name)
      end

      # set requested material properties
      new_material.setRoughness(roughness) unless roughness.nil?
      new_material.setThickness(thickness) unless thickness.nil?
      new_material.setConductivity(conductivity) unless conductivity.nil?
      new_material.setDensity(density) unless density.nil?
      new_material.setSpecificHeat(specific_heat) unless specific_heat.nil?
      new_material.setThermalAbsorptance(thermal_absorptance) unless thermal_absorptance.nil?
      new_material.setSolarAbsorptance(solar_absorptance) unless solar_absorptance.nil?
      new_material.setVisibleAbsorptance(visible_absorptance) unless visible_absorptance.nil?

      # add material to construction
      construction.insertLayer(layer_index, new_material)

      return new_material
    end

    # Find and set the insulation layer for a layered construction
    #
    # @param construction [OpenStudio::Model::Construction] OpenStudio Construction object
    # @return [OpenStudio::Model::OpaqueMaterial] OpenStudio OpaqueMaterial representing the insulation layer
    def self.construction_find_and_set_insulation_layer(construction)
      # skip and return the insulation layer if already set
      return construction.insulation.get if construction.insulation.is_initialized

      # loop through construction layers to find insulation layer
      min_conductance = 100.0
      insulation_material = nil
      construction.layers.each do |layer|
        # skip layers that aren't an OpaqueMaterial
        next unless layer.to_OpaqueMaterial.is_initialized

        material = layer.to_OpaqueMaterial.get
        material_conductance = OpenstudioStandards::Constructions::Materials.material_get_conductance(material)
        if material_conductance < min_conductance
          min_conductance = material_conductance
          insulation_material = material
        end
      end
      construction.setInsulation(insulation_material) unless insulation_material.nil?

      if construction.isOpaque && !construction.insulation.is_initialized
        OpenStudio.logFree(OpenStudio::Error, 'OpenstudioStandards::Constructions', "Unable to determine the insulation layer for construction #{construction.name.get}.")
        return nil
      end

      return construction.insulation.get
    end

    # Sets the heat transfer coefficient (U-value) of a construction to a specified value by modifying the thickness of the insulation layer.
    #
    # @param construction [OpenStudio::Model::Construction] OpenStudio Construction object
    # @param target_u_value_ip [Double] Target heat transfer coefficient (U-Value) (Btu/ft^2*hr*R)
    # @param insulation_layer_name [String] The insulation layer in this construction. If none provided, the method will attempt to determine the insulation layer.
    # @param intended_surface_type [String] Intended surface type, used for determining film coefficients.
    #   Valid choices:  'AtticFloor', 'AtticWall', 'AtticRoof', 'DemisingFloor', 'InteriorFloor', 'InteriorCeiling',
    #   'DemisingWall', 'InteriorWall', 'InteriorPartition', 'InteriorWindow', 'InteriorDoor', 'DemisingRoof',
    #   'ExteriorRoof', 'Skylight', 'TubularDaylightDome', 'TubularDaylightDiffuser', 'ExteriorFloor',
    #   'ExteriorWall', 'ExteriorWindow', 'ExteriorDoor', 'GlassDoor', 'OverheadDoor', 'GroundContactFloor',
    #   'GroundContactWall', 'GroundContactRoof'
    # @param target_includes_interior_film_coefficients [Boolean] If true, subtracts off standard interior film coefficients
    #   from the target heat transfer coefficient before modifying insulation thickness.
    # @param target_includes_exterior_film_coefficients [Boolean] If true, subtracts off standard exterior film coefficients
    #   from the target heat transfer coefficient before modifying insulation thickness.
    # @return [Boolean] returns true if successful, false if not
    def self.construction_set_u_value(construction, target_u_value_ip,
                                      insulation_layer_name: nil,
                                      intended_surface_type: 'ExteriorWall',
                                      target_includes_interior_film_coefficients: true,
                                      target_includes_exterior_film_coefficients: true)
      # Skip layer-by-layer fenestration constructions
      if construction.isFenestration
        OpenStudio.logFree(OpenStudio::Warn, 'OpenstudioStandards::Constructions', "Can only set the u-value of opaque constructions or simple glazing. #{construction.name} is not opaque or simple glazing.")
        return false
      end

      # Make sure an insulation layer was specified
      if insulation_layer_name.nil? && target_u_value_ip == 0.0
        # Do nothing if the construction already doesn't have an insulation layer
      elsif insulation_layer_name.nil?
        insulation_layer_name = OpenstudioStandards::Constructions.construction_find_and_set_insulation_layer(construction).name.get
      end

      # Remove the insulation layer if the specified U-value is zero.
      if target_u_value_ip == 0.0
        layer_index = 0
        construction.layers.each do |layer|
          break if layer.name.get == insulation_layer_name

          layer_index += 1
        end
        construction.eraseLayer(layer_index)
        return true
      end

      min_r_value_si = OpenstudioStandards::Constructions.film_coefficients_r_value(intended_surface_type, target_includes_interior_film_coefficients, target_includes_exterior_film_coefficients)
      max_u_value_si = 1.0 / min_r_value_si
      max_u_value_ip = OpenStudio.convert(max_u_value_si, 'W/m^2*K', 'Btu/ft^2*hr*R').get
      if target_u_value_ip >= max_u_value_ip
        target_u_value_ip = 1.0 / OpenStudio.convert(min_r_value_si + 0.001, 'm^2*K/W', 'ft^2*hr*R/Btu').get
        OpenStudio.logFree(OpenStudio::Warn, 'OpenstudioStandards::Constructions', "Requested U-value of #{target_u_value_ip} for #{construction.name} is greater than the sum of the inside and outside resistance, and the max U-value (6.636 SI) is used instead.")
      end

      # Convert the target U-value to SI
      target_r_value_ip = 1.0 / target_u_value_ip.to_f
      target_u_value_si = OpenStudio.convert(target_u_value_ip, 'Btu/ft^2*hr*R', 'W/m^2*K').get
      target_r_value_si = 1.0 / target_u_value_si

      OpenStudio.logFree(OpenStudio::Debug, 'OpenstudioStandards::Constructions', "Setting U-Value for #{construction.name} to #{target_u_value_si.round(3)} W/m^2*K or #{target_u_value_ip.round(3)} 'Btu/ft^2*hr*R', which is an R-value of #{target_r_value_si.round(3)} m^2*K/W or #{target_r_value_ip.round(3)} 'ft^2*hr*R/Btu'.")

      # Determine the R-value of the non-insulation layers
      other_layer_r_value_si = 0.0
      construction.layers.each do |layer|
        next if layer.to_OpaqueMaterial.empty?
        next if layer.name.get == insulation_layer_name

        other_layer_r_value_si += layer.to_OpaqueMaterial.get.thermalResistance
      end

      # Determine the R-value of the air films, if requested
      other_layer_r_value_si += OpenstudioStandards::Constructions.film_coefficients_r_value(intended_surface_type, target_includes_interior_film_coefficients, target_includes_exterior_film_coefficients)

      # Determine the difference between the desired R-value
      # and the R-value of the non-insulation layers and air films.
      # This is the desired R-value of the insulation.
      ins_r_value_si = target_r_value_si - other_layer_r_value_si

      # Set the R-value of the insulation layer
      construction.layers.each_with_index do |layer, l|
        next unless layer.name.get == insulation_layer_name

        # Remove insulation layer if requested R-value is lower than sum of non-insulation materials
        if ins_r_value_si <= 0.0
          OpenStudio.logFree(OpenStudio::Warn, 'OpenstudioStandards::Construction', "Requested U-value of #{target_u_value_ip} for #{construction.name} is too low given the other materials in the construction; insulation layer will be removed.")
          construction.eraseLayer(l)
          # Set the target R-value to the sum of other layers to make name match properties
          target_r_value_ip = OpenStudio.convert(other_layer_r_value_si, 'm^2*K/W', 'ft^2*hr*R/Btu').get
          break # Don't modify the insulation layer since it has been removed
        end

        # Modify the insulation layer
        ins_r_value_ip = OpenStudio.convert(ins_r_value_si, 'm^2*K/W', 'ft^2*h*R/Btu').get
        if layer.to_StandardOpaqueMaterial.is_initialized
          layer = layer.to_StandardOpaqueMaterial.get
          layer.setThickness(ins_r_value_si * layer.conductivity)
          layer.setName("#{layer.name} R-#{ins_r_value_ip.round(2)}")
          break # Stop looking for the insulation layer once found
        elsif layer.to_MasslessOpaqueMaterial.is_initialized
          layer = layer.to_MasslessOpaqueMaterial.get
          layer.setThermalResistance(ins_r_value_si)
          layer.setName("#{layer.name} R-#{ins_r_value_ip.round(2)}")
          break # Stop looking for the insulation layer once found
        elsif layer.to_AirGap.is_initialized
          layer = layer.to_AirGap.get
          target_thickness = ins_r_value_si * layer.thermalConductivity
          layer.setThickness(target_thickness)
          layer.setName("#{layer.name} R-#{ins_r_value_ip.round(2)}")
          break # Stop looking for the insulation layer once found
        end
      end

      # Modify the construction name
      construction.setName("#{construction.name} R-#{target_r_value_ip.round(2)}")

      return true
    end

    # set construction surface properties
    #
    # @param construction [OpenStudio::Model::Construction] OpenStudio Construction object
    # @param roughness [String] surface roughness
    # @param thermal_absorptance [Double] target thermal absorptance
    # @param solar_absorptance [Double] target solar absorptance
    # @param visible_absorptance [Double] target visible absorptance
    # @return [OpenStudio::Model::OpaqueMaterial] OpenStudio OpaqueMaterial object
    def self.construction_set_surface_properties(construction,
                                                 roughness: nil,
                                                 thermal_absorptance: nil,
                                                 solar_absorptance: nil,
                                                 visible_absorptance: nil)

      surface_material = construction.to_LayeredConstruction.get.getLayer(0)
      new_material = OpenstudioStandards::Constructions::Materials.opaque_material_set_surface_properties(surface_material,
                                                                                                          roughness: roughness,
                                                                                                          thermal_absorptance: thermal_absorptance,
                                                                                                          solar_absorptance: solar_absorptance,
                                                                                                          visible_absorptance: visible_absorptance)
      return new_material
    end
  end
end
