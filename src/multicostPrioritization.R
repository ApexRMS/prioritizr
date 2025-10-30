## prioritizr SyncroSim - Multi-cost prioritization transformer
##
## Written by Carina Rauen Firkowski, with support from Jeffrey Hanson
##
## This script integrates multiple cost layers into the prioritization problem
## based on one of three methods: hierarchical, equal or weighted approach. It
## requires a dependency on a scenario with base prioritization.

## NOTE: This transformer currently only support tabular problem formulations.

# Workspace --------------------------------------------------------------------

# Load packages
library(rsyncrosim)
progressBar(type = "message", message = "Setting up workspace")
library(stringr)
library(terra)
library(tidyr)
library(dplyr)
library(prioritizr)

# Load environment, library, project & scenario
e <- ssimEnvironment()
myLibrary <- ssimLibrary()
myProject <- rsyncrosim::project()
myScenario <- scenario()

# Data directory
dataDir <- e$DataDirectory

# Scenario path
dataPath <- paste(
  dataDir,
  paste0("Scenario-", scenarioId(myScenario)),
  sep = "\\"
)


# Open datasheets --------------------------------------------------------------

progressBar(type = "message", message = "Loading data and setting up scenario")

costMethodDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_costLayersMethod"
)
costEqualDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_costLayersEqualInput"
)
costHrchyDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_costLayersHrchyInput"
)
costWeightInputsDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_costLayersWeightInput"
)
costDataDatasheet <- datasheet(myScenario, name = "prioritizr_costLayersData")
costOrderDatasheet <- datasheet(myScenario, name = "prioritizr_costLayersOrder")
costWeightsDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_costLayersWeight"
)
objectiveDatasheet <- datasheet(myScenario, name = "prioritizr_objective")
problemFormatDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_problemFormat"
)
problemSpatialDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_problemSpatial"
)
featureRepresentationOutput <- datasheet(
  myScenario,
  name = "prioritizr_featureRepresentationOutput",
  lookupsAsFactors = T
)
solutionTabularOutput <- datasheet(
  myScenario,
  name = "prioritizr_solutionTabularOutput"
)
solutionObject <- datasheet(myScenario, name = "prioritizr_solutionObject")
performanceDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_evaluatePerformance"
)
importanceDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_evaluateImportance"
)
costOutputOptionsDatasheet <- datasheet(
  myScenario,
  name = "prioritizr_costOutputOptions"
)


# Rename variable names --------------------------------------------------------

# For consistency with prioritizr R
names(solutionTabularOutput)[
  names(solutionTabularOutput) == "solution1"
] <- "solution_1"
names(performanceDatasheet) <- c(
  "eval_n_summary",
  "eval_cost_summary",
  "eval_feature_representation_summary",
  "eval_target_coverage_summary",
  "eval_boundary_summary"
)
names(importanceDatasheet) <- c(
  "eval_replacement_importance",
  "eval_ferrier_importance",
  "eval_rare_richness_importance"
)


# Validation -------------------------------------------------------------------

# Check if attempting to use spatial data
if (problemFormatDatasheet$dataType == "Spatial") {
  stop("Multi-cost optimization currently only supports tabular formulation.")
}

# Check if feature representation was calculated
if (dim(featureRepresentationOutput)[1] == 0) {
  stop(
    "Multi-cost optimization requires that feature representation be calculated for
       the reference (no cost) scenario."
  )
}

# If datasheet is not empty, set NA values to FALSE
# If datasheet is empty, set all columns to FALSE
if (dim(performanceDatasheet)[1] != 0) {
  performanceDatasheet[, is.na(performanceDatasheet)] <- FALSE
} else {
  performanceDatasheet <- data.frame(
    eval_n_summary = FALSE,
    eval_cost_summary = FALSE,
    eval_feature_representation_summary = FALSE,
    eval_target_coverage_summary = FALSE,
    eval_boundary_summary = FALSE
  )
}
if (dim(importanceDatasheet)[1] != 0) {
  importanceDatasheet[, is.na(importanceDatasheet)] <- FALSE
} else {
  importanceDatasheet <- data.frame(
    eval_replacement_importance = FALSE,
    eval_ferrier_importance = FALSE,
    eval_rare_richness_importance = FALSE
  )
}

# Cost variable names match
if (dim(costOrderDatasheet)[1] != 0) {
  checkMatchOrder <- setdiff(
    costDataDatasheet$costName,
    costOrderDatasheet$costName
  )
  if (length(checkMatchOrder) != 0) {
    stop(
      "Cost variable names do not match between Data and Hierarchical Order inputs."
    )
  }
}
if (dim(costWeightsDatasheet)[1] != 0) {
  checkMatchWeights <- setdiff(
    costDataDatasheet$costName,
    costWeightsDatasheet$costName
  )
  if (length(checkMatchWeights) != 0) {
    stop("Cost variable names do not match between Data and Weights inputs.")
  }
}

# Set default values
if (dim(costOutputOptionsDatasheet)[1] == 0) {
  costOutputOptionsDatasheet <- data.frame(
    costs = TRUE,
    solutionComparison = TRUE
  )
}


# Load data --------------------------------------------------------------------

# Pivot cost data wide
costLayers <- costDataDatasheet %>%
  pivot_wider(names_from = costName, values_from = costAmount)

# Extract number of cost layers
n_cost_layers <- dim(costLayers)[2] - 1

# Extract cost layers' names
costsDatasheet <- data.frame(
  Name = names(costLayers)[-1],
  variableName = names(costLayers)[-1],
  from = c(1:length(names(costLayers)[-1]))
)

# Load existing costs from project scope
costDatasheetExisting <- datasheet(myScenario, name = "prioritizr_projectCosts")

