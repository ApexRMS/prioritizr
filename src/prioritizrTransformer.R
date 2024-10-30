## prioritizr SyncroSim
##
## Written by Carina Rauen Firkowski
##
## This script is the transformer for the prioritizr SyncroSim package. It loads
## the inputs from SyncroSim to create the prioritizr problem, solves the
## problem, prepares the solution output, and performs any required evaluations.

# Workspace -------------------------------------------------------------------

# Load conda packages
library(rsyncrosim); progressBar(type = "message", 
                                 message = "Setting up workspace")
library(stringr)
library(terra)
library(tidyr)
library(dplyr)

# Load environment, library, project & scenario
e <- ssimEnvironment()
myLibrary <- ssimLibrary()
myProject <- rsyncrosim::project()
myScenario <- scenario()

# Open Conda configuration options
condaDatasheet <- datasheet(myLibrary, name = "core_Option")

# Install missing packages when using Conda
if(isTRUE(condaDatasheet$UseConda)){
  
  # Path to R session package library
  packagePath <- e$PackageDirectory
  syncrosimPath <- str_remove(packagePath, fixed("\\Packages")) %>%
    str_remove(fixed("\\prioritizr"))
  rLibraryPath <- file.path(syncrosimPath, "Conda", "envs", "prioritizr", 
                            "prioritizrEnv", "lib", "R", "library")
  
  # Check which packages to install
  packagesToCheck <- c("prioritizr", "symphony", "Rsymphony")
  packagesToInstall <- packagesToCheck[!(packagesToCheck %in% 
                      installed.packages(lib.loc = rLibraryPath)[,"Package"])]
  # Install missing packages
  if(length(packagesToInstall) != 0){
    install.packages(packagesToInstall,
                     dependencies = TRUE,
                     lib = rLibraryPath,
                     repos = "https://mirror.rcg.sfu.ca/mirror/CRAN/")
  }
  
  # Load additional packages
  .libPaths(rLibraryPath)
  library(prioritizr)
  library(Rsymphony)
} else {
  # Load additional packages
  library(prioritizr)
  library(Rsymphony)
}

# Data directory
dataDir <- e$DataDirectory

# Create directory if it does not exist
ifelse(!dir.exists(file.path(dataDir)), 
       dir.create(file.path(dataDir)), FALSE)

# Scenario path
dataPath <- paste(dataDir, paste0("Scenario-", scenarioId(myScenario)), sep="\\") 



# Open datasheets --------------------------------------------------------------

progressBar(type = "message", message = "Loading data and setting up scenario")

problemFormatDatasheet <- datasheet(myScenario,
                                    name = "prioritizr_problemFormat")
problemSpatialDatasheet <- datasheet(myScenario,
                                     name = "prioritizr_problemSpatial")
problemTabularDatasheet <- datasheet(myScenario, 
                                     name = "prioritizr_problemTabular")
objectiveDatasheet <- datasheet(myScenario, 
                                name = "prioritizr_objective")
targetDatasheet <- datasheet(myScenario,
                             name = "prioritizr_targets")
contiguityDatasheet <- datasheet(myScenario,
                                 name = "prioritizr_contiguity")
featureContiguityDatasheet <- datasheet(myScenario,
                                        name = "prioritizr_featureContiguity")
linearConstraintDatasheet <- datasheet(myScenario,
                               name = "prioritizr_linear")
lockedInDatasheet <- datasheet(myScenario,
                               name = "prioritizr_lockedIn")
lockedOutDatasheet <- datasheet(myScenario,
                                name = "prioritizr_lockedOut")
neighborDatasheet <- datasheet(myScenario,
                               name = "prioritizr_neighbor")
boundaryDatasheet <- datasheet(myScenario,
                               name = "prioritizr_boundaryPenalties")
decisionDatasheet <- datasheet(myScenario,
                               name = "prioritizr_decisionTypes")
solverDatasheet <- datasheet(myScenario,
                             name = "prioritizr_solver")
performanceDatasheet <- datasheet(myScenario,
                                  name = "prioritizr_evaluatePerformance")
linearDatasheet <- datasheet(myScenario,
                             name = "prioritizr_linearPenalties")
importanceDatasheet <- datasheet(myScenario,
                                 name = "prioritizr_evaluateImportance")
weightsDatasheet <- datasheet(myScenario,
                              name = "prioritizr_featureWeights")
