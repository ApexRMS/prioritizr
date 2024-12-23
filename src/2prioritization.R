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
  names(solutionTabularOutput)[6] <- "solution_1"
  
  # Combine result and datasheet
  solutionTabularOutput <- merge(solutionTabularOutput, 
                                 scenarioSolution, 
                                 all = TRUE)
  # Reorder columns
  solutionTabularOutput <- data.frame(id = solutionTabularOutput$id,
                                      cost = solutionTabularOutput$cost,
                                      status = solutionTabularOutput$status,
                                      xloc = solutionTabularOutput$xloc,
                                      yloc = solutionTabularOutput$yloc,
                                      solution_1 = solutionTabularOutput$solution_1)
  # Remove all NA rows
  solutionTabularOutput <- solutionTabularOutput[
   rowSums(is.na(solutionTabularOutput)) != ncol(solutionTabularOutput), ]
  
  # Rename column
  names(solutionTabularOutput)[6] <- "solution1"
  
  # Save solution tabular results
  saveDatasheet(ssimObject = myScenario, 
                data = solutionTabularOutput, 
                name = "prioritizr_solutionTabularOutput")
  
  # Spatial data for visualization
  if(dim(problemSpatialDatasheet)[1] != 0){
    if(!is.na(problemSpatialDatasheet$x)){
      pu_vis <- rast(file.path(problemSpatialDatasheet$x))
      crs(pu_vis) <- NA
      puVis <- TRUE
    }
  } 
  if(is.na(problemSpatialDatasheet$x)){
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


