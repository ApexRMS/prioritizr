## prioritizr SyncroSim - Base prioritization transformer
##
## Written by Carina Rauen Firkowski
##
## This script runs all the steps in a prioritization problem, from problem
## formulation to solving and evaluating the solution.

# Workspace --------------------------------------------------------------------

# Load rsyncrosim packages
library(rsyncrosim)
progressBar(
  type = "message",
  message = "Validating environment and installing missing dependencies"
)

# Load environment, library, project & scenario
e <- ssimEnvironment()
myLibrary <- ssimLibrary()
myProject <- rsyncrosim::project()
myScenario <- scenario()

# Open Conda configuration options
condaDatasheet <- datasheet(myLibrary, name = "core_Option")

## Check OS
isWindows <- function() tolower(Sys.info()[["sysname"]]) == "windows"


# Install missing packages when using Conda on Windows
if (isTRUE(condaDatasheet$UseConda) && isWindows()) {
  # Update packages
  update.packages(
    repos = 'http://cran.us.r-project.org',
    ask = FALSE,
    oldPkgs = "terra",
    type = "binary"
  )
  update.packages(
    repos = 'http://cran.us.r-project.org',
    ask = FALSE,
    oldPkgs = "sf",
    type = "binary"
  )

  # Check which packages to install
  packagesToCheck <- c("sf", "prioritizr", "symphony", "Rsymphony")
  packagesToInstallList <- packagesToCheck[
    !(packagesToCheck %in%
      installed.packages()[, "Package"])
  ]

  # Install missing packages
  for (packagesToInstall in packagesToInstallList) {
    if (packagesToInstall == "sf") {
      install.packages(
        "sf",
        repos = "http://cran.us.r-project.org",
        type = "binary"
      )
    }
    if (packagesToInstall == "prioritizr") {
      install.packages(
        "https://cran.r-project.org/src/contrib/Archive/prioritizr/prioritizr_8.0.4.tar.gz",
        repos = NULL,
        type = "source"
      )
    }
    if (packagesToInstall == "Rsymphony") {
      install.packages("Rsymphony", repos = "http://cran.us.r-project.org")
    }
  }
}

# Load packages
progressBar(type = "message", message = "Setting up workspace")
library(stringr)
library(terra)
library(tidyr)
library(dplyr)
library(prioritizr)
if (isWindows()) {
  library(Rsymphony)
} else {
  library(lpsymphony)
}

# Data directory
dataDir <- e$DataDirectory

# Create directory if it does not exist
ifelse(!dir.exists(file.path(dataDir)), dir.create(file.path(dataDir)), FALSE)

# Scenario path
dataPath <- paste(
  dataDir,
  paste0("Scenario-", scenarioId(myScenario)),
  sep = "\\"
)

# Create directory if it does not exist
ifelse(!dir.exists(file.path(dataPath)), dir.create(file.path(dataPath)), FALSE)


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
saveDatasheet(
  ssimObject = myScenario,
  data = problemOutput,
  name = "prioritizr_problemFormulation"
)

# Solution
# Write file
solutionObjectFilename <- file.path(paste0(dataPath, "\\solution.rds"))
saveRDS(scenarioSolution, file = solutionObjectFilename)
# Save file path to datasheet
solutionOutput <- data.frame(solution = solutionObjectFilename)
saveDatasheet(
  ssimObject = myScenario,
  data = solutionOutput,
  name = "prioritizr_solutionObject"
)
