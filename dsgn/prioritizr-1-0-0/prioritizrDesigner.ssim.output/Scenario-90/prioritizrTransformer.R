## prioritizr SyncroSim
##
## Written by Carina Rauen Firkowski
##
## This script is the transformer for the prioritizr SyncroSim package. It loads
## the inputs from SyncroSim to create the prioritizr problem, solves the
## problem, prepares the solution output, and performs any required evaluations.



# Workspace -------------------------------------------------------------------

# Load conda packages
library(rsyncrosim) ; progressBar(type = "message", 
                                  message = "Setting up workspace")
library(stringr)
library(raster)
library(terra)
library(tidyr)
library(dplyr)

# Load environment, library, project & scenario
e <- ssimEnvironment()
myLibrary <- ssimLibrary()
myProject <- rsyncrosim::project()
myScenario <- scenario()

# Open Conda configuration options
condaDatasheet <- datasheet(myLibrary, name = "core_Options")

# Install missing packages when using Conda
if(condaDatasheet$UseConda){

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
                     lib = rLibraryPath,
                     repos = "https://mirror.rcg.sfu.ca/mirror/CRAN/")
  }
}

# Load additional packages
library(prioritizr)
library(Rsymphony)

# Output directory
outputDir <- e$OutputDirectory
# Create directory if it does not exist
ifelse(!dir.exists(file.path(outputDir)), 
       dir.create(file.path(outputDir)), FALSE)



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
lockedInDatasheet <- datasheet(myScenario,
                               name = "prioritizr_lockedIn")
lockedOutDatasheet <- datasheet(myScenario,
                               name = "prioritizr_lockedOut")
neighborDatasheet <- datasheet(myScenario,
                                name = "prioritizr_neighbor")
contiguityDatasheet <- datasheet(myScenario,
                                 name = "prioritizr_contiguity")
featureContiguityDatasheet <- datasheet(myScenario,
                                 name = "prioritizr_featureContiguity")
boundaryDatasheet <- datasheet(myScenario,
                               name = "prioritizr_boundaryPenalties")
decisionDatasheet <- datasheet(myScenario,
                               name = "prioritizr_decisionTypes")
solverDatasheet <- datasheet(myScenario,
                             name = "prioritizr_solver")
performanceDatasheet <- datasheet(myScenario,
                                  name = "prioritizr_evaluatePerformance")
importanceDatasheet <- datasheet(myScenario,
                                 name = "prioritizr_evaluateImportance")
solutionRasterOutput <- datasheet(myScenario,
                                  name = "prioritizr_solutionRasterOutput")
solutionTabularOutput <- datasheet(myScenario,
                                   name = "prioritizr_solutionTabularOutput")
numberOutput <- datasheet(myScenario,
                          name = "prioritizr_numberOutput")
costOutput <- datasheet(myScenario,
                        name = "prioritizr_costOutput")
featureRepresentationOutput <- datasheet(myScenario,
                                name = "prioritizr_featureRepresentationOutput",
                                lookupsAsFactors = T)
targetCoverageOutput <- datasheet(myScenario,
                                  name = "prioritizr_targetCoverageOutput",
                                  lookupsAsFactors = T)
boundaryOutput <- datasheet(myScenario,
                            name = "prioritizr_boundaryOutput")
replacementSpatialOutput <- datasheet(myScenario,
                            name = "prioritizr_replacementSpatialOutput")
replacementTabularOutput <- datasheet(myScenario,
                            name = "prioritizr_replacementTabularOutput")
ferrierSpatialOutput <- datasheet(myScenario,
                           name = "prioritizr_ferrierSpatialOutput")
ferrierTabularOutput <- datasheet(myScenario,
                                  name = "prioritizr_ferrierTabularOutput")
raritySpatialOutput <- datasheet(myScenario,
                          name = "prioritizr_raritySpatialOutput")
rarityTabularOutput <- datasheet(myScenario,
                                 name = "prioritizr_rarityTabularOutput")



# Validation -------------------------------------------------------------------

if(dim(performanceDatasheet)[1] != 0){
  performanceDatasheet[,is.na(performanceDatasheet)] <- FALSE
} else {
  temp_performanceDatasheet <- data.frame(
    eval_n_summary = FALSE,
    eval_cost_summary = FALSE,
    eval_feature_representation_summary = FALSE,
    eval_target_coverage_summary = FALSE,
    eval_boundary_summary = FALSE)
  performanceDatasheet <- rbind(performanceDatasheet, temp_performanceDatasheet)
  }
if(dim(importanceDatasheet)[1] != 0){
  importanceDatasheet[,is.na(importanceDatasheet)] <- FALSE
} else {
  temp_importanceDatasheet <- data.frame(eval_replacement_importance = FALSE,
                                         eval_ferrier_importance = FALSE,
                                         eval_rare_richness_importance = FALSE)
  importanceDatasheet <- rbind(importanceDatasheet, temp_importanceDatasheet)
  }
