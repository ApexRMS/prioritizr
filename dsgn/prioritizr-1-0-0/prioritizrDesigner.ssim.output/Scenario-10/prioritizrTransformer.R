## prioritizr SyncroSim
##
## Written by Carina Rauen Firkowski
##
## This script:
##



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


# Open datasheets --------------------------------------------------------------

problemDatasheet <- datasheet(myScenario, 
                              name = "prioritizr_problem")
objectiveDatasheet <- datasheet(myScenario, 
                                name = "prioritizr_objective")
targetDatasheet <- datasheet(myScenario,
                             name = "prioritizr_targets")
constraintsDatasheet <- datasheet(myScenario,
                                  name = "prioritizr_constraints")
penaltiesDatasheet <- datasheet(myScenario,
                                name = "prioritizr_penalties")
decisionDatasheet <- datasheet(myScenario,
                               name = "prioritizr_decisionTypes")
solverDatasheet <- datasheet(myScenario,
                             name = "prioritizr_solver")

# Load data --------------------------------------------------------------------

# Planning unit
pu_filename <- problemDatasheet$x
sim_pu_raster <- raster(file.path(pu_filename))

# Features
features_filename <- problemDatasheet$features
sim_features <- rast(file.path(features_filename))

data(sim_pu_raster)
data(sim_features)


# Validation -------------------------------------------------------------------

# Create list of criteria if required input
criteriaList <- c("Objective", "Target", "Decision", "Solver")

# Append with additional criteria
if(dim(constraintsDatasheet)[1] != 0){
  if(constraintsDatasheet$add_locked_in_constraints){
  criteriaList <- c(criteriaList, "Locked in constraints") }}  
if(dim(constraintsDatasheet)[1] != 0){
  if(constraintsDatasheet$add_contiguity_constraints){
  criteriaList <- c(criteriaList, "Contiguity constraints") }} 
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
    if(decisionDatasheet$add_binary_decisions){
      criteriaFunction <- function(x) add_binary_decisions(x) }
  }  
  
  # Solver
  if(criteria == "Solver"){
    if(!is.na(solverDatasheet$gap)){
      gap <- solverDatasheet$gap
      criteriaFunction <- function(x) add_rsymphony_solver(x, 
                                                           gap = 0.015)
    } else {
      criteriaFunction <- function(x) add_rsymphony_solver(x) }
  } 
  
  # Update
  scenarioProblem <- criteriaFunction(scenarioProblem)
}



# Solve the problem ------------------------------------------------------------

scenarioSolution <- solve(scenarioProblem)

# extract the objective
print(attr(scenarioSolution, "objective"))

# extract time spent solving the problem
print(attr(scenarioSolution, "runtime"))

# extract state message from the solver
print(attr(scenarioSolution, "status"))

# plot the solution
plot(scenarioSolution, col = c("grey90", "darkgreen"), main = "Solution",
     xlim = c(-0.1, 1.1), ylim = c(-0.1, 1.1))

# calculate solution cost
eval_cost_summary(scenarioProblem, scenarioSolution)

# calculate information describing how well the targets are met by the solution
print(eval_target_coverage_summary(scenarioProblem, scenarioSolution),
      width = Inf)

# create new problem with locked in constraints added to it
p2 <- p1 %>%
  add_locked_in_constraints("locked_in")

# solve the problem
s2 <- solve(p2)

# plot the solution
spplot(s2, "solution_1", main = "Solution", at = c(0, 0.5, 1.1),
       col.regions = c("grey90", "darkgreen"), xlim = c(-0.1, 1.1),
       ylim = c(-0.1, 1.1))

# create new problem with boundary penalties added to it
p3 <- p2 %>%
  add_boundary_penalties(penalty = 300, edge_factor = 0.5)

# solve the problem
s3 <- solve(p3)

# plot the solution
spplot(s3, "solution_1", main = "Solution", at = c(0, 0.5, 1.1),
       col.regions = c("grey90", "darkgreen"), xlim = c(-0.1, 1.1),
       ylim = c(-0.1, 1.1))

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