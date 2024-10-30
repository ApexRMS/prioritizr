## prioritizr SyncroSim
##
## Written by Carina Rauen Firkowski
##
## This script is the transformer for the prioritizr SyncroSim package. It loads
## the inputs from SyncroSim to create the prioritizr problem, solves the
## problem, prepares the solution output, and performs any required evaluations.



# Workspace -------------------------------------------------------------------

# Load packages
library(rsyncrosim) ; progressBar(type = "message", 
                                  message = "Setting up workspace")
library(stringr)
library(raster)
library(terra)
library(prioritizr)
library(Rsymphony)

# Load project & scenario
myProject <- rsyncrosim::project()
myScenario <- scenario()

# Output directory
e <- ssimEnvironment()
outputDir <- e$OutputDirectory
# Create directory if it does not exist
ifelse(!dir.exists(file.path(outputDir)), 
       dir.create(file.path(outputDir)), FALSE)



# Open datasheets --------------------------------------------------------------

progressBar(type = "message", message = "Loading data and setting up scenario")

problemDatasheet <- datasheet(myScenario, 
                              name = "prioritizr_problem")
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
replacementOutput <- datasheet(myScenario,
                               name = "prioritizr_replacementOutput")



# Load data --------------------------------------------------------------------

# Planning unit
pu_filename <- problemDatasheet$x
fileExtension <- str_sub(pu_filename, start= -3)
if(fileExtension == "tif"){
  sim_pu <- raster(file.path(pu_filename))
  crs(sim_pu) <- NA }
if(fileExtension == "csv"){
  sim_pu <- data.table::fread(file.path(pu_filename),
                              data.table = FALSE)[,-1] }

# Features
features_filename <- problemDatasheet$features
fileExtension <- str_sub(features_filename, start= -3)
if(fileExtension == "tif"){
  sim_features <- stack(file.path(features_filename))
  crs(sim_features) <- NA }
if(fileExtension == "csv"){
  sim_features <- data.table::fread(file.path(features_filename),
                                    data.table = FALSE)[,-1]}

# Planning units vs. Features
if(!is.na(problemDatasheet$rij)){
  rij_filename <- problemDatasheet$rij
  rij <- data.table::fread(file.path(rij_filename), data.table = FALSE)[,-1] }

# Save features to project scope
if(fileExtension == "tif"){
  featuresDatasheet <- data.frame(Name = names(sim_features)) }
if(fileExtension == "csv"){
  featuresDatasheet <- data.frame(Name = sim_features$name) }
saveDatasheet(ssimObject = myProject, 
              data = featuresDatasheet, 
              name = "prioritizr_projectFeatures")



# Validation -------------------------------------------------------------------

# Create list of criteria if required input
criteriaList <- c("Objective", "Target", "Decision", "Solver")

# Append with additional criteria
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
  criteriaList <- c(criteriaList, "Boundary penalties") }  



# Create problem ---------------------------------------------------------------

progressBar(message = "Creating and solving problem", 
            type = "message")

# Problem
if(fileExtension == "tif"){
  scenarioProblem <- problem(sim_pu, features = sim_features) }
if(fileExtension == "csv"){
  scenarioProblem <- problem(sim_pu, features = sim_features,
                             cost_column = "cost", rij = rij) }