if(dim(boundaryDatasheet)[1] != 0){
  boundaryDatasheet$add_boundary_penalties[
    is.na(boundaryDatasheet$add_boundary_penalties)] <- FALSE
} else {
  temp_boundaryDatasheet <- data.frame(add_boundary_penalties = FALSE,
                                       penalty = NA,
                                       edge_factor = NA,
                                       data = NA)
  boundaryDatasheet <- rbind(boundaryDatasheet, temp_boundaryDatasheet)
}



# Load data --------------------------------------------------------------------

# Spatial data
if(problemFormatDatasheet$dataType == "Spatial"){
  
  # Planning unit
  sim_pu <- raster(file.path(problemSpatialDatasheet$x))
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
                              data.table = FALSE)[,-1]
  # Features
  sim_features <- data.table::fread(file.path(problemTabularDatasheet$features),
                                    data.table = FALSE)[,-1]
  # Planning units vs. Features
  rij <- data.table::fread(file.path(problemTabularDatasheet$rij),
                           data.table = FALSE)[,-1]
  
  # Features' names
  featuresDatasheet <- data.frame(Name = sim_features$name)
}

# Save features to project scope
saveDatasheet(ssimObject = myProject, 
              data = featuresDatasheet, 
              name = "prioritizr_projectFeatures")



# Define criteria --------------------------------------------------------------

# Create list of criteria if required input
criteriaList <- c("Objective", "Decision", "Solver")

# Append with additional criteria
if(dim(targetDatasheet)[1] != 0){
  criteriaList <- c(criteriaList, "Target") }
if(dim(lockedInDatasheet)[1] != 0){
  if(lockedInDatasheet$add_locked_in_constraints){
    criteriaList <- c(criteriaList, "Locked in") }}
if(dim(lockedOutDatasheet)[1] != 0){
  if(lockedOutDatasheet$add_locked_out_constraints){ 
    criteriaList <- c(criteriaList, "Locked out") }}
if(dim(neighborDatasheet)[1] != 0){
  if(neighborDatasheet$add_neighbor_constraints){
    criteriaList <- c(criteriaList, "Neighbor") }}
if(dim(contiguityDatasheet)[1] != 0){
  if(contiguityDatasheet$add_contiguity_constraints){
    criteriaList <- c(criteriaList, "Contiguity") }}
if(dim(featureContiguityDatasheet)[1] != 0){
  if(featureContiguityDatasheet$add_feature_contiguity_constraints){
    criteriaList <- c(criteriaList, "Feature contiguity") }}
if(dim(boundaryDatasheet)[1] != 0){
  if(boundaryDatasheet$add_boundary_penalties) {
    criteriaList <- c(criteriaList, "Boundary penalties") }}
    



# Create problem ---------------------------------------------------------------

progressBar(message = "Creating and solving problem", 
            type = "message")

# Problem
if(problemFormatDatasheet$dataType == "Spatial"){
  scenarioProblem <- problem(sim_pu, features = sim_features) }