solutionRasterOutput <- datasheet(myScenario,
                                  name = "prioritizr_solutionRasterOutput")
replacementSpatialOutput <- datasheet(
  myScenario, name = "prioritizr_replacementSpatialOutput")
ferrierSpatialOutput <- datasheet(myScenario,
                                  name = "prioritizr_ferrierSpatialOutput")
solutionTabularOutput <- datasheet(myScenario,
                                   name = "prioritizr_solutionTabularOutput") 
raritySpatialOutput <- datasheet(myScenario,
                                 name = "prioritizr_raritySpatialOutput")
numberOutput <- datasheet(myScenario,
                          name = "prioritizr_numberOutput")
costOutput <- datasheet(myScenario,
                        name = "prioritizr_costOutput")
featureRepresentationOutput <- datasheet(
  myScenario, 
  name = "prioritizr_featureRepresentationOutput",
  lookupsAsFactors = T)
targetCoverageOutput <- datasheet(myScenario,
                                  name = "prioritizr_targetCoverageOutput",
                                  lookupsAsFactors = T)
boundaryOutput <- datasheet(myScenario,
                            name = "prioritizr_boundaryOutput")
replacementTabularOutput <- datasheet(
  myScenario, name = "prioritizr_replacementTabularOutput")
ferrierTabularOutput <- datasheet(myScenario,
                                  name = "prioritizr_ferrierTabularOutput")
rarityTabularOutput <- datasheet(myScenario,
                                 name = "prioritizr_rarityTabularOutput")



# Rename variable names for consistency with prioritizr R ----------------------

names(problemTabularDatasheet)[4] <- "cost_column"
names(contiguityDatasheet)[1] <- "add_contiguity_constraints"
names(featureContiguityDatasheet) <- "add_feature_contiguity_constraints"
names(linearConstraintDatasheet)[1] <- "add_linear_constraints"
names(lockedInDatasheet) <- c("add_locked_in_constraints", "locked_in")
names(lockedOutDatasheet) <- c("add_locked_out_constraints", "locked_out")
names(neighborDatasheet)[1] <- "add_neighbor_constraints"
names(boundaryDatasheet)[1] <- "add_boundary_penalties"
names(boundaryDatasheet)[3] <- "edge_factor"
names(decisionDatasheet)[2] <- "upper_limit"
names(performanceDatasheet) <- c("eval_n_summary", "eval_cost_summary",
                                 "eval_feature_representation_summary",
                                 "eval_target_coverage_summary",
                                 "eval_boundary_summary")
names(linearDatasheet)[1] <- "add_linear_penalties"
names(importanceDatasheet) <- c("eval_replacement_importance",
                                "eval_ferrier_importance", 
                                "eval_rare_richness_importance")
names(weightsDatasheet)[1] <- "add_feature_weights"
names(solutionTabularOutput)[6] <- "solution_1"
names(featureRepresentationOutput)[3:5] <- c("total_amount", "absolute_held",
                                             "relative_held") 
names(targetCoverageOutput)[3:9] <- c("total_amount", "absolute_target", 
                                      "absolute_held", "absolute_shortfall",
                                      "relative_target", "relative_held",
                                      "relative_shortfall")



# Validation -------------------------------------------------------------------

# If datasheet is not empty, set NA values to FALSE 
# If datasheet is empty, set all columns to FALSE
if(dim(performanceDatasheet)[1] != 0){
  performanceDatasheet[,is.na(performanceDatasheet)] <- FALSE
} else {
  performanceDatasheet <- data.frame(
    eval_n_summary = FALSE,
    eval_cost_summary = FALSE,
    eval_feature_representation_summary = FALSE,
    eval_target_coverage_summary = FALSE,
    eval_boundary_summary = FALSE)
}
if(dim(importanceDatasheet)[1] != 0){
  importanceDatasheet[,is.na(importanceDatasheet)] <- FALSE
} else {
  importanceDatasheet <- data.frame(eval_replacement_importance = FALSE,
                                    eval_ferrier_importance = FALSE,
                                    eval_rare_richness_importance = FALSE)
}
if(dim(boundaryDatasheet)[1] != 0){
  boundaryDatasheet$add_boundary_penalties[
    is.na(boundaryDatasheet$add_boundary_penalties)] <- FALSE
} else {
  boundaryDatasheet <- data.frame(add_boundary_penalties = FALSE,
                                  penalty = NA,
                                  edge_factor = NA,
                                  data = NA)
}
if(dim(linearDatasheet)[1] != 0){
  linearDatasheet$add_linear_penalties[
    is.na(linearDatasheet$add_linear_penalties)] <- FALSE
} else {
  linearDatasheet <- data.frame(add_linear_penalties = FALSE,
                                     penalty = NA,
                                     data = NA)
}



