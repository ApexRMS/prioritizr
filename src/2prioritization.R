## prioritizr SyncroSim - Prioritization
##
## Written by Carina Rauen Firkowski
##
## This script loads a prioritizr problem formulation and solves it. It requires
## that the model stage "Problem formulation" be run first.



# Solve and save solution ------------------------------------------------------

progressBar(type = "message", message = "Solving problem")

# Run solver
scenarioSolution <- solve(scenarioProblem)

# Save raster
if(class(scenarioSolution) != "data.frame"){
  solutionFilename <- file.path(paste0(dataDir, "\\solutionRaster.tif"))
  writeRaster(scenarioSolution, filename = solutionFilename,
              overwrite = TRUE)
  # Save file path to datasheet
  solutionRasterOutput <- data.frame(solution = solutionFilename)
  saveDatasheet(ssimObject = myScenario, 
                data = solutionRasterOutput, 
                name = "prioritizr_solutionRasterOutput")
}
# Save tabular output
if(class(scenarioSolution) == "data.frame"){
  
  # Open datasheet
  solutionTabularOutput <- datasheet(myScenario,
                                     name = "prioritizr_solutionTabularOutput")
  
  # Rename variable names for consistency with prioritizr R
  names(solutionTabularOutput)[
    names(solutionTabularOutput) == "solution1"] <- "solution_1"
  
  # Combine result and datasheet
  solutionTabularOutputMerge <- merge(solutionTabularOutput, 
                                      scenarioSolution, 
                                      all = TRUE)
  # Add missing columns
  solutionTabularOutput <- data.frame(
    displayName = NA,
    id = solutionTabularOutputMerge$id,
    cost = solutionTabularOutputMerge$cost,
    status = NA,
    xloc = NA,
    yloc = NA,
    solution_1 = solutionTabularOutputMerge$solution_1)
  
  # Add PU display name
  solutionTabularOutput <- merge(solutionTabularOutput,
                                 sim_pu[,1:2], by = "id")
  solutionTabularOutput$displayName <- solutionTabularOutput$Name
  solutionTabularOutput <- solutionTabularOutput[,-(dim(solutionTabularOutput)[2])]
  
  # Add optional columns
  if("status" %in% colnames(solutionTabularOutputMerge)){
    solutionTabularOutput$status <- solutionTabularOutputMerge$status
  }
  if("xloc" %in% colnames(solutionTabularOutputMerge)){
    solutionTabularOutput$xloc <- solutionTabularOutputMerge$xloc
  }
  if("yloc" %in% colnames(solutionTabularOutputMerge)){
    solutionTabularOutput$yloc <- solutionTabularOutputMerge$yloc
  }
  
  # Remove rows where all columns are NA
  solutionTabularOutput <- solutionTabularOutput[
   rowSums(is.na(solutionTabularOutput)) != ncol(solutionTabularOutput), ]
  
  # Rename column
  names(solutionTabularOutput)[
    names(solutionTabularOutput) == "solution_1"] <- "solution1"
  
  # Save solution tabular results
  saveDatasheet(ssimObject = myScenario, 
                data = solutionTabularOutput, 
                name = "prioritizr_solutionTabularOutput")
  
  # Spatial data for visualization
  if(dim(problemSpatialDatasheet)[1] != 0){
    if(!is.na(problemSpatialDatasheet$x)){
      pu_vis <- rast(file.path(problemSpatialDatasheet$x))
      puVis <- TRUE
    }
  } else {
    puVis <- FALSE
  }
  
  # Save solution spatial visualization
  if(isTRUE(puVis)){
    
    # Reclass table between planning unit id & solution
    reclassTable <- matrix(c(scenarioSolution$id,
                             scenarioSolution$solution_1),
                           byrow = FALSE, ncol = 2)
    # Reclassify raster
    solutionVis <- classify(pu_vis, reclassTable)
    
    # Define file path
    solutionFilepath <- paste0(dataPath, "\\prioritizr_solutionRasterOutput")
    solutionFilename <- file.path(paste0(solutionFilepath,
                                         "\\solutionRaster.tif"))
    # Create directory if it does not exist
    ifelse(!dir.exists(file.path(solutionFilepath)), 
           dir.create(file.path(solutionFilepath)), FALSE)
    writeRaster(solutionVis, filename = solutionFilename, overwrite = TRUE)
    # Save file path to datasheet
    solutionRasterOutput <- data.frame(solution = solutionFilename)
    saveDatasheet(ssimObject = myScenario, 
                  data = solutionRasterOutput, 
                  name = "prioritizr_solutionRasterOutput")
  }
}


