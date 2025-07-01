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


# Format data ------------------------------------------------------------------

# Tabular problem
if(length(inputDatasheet$tabularProblem) != 0){
  if(!is.na(inputDatasheet$tabularProblem)){
 
    # Read data
    inputData <- read.csv(inputDatasheet$tabularProblem, header = TRUE)
    
    # Planning units
    puData <- inputData[,1:3]
    
    # Features
    numberFeatures <- dim(inputData)[2]-3
    featuresData <- data.frame(id = c(1:numberFeatures),
                               name = names(inputData[,4:(numberFeatures+3)]))
    
    # Planning units vs. Features
    puVsFt <- inputData[,-2:-3] %>%
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
