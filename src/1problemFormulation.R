## prioritizr SyncroSim - Problem formulation
##
## Written by Carina Rauen Firkowski
##
## This script loads the inputs from SyncroSim to create a prioritizr problem.

# Open datasheets --------------------------------------------------------------

progressBar(type = "message", message = "Loading data and setting up scenario")

problemFormatDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_problemFormat"
)
problemSpatialDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_problemSpatial"
)
targetDatasheet <- datasheet(myScenario, name = "prioritizr_targets")
contiguityDatasheet <- datasheet(myScenario, name = "prioritizr_contiguity")
featureContiguityDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_featureContiguity"
)
linearConstraintDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_linearParameters"
)
linearSpatialDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_linearDataSpatial"
)
linearTabularDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_linearDataTabular"
)
lockedInSpatialDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_lockedInSpatial"
)
lockedInTabularDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_lockedInTabular"
)
lockedOutSpatialDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_lockedOutSpatial"
)
lockedOutTabularDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_lockedOutTabular"
)
neighborDatasheet <- datasheet(myScenario, name = "prioritizr_neighbor")
boundaryParametersDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_boundaryPenaltiesParameters"
)
boundaryDataDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_boundaryPenaltiesData"
)
linearDataDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_linearPenaltiesData"
)
linearParameterDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_linearPenaltiesParameter"
)
weightsDatasheet <- datasheet(myScenario, name = "prioritizr_featureWeights")
objectiveDatasheet <- datasheet(myScenario, name = "prioritizr_objective")
decisionDatasheet <- datasheet(myScenario, name = "prioritizr_decisionTypes")
solverDatasheet <- datasheet(myScenario, name = "prioritizr_solver")


# Rename variable names for consistency with prioritizr R ----------------------

names(lockedInSpatialDatasheet)[1] <- "locked_in"
names(lockedOutSpatialDatasheet)[1] <- "locked_out"
names(boundaryParametersDatasheet)[2] <- "edge_factor"
names(decisionDatasheet)[2] <- "upper_limit"


# Validation -------------------------------------------------------------------

# Set default values if missing
if (dim(objectiveDatasheet)[1] == 0) {
  stop("A problem Objective must be defined.")
}
if (dim(objectiveDatasheet)[1] != 0) {
  if (
    objectiveDatasheet$addObjective != "Minimum set" &
      is.na(objectiveDatasheet$budget)
  ) {
    stop("A problem Budget must be defined.")
  }
}
if (dim(targetDatasheet)[1] == 0) {
  targetDatasheet <- data.frame(addTarget = "Relative", targets = 1.0)
  saveDatasheet(
    ssimObject = myScenario,
    data = targetDatasheet,
    name = "prioritizr_targets"
  )
  updateRunLog(
    "No inputs were provided for the Target datasheet, therefore default values were used.",
    type = "warning"
  )
}
if (dim(decisionDatasheet)[1] == 0) {
  decisionDatasheet <- data.frame(addDecision = "Binary", upperLimit = NA)
  saveDatasheet(
    ssimObject = myScenario,
    data = decisionDatasheet,
    name = "prioritizr_decisionTypes"
  )
  names(decisionDatasheet)[2] <- "upper_limit"
  updateRunLog(
    "No inputs were provided for the Decision Types datasheet, therefore default values were used.",
    type = "warning"
  )
}
if (dim(solverDatasheet)[1] == 0) {
  solverDatasheet <- data.frame(solver = "Default", gap = NA)
  saveDatasheet(
    ssimObject = myScenario,
    data = solverDatasheet,
    name = "prioritizr_solver"
  )
  updateRunLog(
    "No inputs were provided for the Solver datasheet, therefore default values were used.",
    type = "warning"
  )
}


# NOTE: For constraints linear, locked in, locked out, scripts add validation to
#       check if provided data format matches "problemFormatDatasheet$dataType".
#       Scripts could be adapted to not force user to use same input format.

# Return warning if boundary data is provided without input settings
if (
  dim(boundaryDataDatasheet)[1] != 0 &
    dim(boundaryParametersDatasheet)[1] == 0
) {
  updateRunLog(
    "Boundary penalty data was provided without parameter settings. 
  Penalties have not been included in the problem formulation.",
    type = "warning"
  )
}


# Load data --------------------------------------------------------------------

# Spatial data
if (problemFormatDatasheet$dataType == "Spatial") {
  # Planning unit
  sim_pu <- rast(file.path(problemSpatialDatasheet$x))

  # Features
  sim_features <- rast(file.path(problemSpatialDatasheet$features))

  # Set features' names
  featuresDatasheet <- data.frame(
    featureID = 1:dim(sim_features)[3],
    Name = names(sim_features),
    variableName = names(sim_features)
  )
}

