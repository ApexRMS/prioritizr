## prioritizr SyncroSim
##
## Written by Carina Rauen Firkowski
##
## This script is the transformer for the prioritizr SyncroSim package. It loads
## the inputs from SyncroSim to create the prioritizr problem, solves the
## problem, prepares the solution output, and performs any requires evaluations.



# Workspace -------------------------------------------------------------------

# Load packages
library(rsyncrosim)
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
penaltiesDatasheet <- datasheet(myScenario,
                                name = "prioritizr_penalties")
decisionDatasheet <- datasheet(myScenario,
                               name = "prioritizr_decisionTypes")
solverDatasheet <- datasheet(myScenario,
                             name = "prioritizr_solver")
performanceDatasheet <- datasheet(myScenario,
                                  name = "prioritizr_evaluatePerformance")
importanceDatasheet <- datasheet(myScenario,
                                 name = "prioritizr_evaluateImportance")
resultsDatasheet <- datasheet(myScenario,
                              name = "prioritizr_results")



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
if(dim(contiguityDatasheet)[1] != 0){
  criteriaList <- c(criteriaList, "Contiguity") } 
if(dim(penaltiesDatasheet)[1] != 0){
  if(penaltiesDatasheet$add_boundary_penalties){
  criteriaList <- c(criteriaList, "Boundary penalties") }}  



# Create problem ---------------------------------------------------------------

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
      criteriaFunction <- function(x) add_relative_targets(x, 
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
  
  # Penalties
  # Boundary penalties
  if(criteria == "Boundary penalties"){
    penalty <- penaltiesDatasheet$penalty
    if(!is.na(penaltiesDatasheet$edge_factor)){
      edge_factor <- penaltiesDatasheet$edge_factor
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
plot(scenarioSolution)
solutionFilename <- file.path(paste0(outputDir, "\\solutionRaster.tif"))
writeRaster(scenarioSolution, filename = solutionFilename,
            format = "GTiff", overwrite = TRUE)

# Save file path to datasheet
temp_resultsDatasheet <- data.frame(solution = solutionFilename)
resultsDatasheet <- rbind(resultsDatasheet, temp_resultsDatasheet)
saveDatasheet(ssimObject = myScenario, 
              data = resultsDatasheet, 
              name = "prioritizr_results")



# Evaluate performance & importance --------------------------------------------

# Calculate solution cost
if(performanceDatasheet$eval_cost_summary){
  cost <- eval_cost_summary(scenarioProblem, scenarioSolution)
}

# Calculate how well the targets are met by the solution
if(performanceDatasheet$eval_target_coverage_summary){
  targetCoverage <- eval_target_coverage_summary(scenarioProblem, 
                                                 scenarioSolution)
}

# 
#if(importanceDatasheet$eval_replacement_importance){
#  targetCoverage <- eval_replacement_importance(scenarioProblem, 
#                                                scenarioSolution)
#}


# create new problem with contiguity constraints
p4 <- p3 %>%
  add_contiguity_constraints()

# solve the problem
s4 <- solve(p4)

# plot the solution
spplot(s4, "solution_1", main = "Solution", at = c(0, 0.5, 1.1),
       col.regions = c("grey90", "darkgreen"), xlim = c(-0.1, 1.1),
       ylim = c(-0.1, 1.1))

# solve the problem
rc <- p4 %>%
  add_default_solver(gap = 0, verbose = FALSE) %>%
  eval_replacement_importance(s4[, "solution_1"])

# set infinite values as 1.09 so we can plot them
rc$rc[rc$rc > 100] <- 1.09

# plot the importance scores
# planning units that are truly irreplaceable are shown in red
spplot(rc, "rc", main = "Irreplaceability", xlim = c(-0.1, 1.1),
       ylim = c(-0.1, 1.1), at = c(seq(0, 0.9, 0.1), 1.01, 1.1),
       col.regions = c("#440154", "#482878", "#3E4A89", "#31688E", "#26828E",
                       "#1F9E89", "#35B779", "#6DCD59", "#B4DE2C", "#FDE725",
                       "#FF0000"))