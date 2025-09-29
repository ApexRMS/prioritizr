## prioritizr SyncroSim - Evaluate importance
##
## Written by Carina Rauen Firkowski
##
## This script loads a prioritizr problem formulation and solution and evaluates
## the relative importance of the selected planning units in the solution. It 
## requires that model stages "Problem formulation" and "Prioritization" be run
## first.



# Open datasheets --------------------------------------------------------------

progressBar(type = "message", message = "Calculating importance scores for the solution")

importanceDatasheet <- datasheet(myScenario,
                                 name = "prioritizr_evaluateImportance")



# Rename variable names for consistency with prioritizr R ----------------------

names(importanceDatasheet) <- c("eval_replacement_importance",
                                "eval_ferrier_importance", 
                                "eval_rare_richness_importance")



# Validation -------------------------------------------------------------------

# If datasheet is not empty, set NA values to FALSE 
# If datasheet is empty, set all columns to FALSE
if(dim(importanceDatasheet)[1] != 0){
  importanceDatasheet[,is.na(importanceDatasheet)] <- FALSE
} else {
  importanceDatasheet <- data.frame(eval_replacement_importance = FALSE,
                                    eval_ferrier_importance = FALSE,
                                    eval_rare_richness_importance = FALSE)
}



# Evaluate importance ----------------------------------------------------------

# Determine if there is spatial data for visualization
if(dim(problemSpatialDatasheet)[1] != 0){
  if(!is.na(problemSpatialDatasheet$x)){
    pu_vis <- rast(file.path(problemSpatialDatasheet$x))
    crs(pu_vis) <- NA
    puVis <- TRUE
  }
} else {
  puVis <- FALSE
}

# Calculate replacement cost scores
if(isTRUE(importanceDatasheet$eval_replacement_importance) &
   sum(scenarioSolution$solution_1) != 0){
  if(class(scenarioSolution) != "data.frame"){
    
    replacementImportance <- scenarioProblem %>%
      eval_replacement_importance(scenarioSolution)
    
    # Save raster
    replacementFilename <- file.path(paste0(dataDir, "\\replacementRaster.tif"))
    writeRaster(replacementImportance, 
                filename = replacementFilename,
                overwrite = TRUE)
    
    # Save file path to datasheet
    replacementSpatialOutput <- data.frame(replacement = replacementFilename)
    saveDatasheet(ssimObject = myScenario, 
                  data = replacementSpatialOutput, 
                  name = "prioritizr_replacementSpatialOutput")
  }
  if(class(scenarioSolution) == "data.frame"){
    replacementImportance <- scenarioProblem %>%
      eval_replacement_importance(scenarioSolution[,"solution_1", 
                                                   drop = FALSE])
    # Save tabular results
    replacementTabularOutput <- data.frame(
      id = sim_pu$id,
      rc = replacementImportance$rc)
    saveDatasheet(ssimObject = myScenario, 
                  data = replacementTabularOutput, 
                  name = "prioritizr_replacementTabularOutput")
    
    # Save solution spatial visualization
    if(isTRUE(puVis)){
      
      # Reclass table between planning unit id & solution
      reclassTable <- matrix(c(1:dim(replacementImportance)[1],
                               replacementImportance$rc),
                             byrow = FALSE, ncol = 2)
      # Reclassify raster
      replaceImportanceVis <- classify(pu_vis, reclassTable)
      
      # Define file path
      replaceImportanceFilepath <- paste0(
        dataPath, "\\prioritizr_replacementSpatialOutput")
      replaceImportanceFilename <- file.path(paste0(replaceImportanceFilepath,
                                           "\\replacementRaster.tif"))
      # Create directory if it does not exist
      ifelse(!dir.exists(file.path(replaceImportanceFilepath)), 
             dir.create(file.path(replaceImportanceFilepath)), FALSE)
      writeRaster(replaceImportanceVis, filename = replaceImportanceFilename, 
                  overwrite = TRUE)
      # Save file path to datasheet
      replacementSpatialOutput <- data.frame(
        replacement = replaceImportanceFilename)
      saveDatasheet(ssimObject = myScenario, 
                    data = replacementSpatialOutput, 
                    name = "prioritizr_replacementSpatialOutput")
    }
  }
}

