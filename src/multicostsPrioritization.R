## prioritizr SyncroSim
##
## Written by Carina Rauen Firkowski, with support from Jeffrey Hanson
##
## This script integrates multiple cost layers into the prioritization problem
## based on one of two methods: hierarchical or equal approach. It requires a 
## dependency on a scenario with custom prioritization.



# Workspace -------------------------------------------------------------------

# Load packages
library(rsyncrosim); progressBar(type = "message", 
                                 message = "Setting up workspace")
library(stringr)
library(terra)
library(tidyr)
library(dplyr)
library(prioritizr)
library(Rsymphony)

# Load environment, library, project & scenario
e <- ssimEnvironment()
myLibrary <- ssimLibrary()
myProject <- rsyncrosim::project()
myScenario <- scenario()

# Data directory
dataDir <- e$DataDirectory

# Scenario path
dataPath <- paste(dataDir, paste0("Scenario-", scenarioId(myScenario)), sep="\\") 



# Open datasheets --------------------------------------------------------------

progressBar(type = "message", message = "Loading data and setting up scenario")

costLayersDatasheet <- datasheet(myScenario, 
                                 name = "prioritizr_costLayersInput")
objectiveDatasheet <- datasheet(myScenario, 
                                name = "prioritizr_objective")
problemFormatDatasheet <- datasheet(myScenario,
                                    name = "prioritizr_problemFormat")
problemTabularDatasheet <- datasheet(myScenario, 
                                     name = "prioritizr_problemTabular")
problemSpatialDatasheet <- datasheet(myScenario,
                                     name = "prioritizr_problemSpatial")
featureRepresentationOutput <- datasheet(myScenario,
                                         name = "prioritizr_featureRepresentationOutput",
                                         lookupsAsFactors = T)
solutionTabularOutput <- datasheet(myScenario,
                                   name = "prioritizr_solutionTabularOutput")
problemFormulation <- datasheet(myScenario,
                                name = "prioritizr_problemFormulation")
solutionObject <- datasheet(myScenario,
                            name = "prioritizr_solutionObject")



# Rename variable names for consistency with prioritizr R ----------------------

names(problemTabularDatasheet)[4] <- "cost_column"
names(solutionTabularOutput)[6] <- "solution_1"



# Load data --------------------------------------------------------------------

# Cost layers
costLayers <- read.csv(file.path(costLayersDatasheet$costLayers))

# Extract number of cost layers
n_cost_layers <- dim(costLayers)[2]-1

# Extract cost layers' names
costsDatasheet <- data.frame(Name = names(costLayers)[-1])

# Cost layers as features dataframe
costs_features <- data.frame(id = 1:n_cost_layers,
                             name = costsDatasheet$Name)

# Save cost layers to project scope
saveDatasheet(ssimObject = myProject, 
              data = costsDatasheet, 
              name = "prioritizr_projectCosts")

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

# Merge planning unit data with cost layers
sim_pu <- cbind(sim_pu, costLayers[,-1])



# Hierarchical cost optimization -----------------------------------------------

