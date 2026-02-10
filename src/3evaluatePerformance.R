## prioritizr SyncroSim - Evaluate performance
##
## Written by Carina Rauen Firkowski
##
## This script loads a prioritizr problem formulation and solution and evaluates
## the performance of the solution. It requires that model stages "Problem 
## formulation" and "Prioritization" be run first.



# Open datasheets --------------------------------------------------------------

progressBar(type = "message", message = "Evaluating the solution performance")

performanceDatasheet <- datasheet(myScenario,
                                  name = "prioritizr_evaluatePerformance")



# Rename variable names for consistency with prioritizr R ----------------------

names(performanceDatasheet) <- c("eval_n_summary", "eval_cost_summary",
                                 "eval_feature_representation_summary",
                                 "eval_target_coverage_summary",
                                 "eval_boundary_summary")



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



# Evaluate performance ---------------------------------------------------------

# Calculate solution number
if(isTRUE(performanceDatasheet$eval_n_summary)){
  
  if(class(scenarioSolution) != "data.frame"){
    n <- eval_n_summary(scenarioProblem, scenarioSolution) }
  if(class(scenarioSolution) == "data.frame"){
    n <- eval_n_summary(scenarioProblem, scenarioSolution[,"solution_1", 
                                                          drop = FALSE]) }
  # Save results
  numberOutput <- data.frame(n = n$n)
  saveDatasheet(ssimObject = myScenario, 
                data = numberOutput, 
                name = "prioritizr_numberOutput")
}

# Calculate solution cost
if(isTRUE(performanceDatasheet$eval_cost_summary)){
  
  if(class(scenarioSolution) != "data.frame"){
    cost <- eval_cost_summary(scenarioProblem, scenarioSolution) }
  if(class(scenarioSolution) == "data.frame"){
    cost <- eval_cost_summary(scenarioProblem, scenarioSolution[,"solution_1",
                                                                drop = FALSE]) }
  # Save results
  costOutput <- data.frame(cost = cost$cost)
  saveDatasheet(ssimObject = myScenario, 
                data = costOutput, 
                name = "prioritizr_costOutput")
}

# Load datasheets
  inputDatasheet <- datasheet(myScenario,
                              name = "prioritizr_inputData")
  optionsDatasheet <- datasheet(myScenario,
                                name = "prioritizr_preprocessOptions")

# Calculate how well features are represented by a solution
if(isTRUE(performanceDatasheet$eval_feature_representation_summary)){

  if(class(scenarioSolution) != "data.frame"){
    featureRepresentation <- eval_feature_representation_summary(
      scenarioProblem, scenarioSolution) }
  if(class(scenarioSolution) == "data.frame"){
    
    # If input data was scaled and/or inverting, use original values.
    # Otherwise, use prioritizr function.
    if (isTRUE((optionsDatasheet$scaleData)) | 
          !is.null(optionsDatasheet$invertData)) {
      
      # Read data
      inputData <- read.csv(
        inputDatasheet$tabularProblem, header = TRUE
      )

      # Create empty dataframe for results
      featureRepresentation <- data.frame(
        summary = as.character(),
        feature = as.character(),
        total_amount = as.numeric(),
        absolute_held = as.numeric(),
        relative_held = as.numeric()
      )

      for(j in 1:length(featuresDatasheet$variableName)){
          
        # Get feature ID
        featureName <- featuresDatasheet$variableName[j]
        
        # Get solution
        solution <- scenarioSolution[,"solution_1", drop = FALSE]

        # Total amount of each feature
        totalFeature <- sum(inputData[,featureName])
        # Amount of each feature held in the solution
        heldFeature <- sum(inputData[solution$solution_1 == 1, featureName])
        # Relative amount
        relativeFeature <- heldFeature/totalFeature

        # Build dataframe
        featureRepresentationTemp <- data.frame(
          summary = "overall",
          feature = featureName,
          total_amount = totalFeature,
          absolute_held = heldFeature,
          relative_held = relativeFeature
        )
              
        # Combine dataframes
        featureRepresentation <- rbind(
          featureRepresentation,
          featureRepresentationTemp
        )
      }
    } else {
      featureRepresentation <- eval_feature_representation_summary(
      scenarioProblem, scenarioSolution[,"solution_1", drop = FALSE])
    }
  }
  
  # Save results
  names(featureRepresentation)[2] <- "projectFeaturesId"
  featureRepresentation$projectFeaturesId[
    featureRepresentation$projectFeaturesId == 
      featuresDatasheet$variableName] <- featuresDatasheet$Name
  featureRepresentationOutput <- as.data.frame(featureRepresentation)
  names(featureRepresentationOutput)[3:5] <- c("totalAmount", "absoluteHeld",
                                               "relativeHeld") 
  saveDatasheet(ssimObject = myScenario, 
                data = featureRepresentationOutput[,-1], 
                name = "prioritizr_featureRepresentationOutput") 
}