# Tabular data
if (problemFormatDatasheet$dataType == "Tabular") {
  # Planning unit
  sim_pu <- datasheet(myScenario, name = "prioritizr_problemTabularPU")
  # Set planning unit names
  puDatasheet <- sim_pu[, 1:2]
  names(puDatasheet)[1] <- "puID"
  names(puDatasheet)[2] <- "Name"
  if (all(is.na(puDatasheet$Name))) {
    puDatasheet$variableName <- puDatasheet$Name <- as.character(
      puDatasheet$puID
    )
  } else {
    puDatasheet$variableName <- puDatasheet$Name
  }

  # Features
  sim_features <- datasheet(
    myScenario,
    name = "prioritizr_problemTabularFeatures"
  )
  # Set features' names
  featuresDatasheet <- sim_features
  names(featuresDatasheet)[1] <- "featureID"
  names(featuresDatasheet)[2] <- "Name"
  featuresDatasheet$variableName <- featuresDatasheet$Name

  # Planning units vs. Features
  rij <- datasheet(myScenario, name = "prioritizr_problemTabularPUvsFeatures")

  # Spatial data for visualization
  if (dim(problemSpatialDatasheet)[1] != 0) {
    if (!is.na(problemSpatialDatasheet$x)) {
      pu_vis <- rast(file.path(problemSpatialDatasheet$x))
      puVis <- TRUE
    }
  } else {
    puVis <- FALSE
  }
}


# Update project-scope datasheets ----------------------------------------------

# Features ------------------------------------------------------

# Load existing features from project scope
featuresDatasheetExisting <- datasheet(
  myScenario,
  name = "prioritizr_projectFeatures"
)
# If datasheet is empty, save
if (dim(featuresDatasheetExisting)[1] == 0) {
  saveDatasheet(
    ssimObject = myProject,
    data = featuresDatasheet,
    name = "prioritizr_projectFeatures"
  )
} else {
  # Calculate dissimilarities in feature ID and variable names
  featuresDatasheetDifference <- setdiff(
    featuresDatasheet[, c(1, 3)],
    featuresDatasheetExisting[, c(1, 3)]
  )

  # If differences exist, update datasheet
  if (dim(featuresDatasheetDifference)[1] != 0) {
    featuresDatasheetDifference$Name <- featuresDatasheetDifference$variableName
    featuresDatasheetDifference <- featuresDatasheetDifference[, c(1, 3, 2)]
    featuresDatasheetUpdated <- rbind(
      featuresDatasheetExisting,
      featuresDatasheetDifference
    )
    saveDatasheet(
      ssimObject = myProject,
      data = featuresDatasheetUpdated,
      name = "prioritizr_projectFeatures"
    )
  }

  # Check for display name updates
  nameUpdates <- featuresDatasheetExisting$Name ==
    featuresDatasheetExisting$variableName
  featuresDatasheetSimilar <- intersect(
    featuresDatasheet[, c(1, 3)],
    featuresDatasheetExisting[, c(1, 3)]
  )
  featuresDatasheet$Name[
    featuresDatasheet$variableName == featuresDatasheetExisting$variableName
  ] <-
    featuresDatasheetExisting$Name
}

# Planning units ------------------------------------------------

# Load existing planning units from project scope
puDatasheetExisting <- datasheet(myScenario, name = "prioritizr_projectPU")
# If datasheet is empty, save
if (problemFormatDatasheet$dataType == "Tabular") {
  if (dim(puDatasheetExisting)[1] == 0) {
    saveDatasheet(
      ssimObject = myProject,
      data = puDatasheet,
      name = "prioritizr_projectPU"
    )
  } else {
    # Calculate dissimilarities in planning unit ID and variable names
    puDatasheetDifference <- setdiff(
      puDatasheet[, c(1, 3)],
      puDatasheetExisting[, c(1, 3)]
    )

    # # If differences exist in ID or variable name exist, add to datasheet
    # if(dim(puDatasheetDifference)[1] != 0){
    #   puDatasheetDifference$Name <- puDatasheetDifference$variableName
    #   puDatasheetDifference <- puDatasheetDifference[, c(1,3,2)]
    #   puDatasheetUpdated <- rbind(puDatasheetExisting,
    #                                     puDatasheetDifference)
    #   saveDatasheet(ssimObject = myProject,
    #               data = puDatasheetUpdated,
    #                 name = "prioritizr_projectPU")
    # }

    # Check for display name updates
    nameUpdates <- puDatasheetExisting$Name == puDatasheetExisting$variableName
    featuresDatasheetSimilar <- intersect(
      puDatasheet[, c(1, 3)],
      puDatasheetExisting[, c(1, 3)]
    )
    puDatasheet$Name[
      puDatasheet$variableName == puDatasheetExisting$variableName
    ] <-
      puDatasheetExisting$Name
  }
}


