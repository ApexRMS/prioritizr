## prioritizr SyncroSim - Base prioritization transformer
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
library(prioritizr)
library(Rsymphony)

# Load environment, library, project & scenario
e <- ssimEnvironment()
myLibrary <- ssimLibrary()
myProject <- rsyncrosim::project()
myScenario <- scenario()

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