# Calculate how well the targets are met by the solution
if(isTRUE(performanceDatasheet$eval_target_coverage_summary)){
  
  if(class(scenarioSolution) != "data.frame"){
    targetCoverage <- eval_target_coverage_summary(scenarioProblem, 
                                                   scenarioSolution) }
  
  if(class(scenarioSolution) == "data.frame"){

    # If input data was scaled and/or inverting, use original values.
    # Otherwise, use prioritizr function.
    if (isTRUE((optionsDatasheet$scaleData)) | 
          !is.null(optionsDatasheet$invertData) & 
          targetDatasheet$addTarget == "Relative") {
      
      # Read data
      inputData <- read.csv(
        inputDatasheet$tabularProblem, header = TRUE
      )

      # Get target
      targetDatasheet <- datasheet(myScenario, name = "prioritizr_targets")

      # Create empty dataframe for results
      targetCoverage <- data.frame(
        feature = as.character(),
        met = as.character(),
        total_amount = as.numeric(),
        absolute_target = as.numeric(),
        absolute_held = as.numeric(),
        absolute_shortfall = as.numeric(),
        relative_target = as.numeric(),
        relative_held = as.numeric(),
        relative_shortfall = as.numeric()
      )

      for(j in 1:length(featuresDatasheet$variableName)){

        # Get feature name
        featureName <- featuresDatasheet$variableName[j]
        # Get feature ID
        featureID <- featuresDatasheet$featureID[j]
          
        # Get solution
        solution <- scenarioSolution[,"solution_1", drop = FALSE]

        # Total amount of each feature
        totalFeature <- sum(inputData[,featureName])
        # Target amount of each feature
        targetFeature <- totalFeature * targetDatasheet$targets
        # Amount of each feature held in the solution
        heldFeature <- sum(inputData[solution$solution_1 == 1, featureName])
        # Relative amount of each feature held in the solution
        relativeHeld <- heldFeature / totalFeature
        
        # Target absolute shortfall
        absoluteShortfall <- targetFeature - heldFeature
        # Target relative shortfall
        relativeShortfall <- targetDatasheet$targets - relativeHeld
                 
        # Check if target was met or not
        targetMet <- (heldFeature >= targetFeature)

        # Build dataframe
        targetCoverageTemp <- data.frame(
          feature = featureName,
          met = targetMet,
          total_amount = totalFeature,
          absolute_target = targetFeature,
          absolute_held = heldFeature,
          absolute_shortfall = absoluteShortfall,
          relative_target = targetDatasheet$targets,
          relative_held = relativeHeld,
          relative_shortfall = relativeShortfall
        )
              
        # Combine dataframes
        targetCoverage <- rbind(
          targetCoverage,
          targetCoverageTemp
        )
      }      
    } else {
    targetCoverage <- eval_target_coverage_summary(
      scenarioProblem, scenarioSolution[,"solution_1", drop = FALSE]) 
    }
  }
  
  # Save results
  names(targetCoverage)[1] <- "projectFeaturesId"
  targetCoverage$projectFeaturesId[
    targetCoverage$projectFeaturesId == 
      featuresDatasheet$variableName] <- featuresDatasheet$Name
  targetCoverageOutput <- as.data.frame(targetCoverage)
  names(targetCoverageOutput)[3:9] <- c("totalAmount", "absoluteTarget", 
                                        "absoluteHeld", "absoluteShortfall",
                                        "relativeTarget", "relativeHeld",
                                        "relativeShortfall")
  saveDatasheet(ssimObject = myScenario, 
                data = targetCoverageOutput, 
                name = "prioritizr_targetCoverageOutput") 
}

# Calculate the solution total exposed boundary length (perimeter)
if(isTRUE(performanceDatasheet$eval_boundary_summary)){
  
  if(class(scenarioSolution) != "data.frame"){
    temp_boundaryOutput <- eval_boundary_summary(scenarioProblem, 
                                                 scenarioSolution)
    # Save results
    boundaryOutput <- data.frame(boundary = temp_boundaryOutput$boundary)
    saveDatasheet(ssimObject = myScenario, 
                  data = boundaryOutput, 
                  name = "prioritizr_boundaryOutput")
  }
  if(class(scenarioSolution) == "data.frame"){
    updateRunLog("The output option for boundary lenght is not available for a 
    tabular problem formulation.",
                type = "warning")
  }
}


