## prioritizr SyncroSim - Problem formulation
##
## Written by Carina Rauen Firkowski
##
## This script loads the inputs from SyncroSim to create a prioritizr problem.



# Open datasheets --------------------------------------------------------------

progressBar(type = "message", message = "Loading data and setting up scenario")

problemFormatDatasheet <- datasheet(myScenario,
                                    name = "prioritizr_problemFormat")
problemSpatialDatasheet <- datasheet(myScenario,
                                     name = "prioritizr_problemSpatial")
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
linearDatasheet <- datasheet(myScenario,
                             name = "prioritizr_linearPenalties")
weightsDatasheet <- datasheet(myScenario,
                              name = "prioritizr_featureWeights")
objectiveDatasheet <- datasheet(myScenario, 
                                name = "prioritizr_objective")
decisionDatasheet <- datasheet(myScenario,
                               name = "prioritizr_decisionTypes")
solverDatasheet <- datasheet(myScenario,
                             name = "prioritizr_solver")




# Rename variable names for consistency with prioritizr R ----------------------

names(contiguityDatasheet)[1] <- "add_contiguity_constraints"
names(featureContiguityDatasheet) <- "add_feature_contiguity_constraints"
names(linearConstraintDatasheet)[1] <- "add_linear_constraints"
names(lockedInDatasheet) <- c("add_locked_in_constraints", "locked_in")
names(lockedOutDatasheet) <- c("add_locked_out_constraints", "locked_out")
names(neighborDatasheet)[1] <- "add_neighbor_constraints"
names(boundaryDatasheet)[1] <- "add_boundary_penalties"
names(boundaryDatasheet)[3] <- "edge_factor"
names(linearDatasheet)[1] <- "add_linear_penalties"
names(weightsDatasheet)[1] <- "add_feature_weights"
names(decisionDatasheet)[2] <- "upper_limit"



# Validation -------------------------------------------------------------------

# If datasheet is not empty, set NA values to FALSE 
# If datasheet is empty, set all columns to FALSE
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
  sim_features <- rast(file.path(problemSpatialDatasheet$features))
  crs(sim_features) <- NA
  
  # Features' names
  featuresDatasheet <- data.frame(Name = names(sim_features))

}

# Tabular data
if(problemFormatDatasheet$dataType == "Tabular"){
  
  # Open datasheet
  problemTabularDatasheet <- datasheet(myScenario, 
                                       name = "prioritizr_problemTabular")
  # Rename variable for consistency with prioritizr R
  names(problemTabularDatasheet)[4] <- "cost_column"
  
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

progressBar(message = "Formulating problem", type = "message")

# Create list of criteria if required input
criteriaList <- c("Objective", "Decision", "Solver")

# If criteria is enable, append to list of criteria
if(dim(targetDatasheet)[1] != 0){
  if(!is.na(targetDatasheet$addTarget)){
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
    }
    if(problemFormatDatasheet$dataType == "Tabular"){
      data <- data.table::fread(file.path(linearConstraintDatasheet$data),
                                data.table = FALSE)
    }
    threshold <- linearConstraintDatasheet$threshold
    senseCode <- linearConstraintDatasheet$sense
    if(senseCode == "Larger or equal") sense <- ">="
    if(senseCode == "Smaller or equal") sense <- "<="
    if(senseCode == "Equal") sense <- "="
    criteriaFunction <- function(x) add_linear_constraints(x, threshold,
      sense, data[,1])
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
      crs(lockedOut) <- NA
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