# Define criteria --------------------------------------------------------------

progressBar(message = "Formulating problem", type = "message")

# Create list of criteria if required input
criteriaList <- c("Objective", "Decision", "Solver")

# If criteria is enable, append to list of criteria
if (dim(targetDatasheet)[1] != 0) {
  if (!is.na(targetDatasheet$addTarget)) {
    criteriaList <- c(criteriaList, "Target")
  }
}
if (dim(contiguityDatasheet)[1] != 0) {
  criteriaList <- c(criteriaList, "Contiguity")
}
if (dim(featureContiguityDatasheet)[1] != 0) {
  criteriaList <- c(criteriaList, "Feature contiguity")
}
if (dim(linearConstraintDatasheet)[1] != 0) {
  criteriaList <- c(criteriaList, "Linear")
}
if (
  dim(lockedInSpatialDatasheet)[1] != 0 |
    dim(lockedInTabularDatasheet)[1] != 0
) {
  criteriaList <- c(criteriaList, "Locked in")
}
if (
  dim(lockedOutSpatialDatasheet)[1] != 0 |
    dim(lockedOutTabularDatasheet)[1] != 0
) {
  criteriaList <- c(criteriaList, "Locked out")
}
if (dim(neighborDatasheet)[1] != 0) {
  criteriaList <- c(criteriaList, "Neighbor")
}
if (dim(boundaryParametersDatasheet)[1] != 0) {
  criteriaList <- c(criteriaList, "Boundary penalties")
}
if (dim(linearDataDatasheet)[1] != 0) {
  criteriaList <- c(criteriaList, "Linear penalties")
}
if (dim(weightsDatasheet)[1] != 0) {
  criteriaList <- c(criteriaList, "Weights")
}


# Create problem ---------------------------------------------------------------

# Problem
if (problemFormatDatasheet$dataType == "Spatial") {
  scenarioProblem <- problem(sim_pu, features = sim_features)
}
if (problemFormatDatasheet$dataType == "Tabular") {
  scenarioProblem <- problem(
    x = sim_pu[, -which(names(sim_pu) %in% "Name")],
    features = sim_features,
    cost_column = "cost",
    rij = rij
  )
}