if(costLayersDatasheet$method == "Hierarchical"){

  progressBar(type = "message", message = "Optimizing hierarchical cost layers")

  # Calculate objective value
  obj_val <- featureRepresentationOutput$absoluteHeld - 
    (featureRepresentationOutput$absoluteHeld * costLayersDatasheet$initialOptimalityGap)

  # Create empty list for results
  sols <- list()
  costs <- numeric(n_cost_layers)

  # For each cost layer
  for (i in seq_len(n_cost_layers)) {
    
    # Problem formulation
    curr_p <-
      problem(x = sim_pu, features = sim_features,
              rij = rij, cost_column = costsDatasheet$Name[i]) %>%
      add_min_set_objective() %>%                         
      add_absolute_targets(obj_val) %>% 
      add_linear_constraints(threshold = objectiveDatasheet$budget,
                            sense = "=", data = sim_pu$cost) %>%
      add_binary_decisions() %>%
      add_default_solver()
    
    # Account for previous cost layers
    if (i > 1) {
      for (j in seq_len(i - 1)) {
        
        # Update problem
        curr_p <-
          curr_p %>%
          add_linear_constraints(
            threshold = costs[[j]] + (costs[[j]] * 
                                        costLayersDatasheet$costOptimalityGap),
            sense = "<=",
            data = paste0("cost_", j)
          )
      }
    }
    
    # Prioritization
    sols[[i]] <- solve(curr_p, run_checks = FALSE)[, "solution_1", drop = FALSE]
    
    # Calculate cost
    costs[[i]] <- eval_cost_summary(curr_p, sols[[i]])$cost[[1]]
  }

  # Extract best solution
  scenarioSolution <- sols[[length(n_cost_layers)]]

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
    } else {
      puVis <- FALSE
    }
    
    # Save solution spatial visualization
    if(isTRUE(puVis)){
      
      # Reclass table between planning unit id & solution
      reclassTable <- matrix(c(1:17,
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



  # Evaluate solutions ---------------------------------------------------------

  # Read initial problem
  initialProblem <-
    problem(x = sim_pu, features = sim_features,
            rij = rij, cost_column = problemTabularDatasheet$cost_column)

  # Calculate representation by cost optimized solution
  featureRepresentation <- eval_feature_representation_summary(
    initialProblem, scenarioSolution[,"solution_1", drop = FALSE])

  # Save results
  names(featureRepresentation)[2] <- "projectFeaturesId"
  featureRepresentationOutput <- as.data.frame(featureRepresentation)
  names(featureRepresentationOutput)[3:5] <- c("totalAmount", "absoluteHeld",
                                              "relativeHeld") 
  saveDatasheet(ssimObject = myScenario, 
                data = featureRepresentationOutput[,-1], 
                name = "prioritizr_featureRepresentationOutput")

  # Planning units v. cost layers
  rij_costs <- data.frame(pu = as.numeric(), 
                          species = as.numeric(), 
                          amount = as.numeric())
  for(i in 1:3){
    speciesID <- costs_features$id[i]
    rij_temp <- data.frame(pu = sim_pu$id,
                          species = speciesID,
                          amount = sim_pu[,i+2])
    rij_costs <- rbind(rij_costs, rij_temp)
  }
  
  # Create problem using costs as features
  p_cost <-
    problem(
      x = sim_pu, features = costs_features, rij = rij_costs,
      cost_column = problemTabularDatasheet$cost_column
    )

  # Calculate representation by cost optimized solution
  featureRepresentation <- eval_feature_representation_summary(
    p_cost, scenarioSolution[,"solution_1", drop = FALSE])

  # Save results
  names(featureRepresentation)[1:2] <- c("projectSolutionsId", "projectCostsId")
  costsRepresentationOutput <- as.data.frame(featureRepresentation)
  names(costsRepresentationOutput)[3:5] <- c("totalAmount", "absoluteHeld",
                                              "relativeHeld") 
  costsRepresentationOutput$projectSolutionsId <- "Scenario solution"


  # Solution file name
  solutionFilename <- solutionObject$solution
  
  # Read tabular solution
  initialSolution <- readRDS(file = solutionFilename)

  # Calculate representation by cost optimized solution
  featureRepresentation <- eval_feature_representation_summary(
    p_cost, initialSolution[,"solution_1", drop = FALSE])

  # Save results
  names(featureRepresentation)[1:2] <- c("projectSolutionsId", "projectCostsId")
  costsRepresentationOutput2 <- as.data.frame(featureRepresentation)
  names(costsRepresentationOutput2)[3:5] <- c("totalAmount", "absoluteHeld",
                                            "relativeHeld") 
  costsRepresentationOutput2$projectSolutionsId <- "Initial solution"

  # Combine
  costsRepresentationOutput <- rbind(costsRepresentationOutput, 
                                    costsRepresentationOutput2)

  # Solutions names
  solutionsDatasheet <- data.frame(Name = c("Scenario solution", 
                                            "Initial solution"))

  # Save features to project scope
  saveDatasheet(ssimObject = myProject, 
                data = solutionsDatasheet, 
                name = "prioritizr_projectSolutions")

  saveDatasheet(ssimObject = myScenario, 
                data = costsRepresentationOutput, 
                name = "prioritizr_costRepresentationOutput")


}



# Equal cost optimization ------------------------------------------------------

if(costLayersDatasheet$method == "Equal"){

  progressBar(type = "message", message = "Optimizing equal cost layers")

  # Create empty list for results
  costs <- numeric(n_cost_layers)
  
  # Prioritize each cost layer separately to assess upper bound of cost
  for(i in seq_len(n_cost_layers)) {
    
    # Build problem
    curr_p <-
      problem(x = sim_pu, features = sim_features,
              rij = rij, cost_column = costsDatasheet$Name[i]) %>%
      add_min_set_objective() %>%
      add_absolute_targets(featureRepresentationOutput$absoluteHeld*0.55) %>%
      add_linear_constraints(
        threshold = objectiveDatasheet$budget,
        sense = "<=",
        data = problemTabularDatasheet$cost_column
      ) %>%
      add_binary_decisions() %>%
      add_default_solver(gap = 0, verbose = FALSE)
      
    # Solve problem
    curr_s <- solve(curr_p, force = TRUE, run_checks = FALSE)

    # Calculate the total cost of the solution
    costs[[i]] <- eval_cost_summary(curr_p, curr_s[, "solution_1", drop = FALSE])$cost[[1]]

  }

  # Calculate new targets
  t1 <- featureRepresentationOutput
  t1$new_target <- t1$absoluteHeld * (1 - objectiveDatasheet$budget)

  # Generate budget increments
  budget_increments <- lapply(
    costs,
    function(x) seq(0, x * (1 + costLayersDatasheet$budgetPadding), 
    length.out = costLayersDatasheet$budgetIncrements)
  )

  # Generate solutions by iterating over each budget increment and cost layer
  for(j in seq_len(costLayersDatasheet$budgetIncrements)) {
    
    # Build problem 
    p1 <-
      problem(x = sim_pu, features = sim_features,
              rij = rij, cost_column = problemTabularDatasheet$cost_column) %>%
      add_min_set_objective() %>%
      add_absolute_targets(t1$new_target) %>%
      add_linear_constraints(
        threshold = objectiveDatasheet$budget,
        sense = "<=",
        data = problemTabularDatasheet$cost_column
      ) %>%
      add_binary_decisions() %>%
      add_default_solver(gap = 0, verbose = FALSE)
    
    # Add constraints for each cost layer and the j'th budget
    for (i in seq_len(n_cost_layers)) {
      p1 <-
        p1 %>%
        add_linear_constraints(
          threshold = budget_increments[[i]][[j]],
          sense = "<=",
          data = costsDatasheet$Name[i]
        )
    }

    # Solve problem
    scenarioSolution <- try(solve(p1, force = TRUE, run_checks = FALSE), silent = TRUE)
    
    # If scenarioSolution is a feasible solution, then end loop
    if (!inherits(scenarioSolution, "try-error")) break() 
  }
  if (inherits(scenarioSolution)) {
    stop(
      "Could not find feasible multi-objective solution. Try increasing the parameter `Budget padding`."
    )
  }
  
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
    } else {
      puVis <- FALSE
    }
    
    # Save solution spatial visualization
    if(isTRUE(puVis)){
      
      # Reclass table between planning unit id & solution
      reclassTable <- matrix(c(1:17,
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
  



  # Evaluate solutions ---------------------------------------------------------

  # Read initial problem
  initialProblem <-
    problem(x = sim_pu, features = sim_features,
            rij = rij, cost_column = problemTabularDatasheet$cost_column)

  # Calculate representation by cost optimized solution
  featureRepresentation <- eval_feature_representation_summary(
    initialProblem, scenarioSolution[,"solution_1", drop = FALSE])

  # Save results
  names(featureRepresentation)[2] <- "projectFeaturesId"
  featureRepresentationOutput <- as.data.frame(featureRepresentation)
  names(featureRepresentationOutput)[3:5] <- c("totalAmount", "absoluteHeld",
                                              "relativeHeld") 
  saveDatasheet(ssimObject = myScenario, 
                data = featureRepresentationOutput[,-1], 
                name = "prioritizr_featureRepresentationOutput")

  # Planning units v. cost layers
  rij_costs <- data.frame(pu = as.numeric(), 
                          species = as.numeric(), 
                          amount = as.numeric())
  for(i in 1:3){
    speciesID <- costs_features$id[i]
    rij_temp <- data.frame(pu = sim_pu$id,
                          species = speciesID,
                          amount = sim_pu[,i+2])
    rij_costs <- rbind(rij_costs, rij_temp)
  }

  # Create problem using costs as features
  p_cost <-
    problem(
      x = sim_pu, features = costs_features, rij = rij_costs,
      cost_column = problemTabularDatasheet$cost_column
    )

  # Calculate representation by cost optimized solution
  featureRepresentation <- eval_feature_representation_summary(
    p_cost, scenarioSolution[,"solution_1", drop = FALSE])

  # Save results
  names(featureRepresentation)[1:2] <- c("projectSolutionsId", "projectCostsId")
  costsRepresentationOutput <- as.data.frame(featureRepresentation)
  names(costsRepresentationOutput)[3:5] <- c("totalAmount", "absoluteHeld",
                                              "relativeHeld") 
  costsRepresentationOutput$projectSolutionsId <- "Scenario solution"


  # Solution file name
  solutionFilename <- solutionObject$solution
  
  # Read tabular solution
  initialSolution <- readRDS(file = solutionFilename)

  # Calculate representation by cost optimized solution
  featureRepresentation <- eval_feature_representation_summary(
    p_cost, initialSolution[,"solution_1", drop = FALSE])

  # Save results
  names(featureRepresentation)[1:2] <- c("projectSolutionsId", "projectCostsId")
  costsRepresentationOutput2 <- as.data.frame(featureRepresentation)
  names(costsRepresentationOutput2)[3:5] <- c("totalAmount", "absoluteHeld",
                                            "relativeHeld") 
  costsRepresentationOutput2$projectSolutionsId <- "Initial solution"

  # Combine
  costsRepresentationOutput <- rbind(costsRepresentationOutput, 
                                     costsRepresentationOutput2)

  # Solutions names
  solutionsDatasheet <- data.frame(Name = c("Scenario solution", 
                                            "Initial solution"))

  # Save features to project scope
  saveDatasheet(ssimObject = myProject, 
                data = solutionsDatasheet, 
                name = "prioritizr_projectSolutions")

  saveDatasheet(ssimObject = myScenario, 
                data = costsRepresentationOutput, 
                name = "prioritizr_costRepresentationOutput")

}