# Load data --------------------------------------------------------------------

# Spatial data
if(problemFormatDatasheet$dataType == "Spatial"){
  
  # Planning unit
  sim_pu <- rast(file.path(problemSpatialDatasheet$x))
  crs(sim_pu) <- NA
  # Features
  sim_features <- stack(file.path(problemSpatialDatasheet$features))
  crs(sim_features) <- NA
  
  # Features' names
  featuresDatasheet <- data.frame(Name = names(sim_features))

}

# Tabular data
if(problemFormatDatasheet$dataType == "Tabular"){
  
  # Planning unit
  sim_pu <- data.table::fread(file.path(problemTabularDatasheet$x),
                              data.table = FALSE)
  
  # Features
  sim_features <- data.table::fread(file.path(problemTabularDatasheet$features),
                                    data.table = FALSE)
  # Set features' names
  featuresDatasheet <- data.frame(Name = sim_features$name)
  
  # Planning units vs. Features
  rij <- data.table::fread(file.path(problemTabularDatasheet$rij),
                           data.table = FALSE)
  
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
  
}

# Save features to project scope
saveDatasheet(ssimObject = myProject, 
              data = featuresDatasheet, 
              name = "prioritizr_projectFeatures")



# Define criteria --------------------------------------------------------------

# Create list of criteria if required input
criteriaList <- c("Objective", "Decision", "Solver")

# If criteria is enable, append to list of criteria
if(dim(targetDatasheet)[1] != 0){
  if(isTRUE(targetDatasheet$addTarget)){
    criteriaList <- c(criteriaList, "Target") }}
if(dim(contiguityDatasheet)[1] != 0){
  if(isTRUE(contiguityDatasheet$add_contiguity_constraints)){
    criteriaList <- c(criteriaList, "Contiguity") }}
if(dim(featureContiguityDatasheet)[1] != 0){
  if(isTRUE(featureContiguityDatasheet$add_feature_contiguity_constraints)){
    criteriaList <- c(criteriaList, "Feature contiguity") }}
if(dim(linearConstraintDatasheet)[1] != 0){
  if(isTRUE(linearConstraintDatasheet$add_linear_constraints)){
    criteriaList <- c(criteriaList, "Linear") }}
if(dim(lockedInDatasheet)[1] != 0){
  if(isTRUE(lockedInDatasheet$add_locked_in_constraints)){
    criteriaList <- c(criteriaList, "Locked in") }}
if(dim(lockedOutDatasheet)[1] != 0){
  if(isTRUE(lockedOutDatasheet$add_locked_out_constraints)){ 
    criteriaList <- c(criteriaList, "Locked out") }}
if(dim(neighborDatasheet)[1] != 0){
  if(isTRUE(neighborDatasheet$add_neighbor_constraints)){
    criteriaList <- c(criteriaList, "Neighbor") }}
if(dim(boundaryDatasheet)[1] != 0){
  if(isTRUE(boundaryDatasheet$add_boundary_penalties)) {
    criteriaList <- c(criteriaList, "Boundary penalties") }}
if(dim(linearDatasheet)[1] != 0){
  if(isTRUE(linearDatasheet$add_linear_penalties)) {
    criteriaList <- c(criteriaList, "Linear penalties") }}
if(dim(weightsDatasheet)[1] != 0){
  if(isTRUE(weightsDatasheet$add_feature_weights)) {
    criteriaList <- c(criteriaList, "Weights") }}



# Create problem ---------------------------------------------------------------

progressBar(message = "Creating and solving problem", type = "message")

# Problem
if(problemFormatDatasheet$dataType == "Spatial"){
  scenarioProblem <- problem(sim_pu, features = sim_features) }
if(problemFormatDatasheet$dataType == "Tabular"){
  scenarioProblem <- problem(x = sim_pu, features = sim_features,
                             cost_column = problemTabularDatasheet$cost_column,
                             rij = rij) }