# If datasheet is empty, save
if (dim(costDatasheetExisting)[1] == 0) {
  saveDatasheet(
    ssimObject = myProject,
    data = costsDatasheet[, -3],
    name = "prioritizr_projectCosts"
  )
} else {
  # Calculate dissimilarities in feature ID and variable names
  costDatasheetDifference <- setdiff(
    costsDatasheet[, 2],
    costDatasheetExisting[, 2]
  )

  # If differences exist, update datasheet
  if (length(costDatasheetDifference) != 0) {
    costDatasheetNew <- data.frame(
      Name = costDatasheetDifference,
      variableName = costDatasheetDifference
    )
    #costDatasheetDifference$Name <- costDatasheetDifference$variableName
    #costDatasheetDifference <- costDatasheetDifference[, c(1,3,2)]
    costDatasheetUpdated <- rbind(costDatasheetExisting, costDatasheetNew)
    saveDatasheet(
      ssimObject = myProject,
      data = costDatasheetUpdated,
      name = "prioritizr_projectCosts"
    )
  }

  # Update display names
  costsDatasheet$Name[
    costsDatasheet$variableName == costDatasheetExisting$variableName
  ] <-
    costDatasheetExisting$Name

  # Save cost layers to project scope
  saveDatasheet(
    ssimObject = myProject,
    data = costsDatasheet[, -3],
    name = "prioritizr_projectCosts"
  )
}