# Save inputs ------------------------------------------------------------------

# Load datasheets
inputDatasheet <- datasheet(myScenario,
                            name = "prioritizr_inputData")
optionsDatasheet <- datasheet(myScenario,
                            name = "prioritizr_preprocessOptions")

# Check which inputs need mapping
mapInputsDatasheet <- datasheet(myScenario,
                                name = "prioritizr_mapInputs")

# Enter if statement if any input needs mapping
if(dim(mapInputsDatasheet)[1] !=0 & any(mapInputsDatasheet[1,], na.rm = TRUE)){
  
  # For spatial data format
  if(problemFormatDatasheet$dataType == "Spatial"){
    
    ## Planning units -------------------------------------------
    
    if(isTRUE(mapInputsDatasheet$planningUnits)){
      
      # Get file path
      puRasterOutput <- data.frame(pu = problemSpatialDatasheet$x)
      
      # Save datasheet
      saveDatasheet(ssimObject = myScenario, 
                    data = puRasterOutput, 
                    name = "prioritizr_puRasterOutput")
    }
    
    ## Features -------------------------------------------------
    
    if(isTRUE(mapInputsDatasheet$features)){
      
      # Define folder path
      featureVisFilepath <- paste0(dataPath, "\\prioritizr_featureRasterOutput")
      
      # Create directory if it does not exist
      ifelse(!dir.exists(file.path(featureVisFilepath)), 
             dir.create(file.path(featureVisFilepath)), FALSE)
      
      # Read datasheet
      featureRasterOutputDatasheet <- data.frame(projectFeaturesId = as.character(),
                                                 feature = as.character())
      
      # Loop across feature variables
      for(j in 1:length(featuresDatasheet$variableName)){
        
        # Get feature ID
        featureID <- featuresDatasheet$featureID[j]
        
        # Reclassify raster
        rasterVis <- sim_features[[j]]
        #plot(rasterVis)    
        
        # Define file path
        rasterVisFilename <- file.path(paste0(
          featureVisFilepath, paste0("\\feature", featureID, ".tif")))
        
        # Save file
        writeRaster(rasterVis, filename = rasterVisFilename, overwrite = TRUE)
        
        # Add file path to datasheet
        featureRasterOutputDatasheet[j,1] <- featuresDatasheet$Name[j] 
        featureRasterOutputDatasheet[j,2] <- rasterVisFilename 
        
      }
      
      # Save datasheet
      saveDatasheet(ssimObject = myScenario, 
                    data = featureRasterOutputDatasheet, 
                    name = "prioritizr_featureRasterOutput")
    }
    
    ## Other spatial inputs -------------------------------------
    
    # NOTE: Code will break if more inputs are added to the list or if the order
    #       is changed. The order of inputs should be the same across 
    #       "inputRasterOutput", "candidateSpatialInputs", and 
    #       "mapInputsDatasheet".
    
    # Empty data frame for input raster file paths
    inputRasterOutput <- data.frame(linearConstraintInput = as.character(),
                                    lockedInInput = as.character(),
                                    lockedOutInput = as.character(),
                                    linearPenaltyInput = as.character())
    
    # Combine datasheets into list
    candidateSpatialInputs <- list(linearSpatialDatasheet, 
                                   lockedInSpatialDatasheet,
                                   lockedOutSpatialDatasheet)
    
    # For each of other spatial inputs in mapInputsDatasheet (i.e., columns 3-5)
    # NOTE: The indices/IDs are shifted down by 2 (i.e., starting at 3) because 
    #       mapInputsDatasheet has two other inputs that are not used here.
    for(inputID in 3:5){
      
      # If map input is set to TRUE
      if(isTRUE(mapInputsDatasheet[,inputID])){
        
        # If spatial data was provided
        if(dim(candidateSpatialInputs[[inputID-2]])[1] != 0){
          # Add file path to datasheet
          inputRasterOutput[1, inputID-2] <- 
            candidateSpatialInputs[[inputID-2]][1,1] 
        } else {
          # NOTE: This warning could be improved to return exactly which input
          #       has triggered it.
          updateRunLog("Output options to map inputs were set but no maps provided for one
          or more inputs. Therefore, the output options setting for those inputs were ignored.",
                       type = "warning")
        }
      }
    }
    
    ## Linear penalty input -------------------------------------
    
    # Define folder path
    inputVisFilepath <- paste0(dataPath, "\\prioritizr_inputRasterOutput")
    
    # Create directory if it does not exist
    ifelse(!dir.exists(file.path(inputVisFilepath)), 
           dir.create(file.path(inputVisFilepath)), FALSE)
    
    if(isTRUE(mapInputsDatasheet[,6])){
      if(dim(linearDataDatasheet)[1] != 0){
        
        # Reclass table
        reclassTable <- as.matrix(linearDataDatasheet)
        
        # Reclassify raster
        rasterVis <- classify(pu_vis, reclassTable)
        
        # Define file path
        rasterVisFilename <- file.path(paste0(inputVisFilepath,
                                              paste0("\\input4.tif")))
        
        # Save file
        writeRaster(rasterVis, filename = rasterVisFilename, overwrite = TRUE)
        
        # Add file path to datasheet
        inputRasterOutput[1,4] <- rasterVisFilename 
      } else {
        updateRunLog("Output options to map inputs were set but no maps provided for one 
        or more inputs. Therefore, the output options setting for those inputs were ignored.",
                     type = "warning")
      }
    }
    
    # Save datasheet
    saveDatasheet(ssimObject = myScenario, 
                  data = inputRasterOutput, 
                  name = "prioritizr_inputRasterOutput")
  
  }
  
  # For tabular data format
  if(problemFormatDatasheet$dataType == "Tabular"){
    if(isTRUE(puVis)){
      
      ## Planning units -------------------------------------------
      
      if(isTRUE(mapInputsDatasheet$planningUnits)){
        
        # Get file path
        puRasterOutput <- data.frame(pu = problemSpatialDatasheet$x)
        
        # Save datasheet
        saveDatasheet(ssimObject = myScenario, 
                      data = puRasterOutput, 
                      name = "prioritizr_puRasterOutput")
      }
      
      ## Features ----------------------------------------------------
      
      if(isTRUE(mapInputsDatasheet$features)){
        
        # Define folder path
        featureVisFilepath <- paste0(dataPath, "\\prioritizr_featureRasterOutput")
        
        # Create directory if it does not exist
        ifelse(!dir.exists(file.path(featureVisFilepath)), 
               dir.create(file.path(featureVisFilepath)), FALSE)
        
        # Read data
        inputData <- read.csv(
          inputDatasheet$tabularProblem, header = TRUE
        )

        # Read datasheet
        featureRasterOutputDatasheet <- data.frame(
          projectFeaturesId = as.character(),
          feature = as.character())
        
        # Loop across feature variables
        for(j in 1:length(featuresDatasheet$variableName)){
          
          # Get feature ID
          featureID <- featuresDatasheet$featureID[j]
          featureName <- featuresDatasheet$variableName[j]
          
          # If input data was scaled and/or inverting, map original values.
          # Otherwise, use rij matrix.
          if (isTRUE((optionsDatasheet$scaleData)) | 
                !is.na(optionsDatasheet$invertData)) {

                  # Build reclass table of planning unit ID to value
                  reclassTable <- as.matrix(
                    cbind(inputData$id, inputData[,featureName])
                    )
          } else {
            # Subset rij table to get reclass table of planning unit ID to value
            reclassTable <- as.matrix(rij[rij$species == featureID,c(1,3)])
          }
            
          # Reclassify raster
          rasterVis <- classify(pu_vis, reclassTable)
          #plot(rasterVis)  

          # Define file path
          rasterVisFilename <- file.path(paste0(
            featureVisFilepath, paste0("\\feature", featureID, ".tif")))
          
          # Save file
          writeRaster(rasterVis, filename = rasterVisFilename, overwrite = TRUE)
          
          # Add file path to datasheet
          featureRasterOutputDatasheet[j,1] <- featuresDatasheet$Name[j] 
          featureRasterOutputDatasheet[j,2] <- rasterVisFilename 
          
        }
        
        # Save datasheet
        saveDatasheet(ssimObject = myScenario, 
                      data = featureRasterOutputDatasheet, 
                      name = "prioritizr_featureRasterOutput")
        
      }
      
      ## Other tabular inputs ----------------------------------------------------
      
      # Define folder path
      inputVisFilepath <- paste0(dataPath, "\\prioritizr_inputRasterOutput")
      
      # Create directory if it does not exist
      ifelse(!dir.exists(file.path(inputVisFilepath)), 
             dir.create(file.path(inputVisFilepath)), FALSE)
      
      # Empty data frame for input raster file paths
      inputRasterOutput <- data.frame(linearConstraintInput = as.character(),
                                      lockedInInput = as.character(),
                                      lockedOutInput = as.character(),
                                      linearPenaltyInput = as.character())
      
      # Check for which tabular inputs to generate raster files
      candidateInputs <- list(linearTabularDatasheet, 
                              lockedInTabularDatasheet,
                              lockedOutTabularDatasheet,
                              linearDataDatasheet)
      
      # For each of other inputs in mapInputsDatasheet (i.e., columns 3-6)
      # NOTE: The indices/IDs are shifted down by 2 (i.e., starting at 3) because 
      #       mapInputsDatasheet has two other inputs that are not used here.
      for(inputID in 3:6){
        
        # If map input is set to TRUE
        if(isTRUE(mapInputsDatasheet[,inputID])){
          
          if(dim(candidateInputs[[inputID-2]])[1] != 0){
            
            # Reclass table
            reclassTable <- as.matrix(candidateInputs[[inputID-2]])
            
            # Reclassify raster
            rasterVis <- classify(pu_vis, reclassTable)
            #plot(rasterVis)
            
            # Define file path
            rasterVisFilename <- file.path(paste0(
              inputVisFilepath, paste0("\\input", inputID-2, ".tif")))
            
            # Save file
            writeRaster(rasterVis, filename = rasterVisFilename, overwrite = TRUE)
            
            # Add file path to datasheet
            inputRasterOutput[1,inputID-2] <- rasterVisFilename 
          } else {
            # NOTE: This warning could be improved to return exactly which input
            #       triggered it.
    updateRunLog("Output options to map inputs were set but no data provided for one
    or more inputs. Therefore, the output options setting for those inputs were ignored.",
                         type = "warning")
          }
        }
        
        if(inputID == 6 & dim(inputRasterOutput)[1] != 0){
          # Save datasheet
          saveDatasheet(ssimObject = myScenario, 
                        data = inputRasterOutput, 
                        name = "prioritizr_inputRasterOutput")
        }
      }
    } else {
    updateRunLog("Output options to map inputs were set for a tabular problem 
    formulation but no spatial planning unit raster was provided. Therefore, the 
    output options to map inputs were ignored.",
                   type = "warning")
    } 
  }
}