# Update problem recursively
for(criteria in criteriaList){
  
  # Objective
  if(criteria == "Objective"){
    budget <- objectiveDatasheet$budget
    if(objectiveDatasheet$addObjective == "Maximum cover"){
      criteriaFunction <- function(x) add_max_cover_objective(x, budget) }
    if(objectiveDatasheet$addObjective == "Maximum features"){
      criteriaFunction <- function(x) add_max_features_objective(x, budget) }
    if(objectiveDatasheet$addObjective == "Maximum utility"){
      criteriaFunction <- function(x) add_max_utility_objective(x, budget) }
    if(objectiveDatasheet$addObjective == "Minimum largest shortfall"){
      criteriaFunction <- function(x) add_min_largest_shortfall_objective(x,
                                                                          budget) }
    if(objectiveDatasheet$addObjective == "Minimum set"){
      criteriaFunction <- function(x) add_min_set_objective(x) }
    if(objectiveDatasheet$addObjective == "Minimum shortfall"){
      criteriaFunction <- function(x) add_min_shortfall_objective(x, budget) }
  }
  
  # Target & target amount
  if(criteria == "Target"){
    targetAmount <- targetDatasheet$targets
    if(targetDatasheet$addTarget == "Absolute"){
      criteriaFunction <- function(x) add_absolute_targets(x, 
                                                           targets = targetAmount) }
    if(targetDatasheet$addTarget == "Relative"){
      criteriaFunction <- function(x) add_relative_targets(x, 
                                                           targets = targetAmount) }
  }
  
  # Decision types
  if(criteria == "Decision"){
    if(decisionDatasheet$addDecision == "Default"){
      criteriaFunction <- function(x) add_default_decisions(x) }
    if(decisionDatasheet$addDecision == "Binary"){
      criteriaFunction <- function(x) add_binary_decisions(x) }
    if(decisionDatasheet$addDecision == "Proportion"){
      criteriaFunction <- function(x) add_proportion_decisions(x) }
    if(decisionDatasheet$addDecision == "Semi-continuous"){
      upperLimit <- decisionDatasheet$upper_limit
      criteriaFunction <- function(x) add_semicontinuous_decisions(x, 
                                                                   upperLimit) }
  } 
  
  # Constraints
  # Contiguity constraint
  if(criteria == "Contiguity"){
    if(problemFormatDatasheet$dataType == "Spatial") {
      criteriaFunction <- function(x) add_contiguity_constraints(x)
    }
    if(problemFormatDatasheet$dataType == "Tabular"){
      connect_dat <- data.table::fread(file.path(contiguityDatasheet$data),
                                       data.table = FALSE)
      criteriaFunction <- function(x) add_contiguity_constraints(
        x, data = connect_dat)
    }
  }
  # Feature contiguity constraint
  if(criteria == "Feature contiguity"){
    criteriaFunction <- function(x) add_feature_contiguity_constraints(x)
  }
  # Linear constraint
  if(criteria == "Linear"){
    if(problemFormatDatasheet$dataType == "Spatial"){
      for(i in dim(linearConstraintDatasheet)[1]){
        data <- rast(linearConstraintDatasheet$data)
        crs(data) <- NA
      }
      if(problemFormatDatasheet$dataType == "Tabular"){
        linearData <- data.table::fread(file.path(linearConstraintDatasheet$data),
                                        data.table = FALSE)
      }
      threshold <- linearConstraintDatasheet$threshold
      senseCode <- linearConstraintDatasheet$sense
      if(senseCode == 1) sense <- ">="
      if(senseCode == 2) sense <- "<="
      if(senseCode == 3) sense <- "="
      criteriaFunction <- function(x) add_linear_constraints(x, threshold,
        sense, data)
    }
  }
  # Locked in constraint
  if(criteria == "Locked in"){
    if(problemFormatDatasheet$dataType == "Spatial"){
      lockedIn <- rast(lockedInDatasheet$locked_in)
      crs(lockedIn) <- NA
    }
    if(problemFormatDatasheet$dataType == "Tabular"){
      lockedIn <- data.table::fread(file.path(lockedInDatasheet$locked_in),
                                    data.table = FALSE)
    }
    criteriaFunction <- function(x) add_locked_in_constraints(x, lockedIn)
  }
  # Locked out constraint
  if(criteria == "Locked out"){
    if(problemFormatDatasheet$dataType == "Spatial"){
      lockedOut <- rast(lockedOutDatasheet$locked_out)
      crs(lockedIn) <- NA
    }
    if(problemFormatDatasheet$dataType == "Tabular"){
      lockedOut <- data.table::fread(file.path(lockedOutDatasheet$locked_out),
                                     data.table = FALSE)
    }
    criteriaFunction <- function(x) add_locked_out_constraints(x, 
                                                               lockedOut)
  }
  # Neighbor constraint
  if(criteria == "Neighbor"){
    k <- neighborDatasheet$k
    criteriaFunction <- function(x) add_neighbor_constraints(x, k)
  }
  
  
  # Penalties
  # Boundary penalties
  if(criteria == "Boundary penalties"){
    penalty <- boundaryDatasheet$penalty
    if(problemFormatDatasheet$dataType == "Spatial"){
      if(!is.na(boundaryDatasheet$edge_factor)){
        edge_factor <- boundaryDatasheet$edge_factor
        criteriaFunction <- function(x) 
          add_boundary_penalties(x, penalty = penalty, edge_factor = edge_factor) 
      } else {
        criteriaFunction <- function(x) add_boundary_penalties(x, 
                                                               penalty = penalty)
      }
      if(problemFormatDatasheet$dataType == "Tabular"){
        bound_dat <- data.table::fread(file.path(boundaryDatasheet$data),
                                       data.table = FALSE)
        if(!is.na(boundaryDatasheet$edge_factor)){
          edge_factor <- boundaryDatasheet$edge_factor
          criteriaFunction <- function(x) 
            add_boundary_penalties(x, penalty = penalty, 
                                   edge_factor = edge_factor,
                                   data = bound_dat) 
        } else {
          criteriaFunction <- function(x) add_boundary_penalties(
            x, penalty = penalty, data = bound_dat)
        }
      }
    }
  }
  # Linear penalties
  if(criteria == "Linear penalties"){
    penalty <- linearDatasheet$penalty
    if(problemFormatDatasheet$dataType == "Spatial"){
      linearData <- rast(file.path(linearDatasheet$data))
      crs(linearData) <- NA
      criteriaFunction <- function(x) add_linear_penalties(x, 
                                                           penalty = penalty,
                                                           data = linearData)
    }
    if(problemFormatDatasheet$dataType == "Tabular"){
      linearData <- read.csv(file.path(linearDatasheet$data))
      criteriaFunction <- function(x) add_linear_penalties(x, 
                                                           penalty = penalty, 
                                                           data = linearData[,1, drop = TRUE])
    }
  }
  
  # Solver
  if(criteria == "Solver"){
    if(!is.na(solverDatasheet$gap)){
      gap <- solverDatasheet$gap
      criteriaFunction <- function(x) add_rsymphony_solver(x, 
                                                           gap = gap)
    } else {
      criteriaFunction <- function(x) add_rsymphony_solver(x) }
  } 
  
  # Weights
  if(criteria == "Weights"){
    weights_dat <- read.csv(file.path(weightsDatasheet$weights), header = T)
    criteriaFunction <- function(x) add_feature_weights(
      x, weights = weights_dat[,1, drop = TRUE])
  }
  
  # Update
  scenarioProblem <- criteriaFunction(scenarioProblem)
}



