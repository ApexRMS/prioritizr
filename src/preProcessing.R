## prioritizr SyncroSim - Data formatting transformer
##
## Written by Carina Rauen Firkowski
##
## This script formats input data for tabular problems and multiple cost layers
## as required by the base and multi-cost prioritization transformers, 
## respectively.



# Workspace --------------------------------------------------------------------

# Load rsyncrosim packages
library(rsyncrosim)
library(dplyr)
library(tidyr)

progressBar(type = "message", message = "Loading data and setting up scenario")

# Load environment, library, project & scenario
e <- ssimEnvironment()
myLibrary <- ssimLibrary()
myProject <- rsyncrosim::project()
myScenario <- scenario()



# Open datasheets --------------------------------------------------------------

inputDatasheet <- datasheet(myScenario,
                            name = "prioritizr_inputData")
optionsDatasheet <- datasheet(myScenario,
                            name = "prioritizr_preprocessOptions")



# Functions --------------------------------------------------------------------

# Scale variables 
scale_feature <- function(featureVector){
  
  # Get minimum and maximum value across all features
  maxValue <- max(featureVector)
  minValue <- min(featureVector)
  
  # Scale data from 0 to 1
  scaled_feature <- (featureVector - minValue) / (maxValue - minValue)
  
  return(scaled_feature)
}

# Function to reverse scale
reverse_scale <- function(featureVector) {
  featureVector <- unlist(lapply(featureVector, function(x) 0 - x + 1))
  return(featureVector)
}



# Format data ------------------------------------------------------------------

# Tabular problem
if(length(inputDatasheet$tabularProblem) != 0){
  if(!is.na(inputDatasheet$tabularProblem)){
 
    # Read data
    inputData <- read.csv(inputDatasheet$tabularProblem, header = TRUE)
    
    # Planning units
    puData <- inputData[,c(1,3:4)]
    names(puData) <- c("id", "Name", "cost")
    
    # Features
    numberFeatures <- dim(inputData)[2]-4
    featuresData <- data.frame(id = c(1:numberFeatures),
                               name = names(inputData[,5:(numberFeatures+4)]))
    
    # Check if data should be scaled
    if (isTRUE(optionsDatasheet$scaleData)) {
      
      # Scale features
      for(i in 5:(numberFeatures+4)){
        inputData[,i] <- scale_feature(inputData[,i, drop = TRUE])
      }
    }
    
    # Check is feature variables need to be inverted
    if (!is.null(optionsDatasheet$invertData)) {
      
      # Open list of feature variables to invert
      toInvert <- as.vector(
        read.csv(optionsDatasheet$invertData, header = FALSE)[,1]
        )
      
      # Reverse scale
      for(i in toInvert){
        inputData[,i] <- reverse_scale(inputData[,i, drop = TRUE])
      }
    }
    
    # Planning units vs. Features
    puVsFt <- inputData[,-2:-4] %>%
      pivot_longer(cols = 2:(numberFeatures+1),
                   names_to = "species", values_to = "amount")
    puVsFt$species[puVsFt$species == featuresData$name] <- featuresData$id
    names(puVsFt)[1] <- "pu"
    
    # Save
    saveDatasheet(ssimObject = myScenario, 
                  data = puData, 
                  name = "prioritizr_problemTabularPU")
    saveDatasheet(ssimObject = myScenario, 
                  data = featuresData, 
                  name = "prioritizr_problemTabularFeatures")
    saveDatasheet(ssimObject = myScenario, 
                  data = puVsFt, 
                  name = "prioritizr_problemTabularPUvsFeatures")
    
    
    # Project definition ----------------------------------------
    
    # Load existing planning units from project scope
    puDatasheetExisting <- datasheet(myScenario,
                                     name = "prioritizr_projectPU")
    
    # Project planning unit definition
    projectPU <- inputData[,1:3]
    names(projectPU) <- c("puID", "Name", "variableName")
    
    # If datasheet is empty
    if(dim(puDatasheetExisting)[1] == 0){
      
      # Save
      saveDatasheet(ssimObject = myProject, 
                    data = projectPU, 
                    name = "prioritizr_projectPU")
    } else {
      
      # Calculate dissimilarities in planning unit ID and variable names  
      puDatasheetDifference <- setdiff(projectPU[,c(1,3)], 
                                       puDatasheetExisting[,c(1,3)])
      
      # Add extra rows to project datasheet
      newRows <- projectPU[projectPU$puID == puDatasheetDifference$puID,]
      projectPUnew <- rbind(puDatasheetExisting, newRows)
      
      # Save
      saveDatasheet(ssimObject = myProject, 
                    data = projectPUnew, 
                    name = "prioritizr_projectPU")
      
    }
  }
}

# Multi-cost
if(length(inputDatasheet$costData) != 0){
  if(!is.na(inputDatasheet$costData)){
    
    # Read data
    costData <- read.csv(inputDatasheet$costData, header = TRUE)
    
    # Pivot 
    numberCosts <- dim(costData)[2]-1
    costDataLong <- costData %>%
      pivot_longer(cols = 2:(numberCosts+1),
                   names_to = "costName", values_to = "costAmount")
    
    # Save
    saveDatasheet(ssimObject = myScenario, 
                  data = costDataLong, 
                  name = "prioritizr_costLayersData")
    
  }
}
