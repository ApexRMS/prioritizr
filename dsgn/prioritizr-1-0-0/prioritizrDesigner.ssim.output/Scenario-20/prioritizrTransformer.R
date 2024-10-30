## prioritizr SyncroSim
##
## Written by Carina Rauen Firkowski
##
## This script is the transformer for the prioritizr SyncroSim package. It loads
## the inputs from SyncroSim to create the prioritizr problem, solves the
## problem, prepares the solution output, and performs any requires evaluations.



# Workspace -------------------------------------------------------------------

# Load packages
library(rsyncrosim) ; progressBar(type = "message", 
                                  message = "Setting up workspace")
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

problemDatasheet <- datasheet(myScenario, 
                              name = "prioritizr_problem")
objectiveDatasheet <- datasheet(myScenario, 
                                name = "prioritizr_objective")
targetDatasheet <- datasheet(myScenario,
                             name = "prioritizr_targets")
lockedInDatasheet <- datasheet(myScenario,
                               name = "prioritizr_lockedIn")
contiguityDatasheet <- datasheet(myScenario,
                                 name = "prioritizr_contiguity")
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
solutionDatasheet <- datasheet(myScenario,
                                     name = "prioritizr_solutionOutput")
costDatasheet <- datasheet(myScenario,
                           name = "prioritizr_costOutput")
targetCoverageDatasheet <- datasheet(myScenario,
                                     name = "prioritizr_targetCoverageOutput")
replacementDatasheet <- datasheet(myScenario,
                                  name = "prioritizr_replacementOutput")



# Load data --------------------------------------------------------------------

# Planning unit
pu_filename <- problemDatasheet$x
sim_pu_raster <- raster(file.path(pu_filename))
crs(sim_pu_raster) <- NA

# Features
features_filename <- problemDatasheet$features
sim_features <- stack(file.path(features_filename))
crs(sim_features) <- NA



# Validation -------------------------------------------------------------------

# Create list of criteria if required input
criteriaList <- c("Objective", "Target", "Decision", "Solver")

# Append with additional criteria
if(dim(lockedInDatasheet)[1] != 0){
  criteriaList <- c(criteriaList, "Locked in") }
if(contiguityDatasheet$add_contiguity_constraints){
  criteriaList <- c(criteriaList, "Contiguity") } 
if(dim(boundaryDatasheet)[1] != 0){
  criteriaList <- c(criteriaList, "Boundary penalties") }  



# Create problem ---------------------------------------------------------------

progressBar(message = "Creating and solving prioritizr problem", 
            type = "message")

# Problem
scenarioProblem <- problem(sim_pu_raster, features = sim_features)

# Update problem recursively
for(criteria in criteriaList){
  
  # Objective
  if(criteria == "Objective"){
    if(objectiveDatasheet$addObjective == "Minimum set objective"){
      criteriaFunction <- function(x) add_min_set_objective(x) }
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
    if(decisionDatasheet$addDecision == "Binary"){
      criteriaFunction <- function(x) add_binary_decisions(x) }
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
    if(!is.na(lockedInDatasheet$locked_in_raster)){
      lockedIn <- raster(lockedInDatasheet$locked_in_raster)
      crs(lockedIn) <- NA
    }
    criteriaFunction <- function(x) add_locked_in_constraints(x, 
                                                              lockedIn)
  }
  # Contiguity constraint
  if(criteria == "Contiguity"){
    criteriaFunction <- function(x) add_contiguity_constraints(x)
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
solutionFilename <- file.path(paste0(outputDir, "\\solutionRaster.tif"))
writeRaster(scenarioSolution, filename = solutionFilename,
            format = "GTiff", overwrite = TRUE)

# Save file path to datasheet
temp_solutionDatasheet <- data.frame(solution = solutionFilename)
solutionDatasheet <- rbind(solutionDatasheet, temp_solutionDatasheet)
saveDatasheet(ssimObject = myScenario, 
              data = solutionDatasheet, 
              name = "prioritizr_solutionOutput")



# Evaluate performance & importance --------------------------------------------

progressBar(message = "Evaluating performance and importance", type = "message")

# Calculate solution cost
if(performanceDatasheet$eval_cost_summary){
  cost <- eval_cost_summary(scenarioProblem, scenarioSolution) }
# Save results
costDatasheet <- rbind(costDatasheet, as.data.frame(cost))
saveDatasheet(ssimObject = myScenario, 
              data = costDatasheet, 
              name = "prioritizr_costOutput")

# Calculate how well the targets are met by the solution
if(performanceDatasheet$eval_target_coverage_summary){
  targetCoverage <- eval_target_coverage_summary(scenarioProblem, 
                                                 scenarioSolution) }
# Save results
targetCoverageDatasheet <- rbind(targetCoverageDatasheet, 
                                 as.data.frame(targetCoverage))
saveDatasheet(ssimObject = myScenario, 
              data = targetCoverageDatasheet, 
              name = "prioritizr_targetCoverageOutput")

# Calculate replacement cost scores
if(importanceDatasheet$eval_replacement_importance){
  replacementImportance <- scenarioProblem %>%
    eval_replacement_importance(scenarioSolution)
}
# Save raster
replacementFilename <- file.path(paste0(outputDir, "\\replacementRaster.tif"))
writeRaster(replacementImportance, filename = replacementFilename,
            format = "GTiff", overwrite = TRUE)

# Save file path to datasheet
temp_replacementDatasheet <- data.frame(replacement = replacementFilename)
replacementDatasheet <- rbind(replacementDatasheet, temp_replacementDatasheet)
saveDatasheet(ssimObject = myScenario, 
              data = replacementDatasheet, 
              name = "prioritizr_replacementOutput")