# Solve the problem ------------------------------------------------------------

# Run solver
scenarioSolution <- solve(scenarioProblem)

# Save raster
if(problemFormatDatasheet$dataType == "Spatial"){
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
if(problemFormatDatasheet$dataType == "Tabular"){
  
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



# Evaluate performance ---------------------------------------------------------

progressBar(message = "Evaluating performance and importance", type = "message")

# Calculate solution number
if(isTRUE(performanceDatasheet$eval_n_summary)){
  
  if(problemFormatDatasheet$dataType == "Spatial"){
    n <- eval_n_summary(scenarioProblem, scenarioSolution) }
  if(problemFormatDatasheet$dataType == "Tabular"){
    n <- eval_n_summary(scenarioProblem, scenarioSolution[,"solution_1", 
                                                          drop = FALSE]) }
  # Save results
  numberOutput <- as.data.frame(n)
  saveDatasheet(ssimObject = myScenario, 
                data = numberOutput, 
                name = "prioritizr_numberOutput")
}

# Calculate solution cost
if(isTRUE(performanceDatasheet$eval_cost_summary)){
  
  if(problemFormatDatasheet$dataType == "Spatial"){
    cost <- eval_cost_summary(scenarioProblem, scenarioSolution) }
  if(problemFormatDatasheet$dataType == "Tabular"){
    cost <- eval_cost_summary(scenarioProblem, scenarioSolution[,"solution_1",
                                                                drop = FALSE]) }
  # Save results
  costOutput <- as.data.frame(cost)
  saveDatasheet(ssimObject = myScenario, 
                data = costOutput, 
                name = "prioritizr_costOutput")
}

# Calculate how well features are represented by a solution
if(isTRUE(performanceDatasheet$eval_feature_representation_summary)){
  
  if(problemFormatDatasheet$dataType == "Spatial"){
    featureRepresentation <- eval_feature_representation_summary(
      scenarioProblem, scenarioSolution) }
  if(problemFormatDatasheet$dataType == "Tabular"){
    featureRepresentation <- eval_feature_representation_summary(
      scenarioProblem, scenarioSolution[,"solution_1", drop = FALSE]) }
  
  # Save results
  names(featureRepresentation)[2] <- "projectFeaturesId"
  featureRepresentationOutput <- as.data.frame(featureRepresentation)
  names(featureRepresentationOutput)[3:5] <- c("totalAmount", "absoluteHeld",
                                               "relativeHeld") 
  saveDatasheet(ssimObject = myScenario, 
                data = featureRepresentationOutput, 
                name = "prioritizr_featureRepresentationOutput") 
}

# Calculate how well the targets are met by the solution
if(isTRUE(performanceDatasheet$eval_target_coverage_summary)){
  if(problemFormatDatasheet$dataType == "Spatial"){
    targetCoverage <- eval_target_coverage_summary(scenarioProblem, 
                                                   scenarioSolution) }
  if(problemFormatDatasheet$dataType == "Tabular"){
    targetCoverage <- eval_target_coverage_summary(
      scenarioProblem, scenarioSolution[,"solution_1", drop = FALSE]) }
  
  # Save results
  names(targetCoverage)[1] <- "projectFeaturesId"
  targetCoverageOutput <- as.data.frame(targetCoverage)
  names(targetCoverageOutput)[3:9] <- c("totalAmount", "absoluteTarget", 
                                        "absoluteHeld", "absoluteShortfall",
                                        "relativeTarget", "relativeHeld",
                                        "relativeShortfall")
  saveDatasheet(ssimObject = myScenario, 
                data = targetCoverageOutput, 
                name = "prioritizr_targetCoverageOutput") 
}

# Calculate solution the total exposed boundary length (perimeter)
if(isTRUE(performanceDatasheet$eval_boundary_summary)){
  
  if(problemFormatDatasheet$dataType == "Spatial"){
    temp_boundaryOutput <- eval_boundary_summary(scenarioProblem, 
                                                 scenarioSolution)
    # Save results
    boundaryOutput <- as.data.frame(temp_boundaryOutput)
    saveDatasheet(ssimObject = myScenario, 
                  data = boundaryOutput, 
                  name = "prioritizr_boundaryOutput")
  }
}



# Evaluate importance ----------------------------------------------------------

# Calculate replacement cost scores
if(isTRUE(importanceDatasheet$eval_replacement_importance)){
  if(problemFormatDatasheet$dataType == "Spatial"){
    
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
  if(problemFormatDatasheet$dataType == "Tabular"){
    replacementImportance <- scenarioProblem %>%
      eval_replacement_importance(scenarioSolution[,"solution_1", 
                                                   drop = FALSE])
    # Save tabular results
    replacementTabularOutput <- as.data.frame(replacementImportance)
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
if(isTRUE(importanceDatasheet$eval_ferrier_importance)){
  if(problemFormatDatasheet$dataType == "Spatial"){
    
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
  if(problemFormatDatasheet$dataType == "Tabular"){
    
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
  if(problemFormatDatasheet$dataType == "Spatial"){
    
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
  if(problemFormatDatasheet$dataType == "Tabular"){
    
    rarityScores <- eval_rare_richness_importance(
      scenarioProblem, scenarioSolution[,"solution_1", drop = FALSE])
    
    # Save results
    rarityTabularOutput <- as.data.frame(rarityScores)
    saveDatasheet(ssimObject = myScenario, 
                  data = rarityTabularOutput, 
                  name = "prioritizr_rarityTabularOutput")
  }
}


