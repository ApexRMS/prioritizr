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

# Calculate replacement cost scores
if(isTRUE(importanceDatasheet$eval_replacement_importance)){
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
    replacementTabularOutput <- as.data.frame(replacementImportance)
    saveDatasheet(ssimObject = myScenario, 
                  data = replacementTabularOutput, 
                  name = "prioritizr_replacementTabularOutput")
    
    # Spatial data for visualization
    if(dim(problemSpatialDatasheet)[1] != 0){
      if(!is.na(problemSpatialDatasheet$x)){
        pu_vis <- rast(file.path(problemSpatialDatasheet$x))
        crs(pu_vis) <- NA
        puVis <- TRUE
      }
    } else {
      puVis <- FALSE
    }
    
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
if(isTRUE(importanceDatasheet$eval_ferrier_importance)){
  if(class(scenarioSolution) != "data.frame"){
    
    ferrierScores <- eval_ferrier_importance(scenarioProblem, scenarioSolution)
    
    # Save raster
    ferrierFilename <- file.path(paste0(dataDir, "\\ferrierRaster.tif"))
    writeRaster(ferrierScores[["total"]], filename = ferrierFilename,
                overwrite = TRUE)
    
    # Save file path to datasheet
    ferrierSpatialOutput <- data.frame(ferrierMethod = ferrierFilename)
    saveDatasheet(ssimObject = myScenario, 
                  data = ferrierSpatialOutput, 
                  name = "prioritizr_ferrierSpatialOutput")
  }
  if(class(scenarioSolution) == "data.frame"){
    
    ferrierScores <- eval_ferrier_importance(scenarioProblem, 
                                             scenarioSolution[,"solution_1",
                                                              drop = FALSE])
    featureNames <- names(ferrierScores)
    # Add planning unit id
    ferrierScores$id <- sim_pu$id
    # Pivot data
    ferrierScores <- ferrierScores %>%
      pivot_longer(cols = featureNames,
                   names_to = "projectFeaturesId",
                   values_to = "scores")
    
    # Save results
    ferrierTabularOutput <- as.data.frame(ferrierScores)
    saveDatasheet(ssimObject = myScenario, 
                  data = ferrierTabularOutput, 
                  name = "prioritizr_ferrierTabularOutput")
  }
}

# Calculate rarity weighted richness scores
if(isTRUE(importanceDatasheet$eval_rare_richness_importance)){
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
    rarityTabularOutput <- as.data.frame(rarityScores)
    saveDatasheet(ssimObject = myScenario, 
                  data = rarityTabularOutput, 
                  name = "prioritizr_rarityTabularOutput")
  }
}