# Update problem recursively
for(criteria in criteriaList){
  
  # Objective
  if(criteria == "Objective"){
    if(objectiveDatasheet$addObjective == "Maximum cover"){
      criteriaFunction <- function(x) add_max_cover_objective(x) }
    if(objectiveDatasheet$addObjective == "Maximum features"){
      criteriaFunction <- function(x) add_max_features_objective(x) }
    if(objectiveDatasheet$addObjective == "Maximum utility"){
      criteriaFunction <- function(x) add_max_utility_objective(x) }
    if(objectiveDatasheet$addObjective == "Minimum largest shortfall"){
      criteriaFunction <- function(x) add_min_largest_shortfall_objective(x) }
    if(objectiveDatasheet$addObjective == "Minimum set"){
      criteriaFunction <- function(x) add_min_set_objective(x) }
    if(objectiveDatasheet$addObjective == "Minimum shortfall"){
      criteriaFunction <- function(x) add_min_shortfall_objective(x) }
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
  
  # Solver
  if(criteria == "Solver"){
    if(!is.na(solverDatasheet$gap)){
      gap <- solverDatasheet$gap
      criteriaFunction <- function(x) add_rsymphony_solver(x, 
                                                           gap = gap)
    } else {
      criteriaFunction <- function(x) add_rsymphony_solver(x) }
  } 
  
  # Constraints
  # Locked in constraint
  if(criteria == "Locked in"){
    if(!is.na(lockedInDatasheet$locked_in)){
      lockedIn <- lockedInDatasheet$locked_in
    }
    if(fileExtension == "tif"){
      if(!is.na(lockedInDatasheet$locked_in_raster)){
        lockedIn <- raster(lockedInDatasheet$locked_in_raster)
        crs(lockedIn) <- NA
    } }
    if(fileExtension == "csv"){
      if(!is.na(lockedInDatasheet$locked_in_column)){
        lockedIn <- lockedInDatasheet$locked_in_column
    } }
    criteriaFunction <- function(x) add_locked_in_constraints(x, 
                                                              lockedIn)
  }
  # Locked out constraint
  if(criteria == "Locked out"){
    if(!is.na(lockedOutDatasheet$locked_out)){
      lockedOut <- lockedOutDatasheet$locked_out
    }
    if(fileExtension == "tif"){
      if(!is.na(lockedOutDatasheet$locked_out_raster)){
        lockedOut <- raster(lockedOutDatasheet$locked_out_raster)
        crs(lockedIn) <- NA
    } }
    if(fileExtension == "csv"){
      if(!is.na(lockedOutDatasheet$locked_out_column)){
        lockedOut <- lockedOutDatasheet$locked_out_column
    } }
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
    criteriaFunction <- function(x) add_contiguity_constraints(x)
  }
  # Feature contiguity constraint
  if(criteria == "Feature contiguity"){
    criteriaFunction <- function(x) add_feature_contiguity_constraints(x)
  }
  
  # Penalties
  # Boundary penalties
  if(criteria == "Boundary penalties"){
    penalty <- boundaryDatasheet$penalty
    if(!is.na(boundaryDatasheet$edge_factor)){
      edge_factor <- boundaryDatasheet$edge_factor
      criteriaFunction <- function(x) 
        add_boundary_penalties(x, penalty = penalty, edge_factor = edge_factor) 
    } else {
      criteriaFunction <- function(x) add_boundary_penalties(x, 
                                                             penalty = penalty) 
    }
  }
  
  # Update
  scenarioProblem <- criteriaFunction(scenarioProblem)
}



# Solve the problem ------------------------------------------------------------

# Run solver
scenarioSolution <- solve(scenarioProblem)

# Save raster
if(fileExtension == "tif"){
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
if(fileExtension == "csv"){
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
  
  if(fileExtension == "tif"){
    n <- eval_n_summary(scenarioProblem, scenarioSolution) }
  if(fileExtension == "csv"){
    totalN <- sum(scenarioSolution$solution_1, na.rm = T)
    n <- data.frame(summary = "overall",
                    n = totalN) }
  # Save results
  numberOutput <- rbind(numberOutput, as.data.frame(n))
  saveDatasheet(ssimObject = myScenario, 
                data = numberOutput, 
                name = "prioritizr_numberOutput")
}

# Calculate solution cost
if(performanceDatasheet$eval_cost_summary){
  
  if(fileExtension == "tif"){
    cost <- eval_cost_summary(scenarioProblem, scenarioSolution) }
  if(fileExtension == "csv"){
    totalCost <- sum(scenarioSolution$solution_1 * sim_pu$cost, na.rm = T)
    cost <- data.frame(summary = "overall",
                       cost = totalCost) }
  # Save results
  costOutput <- rbind(costOutput, as.data.frame(cost))
  saveDatasheet(ssimObject = myScenario, 
                data = costOutput, 
                name = "prioritizr_costOutput")
}

# Calculate how well features are represented by a solution
if(performanceDatasheet$eval_feature_representation_summary){
  if(fileExtension == "tif"){
    
    featureRepresentation <- eval_feature_representation_summary(scenarioProblem,
                                                                 scenarioSolution)
    
    # Save results
    names(featureRepresentation)[2] <- "projectFeaturesID"
    featureRepresentationOutput <- addRow(featureRepresentationOutput,
                                          as.data.frame(featureRepresentation))
    saveDatasheet(ssimObject = myScenario, 
                  data = featureRepresentationOutput, 
                  name = "prioritizr_featureRepresentationOutput") 
  }
}

# Calculate how well the targets are met by the solution
if(performanceDatasheet$eval_target_coverage_summary){
  if(fileExtension == "tif"){
    
    targetCoverage <- eval_target_coverage_summary(scenarioProblem, 
                                                   scenarioSolution)
    
    # Save results
    names(targetCoverage)[1] <- "projectFeaturesID"
    targetCoverageOutput <- addRow(targetCoverageOutput, 
                                      as.data.frame(targetCoverage))
    saveDatasheet(ssimObject = myScenario, 
                  data = targetCoverageOutput, 
                  name = "prioritizr_targetCoverageOutput") 
  }
}

# Calculate solution the total exposed boundary length (perimeter)
if(performanceDatasheet$eval_boundary_summary){
  
  if(fileExtension == "tif"){
    temp_boundaryOutput <- eval_boundary_summary(scenarioProblem, 
                                                 scenarioSolution) }
  # Save results
  boundaryOutput <- rbind(boundaryOutput, as.data.frame(temp_boundaryOutput))
  saveDatasheet(ssimObject = myScenario, 
                data = boundaryOutput, 
                name = "prioritizr_boundaryOutput")
}



# Evaluate importance ----------------------------------------------------------

# Calculate replacement cost scores
if(importanceDatasheet$eval_replacement_importance){
  if(fileExtension == "tif"){
    
    replacementImportance <- scenarioProblem %>%
      eval_replacement_importance(scenarioSolution)
    
    # Save raster
    replacementFilename <- file.path(paste0(outputDir, "\\replacementRaster.tif"))
    writeRaster(replacementImportance, filename = replacementFilename,
                format = "GTiff", overwrite = TRUE)
    
    # Save file path to datasheet
    temp_replacementOutput <- data.frame(replacement = replacementFilename)
    replacementOutput <- rbind(replacementOutput, temp_replacementOutput)
    saveDatasheet(ssimObject = myScenario, 
                  data = replacementOutput, 
                  name = "prioritizr_replacementOutput")
  }
}