if(problemFormatDatasheet$dataType == "Tabular"){
  scenarioProblem <- problem(sim_pu, features = sim_features,
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
  # Locked in constraint
  if(criteria == "Locked in"){
    if(problemFormatDatasheet$dataType == "Spatial"){
      lockedIn <- raster(lockedInDatasheet$locked_in)
      crs(lockedIn) <- NA
    }
    if(problemFormatDatasheet$dataType == "Tabular"){
      lockedIn <- data.table::fread(file.path(lockedInDatasheet$locked_in),
                                    data.table = FALSE)[,-1]
    }
    criteriaFunction <- function(x) add_locked_in_constraints(x, lockedIn)
  }
  # Locked out constraint
  if(criteria == "Locked out"){
    if(problemFormatDatasheet$dataType == "Spatial"){
      lockedOut <- raster(lockedOutDatasheet$locked_out)
      crs(lockedIn) <- NA
    }
    if(problemFormatDatasheet$dataType == "Tabular"){
      lockedOut <- data.table::fread(file.path(lockedOutDatasheet$locked_out),
                                    data.table = FALSE)[,-1]
      }
    criteriaFunction <- function(x) add_locked_out_constraints(x, 
                                                               lockedOut)
  }
  # Contiguity constraint
  if(criteria == "Neighbor"){
    k <- neighborDatasheet$k
    criteriaFunction <- function(x) add_neighbor_constraints(x, k)
  }
  # Contiguity constraint
  if(criteria == "Contiguity"){
    if(problemFormatDatasheet$dataType == "Spatial") {
      criteriaFunction <- function(x) add_contiguity_constraints(x)
    }
    if(problemFormatDatasheet$dataType == "Tabular"){
      connect_dat <- data.table::fread(file.path(boundaryDatasheet$data),
                                     data.table = FALSE)[,-1]
      criteriaFunction <- function(x) add_contiguity_constraints(
        x, data = connect_dat)
    }
  }
  # Feature contiguity constraint
  if(criteria == "Feature contiguity"){
    criteriaFunction <- function(x) add_feature_contiguity_constraints(x)
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
                                    data.table = FALSE)[,-1]
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
  
  # Solver
  if(criteria == "Solver"){
    if(!is.na(solverDatasheet$gap)){
      gap <- solverDatasheet$gap
      criteriaFunction <- function(x) add_rsymphony_solver(x, 
                                                           gap = gap)
    } else {
      criteriaFunction <- function(x) add_rsymphony_solver(x) }
  } 
  
  # Update
  scenarioProblem <- criteriaFunction(scenarioProblem)
}



# Solve the problem ------------------------------------------------------------

# Run solver
scenarioSolution <- solve(scenarioProblem)

# Save raster
if(problemFormatDatasheet$dataType == "Spatial"){
  solutionFilename <- file.path(paste0(outputDir, "\\solutionRaster.tif"))
  writeRaster(scenarioSolution, filename = solutionFilename,
              format = "GTiff", overwrite = TRUE)
  # Save file path to datasheet
  temp_solutionRasterOutput <- data.frame(solution = solutionFilename)
  solutionRasterOutput <- rbind(solutionRasterOutput, 
                                   temp_solutionRasterOutput)
  saveDatasheet(ssimObject = myScenario, 
                data = solutionRasterOutput, 
                name = "prioritizr_solutionRasterOutput")
}
# Save tabular output
if(problemFormatDatasheet$dataType == "Tabular"){
    # Save file path to datasheet
  solutionTabularOutput <- rbind(solutionTabularOutput, 
                                    scenarioSolution)
  saveDatasheet(ssimObject = myScenario, 
                data = solutionTabularOutput, 
                name = "prioritizr_solutionTabularOutput")
}



# Evaluate performance ---------------------------------------------------------

progressBar(message = "Evaluating performance and importance", type = "message")

# Calculate solution number
if(performanceDatasheet$eval_n_summary){
  
  if(problemFormatDatasheet$dataType == "Spatial"){
    n <- eval_n_summary(scenarioProblem, scenarioSolution) }
  if(problemFormatDatasheet$dataType == "Tabular"){
    n <- eval_n_summary(scenarioProblem, scenarioSolution[,"solution_1", 
                                                          drop = FALSE]) }
  # Save results
  numberOutput <- rbind(numberOutput, as.data.frame(n))
  saveDatasheet(ssimObject = myScenario, 
                data = numberOutput, 
                name = "prioritizr_numberOutput")
}

# Calculate solution cost
if(performanceDatasheet$eval_cost_summary){
  
  if(problemFormatDatasheet$dataType == "Spatial"){
    cost <- eval_cost_summary(scenarioProblem, scenarioSolution) }
  if(problemFormatDatasheet$dataType == "Tabular"){
    cost <- eval_cost_summary(scenarioProblem, scenarioSolution[,"solution_1",
                                                                drop = FALSE]) }
  # Save results
  costOutput <- rbind(costOutput, as.data.frame(cost))
  saveDatasheet(ssimObject = myScenario, 
                data = costOutput, 
                name = "prioritizr_costOutput")
}

# Calculate how well features are represented by a solution
if(performanceDatasheet$eval_feature_representation_summary){
  
  if(problemFormatDatasheet$dataType == "Spatial"){
    featureRepresentation <- eval_feature_representation_summary(
      scenarioProblem, scenarioSolution) }
  if(problemFormatDatasheet$dataType == "Tabular"){
    featureRepresentation <- eval_feature_representation_summary(
      scenarioProblem, scenarioSolution[,"solution_1", drop = FALSE]) }
  
  # Save results
  names(featureRepresentation)[2] <- "projectFeaturesID"
  featureRepresentationOutput <- addRow(featureRepresentationOutput,
                                        as.data.frame(featureRepresentation))
  saveDatasheet(ssimObject = myScenario, 
                data = featureRepresentationOutput, 
                name = "prioritizr_featureRepresentationOutput") 
}

# Calculate how well the targets are met by the solution
if(performanceDatasheet$eval_target_coverage_summary){
  if(problemFormatDatasheet$dataType == "Spatial"){
    targetCoverage <- eval_target_coverage_summary(scenarioProblem, 
                                                   scenarioSolution) }
  if(problemFormatDatasheet$dataType == "Tabular"){
    targetCoverage <- eval_target_coverage_summary(
      scenarioProblem, scenarioSolution[,"solution_1", drop = FALSE]) }
    
  # Save results
  names(targetCoverage)[1] <- "projectFeaturesID"
  targetCoverageOutput <- rbind(targetCoverageOutput,
                                as.data.frame(targetCoverage))
  saveDatasheet(ssimObject = myScenario, 
                data = targetCoverageOutput, 
                name = "prioritizr_targetCoverageOutput") 
}

# Calculate solution the total exposed boundary length (perimeter)
if(performanceDatasheet$eval_boundary_summary){
  
  if(problemFormatDatasheet$dataType == "Spatial"){
    temp_boundaryOutput <- eval_boundary_summary(scenarioProblem, 
                                                 scenarioSolution)
  # Save results
  boundaryOutput <- rbind(boundaryOutput, as.data.frame(temp_boundaryOutput))
  saveDatasheet(ssimObject = myScenario, 
                data = boundaryOutput, 
                name = "prioritizr_boundaryOutput")
  }
}



# Evaluate importance ----------------------------------------------------------

# Calculate replacement cost scores
if(importanceDatasheet$eval_replacement_importance){
  if(problemFormatDatasheet$dataType == "Spatial"){
    
    replacementImportance <- scenarioProblem %>%
      eval_replacement_importance(scenarioSolution)
    
    # Save raster
    replacementFilename <- file.path(paste0(outputDir, "\\replacementRaster.tif"))
    writeRaster(replacementImportance, filename = replacementFilename,
                format = "GTiff", overwrite = TRUE)
    
    # Save file path to datasheet
    temp_replacementSpatialOutput <- data.frame(replacement = replacementFilename)
    replacementSpatialOutput <- rbind(replacementSpatialOutput, temp_replacementSpatialOutput)
    saveDatasheet(ssimObject = myScenario, 
                  data = replacementSpatialOutput, 
                  name = "prioritizr_replacementSpatialOutput")
    }
  if(problemFormatDatasheet$dataType == "Tabular"){
    replacementImportance <- scenarioProblem %>%
      eval_replacement_importance(scenarioSolution[,"solution_1", 
                                                   drop = FALSE])
    # Save results
    replacementTabularOutput <- addRow(replacementTabularOutput,
                                       as.data.frame(replacementImportance))
    saveDatasheet(ssimObject = myScenario, 
                  data = replacementTabularOutput, 
                  name = "prioritizr_replacementTabularOutput") 
    }
}

# Calculate Ferrier scores and extract total score
if(importanceDatasheet$eval_ferrier_importance){
  if(problemFormatDatasheet$dataType == "Spatial"){
    
    ferrierScores <- eval_ferrier_importance(scenarioProblem, scenarioSolution)
    
    # Save raster
    ferrierFilename <- file.path(paste0(outputDir, "\\ferrierRaster.tif"))
    writeRaster(ferrierScores[["total"]], filename = ferrierFilename,
                format = "GTiff", overwrite = TRUE)
    
    # Save file path to datasheet
    temp_ferrierSpatialOutput <- data.frame(ferrierMethod = ferrierFilename)
    ferrierSpatialOutput <- rbind(ferrierSpatialOutput, temp_ferrierSpatialOutput)
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
                   names_to = "projectFeaturesID",
                   values_to = "scores")
    
    # Save results
    ferrierTabularOutput <- addRow(ferrierTabularOutput,
                                   as.data.frame(ferrierScores))
    saveDatasheet(ssimObject = myScenario, 
                  data = ferrierTabularOutput, 
                  name = "prioritizr_ferrierTabularOutput")
    }
}

