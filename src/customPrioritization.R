## prioritizr SyncroSim - Simple prioritization transformer
##
## Written by Carina Rauen Firkowski
##
## This script runs all the steps in a prioritization problem, from problem
## formulation to solving and evaluating the solution.



# Workspace --------------------------------------------------------------------

# Load conda packages
library(rsyncrosim); progressBar(type = "message", 
                                 message = "Setting up workspace")
library(stringr)
library(terra)
library(tidyr)
library(dplyr)

# Load environment, library, project & scenario
e <- ssimEnvironment()
myLibrary <- ssimLibrary()
myProject <- rsyncrosim::project()
myScenario <- scenario()

# Open Conda configuration options
condaDatasheet <- datasheet(myLibrary, name = "core_Option")

# Install missing packages when using Conda
if(isTRUE(condaDatasheet$UseConda)){
  
  # Path to R session package library
  packagePath <- e$PackageDirectory
  syncrosimPath <- str_remove(packagePath, fixed("\\Packages")) %>%
    str_remove(fixed("\\prioritizr"))
  rLibraryPath <- file.path(syncrosimPath, "Conda", "envs", "prioritizr", 
                            "prioritizrEnv-v2", "lib", "R", "library")
  
  # Check which packages to install
  packagesToCheck <- c("prioritizr", "symphony", "Rsymphony")
  packagesToInstall <- packagesToCheck[!(packagesToCheck %in% 
                      installed.packages(lib.loc = rLibraryPath)[,"Package"])]
  # Install missing packages
  if(length(packagesToInstall) != 0){
    install.packages(packagesToInstall,
                     dependencies = TRUE,
                     lib = rLibraryPath,
                     repos = "https://mirror.rcg.sfu.ca/mirror/CRAN/")
  }
  
  # Load additional packages
  .libPaths(rLibraryPath)
  library(prioritizr)
  library(Rsymphony)
} else {
  # Load additional packages
  library(prioritizr)
  library(Rsymphony)
}

# Data directory
dataDir <- e$DataDirectory

# Create directory if it does not exist
ifelse(!dir.exists(file.path(dataDir)), 
       dir.create(file.path(dataDir)), FALSE)

# Scenario path
dataPath <- paste(dataDir, paste0("Scenario-", scenarioId(myScenario)), sep="\\") 



# Model steps ------------------------------------------------------------------

# Problem formulation
source(file.path(e$PackageDirectory, "1problemFormulation.R"))

# Prioritization
source(file.path(e$PackageDirectory, "2prioritization.R"))

# Evaluate performance
source(file.path(e$PackageDirectory, "3evaluatePerformance.R"))

# Evaluate importance
source(file.path(e$PackageDirectory, "4evaluateImportance.R"))



# Save intermediate files ------------------------------------------------------

# Problem
# Write file
problemFilename <- file.path(paste0(dataPath, "\\problemFormulation.rds"))
saveRDS(scenarioProblem, file = problemFilename)
# Save file path to datasheet
problemOutput <- data.frame(problem = problemFilename)
saveDatasheet(ssimObject = myScenario, 
              data = problemOutput,
              name = "prioritizr_problemFormulation")

# Solution
# Write file
solutionObjectFilename <- file.path(paste0(dataPath, "\\solution.rds"))
saveRDS(scenarioSolution, file = solutionObjectFilename)
# Save file path to datasheet
solutionOutput <- data.frame(solution = solutionObjectFilename)
saveDatasheet(ssimObject = myScenario, 
              data = solutionOutput, 
              name = "prioritizr_solutionObject")