# Update problem recursively
for (criteria in criteriaList) {
  # Objective
  if (criteria == "Objective") {
    budget <- objectiveDatasheet$budget
    if (objectiveDatasheet$addObjective == "Maximum cover") {
      criteriaFunction <- function(x) add_max_cover_objective(x, budget)
    }
    if (objectiveDatasheet$addObjective == "Maximum features") {
      criteriaFunction <- function(x) add_max_features_objective(x, budget)
    }
    if (objectiveDatasheet$addObjective == "Maximum utility") {
      criteriaFunction <- function(x) add_max_utility_objective(x, budget)
    }
    if (objectiveDatasheet$addObjective == "Minimum largest shortfall") {
      criteriaFunction <- function(x) {
        add_min_largest_shortfall_objective(x, budget)
      }
    }
    if (objectiveDatasheet$addObjective == "Minimum set") {
      criteriaFunction <- function(x) add_min_set_objective(x)
    }
    if (objectiveDatasheet$addObjective == "Minimum shortfall") {
      criteriaFunction <- function(x) add_min_shortfall_objective(x, budget)
    }
  }

  # Target & target amount
  if (criteria == "Target") {
    targetAmount <- targetDatasheet$targets
    if (targetDatasheet$addTarget == "Absolute") {
      criteriaFunction <- function(x) {
        add_absolute_targets(x, targets = targetAmount)
      }
    }
    if (targetDatasheet$addTarget == "Relative") {
      criteriaFunction <- function(x) {
        add_relative_targets(x, targets = targetAmount)
      }
    }
  }

  # Decision types
  if (criteria == "Decision") {
    if (decisionDatasheet$addDecision == "Default") {
      criteriaFunction <- function(x) add_default_decisions(x)
    }
    if (decisionDatasheet$addDecision == "Binary") {
      criteriaFunction <- function(x) add_binary_decisions(x)
    }
    if (decisionDatasheet$addDecision == "Proportion") {
      criteriaFunction <- function(x) add_proportion_decisions(x)
    }
    if (decisionDatasheet$addDecision == "Semi-continuous") {
      upperLimit <- decisionDatasheet$upper_limit
      criteriaFunction <- function(x) {
        add_semicontinuous_decisions(x, upperLimit)
      }
    }
  }

  # Constraints
  # Contiguity constraint
  if (criteria == "Contiguity") {
    connect_dat <- contiguityDatasheet
    criteriaFunction <- function(x) {
      add_contiguity_constraints(
        x,
        data = connect_dat
      )
    }
  }
  # Feature contiguity constraint
  if (criteria == "Feature contiguity") {
    connect_dat <- featureContiguityDatasheet
    criteriaFunction <- function(x) {
      add_feature_contiguity_constraints(
        x,
        data = connect_dat
      )
    }
  }
  # Linear constraint
  if (criteria == "Linear") {
    if (problemFormatDatasheet$dataType == "Spatial") {
      data <- rast(linearSpatialDatasheet$linearConstraint)
    }
    if (problemFormatDatasheet$dataType == "Tabular") {
      data <- linearTabularDatasheet[, 2]
    }
    threshold <- linearConstraintDatasheet$threshold
    senseCode <- linearConstraintDatasheet$sense
    if (senseCode == "Larger or equal") {
      sense <- ">="
    }
    if (senseCode == "Smaller or equal") {
      sense <- "<="
    }
    if (senseCode == "Equal") {
      sense <- "="
    }
    criteriaFunction <- function(x) {
      add_linear_constraints(x, threshold, sense, data)
    }
  }
  # Locked in constraint
  if (criteria == "Locked in") {
    if (problemFormatDatasheet$dataType == "Spatial") {
      lockedIn <- rast(lockedInSpatialDatasheet$locked_in)
    }
    if (problemFormatDatasheet$dataType == "Tabular") {
      lockedIn <- lockedInTabularDatasheet[, 2]
    }
    criteriaFunction <- function(x) add_locked_in_constraints(x, lockedIn)
  }
  # Locked out constraint
  if (criteria == "Locked out") {
    if (problemFormatDatasheet$dataType == "Spatial") {
      lockedOut <- rast(lockedOutSpatialDatasheet$locked_out)
    }
    if (problemFormatDatasheet$dataType == "Tabular") {
      lockedOut <- lockedOutTabularDatasheet[, 2]
    }
    criteriaFunction <- function(x) add_locked_out_constraints(x, lockedOut)
  }
  # Neighbor constraint
  if (criteria == "Neighbor") {
    k <- neighborDatasheet$k
    criteriaFunction <- function(x) add_neighbor_constraints(x, k)
  }

  # Penalties
  # Boundary penalties
  if (criteria == "Boundary penalties") {
    penalty <- boundaryParametersDatasheet$penalty
    if (dim(boundaryDataDatasheet)[1] == 0) {
      if (!is.na(boundaryParametersDatasheet$edge_factor)) {
        edge_factor <- boundaryParametersDatasheet$edge_factor
        criteriaFunction <- function(x) {
          add_boundary_penalties(
            x,
            penalty = penalty,
            edge_factor = edge_factor
          )
        }
      } else {
        criteriaFunction <- function(x) {
          add_boundary_penalties(x, penalty = penalty)
        }
      }
    }
    if (dim(boundaryDataDatasheet)[1] != 0) {
      bound_dat <- boundaryDataDatasheet
      if (!is.na(boundaryParametersDatasheet$edge_factor)) {
        edge_factor <- boundaryParametersDatasheet$edge_factor
        criteriaFunction <- function(x) {
          add_boundary_penalties(
            x,
            penalty = penalty,
            edge_factor = edge_factor,
            data = bound_dat
          )
        }
      } else {
        criteriaFunction <- function(x) {
          add_boundary_penalties(x, penalty = penalty, data = bound_dat)
        }
      }
    }
  }
  # Linear penalties
  if (criteria == "Linear penalties") {
    penalty <- linearParameterDatasheet$penalty
    linearData <- linearDataDatasheet$data
    criteriaFunction <- function(x) {
      add_linear_penalties(
        x,
        penalty = penalty,
        data = linearData
      )
    }
  }
  isWindows <- function() tolower(Sys.info()[["sysname"]]) == "windows"
  if (!isWindows()) {
    updateRunLog(
      "Linux defaults to using lpsymphony even when Rsymphony is selected.",
      type = "warning"
    )
  }

  # Solver
  if (criteria == "Solver") {
    if (!is.na(solverDatasheet$gap)) {
      gap <- solverDatasheet$gap
      criteriaFunction <- function(x) {
        if (isWindows()) {
          add_rsymphony_solver(x, gap = gap)
        } else {
          add_lpsymphony_solver(x, gap = gap)
        }
      }
    } else {
      criteriaFunction <- function(x) {
        if (isWindows()) {
          add_rsymphony_solver(x)
        } else {
          add_lpsymphony_solver(x)
        }
      }
    }
  }

  # Weights
  if (criteria == "Weights") {
    weights_dat <- weightsDatasheet$weights
    criteriaFunction <- function(x) {
      add_feature_weights(
        x,
        weights = weights_dat
      )
    }
  }

  # Update
  scenarioProblem <- criteriaFunction(scenarioProblem)
}