# Calculate rarity weighted richness scores
if(importanceDatasheet$eval_rare_richness_importance){
  if(problemFormatDatasheet$dataType == "Spatial"){
    
    rarityScores <- eval_rare_richness_importance(scenarioProblem, 
                                                  scenarioSolution)
    
    # Save raster
    rarityFilename <- file.path(paste0(outputDir, "\\rarityRaster.tif"))
    writeRaster(rarityScores, filename = rarityFilename,
                format = "GTiff", overwrite = TRUE)
    
    # Save file path to datasheet
    temp_raritySpatialOutput <- data.frame(rarityWeightedRichness = rarityFilename)
    raritySpatialOutput <- rbind(raritySpatialOutput, temp_raritySpatialOutput)
    saveDatasheet(ssimObject = myScenario, 
                  data = raritySpatialOutput, 
                  name = "prioritizr_raritySpatialOutput")
  }
  if(problemFormatDatasheet$dataType == "Tabular"){
    
    rarityScores <- eval_rare_richness_importance(
      scenarioProblem, scenarioSolution[,"solution_1", drop = FALSE])
    
    # Save results
    rarityTabularOutput <- addRow(rarityTabularOutput,
                                   as.data.frame(rarityScores))
    saveDatasheet(ssimObject = myScenario, 
                  data = rarityTabularOutput, 
                  name = "prioritizr_rarityTabularOutput")
    }
}