# Tabular data
if (problemFormatDatasheet$dataType == "Tabular") {
  # Planning unit
  sim_pu <- datasheet(myScenario, name = "prioritizr_problemTabularPU")
  # Add names if missing
  if (all(is.na(sim_pu$Name))) {
    sim_pu$Name <- as.character(sim_pu$id)
  }

  # Features
  sim_features <- datasheet(
    myScenario,
    name = "prioritizr_problemTabularFeatures"
  )
  # Set features' names
  # featuresDatasheet <- sim_features
  # names(featuresDatasheet)[1] <- "featureID"
  # names(featuresDatasheet)[2] <- "Name"
  # featuresDatasheet$variableName <- featuresDatasheet$Name

  # Load existing features from project scope
  featuresDatasheet <- datasheet(
    myScenario,
    name = "prioritizr_projectFeatures"
  )

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

# Merge planning unit data with cost layers
sim_pu <- merge(sim_pu, costLayers, "id")


# Hierarchical cost optimization -----------------------------------------------

if (costMethodDatasheet$method == "Hierarchical") {
  progressBar(type = "message", message = "Optimizing hierarchical cost layers")

  # Get reclass table to reorder cost layers
  costsDatasheetReclass <- merge(
    costsDatasheet,
    costOrderDatasheet,
    by.x = "variableName",
    by.y = "costName",
    all = TRUE
  )
  # Match costLayers order to user provided order of importance
  costLayers <- costLayers[, c(1, costsDatasheetReclass$costOrder + 1)]
  costsDatasheet <- costsDatasheet[costsDatasheetReclass$costOrder, ]

  # Cost layers as features dataframe
  costs_features <- data.frame(
    id = costsDatasheetReclass$costOrder,
    name = costsDatasheetReclass$Name
  )

  # Calculate objective value
  obj_val <- featureRepresentationOutput$absoluteHeld -
    (featureRepresentationOutput$absoluteHeld *
      costMethodDatasheet$initialOptimalityGap)

  # Create empty list for results
  sols <- list()
  costs <- numeric(n_cost_layers)

  # For each cost layer
  for (i in seq_len(n_cost_layers)) {
    # Problem formulation
    curr_p <-
      problem(
        x = sim_pu[, -2],
        features = sim_features,
        rij = rij,
        cost_column = costsDatasheet$variableName[i]
      ) %>%
      add_min_set_objective() %>%
      add_absolute_targets(obj_val) %>%
      add_linear_constraints(
        threshold = objectiveDatasheet$budget,
        sense = "=",
        data = "cost"
      ) %>%
      add_binary_decisions() %>%
      add_default_solver()

    # Account for previous cost layers
    if (i > 1) {
      for (j in seq_len(i - 1)) {
        # Update problem
        curr_p <-
          curr_p %>%
          add_linear_constraints(
            threshold = costs[[j]] +
              (costs[[j]] *
                costHrchyDatasheet$costOptimalityGap),
            sense = "<=",
            data = costsDatasheet$variableName[j]
          )
      }
    }

    # Prioritization
    iSolution <- solve(curr_p, run_checks = FALSE)
    sols[[i]] <- iSolution[, which(
      names(iSolution) %in%
        c("id", "cost", "solution_1")
    )]

    # Calculate cost
    costs[[i]] <- eval_cost_summary(
      curr_p,
      as.data.frame(sols[[i]]$solution_1)
    )$cost[[1]]
  }

  # Extract best solution
  scenarioSolution <- sols[[length(n_cost_layers)]]

  # Save raster
  if (class(scenarioSolution) != "data.frame") {
    solutionFilename <- file.path(paste0(dataDir, "\\solutionRaster.tif"))
    writeRaster(scenarioSolution, filename = solutionFilename, overwrite = TRUE)
    # Save file path to datasheet
    solutionRasterOutput <- data.frame(solution = solutionFilename)
    saveDatasheet(
      ssimObject = myScenario,
      data = solutionRasterOutput,
      name = "prioritizr_solutionRasterOutput"
    )
  }
  # Save tabular output
  if (class(scenarioSolution) == "data.frame") {
    # Combine result and datasheet
    solutionTabularOutputMerge <- merge(
      solutionTabularOutput,
      scenarioSolution,
      all = TRUE
    )

    # Add missing columns
    solutionTabularOutput <- data.frame(
      displayName = NA,
      id = solutionTabularOutputMerge$id,
      cost = solutionTabularOutputMerge$cost,
      status = NA,
      xloc = NA,
      yloc = NA,
      solution_1 = solutionTabularOutputMerge$solution_1
    )

    # Add PU display name
    solutionTabularOutput <- merge(
      solutionTabularOutput,
      sim_pu[, 1:2],
      by = "id"
    )
    solutionTabularOutput$displayName <- solutionTabularOutput$Name
    solutionTabularOutput <- solutionTabularOutput[,
      -(dim(solutionTabularOutput)[2])
    ]

    # Add optional columns
    if ("status" %in% colnames(solutionTabularOutputMerge)) {
      solutionTabularOutput$status <- solutionTabularOutputMerge$status
    }
    if ("xloc" %in% colnames(solutionTabularOutputMerge)) {
      solutionTabularOutput$xloc <- solutionTabularOutputMerge$xloc
    }
    if ("yloc" %in% colnames(solutionTabularOutputMerge)) {
      solutionTabularOutput$yloc <- solutionTabularOutputMerge$yloc
    }

    # Remove rows where all columns are NA
    solutionTabularOutput <- solutionTabularOutput[
      rowSums(is.na(solutionTabularOutput)) != ncol(solutionTabularOutput),
    ]

    # Rename column
    names(solutionTabularOutput)[
      names(solutionTabularOutput) == "solution_1"
    ] <- "solution1"

    # Save solution tabular results
    saveDatasheet(
      ssimObject = myScenario,
      data = solutionTabularOutput,
      name = "prioritizr_solutionTabularOutput"
    )

    # Spatial data for visualization
    if (dim(problemSpatialDatasheet)[1] != 0) {
      if (!is.na(problemSpatialDatasheet$x)) {
        pu_vis <- rast(file.path(problemSpatialDatasheet$x))
        puVis <- TRUE
      }
    } else {
      puVis <- FALSE
    }

    # Save solution spatial visualization
    if (isTRUE(puVis)) {
      # Reclass table between planning unit id & solution
      reclassTable <- matrix(
        c(1:length(scenarioSolution$solution_1), scenarioSolution$solution_1),
        byrow = FALSE,
        ncol = 2
      )
      # Reclassify raster
      solutionVis <- classify(pu_vis, reclassTable)

      # Define file path
      solutionFilepath <- paste0(dataPath, "\\prioritizr_solutionRasterOutput")
      solutionFilename <- file.path(paste0(
        solutionFilepath,
        "\\solutionRaster.tif"
      ))
      # Create directory if it does not exist
      ifelse(
        !dir.exists(file.path(solutionFilepath)),
        dir.create(file.path(solutionFilepath)),
        FALSE
      )
      writeRaster(solutionVis, filename = solutionFilename, overwrite = TRUE)
      # Save file path to datasheet
      solutionRasterOutput <- data.frame(solution = solutionFilename)
      saveDatasheet(
        ssimObject = myScenario,
        data = solutionRasterOutput,
        name = "prioritizr_solutionRasterOutput"
      )
    }
  }
}


# Equal cost optimization ------------------------------------------------------

if (costMethodDatasheet$method == "Equal") {
  progressBar(type = "message", message = "Optimizing equal cost layers")

  # Create empty list for results
  costs <- numeric(n_cost_layers)

  # Prioritize each cost layer separately to assess upper bound of cost
  for (i in seq_len(n_cost_layers)) {
    # Build problem
    curr_p <-
      problem(
        x = sim_pu[, -2],
        features = sim_features,
        rij = rij,
        cost_column = costsDatasheet$variableName[i]
      ) %>%
      add_min_set_objective() %>%
      add_absolute_targets(featureRepresentationOutput$absoluteHeld * 0.1) %>%
      add_linear_constraints(
        threshold = objectiveDatasheet$budget,
        sense = "=",
        data = "cost"
      ) %>%
      add_binary_decisions() %>%
      add_default_solver(gap = 0, verbose = FALSE)

    # Solve problem
    curr_s <- solve(curr_p, force = TRUE, run_checks = FALSE)

    # Calculate the total cost of the solution
    costs[[i]] <- eval_cost_summary(
      curr_p,
      curr_s[, "solution_1", drop = FALSE]
    )$cost[[1]]
  }

  # Calculate new targets
  t1 <- featureRepresentationOutput
  t1$new_target <- t1$absoluteHeld *
    (1 - costMethodDatasheet$initialOptimalityGap)

  # Generate budget increments
  budget_increments <- lapply(
    costs,
    function(x) {
      seq(
        0,
        x * (1 + costEqualDatasheet$budgetPadding),
        length.out = costEqualDatasheet$budgetIncrements
      )
    }
  )

  # Generate solutions by iterating over each budget increment and cost layer
  for (j in seq_len(costEqualDatasheet$budgetIncrements)) {
    # Build problem
    p1 <-
      problem(
        x = sim_pu[, -2],
        features = sim_features,
        rij = rij,
        cost_column = "cost"
      ) %>%
      add_min_set_objective() %>%
      add_absolute_targets(t1$new_target) %>%
      add_linear_constraints(
        threshold = objectiveDatasheet$budget,
        sense = "=",
        data = "cost"
      ) %>%
      add_binary_decisions() %>%
      add_default_solver(gap = 0.1, verbose = FALSE)

    # Add constraints for each cost layer and the j'th budget
    for (i in seq_len(n_cost_layers)) {
      p1 <-
        p1 %>%
        add_linear_constraints(
          threshold = budget_increments[[i]][[j]],
          sense = "<=",
          data = costsDatasheet$variableName[i]
        )
    }

    # Solve problem
    scenarioSolution <- try(
      solve(p1, force = TRUE, run_checks = FALSE),
      silent = TRUE
    )

    # If scenarioSolution is a feasible solution, then end loop
    if (!inherits(scenarioSolution, "try-error")) break()
  }
  if (inherits(scenarioSolution, "try-error")) {
    stop(
      "Could not find feasible multi-objective solution. 
         Try increasing the parameter `Budget padding`."
    )
  }

  # Save raster
  if (class(scenarioSolution) != "data.frame") {
    solutionFilename <- file.path(paste0(dataDir, "\\solutionRaster.tif"))
    writeRaster(scenarioSolution, filename = solutionFilename, overwrite = TRUE)
    # Save file path to datasheet
    solutionRasterOutput <- data.frame(solution = solutionFilename)
    saveDatasheet(
      ssimObject = myScenario,
      data = solutionRasterOutput,
      name = "prioritizr_solutionRasterOutput"
    )
  }
  # Save tabular output
  if (class(scenarioSolution) == "data.frame") {
    # Combine result and datasheet
    solutionTabularOutputMerge <- merge(
      solutionTabularOutput,
      scenarioSolution,
      all = TRUE
    )

    # Add missing columns
    solutionTabularOutput <- data.frame(
      displayName = NA,
      id = solutionTabularOutputMerge$id,
      cost = solutionTabularOutputMerge$cost,
      status = NA,
      xloc = NA,
      yloc = NA,
      solution_1 = solutionTabularOutputMerge$solution_1
    )

    # Add PU display name
    solutionTabularOutput <- merge(
      solutionTabularOutput,
      sim_pu[, 1:2],
      by = "id"
    )
    solutionTabularOutput$displayName <- solutionTabularOutput$Name
    solutionTabularOutput <- solutionTabularOutput[,
      -(dim(solutionTabularOutput)[2])
    ]

    # Add optional columns
    if ("status" %in% colnames(solutionTabularOutputMerge)) {
      solutionTabularOutput$status <- solutionTabularOutputMerge$status
    }
    if ("xloc" %in% colnames(solutionTabularOutputMerge)) {
      solutionTabularOutput$xloc <- solutionTabularOutputMerge$xloc
    }
    if ("yloc" %in% colnames(solutionTabularOutputMerge)) {
      solutionTabularOutput$yloc <- solutionTabularOutputMerge$yloc
    }

    # Remove rows where all columns are NA
    solutionTabularOutput <- solutionTabularOutput[
      rowSums(is.na(solutionTabularOutput)) != ncol(solutionTabularOutput),
    ]

    # Rename column
    names(solutionTabularOutput)[
      names(solutionTabularOutput) == "solution_1"
    ] <- "solution1"

    # Save solution tabular results
    saveDatasheet(
      ssimObject = myScenario,
      data = solutionTabularOutput,
      name = "prioritizr_solutionTabularOutput"
    )

    # Spatial data for visualization
    if (dim(problemSpatialDatasheet)[1] != 0) {
      if (!is.na(problemSpatialDatasheet$x)) {
        pu_vis <- rast(file.path(problemSpatialDatasheet$x))
        puVis <- TRUE
      }
    } else {
      puVis <- FALSE
    }

    # Save solution spatial visualization
    if (isTRUE(puVis)) {
      # Reclass table between planning unit id & solution
      reclassTable <- matrix(
        c(1:length(scenarioSolution$solution_1), scenarioSolution$solution_1),
        byrow = FALSE,
        ncol = 2
      )
      # Reclassify raster
      solutionVis <- classify(pu_vis, reclassTable)

      # Define file path
      solutionFilepath <- paste0(dataPath, "\\prioritizr_solutionRasterOutput")
      solutionFilename <- file.path(paste0(
        solutionFilepath,
        "\\solutionRaster.tif"
      ))
      # Create directory if it does not exist
      ifelse(
        !dir.exists(file.path(solutionFilepath)),
        dir.create(file.path(solutionFilepath)),
        FALSE
      )
      writeRaster(solutionVis, filename = solutionFilename, overwrite = TRUE)
      # Save file path to datasheet
      solutionRasterOutput <- data.frame(solution = solutionFilename)
      saveDatasheet(
        ssimObject = myScenario,
        data = solutionRasterOutput,
        name = "prioritizr_solutionRasterOutput"
      )
    }
  }
}


# Weighted cost optimization ---------------------------------------------------

if (costMethodDatasheet$method == "Weighted") {
  progressBar(type = "message", message = "Optimizing weighted cost layers")

  # Create empty list for results
  costs <- numeric(n_cost_layers)

  # Prioritize each cost layer separately to assess upper bound of cost
  for (i in seq_len(n_cost_layers)) {
    # Build problem
    curr_p <-
      problem(
        x = sim_pu[, -2],
        features = sim_features,
        rij = rij,
        cost_column = costsDatasheet$variableName[i]
      ) %>%
      add_min_set_objective() %>%
      add_absolute_targets(featureRepresentationOutput$absoluteHeld * 0.1) %>%
      add_linear_constraints(
        threshold = objectiveDatasheet$budget,
        sense = "=",
        data = "cost"
      ) %>%
      add_binary_decisions() %>%
      add_default_solver(gap = 0, verbose = FALSE)

    # Solve problem
    curr_s <- solve(curr_p, force = TRUE, run_checks = FALSE)

    # Calculate the total cost of the solution
    costs[[i]] <- eval_cost_summary(
      curr_p,
      curr_s[, "solution_1", drop = FALSE]
    )$cost[[1]]
  }

  # Calculate new targets
  t1 <- featureRepresentationOutput
  t1$new_target <- t1$absoluteHeld *
    (1 - costMethodDatasheet$initialOptimalityGap)

  # Reorder weights
  costWeightsDatasheet$costWeight <- 1 - costWeightsDatasheet$costWeight

  # Calculate weighted budgets
  new_budgets <- costs *
    (1 + costWeightsDatasheet$costWeight) *
    costWeightInputsDatasheet$budgetMultiplier

  # Generate problem with multiple cost weights
  p1 <-
    problem(
      x = sim_pu[, -2],
      features = sim_features,
      rij = rij,
      cost_column = "cost"
    ) %>%
    add_min_set_objective() %>%
    add_absolute_targets(t1$new_target) %>%
    add_linear_constraints(
      threshold = objectiveDatasheet$budget,
      sense = "=",
      data = "cost"
    ) %>%
    add_binary_decisions() %>%
    add_default_solver(gap = 0.1)

  # Add constraints for each cost layer and its budget
  for (i in seq_len(n_cost_layers)) {
    p1 <-
      p1 %>%
      add_linear_constraints(
        threshold = new_budgets[i],
        sense = "<=",
        data = costsDatasheet$variableName[i]
      )
  }

  # Solve problem
  scenarioSolution <- try(
    solve(p1, force = TRUE, run_checks = FALSE),
    silent = TRUE
  )

  # If scenarioSolution is infeasible solution, return error
  if (inherits(scenarioSolution, "try-error")) {
    stop(
      "Could not find feasible multi-cost solution. Try increasing the 
    parameter `Optimality gap`."
    )
  }

  # Save raster
  if (class(scenarioSolution) != "data.frame") {
    solutionFilename <- file.path(paste0(dataDir, "\\solutionRaster.tif"))
    writeRaster(scenarioSolution, filename = solutionFilename, overwrite = TRUE)
    # Save file path to datasheet
    solutionRasterOutput <- data.frame(solution = solutionFilename)
    saveDatasheet(
      ssimObject = myScenario,
      data = solutionRasterOutput,
      name = "prioritizr_solutionRasterOutput"
    )
  }
  # Save tabular output
  if (class(scenarioSolution) == "data.frame") {
    # Combine result and datasheet
    solutionTabularOutputMerge <- merge(
      solutionTabularOutput,
      scenarioSolution,
      all = TRUE
    )

    # Add missing columns
    solutionTabularOutput <- data.frame(
      displayName = NA,
      id = solutionTabularOutputMerge$id,
      cost = solutionTabularOutputMerge$cost,
      status = NA,
      xloc = NA,
      yloc = NA,
      solution_1 = solutionTabularOutputMerge$solution_1
    )

    # Add PU display name
    solutionTabularOutput <- merge(
      solutionTabularOutput,
      sim_pu[, 1:2],
      by = "id"
    )
    solutionTabularOutput$displayName <- solutionTabularOutput$Name
    solutionTabularOutput <- solutionTabularOutput[,
      -(dim(solutionTabularOutput)[2])
    ]

    # Add optional columns
    if ("status" %in% colnames(solutionTabularOutputMerge)) {
      solutionTabularOutput$status <- solutionTabularOutputMerge$status
    }
    if ("xloc" %in% colnames(solutionTabularOutputMerge)) {
      solutionTabularOutput$xloc <- solutionTabularOutputMerge$xloc
    }
    if ("yloc" %in% colnames(solutionTabularOutputMerge)) {
      solutionTabularOutput$yloc <- solutionTabularOutputMerge$yloc
    }

    # Remove rows where all columns are NA
    solutionTabularOutput <- solutionTabularOutput[
      rowSums(is.na(solutionTabularOutput)) != ncol(solutionTabularOutput),
    ]

    # Rename column
    names(solutionTabularOutput)[
      names(solutionTabularOutput) == "solution_1"
    ] <- "solution1"

    # Save solution tabular results
    saveDatasheet(
      ssimObject = myScenario,
      data = solutionTabularOutput,
      name = "prioritizr_solutionTabularOutput"
    )

    # Spatial data for visualization
    if (dim(problemSpatialDatasheet)[1] != 0) {
      if (!is.na(problemSpatialDatasheet$x)) {
        pu_vis <- rast(file.path(problemSpatialDatasheet$x))
        puVis <- TRUE
      }
    } else {
      puVis <- FALSE
    }

    # Save solution spatial visualization
    if (isTRUE(puVis)) {
      # Reclass table between planning unit id & solution
      reclassTable <- matrix(
        c(1:length(scenarioSolution$solution_1), scenarioSolution$solution_1),
        byrow = FALSE,
        ncol = 2
      )
      # Reclassify raster
      solutionVis <- classify(pu_vis, reclassTable)

      # Define file path
      solutionFilepath <- paste0(dataPath, "\\prioritizr_solutionRasterOutput")
      solutionFilename <- file.path(paste0(
        solutionFilepath,
        "\\solutionRaster.tif"
      ))
      # Create directory if it does not exist
      ifelse(
        !dir.exists(file.path(solutionFilepath)),
        dir.create(file.path(solutionFilepath)),
        FALSE
      )
      writeRaster(solutionVis, filename = solutionFilename, overwrite = TRUE)
      # Save file path to datasheet
      solutionRasterOutput <- data.frame(solution = solutionFilename)
      saveDatasheet(
        ssimObject = myScenario,
        data = solutionRasterOutput,
        name = "prioritizr_solutionRasterOutput"
      )
    }
  }
}

# Evaluate solutions -----------------------------------------------------------

## Number of planning units --------------------------------------

if (isTRUE(performanceDatasheet$eval_n_summary)) {
  # if(class(scenarioSolution) != "data.frame"){
  #   if(costMethodDatasheet$method == "Hierarchical"){
  #     n <- eval_n_summary(curr_p, scenarioSolution)
  #   } else {
  #     n <- eval_n_summary(p1, scenarioSolution)
  #   }
  # }
  if (class(scenarioSolution) == "data.frame") {
    if (costMethodDatasheet$method == "Hierarchical") {
      n <- eval_n_summary(
        curr_p,
        scenarioSolution[, "solution_1", drop = FALSE]
      )
    } else {
      n <- eval_n_summary(p1, scenarioSolution[, "solution_1", drop = FALSE])
    }
  }
  # Save results
  numberOutput <- data.frame(n = n$n)
  #numberOutput <- as.data.frame(n)
  saveDatasheet(
    ssimObject = myScenario,
    data = numberOutput,
    name = "prioritizr_numberOutput"
  )
}

## Solution cost -------------------------------------------------

if (isTRUE(performanceDatasheet$eval_cost_summary)) {
  # if(class(scenarioSolution) != "data.frame"){
  #   cost <- eval_cost_summary(p1, scenarioSolution) }
  if (class(scenarioSolution) == "data.frame") {
    if (costMethodDatasheet$method == "Hierarchical") {
      cost <- eval_cost_summary(
        curr_p,
        scenarioSolution[, "solution_1", drop = FALSE]
      )
    } else {
      cost <- eval_cost_summary(p1, scenarioSolution[, "solution_1", drop = FALSE])
    }
  }
  # Save results
  costOutput <- data.frame(cost = cost$cost)
  #costOutput <- as.data.frame(cost)
  saveDatasheet(
    ssimObject = myScenario,
    data = costOutput,
    name = "prioritizr_costOutput"
  )
}

## Feature representation ----------------------------------------

if (isTRUE(performanceDatasheet$eval_feature_representation_summary)) {
  # Read initial problem
  initialProblem <-
    problem(
      x = sim_pu[, -2],
      features = sim_features,
      rij = rij,
      cost_column = "cost"
    )

  # Calculate representation by cost optimized solution
  featureRepresentation <- eval_feature_representation_summary(
    initialProblem,
    scenarioSolution[, "solution_1", drop = FALSE]
  )

  # Save results
  names(featureRepresentation)[2] <- "projectFeaturesId"
  nameDiff <- setdiff(
    featureRepresentation$projectFeaturesId,
    featuresDatasheet$Name
  )
  if (length(nameDiff) != 0) {
    featureRepresentation$projectFeaturesId[
      featureRepresentation$projectFeaturesId == featuresDatasheet$variableName
    ] <- featuresDatasheet$Name
  }
  featureRepresentationOutput <- as.data.frame(featureRepresentation)
  names(featureRepresentationOutput)[3:5] <- c(
    "totalAmount",
    "absoluteHeld",
    "relativeHeld"
  )
  saveDatasheet(
    ssimObject = myScenario,
    data = featureRepresentationOutput[, -1],
    name = "prioritizr_featureRepresentationOutput"
  )
}

## Target representation -----------------------------------------

if (isTRUE(performanceDatasheet$eval_target_coverage_summary)) {
  # if(class(scenarioSolution) != "data.frame"){
  #   targetCoverage <- eval_target_coverage_summary(p1, scenarioSolution) }
  if (class(scenarioSolution) == "data.frame") {
    if (costMethodDatasheet$method == "Hierarchical") {
      targetCoverage <- eval_target_coverage_summary(
        curr_p,
        scenarioSolution[, "solution_1", drop = FALSE]
      )
    } else {
      targetCoverage <- eval_target_summary(
        p1,
        scenarioSolution[, "solution_1", drop = FALSE]
      )
    }
  }

  # Save results
  names(targetCoverage)[1] <- "projectFeaturesId"
  targetCoverage$projectFeaturesId[
    targetCoverage$projectFeaturesId == featuresDatasheet$variableName
  ] <- featuresDatasheet$Name
  targetCoverageOutput <- as.data.frame(targetCoverage)
  names(targetCoverageOutput)[3:9] <- c(
    "totalAmount",
    "absoluteTarget",
    "absoluteHeld",
    "absoluteShortfall",
    "relativeTarget",
    "relativeHeld",
    "relativeShortfall"
  )
  saveDatasheet(
    ssimObject = myScenario,
    data = targetCoverageOutput,
    name = "prioritizr_targetCoverageOutput"
  )
}

## Boundary length -----------------------------------------------

if (isTRUE(performanceDatasheet$eval_boundary_summary)) {
  # if(class(scenarioSolution) != "data.frame"){
  #   temp_boundaryOutput <- eval_boundary_summary(p1,
  #                                                scenarioSolution)
  #   # Save results
  #   boundaryOutput <- as.data.frame(temp_boundaryOutput)
  #   saveDatasheet(ssimObject = myScenario,
  #                 data = boundaryOutput,
  #                 name = "prioritizr_boundaryOutput")
  # }
  if (class(scenarioSolution) == "data.frame") {
    updateRunLog(
      "The output option for boundary lenght is not available for a 
    tabular problem formulation.",
      type = "warning"
    )
  }
}

## Cost representation -------------------------------------------

# Cost layers as features dataframe
costs_features <- data.frame(
  id = costsDatasheet$from,
  name = costsDatasheet$variableName
)

# Planning units v. cost layers
rij_costs <- data.frame(
  pu = as.numeric(),
  species = as.numeric(),
  amount = as.numeric()
)
for (i in 1:n_cost_layers) {
  speciesID <- costs_features$id[i]
  rij_temp <- data.frame(
    pu = sim_pu$id,
    species = speciesID,
    amount = sim_pu[, speciesID + 3]
  )
  rij_costs <- rbind(rij_costs, rij_temp)
}

# Create problem using costs as features
p_cost <-
  problem(
    x = sim_pu[, -2],
    features = costs_features,
    rij = rij_costs,
    cost_column = "cost"
  )

# Save cost problem
problemFilename <- file.path(paste0(dataPath, "\\costProblemFormulation.rds"))
saveRDS(p_cost, file = problemFilename)
# Save file path to datasheet
costProblemOutput <- data.frame(problem = problemFilename)
saveDatasheet(
  ssimObject = myScenario,
  data = costProblemOutput,
  name = "prioritizr_costProblemFormulation"
)

# Calculate representation by cost-optimized solution
featureRepresentation <- eval_feature_representation_summary(
  p_cost,
  scenarioSolution[, "solution_1", drop = FALSE]
)

# Save results
names(featureRepresentation)[2] <- c("projectCostsId")
nameDiff <- setdiff(featureRepresentation$projectCostsId, costsDatasheet$Name)
if (length(nameDiff) != 0) {
  featureRepresentation$projectCostsId[
    featureRepresentation$projectCostsId == costsDatasheet$variableName
  ] <- costsDatasheet$Name
}
costsRepresentationOutput <- as.data.frame(featureRepresentation[, -1])
names(costsRepresentationOutput)[2:4] <- c(
  "totalAmount",
  "absoluteHeld",
  "relativeHeld"
)

# Save cost representation for cost-optimized solution
saveDatasheet(
  ssimObject = myScenario,
  data = costsRepresentationOutput,
  name = "prioritizr_optimizedCostRepresentationOutput"
)


# Evaluate importance ----------------------------------------------------------

# Calculate replacement cost scores
if (isTRUE(importanceDatasheet$eval_replacement_importance)) {
  # if(class(scenarioSolution) != "data.frame"){
  #
  #   replacementImportance <- scenarioProblem %>%
  #     eval_replacement_importance(scenarioSolution)
  #
  #   # Save raster
  #   replacementFilename <- file.path(paste0(dataDir, "\\replacementRaster.tif"))
  #   writeRaster(replacementImportance,
  #               filename = replacementFilename,
  #               overwrite = TRUE)
  #
  #   # Save file path to datasheet
  #   replacementSpatialOutput <- data.frame(replacement = replacementFilename)
  #   saveDatasheet(ssimObject = myScenario,
  #                 data = replacementSpatialOutput,
  #                 name = "prioritizr_replacementSpatialOutput")
  # }
  if (class(scenarioSolution) == "data.frame") {
    if (costMethodDatasheet$method == "Hierarchical") {
      replacementImportance <- curr_p %>%
        eval_replacement_importance(scenarioSolution[,
          "solution_1",
          drop = FALSE
        ])
    } else {
      replacementImportance <- p1 %>%
        eval_replacement_importance(scenarioSolution[,
          "solution_1",
          drop = FALSE
        ])
    }

    # Save tabular results
    replacementTabularOutput <- data.frame(
      id = sim_pu$id,
      rc = as.numeric(replacementImportance$rc)
    )

    # Reclass Inf to 9999
    replacementTabularOutput$rc[is.infinite(
      replacementTabularOutput$rc
    )] <- 9999

    saveDatasheet(
      ssimObject = myScenario,
      data = replacementTabularOutput,
      name = "prioritizr_replacementTabularOutput"
    )

    # Save solution spatial visualization
    if (isTRUE(puVis)) {
      # Reclass table between planning unit id & solution
      reclassTable <- matrix(
        c(1:dim(replacementImportance)[1], replacementImportance$rc),
        byrow = FALSE,
        ncol = 2
      )
      # Reclassify raster
      replaceImportanceVis <- classify(pu_vis, reclassTable)

      # Define file path
      replaceImportanceFilepath <- paste0(
        dataPath,
        "\\prioritizr_replacementSpatialOutput"
      )
      replaceImportanceFilename <- file.path(paste0(
        replaceImportanceFilepath,
        "\\replacementRaster.tif"
      ))
      # Create directory if it does not exist
      ifelse(
        !dir.exists(file.path(replaceImportanceFilepath)),
        dir.create(file.path(replaceImportanceFilepath)),
        FALSE
      )
      writeRaster(
        replaceImportanceVis,
        filename = replaceImportanceFilename,
        overwrite = TRUE
      )
      # Save file path to datasheet
      replacementSpatialOutput <- data.frame(
        replacement = replaceImportanceFilename
      )
      saveDatasheet(
        ssimObject = myScenario,
        data = replacementSpatialOutput,
        name = "prioritizr_replacementSpatialOutput"
      )
    }
  }
}

# Calculate Ferrier scores and extract total score
if (isTRUE(importanceDatasheet$eval_ferrier_importance)) {
  # if(class(scenarioSolution) != "data.frame"){
  #
  #   ferrierScores <- eval_ferrier_importance(scenarioProblem, scenarioSolution)
  #
  #   # Save raster
  #   ferrierFilename <- file.path(paste0(dataDir, "\\ferrierRaster.tif"))
  #   writeRaster(ferrierScores[["total"]], filename = ferrierFilename,
  #               overwrite = TRUE)
  #
  #   # Save file path to datasheet
  #   ferrierSpatialOutput <- data.frame(ferrierMethod = ferrierFilename)
  #   saveDatasheet(ssimObject = myScenario,
  #                 data = ferrierSpatialOutput,
  #                 name = "prioritizr_ferrierSpatialOutput")
  # }
  if (class(scenarioSolution) == "data.frame") {
    if (costMethodDatasheet$method == "Hierarchical") {
      ferrierScores <- eval_ferrier_importance(
        curr_p,
        scenarioSolution[, "solution_1", drop = FALSE]
      )
    } else {
      ferrierScores <- eval_ferrier_importance(
        p1,
        scenarioSolution[, "solution_1", drop = FALSE]
      )
    }

    # Add planning unit id
    ferrierScoresOutput <- data.frame(
      id = sim_pu$id,
      scores = ferrierScores$total
    )

    # Save results
    saveDatasheet(
      ssimObject = myScenario,
      data = ferrierScoresOutput,
      name = "prioritizr_ferrierTabularOutput"
    )

    # Save solution spatial visualization
    if (isTRUE(puVis)) {
      # Reclass table between planning unit id & solution
      reclassTable <- matrix(
        c(ferrierScoresOutput$id, ferrierScoresOutput$scores),
        byrow = FALSE,
        ncol = 2
      )
      # Reclassify raster
      ferrierVis <- classify(pu_vis, reclassTable)

      # Define file path
      ferrierFilepath <- paste0(
        dataPath,
        "\\prioritizr_ferrierSpatialOutput"
      )
      ferrierFilename <- file.path(paste0(
        ferrierFilepath,
        "\\ferrierRaster.tif"
      ))
      # Create directory if it does not exist
      ifelse(
        !dir.exists(file.path(ferrierFilepath)),
        dir.create(file.path(ferrierFilepath)),
        FALSE
      )
      writeRaster(ferrierVis, filename = ferrierFilename, overwrite = TRUE)
      # Save file path to datasheet
      ferrierOutput <- data.frame(
        ferrierMethod = ferrierFilename
      )
      saveDatasheet(
        ssimObject = myScenario,
        data = ferrierOutput,
        name = "prioritizr_ferrierSpatialOutput"
      )
    }
  }
}

# Calculate rarity weighted richness scores
if (isTRUE(importanceDatasheet$eval_rare_richness_importance)) {
  # if(class(scenarioSolution) != "data.frame"){
  #
  #   if(costMethodDatasheet$method == "Hierarchical"){
  #     rarityScores <- eval_rare_richness_importance(curr_p,
  #                                                   scenarioSolution)
  #   } else {
  #     rarityScores <- eval_rare_richness_importance(p1,
  #                                                   scenarioSolution)
  #   }
  #
  #   # Save raster
  #   rarityFilename <- file.path(paste0(dataDir, "\\rarityRaster.tif"))
  #   writeRaster(rarityScores, filename = rarityFilename,
  #               overwrite = TRUE)
  #
  #   # Save file path to datasheet
  #   raritySpatialOutput <- data.frame(rarityWeightedRichness = rarityFilename)
  #   saveDatasheet(ssimObject = myScenario,
  #                 data = raritySpatialOutput,
  #                 name = "prioritizr_raritySpatialOutput")
  # }
  if (class(scenarioSolution) == "data.frame") {
    if (costMethodDatasheet$method == "Hierarchical") {
      rarityScores <- eval_rare_richness_importance(
        curr_p,
        scenarioSolution[, "solution_1", drop = FALSE]
      )
    } else {
      rarityScores <- eval_rare_richness_importance(
        p1,
        scenarioSolution[, "solution_1", drop = FALSE]
      )
    }

    # Save results
    rarityTabularOutput <- data.frame(
      id = sim_pu$id,
      rwr = rarityScores$rwr
    )
    saveDatasheet(
      ssimObject = myScenario,
      data = rarityTabularOutput,
      name = "prioritizr_rarityTabularOutput"
    )

    # Save solution spatial visualization
    if (isTRUE(puVis)) {
      # Reclass table between planning unit id & solution
      reclassTable <- matrix(
        c(rarityTabularOutput$id, rarityTabularOutput$rwr),
        byrow = FALSE,
        ncol = 2
      )
      # Reclassify raster
      rarityVis <- classify(pu_vis, reclassTable)

      # Define file path
      rarityFilepath <- paste0(
        dataPath,
        "\\prioritizr_raritySpatialOutput"
      )
      rarityFilename <- file.path(paste0(
        rarityFilepath,
        "\\rarityWeightedRichnessRaster.tif"
      ))
      # Create directory if it does not exist
      ifelse(
        !dir.exists(file.path(rarityFilepath)),
        dir.create(file.path(rarityFilepath)),
        FALSE
      )
      writeRaster(rarityVis, filename = rarityFilename, overwrite = TRUE)
      # Save file path to datasheet
      raritySpatialOutput <- data.frame(
        rarityWeightedRichness = rarityFilename
      )
      saveDatasheet(
        ssimObject = myScenario,
        data = raritySpatialOutput,
        name = "prioritizr_raritySpatialOutput"
      )
    }
  }
}


# Save cost inputs -------------------------------------------------------------

# Enter if statement if any input needs mapping
if (isTRUE(costOutputOptionsDatasheet$costs)) {
  # For tabular data format
  if (isTRUE(puVis)) {
    # Define folder path
    costVisFilepath <- paste0(dataPath, "\\prioritizr_costRasterOutput")

    # Create directory if it does not exist
    ifelse(
      !dir.exists(file.path(costVisFilepath)),
      dir.create(file.path(costVisFilepath)),
      FALSE
    )

    # Read datasheet
    costVisFilepathDatasheet <- data.frame(
      projectCostsId = as.character(),
      cost = as.character()
    )

    # Loop across feature variables
    loopID <- 1
    for (j in costsDatasheet$variableName) {
      # Subset rij table to get reclass table of planning unit ID to value
      reclassTable <- as.matrix(costDataDatasheet[
        costDataDatasheet$costName == j,
        c(1, 3)
      ])

      # Reclassify raster
      rasterVis <- classify(pu_vis, reclassTable)
      #plot(rasterVis)

      # Define file path
      rasterVisFilename <- file.path(paste0(
        costVisFilepath,
        paste0("\\feature", j, ".tif")
      ))

      # Save file
      writeRaster(rasterVis, filename = rasterVisFilename, overwrite = TRUE)

      # Add file path to datasheet
      costVisFilepathDatasheet[loopID, 1] <- costsDatasheet$Name[
        costsDatasheet$variableName == j
      ]
      costVisFilepathDatasheet[loopID, 2] <- rasterVisFilename

      loopID <- loopID + 1
    }

    # Save datasheet
    saveDatasheet(
      ssimObject = myScenario,
      data = costVisFilepathDatasheet,
      name = "prioritizr_costRasterOutput"
    )
  } else {
    updateRunLog(
      "Output options to map inputs were set for a tabular problem 
    formulation but no spatial planning unit raster was provided. Therefore, the 
    output options to map inputs were ignored.",
      type = "warning"
    )
  }
}
