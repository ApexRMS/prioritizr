## prioritizr SyncroSim - Impact assessment transformer
##
## Written by Carina Rauen Firkowski
##
## This script compares two scenarios, calculating the difference between a
## baseline and an alternative scenario of choice.



# Workspace --------------------------------------------------------------------

# Load packages
library(rsyncrosim); progressBar(type = "message", 
                                 message = "Setting up workspace")
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
dataPath <- paste(dataDir, paste0("Scenario-", scenarioId(myScenario)), sep="\\") 

# Create directory if it does not exist
ifelse(!dir.exists(file.path(dataPath)), 
       dir.create(file.path(dataPath)), FALSE)

progressBar(type = "message", message = "Setting up scenario")

# Get ID for scenarios to compare
scenarioIdDatasheet <- datasheet(myScenario,
                                 name = "prioritizr_differenceScenarios")

# Check if IDs were provided
if(is.na(scenarioIdDatasheet$Baseline)){
  stop("The Impact Assessment transformer was added to the pipeline without a 
  baseline scenario ID. Provide a baseline scenario ID to be used for comparison
  or remove the transformer from the pipeline.")
}
if(is.na(scenarioIdDatasheet$Alternative)){
  scenarioPipeline <- datasheet(myScenario, name = "core_Pipeline")
  if(scenarioPipeline$StageNameId[1] != "Impact Assessment"){
    # Set current scenario ID
    scenarioIdDatasheet$Alternative <- scenarioId(myScenario)
    # Save datasheet
    saveDatasheet(ssimObject = myScenario, 
                  data = scenarioIdDatasheet, 
                  name = "prioritizr_differenceScenarios")
    updateRunLog("The Impact Assessment transformer was added to the pipeline but 
    no alternative scenario ID was provided. Therefore, the current scenario was 
    used for the analysis.",
                 type = "warning")
  }
}

# Check if ID is parent or result scenario
allScenarios <- scenario(myProject)
baseScenarioTable <- allScenarios[
  allScenarios$ScenarioId == scenarioIdDatasheet$Baseline,]
altrScenarioTable <- allScenarios[
  allScenarios$ScenarioId == scenarioIdDatasheet$Alternative,]

# Load Results Scenario for the baseline scenario
if(baseScenarioTable$IsResult == "Yes"){
  baseScenario <- scenario(myProject, scenario = scenarioIdDatasheet$Baseline)
} else {
  baseScenarios <- allScenarios[allScenarios$ParentId == scenarioIdDatasheet$Baseline,]
  if(dim(baseScenarios)[1] == 0){
    stop("No results were found for the Baseline Scenario.")
  } else {
    baseResultID <- max(baseScenarios$ScenarioId, na.rm = TRUE)
    baseScenario <- scenario(myProject, scenario = baseResultID)
  }
}
# Load Results Scenario for the alternative scenario
if(altrScenarioTable$IsResult == "Yes"){
  altrScenario <- scenario(myProject, scenario = scenarioIdDatasheet$Alternative)
} else {
  altrScenarios <- allScenarios[allScenarios$ParentId == scenarioIdDatasheet$Alternative,]
  if(dim(altrScenarios)[1] == 0){
    stop("No results were found for the Alternative Scenario.")
  } else {
    altrResultID <- max(altrScenarios$ScenarioId, na.rm = TRUE)
    altrScenario <- scenario(myProject, scenario = altrResultID)
  }
}

# Identify impact assessment type
basePipeline <- datasheet(baseScenario, name = "core_Pipeline")
altrPipeline <- datasheet(altrScenario, name = "core_Pipeline", optional = TRUE)
if(any(basePipeline$StageNameId == "2 - Base Prioritization") &
   any(altrPipeline$StageNameId == "3 - Multi-Cost Prioritization")){
  iaType <- "Cost-optimization"
}
if(any(basePipeline$StageNameId == "2 - Base Prioritization") &
   any(altrPipeline$StageNameId == "2 - Base Prioritization")){
  iaType <- "Base comparison"
}
if(any(basePipeline$StageNameId == "3 - Multi-Cost Prioritization") &
   any(altrPipeline$StageNameId == "3 - Multi-Cost Prioritization")){
  iaType <- "Multi-Cost comparison"
}



# Impact assessment ------------------------------------------------------------

progressBar(type = "message", message = "Comparing scenarios")

# Number of planning units ---------------------
  
# Open datasheets
baseNumberPUDatasheet <- datasheet(
  baseScenario,
  "prioritizr_numberOutput")
altrNumberPUDatasheet <- datasheet(
  altrScenario,
  "prioritizr_numberOutput")

if(dim(baseNumberPUDatasheet)[1] != 0 & dim(altrNumberPUDatasheet)[1] != 0 &
   dim(baseNumberPUDatasheet)[2] == dim(altrNumberPUDatasheet)[2]){
  
  # Calculate difference
  numberPUdiff <- data.frame(
  n = (altrNumberPUDatasheet$n - baseNumberPUDatasheet$n))
  
  # Save feature representation difference
  saveDatasheet(ssimObject = myScenario, 
                data = numberPUdiff, 
                  name = "prioritizr_numberOutputDiff")
}


# Solution cost --------------------------------
  
# Open datasheets
baseCostDatasheet <- datasheet(
  baseScenario,
  "prioritizr_costOutput")
altrCostDatasheet <- datasheet(
  altrScenario,
  "prioritizr_costOutput")
  
if(dim(baseCostDatasheet)[1] != 0 & dim(altrCostDatasheet)[1] != 0 &
   dim(baseCostDatasheet)[2] == dim(altrCostDatasheet)[2]){
    
  # Calculate feature representation difference
  costDiff <- data.frame(
    cost = (altrCostDatasheet$cost - baseCostDatasheet$cost))
  
  # Save feature representation difference
  saveDatasheet(ssimObject = myScenario, 
                data = costDiff, 
                name = "prioritizr_costOutputDiff")
  
}
  
  
# Boundary length ------------------------------

# Open datasheets
baseBoundaryDatasheet <- datasheet(
  baseScenario,
  "prioritizr_boundaryOutput")
altrBoundaryDatasheet <- datasheet(
  altrScenario,
  "prioritizr_boundaryOutput")

if(dim(baseBoundaryDatasheet)[1] != 0 & dim(altrBoundaryDatasheet)[1] != 0 &
   dim(baseBoundaryDatasheet)[2] == dim(altrBoundaryDatasheet)[2]){
  
  # Calculate feature representation difference
  boundaryDiff <- data.frame(
    boundary = (altrBoundaryDatasheet$boundary - baseBoundaryDatasheet$boundary))
  
  # Save feature representation difference
  saveDatasheet(ssimObject = myScenario, 
                data = boundaryDiff, 
                name = "prioritizr_boundaryOutputDiff")
  
}

  
# Target coverage --------------------------------

# Open datasheets
baseTargetCoverageDatasheet <- datasheet(
  baseScenario,
  "prioritizr_targetCoverageOutput")
altrTargetCoverageDatasheet <- datasheet(
  altrScenario,
  "prioritizr_targetCoverageOutput")

if(dim(baseTargetCoverageDatasheet)[1] != 0 & 
   dim(altrTargetCoverageDatasheet)[1] != 0 &
   dim(baseTargetCoverageDatasheet)[2] == dim(altrTargetCoverageDatasheet)[2]){
  
  # Calculate feature representation difference
  targetCoverageOutputDiff <- data.frame(
    projectFeaturesId = baseTargetCoverageDatasheet$projectFeaturesId,
    totalAmount = (altrTargetCoverageDatasheet$totalAmount - 
                     baseTargetCoverageDatasheet$totalAmount),
    absoluteTarget = (altrTargetCoverageDatasheet$absoluteTarget - 
                        baseTargetCoverageDatasheet$absoluteTarget),
    absoluteHeld = (altrTargetCoverageDatasheet$absoluteHeld - 
                      baseTargetCoverageDatasheet$absoluteHeld),
    absoluteShortfall = (altrTargetCoverageDatasheet$absoluteShortfall - 
                           baseTargetCoverageDatasheet$absoluteShortfall),
    relativeTarget = (altrTargetCoverageDatasheet$relativeTarget - 
                        baseTargetCoverageDatasheet$relativeTarget),
    relativeHeld = (altrTargetCoverageDatasheet$relativeHeld - 
                      baseTargetCoverageDatasheet$relativeHeld),
    relativeShortfall = (altrTargetCoverageDatasheet$relativeShortfall - 
                           baseTargetCoverageDatasheet$relativeShortfall))
  
  # Save feature representation difference
  saveDatasheet(ssimObject = myScenario, 
                data = targetCoverageOutputDiff, 
                name = "prioritizr_targetCoverageOutputDiff")
  
}

  
# Replacement importance ----------------------

# Open datasheets
baseReplacementDatasheet <- datasheet(
  baseScenario,
  "prioritizr_replacementTabularOutput")
altrReplacementDatasheet <- datasheet(
  altrScenario,
  "prioritizr_replacementTabularOutput")

if(dim(baseReplacementDatasheet)[1] != 0 & 
   dim(altrReplacementDatasheet)[1] != 0 &
   dim(baseReplacementDatasheet)[2] == dim(altrReplacementDatasheet)[2]){
  
  # Calculate feature representation difference
  replacementDiff <- data.frame(
    id = baseReplacementDatasheet$id,
    rc = (altrReplacementDatasheet$rc - baseReplacementDatasheet$rc))
  
  # Save feature representation difference
  saveDatasheet(ssimObject = myScenario, 
                data = replacementDiff, 
                name = "prioritizr_replacementTabularOutputDiff")
  
}

# Open datasheets
baseReplaceDatasheet <- datasheet(
  baseScenario,
  "prioritizr_replacementSpatialOutput")
altrReplaceDatasheet <- datasheet(
  altrScenario,
  "prioritizr_replacementSpatialOutput")

if(dim(baseReplaceDatasheet)[1] != 0 & dim(altrReplaceDatasheet)[1] != 0){
  
  # Open raster files
  baseRast <- rast(baseReplaceDatasheet$replacement)
  altrRast <- rast(altrReplaceDatasheet$replacement)
  
  # Calculate difference
  diffVis <- altrRast - baseRast
  
  # Save raster
  diffFilepath <- paste0(
    dataPath, "\\prioritizr_replacementSpatialOutputDiff")
  diffFilename <- file.path(paste0(diffFilepath,
                                     "\\replacementDiffRaster.tif"))
  # Create directory if it does not exist
  ifelse(!dir.exists(file.path(diffFilepath)), 
         dir.create(file.path(diffFilepath)), FALSE)
  writeRaster(diffVis, filename = diffFilename, overwrite = TRUE)
  
  # Save file path to datasheet
  replacementSpatialOutput <- data.frame(
    replacement = diffFilename)
  saveDatasheet(ssimObject = myScenario, 
                data = replacementSpatialOutput, 
                name = "prioritizr_replacementSpatialOutputDiff")
}


# Ferrier scores -------------------------------

# Open datasheets
baseFerrierDatasheet <- datasheet(
  baseScenario,
  "prioritizr_ferrierTabularOutput")
altrFerrierDatasheet <- datasheet(
  altrScenario,
  "prioritizr_ferrierTabularOutput")

if(dim(baseFerrierDatasheet)[1] != 0 & dim(altrFerrierDatasheet)[1] != 0 &
   dim(baseFerrierDatasheet)[2] == dim(altrFerrierDatasheet)[2]){
  
  # Calculate feature representation difference
  ferrierDiff <- data.frame(
    id = baseFerrierDatasheet$id,
    projectFeaturesId = baseFerrierDatasheet$projectFeaturesId,
    scores = (altrFerrierDatasheet$scores - baseFerrierDatasheet$scores))
  
  # Save feature representation difference
  saveDatasheet(ssimObject = myScenario, 
                data = ferrierDiff, 
                name = "prioritizr_ferrierTabularOutputDiff")
}

# Open datasheets
baseFerrierDatasheet <- datasheet(
  baseScenario,
  "prioritizr_ferrierSpatialOutput")
altrFerrierDatasheet <- datasheet(
  altrScenario,
  "prioritizr_ferrierSpatialOutput")

if(dim(baseFerrierDatasheet)[1] != 0 & dim(altrFerrierDatasheet)[1] != 0){
  
  # Open project scope datasheet
  featuresDatasheet <- datasheet(myProject,
                                 name = "prioritizr_projectFeatures")
  
  # Define folder path
  diffFilepath <- paste0(
    dataPath, "\\prioritizr_ferrierSpatialOutputDiff")
  
  # Create directory if it does not exist
  ifelse(!dir.exists(file.path(diffFilepath)), 
         dir.create(file.path(diffFilepath)), FALSE)
  
  # Read datasheet
  diffDatasheet <- data.frame(projectFeaturesId = as.character(),
                              ferrierMethod = as.character())
  
  for(j in 1:length(featuresDatasheet$variableName)){
    
    # Get feature ID
    featureID <- featuresDatasheet$featureID[j]
    
    # Open raster files
    baseRast <- rast(baseFerrierDatasheet$ferrierMethod[j])
    altrRast <- rast(altrFerrierDatasheet$ferrierMethod[j])
    
    # Calculate difference
    diffVis <- altrRast - baseRast
    
    # Define file name
    diffFilename <- file.path(
      paste0(diffFilepath,
             "\\replacementDiffRasterFeature", featureID, ".tif"))
    
    # Create directory if it does not exist
    ifelse(!dir.exists(file.path(diffFilepath)), 
           dir.create(file.path(diffFilepath)), FALSE)
    writeRaster(diffVis, filename = diffFilename, overwrite = TRUE)
    
    # Save file path
    diffDatasheet[j,1] <- featuresDatasheet$Name[j]
    diffDatasheet[j,2] <- diffFilename
    
  }

  # Save datasheet
  saveDatasheet(ssimObject = myScenario, 
                data = diffDatasheet, 
                name = "prioritizr_ferrierSpatialOutputDiff")
}
  
# Rarity weighted richness ---------------------

# Open datasheets
baseRarityDatasheet <- datasheet(
  baseScenario,
  "prioritizr_rarityTabularOutput")
altrRarityDatasheet <- datasheet(
  altrScenario,
  "prioritizr_rarityTabularOutput")

if(dim(baseRarityDatasheet)[1] != 0 & dim(altrRarityDatasheet)[1] != 0 &
   dim(baseRarityDatasheet)[2] == dim(altrRarityDatasheet)[2]){
  
  # Calculate feature representation difference
  rarityDiff <- data.frame(
    id = baseRarityDatasheet$id,
    rwr = (altrRarityDatasheet$rwr - baseRarityDatasheet$rwr))
  
  # Save feature representation difference
  saveDatasheet(ssimObject = myScenario, 
                data = rarityDiff, 
                name = "prioritizr_rarityTabularOutputDiff")
  
}

# Open datasheets
baseRarityDatasheet <- datasheet(
  baseScenario,
  "prioritizr_raritySpatialOutput")
altrRarityDatasheet <- datasheet(
  altrScenario,
  "prioritizr_raritySpatialOutput")

if(dim(baseRarityDatasheet)[1] != 0 & dim(altrRarityDatasheet)[1] != 0){
  
  # Open raster files
  baseRast <- rast(baseRarityDatasheet$rarityWeightedRichness)
  altrRast <- rast(altrRarityDatasheet$rarityWeightedRichness)
  
  # Calculate difference
  diffVis <- altrRast - baseRast
  
  # Save raster
  diffFilepath <- paste0(
    dataPath, "\\prioritizr_raritySpatialOutputDiff")
  diffFilename <- file.path(paste0(diffFilepath,
                                   "\\rarityWeightedRichnessDiffRaster.tif"))
  # Create directory if it does not exist
  ifelse(!dir.exists(file.path(diffFilepath)), 
         dir.create(file.path(diffFilepath)), FALSE)
  writeRaster(diffVis, filename = diffFilename, overwrite = TRUE)
  
  # Save file path to datasheet
  raritySpatialOutput <- data.frame(
    rarityWeightedRichness = diffFilename)
  saveDatasheet(ssimObject = myScenario, 
                data = raritySpatialOutput, 
                name = "prioritizr_raritySpatialOutputDiff")
}

# Compare feature representation --------------------------------

# Open datasheets
baseFeatureRepresentationDatasheet <- datasheet(
  baseScenario,
  "prioritizr_featureRepresentationOutput")
altrFeatureRepresentationDatasheet <- datasheet(
  altrScenario,
  "prioritizr_featureRepresentationOutput")

# Calculate feature representation difference
featureRepresentationOutputDiff <- data.frame(
  projectFeaturesId = baseFeatureRepresentationDatasheet$projectFeaturesId,
  totalAmount = (altrFeatureRepresentationDatasheet$totalAmount - 
                   baseFeatureRepresentationDatasheet$totalAmount),
  absoluteHeld = (altrFeatureRepresentationDatasheet$absoluteHeld - 
                    baseFeatureRepresentationDatasheet$absoluteHeld),
  relativeHeld = (altrFeatureRepresentationDatasheet$relativeHeld - 
                    baseFeatureRepresentationDatasheet$relativeHeld))

# Save feature representation difference
saveDatasheet(ssimObject = myScenario, 
              data = featureRepresentationOutputDiff, 
              name = "prioritizr_featureRepresentationDiffOutput")


# Cost-optimization ---------------------------------------------
if(iaType == "Cost-optimization"){
  
  # Open datasheets
  # Project
  costsDatasheet <- datasheet(myProject,
                              name = "prioritizr_projectCosts")
  # Baseline
  problemFormatDatasheet <- datasheet(
    baseScenario,
    name = "prioritizr_problemFormat")
  problemSpatialDatasheet <- datasheet(
    baseScenario,
    name = "prioritizr_problemSpatial")
  solutionOutputDatasheet <- datasheet(
    baseScenario,
    name = "prioritizr_solutionRasterOutput")
  solutionObject <- datasheet(
    baseScenario,
    name = "prioritizr_solutionObject")
  # Alternative
  costProblemDatasheet <- datasheet(
    altrScenario,
    name = "prioritizr_costProblemFormulation")
  costsRepresentationOutput <- datasheet(
    altrScenario, 
    name = "prioritizr_optimizedCostRepresentationOutput")
  
  # Get file names
  solutionFilename <- solutionObject$solution
  problemFilename <- costProblemDatasheet$problem
  
  # Read files
  initialSolution <- readRDS(file = solutionFilename)
  p_cost <- readRDS(file = problemFilename)
  
  # Calculate representation by base solution
  featureRepresentation <- eval_feature_representation_summary(
    p_cost, initialSolution[,"solution_1", drop = FALSE])

  # Arrange alphabetically
  featureRepresentation <-  arrange(featureRepresentation, desc(feature))

  # Save results
  names(featureRepresentation)[2] <- c("projectCostsId")
  nameDiff <- setdiff(featureRepresentation$projectCostsId, costsDatasheet$Name)
  if(length(nameDiff) != 0){
    featureRepresentation$projectCostsId[
      featureRepresentation$projectCostsId == 
        costsDatasheet$variableName] <- costsDatasheet$Name
  }
  costsRepresentationOutputBase <- as.data.frame(featureRepresentation[,-1])
  names(costsRepresentationOutputBase)[2:4] <- c("totalAmount", "absoluteHeld",
                                                 "relativeHeld") 
  
  # Save cost representation for base solution
  saveDatasheet(ssimObject = myScenario, 
                data = costsRepresentationOutputBase, 
                name = "prioritizr_baseCostRepresentationOutput")
  
  # Calculate cost representation difference
  costsRepresentationOutputDiff <- data.frame(
    projectCostsId = costsRepresentationOutputBase$projectCostsId,
    totalAmount = (costsRepresentationOutput$totalAmount - 
                     costsRepresentationOutputBase$totalAmount),
    absoluteHeld = (costsRepresentationOutput$absoluteHeld - 
                      costsRepresentationOutputBase$absoluteHeld),
    relativeHeld = (costsRepresentationOutput$relativeHeld - 
                      costsRepresentationOutputBase$relativeHeld))
  
  # Save cost representation for base solution
  saveDatasheet(ssimObject = myScenario, 
                data = costsRepresentationOutputDiff, 
                name = "prioritizr_diffCostRepresentationOutput")
  
}

# Multi-cost comparison -----------------------------------------
if(iaType == "Multi-cost comparison"){
  
  # Open datasheets
  baseCostRepresentation <- datasheet(
    baseScenario,
    "prioritizr_optimizedCostRepresentationOutput")
  altrCostRepresentation <- datasheet(
    altrScenario,
    "prioritizr_optimizedCostRepresentationOutput")
  
  # Calculate cost representation difference
  costsRepresentationOutputDiff <- data.frame(
    projectCostsId = baseCostRepresentation$projectCostsId,
    totalAmount = (altrCostRepresentation$totalAmount - 
                     baseCostRepresentation$totalAmount),
    absoluteHeld = (altrCostRepresentation$absoluteHeld - 
                      baseCostRepresentation$absoluteHeld),
    relativeHeld = (altrCostRepresentation$relativeHeld - 
                      baseCostRepresentation$relativeHeld))
  
  # Save cost representation difference
  saveDatasheet(ssimObject = myScenario, 
                data = costsRepresentationOutputDiff, 
                name = "prioritizr_diffCostRepresentationOutput")
  
}


# Compare solutions ---------------------------------------------

# Open datasheets
baseSolutionDatasheet <- datasheet(
  baseScenario,
  "prioritizr_solutionRasterOutput")
altrSolutionDatasheet <- datasheet(
  altrScenario,
  "prioritizr_solutionRasterOutput")

# Spatial comparison
if(dim(baseSolutionDatasheet)[1] != 0 & dim(altrSolutionDatasheet)[1] != 0){
  
  # Load raster files
  baseSolution <- rast(baseSolutionDatasheet$solution)
  altrSolution <- rast(altrSolutionDatasheet$solution)
  
  # Calculate difference in selected planning units between solutions
  # 1 - 1 = 0   present in both
  # 0 - 0 = 0   present in neither
  # 1 - 0 = 1   present in base only
  # 0 - 1 = -1  present in altr only
  baseOnlyVis <- altrOnlyVis <- baseSolution - altrSolution
  # Planning units only in base solution
  baseOnlyVis[baseOnlyVis == -1] <- 0
  # Planning units only in altr solution
  altrOnlyVis[altrOnlyVis == 1] <- 0
  altrOnlyVis[altrOnlyVis == -1] <- 1
  
  # Calculate planning units in both solutions
  bothSolutionsVis <- baseSolution + altrSolution
  bothSolutionsVis[bothSolutionsVis == 1] <- 0
  bothSolutionsVis[bothSolutionsVis == 2] <- 1
  
  # Define file path
  solutionDiffFilepath <- paste0(dataPath, 
                                 "\\prioritizr_solutionDiffRasterOutput")
  bothSolutionsFilename <- file.path(paste0(solutionDiffFilepath,
                                            "\\consensusRaster.tif"))
  baseOnlyFilename <- file.path(paste0(solutionDiffFilepath,
                                       "\\baselineOnlyRaster.tif"))
  altrOnlyFilename <- file.path(paste0(solutionDiffFilepath,
                                       "\\alternativeOnlyRaster.tif"))
  # Create directory if it does not exist
  ifelse(!dir.exists(file.path(solutionDiffFilepath)), 
         dir.create(file.path(solutionDiffFilepath)), FALSE)
  
  # Save raster files
  writeRaster(bothSolutionsVis, filename = bothSolutionsFilename, 
              overwrite = TRUE)
  writeRaster(baseOnlyVis, filename = baseOnlyFilename,
              overwrite = TRUE)
  writeRaster(altrOnlyVis, filename = altrOnlyFilename,
              overwrite = TRUE)
  
  # Save file path to datasheet
  solutionDiffRasterOutput <- data.frame(initial = baseOnlyFilename,
                                         optimized = altrOnlyFilename,
                                         both = bothSolutionsFilename)
  saveDatasheet(ssimObject = myScenario, 
                data = solutionDiffRasterOutput, 
                name = "prioritizr_solutionDiffRasterOutput")
  
} else {
  updateRunLog("No spatial solutions are available. Therefore, no solution 
  impact assessment was generated.",
               type = "warning")
}