# Calculate Ferrier scores and extract total score
if(isTRUE(importanceDatasheet$eval_ferrier_importance) &
   sum(scenarioSolution$solution_1) != 0){
  if(class(scenarioSolution) != "data.frame"){
    
    ferrierScores <- eval_ferrier_importance(scenarioProblem, scenarioSolution)
    
    # Define folder path
    ferrierVisFilepath <- paste0(dataPath, "\\prioritizr_ferrierSpatialOutput")
      
    # Create directory if it does not exist
    ifelse(!dir.exists(file.path(ferrierVisFilepath)), 
           dir.create(file.path(ferrierVisFilepath)), FALSE)
      
    # Read datasheet
    ferrierSpatialOutput <- data.frame(projectFeaturesId = as.character(),
                                       ferrierMethod = as.character())
      
    # Loop across feature variables
    for(j in 1:length(featuresDatasheet$variableName)){
      
      # Get feature ID
      featureID <- featuresDatasheet$featureID[j]
      
      # Reclassify raster
      rasterVis <- ferrierScores[[j]]
      #plot(rasterVis)    
      
      # Define file path
      rasterVisFilename <- file.path(paste0(
        ferrierVisFilepath, paste0("\\ferrierScoreFeature", featureID, ".tif")))
      
      # Save file
      writeRaster(rasterVis, filename = rasterVisFilename, overwrite = TRUE)
      
      # Add file path to datasheet
      ferrierSpatialOutput[j,1] <- featuresDatasheet$Name[j] 
      ferrierSpatialOutput[j,2] <- rasterVisFilename 
      
    }
      
    # Save datasheet
    saveDatasheet(ssimObject = myScenario, 
                  data = ferrierSpatialOutput, 
                  name = "prioritizr_ferrierSpatialOutput")
  }
  if(class(scenarioSolution) == "data.frame"){
    
    ferrierScores <- eval_ferrier_importance(scenarioProblem, 
                                             scenarioSolution[,"solution_1",
                                                              drop = FALSE])
    # Add planning unit ID
    ferrierScores$id <- sim_pu$id
    
    # Pivot long
    numFeatures <- dim(ferrierScores)[2]-2
    subsetData <- ferrierScores[,c(1:numFeatures, numFeatures+2)]
    ferrierScoresLong <- subsetData %>%
      pivot_longer(cols = 1:numFeatures,
                   names_to = "projectFeaturesId", values_to = "scores")
    
    # Save results
    saveDatasheet(ssimObject = myScenario, 
                  data = ferrierScoresLong, 
                  name = "prioritizr_ferrierTabularOutput")
    
    # Save solution spatial visualization
    if(isTRUE(puVis)){
      
      # Define folder path
      ferrierVisFilepath <- paste0(dataPath, "\\prioritizr_ferrierSpatialOutput")
      
      # Create directory if it does not exist
      ifelse(!dir.exists(file.path(ferrierVisFilepath)), 
             dir.create(file.path(ferrierVisFilepath)), FALSE)
      
      # Read datasheet
      ferrierSpatialOutput <- data.frame(projectFeaturesId = as.character(),
                                         ferrierMethod = as.character())
      
      # Loop across feature variables
      for(j in 1:length(featuresDatasheet$variableName)){
        
        # Get feature ID
        featureID <- featuresDatasheet$featureID[j]
        
        # Subset Ferrier scores
        subsetRaster <- ferrierScoresLong[ferrierScoresLong$projectFeaturesId == featuresDatasheet$Name[j],]
        # Reclass table between planning unit id & solution
        reclassTable <- matrix(c(subsetRaster$projectPUId,
                                 subsetRaster$scores),
                               byrow = FALSE, ncol = 2)
        # Reclassify raster
        rasterVis <- classify(pu_vis, reclassTable)
        
        # Define file path
        rasterVisFilename <- file.path(paste0(
          ferrierVisFilepath, paste0("\\ferrierScoreFeature", featureID, ".tif")))
        
        # Save file
        writeRaster(rasterVis, filename = rasterVisFilename, overwrite = TRUE)
        
        # Add file path to datasheet
        ferrierSpatialOutput[j,1] <- featuresDatasheet$Name[j] 
        ferrierSpatialOutput[j,2] <- rasterVisFilename 
        
      }
      
      # Save datasheet
      saveDatasheet(ssimObject = myScenario, 
                    data = ferrierSpatialOutput, 
                    name = "prioritizr_ferrierSpatialOutput")
    }
  }
}

# Calculate rarity weighted richness scores
if(isTRUE(importanceDatasheet$eval_rare_richness_importance) &
   sum(scenarioSolution$solution_1) != 0){
  if(class(scenarioSolution) != "data.frame"){
    
    rarityScores <- eval_rare_richness_importance(scenarioProblem, 
                                                  scenarioSolution)
    
    # Save raster
    rarityFilename <- file.path(paste0(dataDir, "\\rarityRaster.tif"))
    writeRaster(rarityScores, filename = rarityFilename,
                overwrite = TRUE)
    
    # Save file path to datasheet
    raritySpatialOutput <- data.frame(rarityWeightedRichness = rarityFilename)
    saveDatasheet(ssimObject = myScenario, 
                  data = raritySpatialOutput, 
                  name = "prioritizr_raritySpatialOutput")
  }
  if(class(scenarioSolution) == "data.frame"){
    
    rarityScores <- eval_rare_richness_importance(
      scenarioProblem, scenarioSolution[,"solution_1", drop = FALSE])
    
    # Save results
    rarityTabularOutput <- data.frame(
      id = sim_pu$id,
      rwr = rarityScores$rwr)
    saveDatasheet(ssimObject = myScenario, 
                  data = rarityTabularOutput, 
                  name = "prioritizr_rarityTabularOutput")
    
    # Save solution spatial visualization
    if(isTRUE(puVis)){
      
      # Reclass table between planning unit id & solution
      reclassTable <- matrix(c(rarityTabularOutput$id,
                               rarityTabularOutput$rwr),
                             byrow = FALSE, ncol = 2)
      # Reclassify raster
      rarityVis <- classify(pu_vis, reclassTable)
      
      # Define file path
      rarityFilepath <- paste0(
        dataPath, "\\prioritizr_raritySpatialOutput")
      rarityFilename <- file.path(paste0(rarityFilepath,
                                         "\\rarityWeightedRichnessRaster.tif"))
      # Create directory if it does not exist
      ifelse(!dir.exists(file.path(rarityFilepath)), 
             dir.create(file.path(rarityFilepath)), FALSE)
      writeRaster(rarityVis, filename = rarityFilename, overwrite = TRUE)
      # Save file path to datasheet
      raritySpatialOutput <- data.frame(
        rarityWeightedRichness = rarityFilename)
      saveDatasheet(ssimObject = myScenario, 
                    data = raritySpatialOutput, 
                    name = "prioritizr_raritySpatialOutput")
    }
  }
}


