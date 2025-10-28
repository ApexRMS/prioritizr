# Installation script for prioritizr package dependencies
# This script:
# 1. Checks for Rtools and installs it if needed (Windows only)
# 2. Installs specific versions of prioritizr and Rsymphony from source
# 3. Installs packages into the conda environment library

# Function to check if Rtools is installed
check_rtools <- function() {
  if (.Platform$OS.type != "windows") {
    message("Not on Windows - Rtools not needed")
    return(TRUE)
  }

  # Check if Rtools is available
  has_rtools <- tryCatch(
    {
      pkgbuild::check_rtools(debug = TRUE)
    },
    error = function(e) {
      FALSE
    }
  )

  return(has_rtools)
}

# Function to install Rtools programmatically
install_rtools <- function() {
  if (.Platform$OS.type != "windows") {
    stop("Rtools is only needed on Windows")
  }

  message("Checking for Rtools...")

  # First check if pkgbuild is installed
  if (!requireNamespace("pkgbuild", quietly = TRUE)) {
    message("Installing pkgbuild package...")
    install.packages("pkgbuild", repos = "https://cran.r-project.org")
  }

  if (check_rtools()) {
    message("Rtools is already installed!")
    return(TRUE)
  }

  message("Rtools not found. Installing...")

  # Get R version to determine Rtools version
  r_version <- getRversion()

  # Determine which Rtools version to install
  if (r_version >= "4.0" && r_version < "4.2") {
    rtools_url <- "https://cran.r-project.org/bin/windows/Rtools/rtools40-x86_64.exe"
    rtools_version <- "4.0"
  } else if (r_version >= "4.2" && r_version < "4.3") {
    rtools_url <- "https://cran.r-project.org/bin/windows/Rtools/rtools42/rtools.html"
    rtools_version <- "4.2"
  } else if (r_version >= "4.3") {
    rtools_url <- "https://cran.r-project.org/bin/windows/Rtools/rtools43/rtools.html"
    rtools_version <- "4.3"
  } else {
    stop("R version too old. Please upgrade R.")
  }

  # Download and install Rtools
  message(paste0("Downloading Rtools ", rtools_version, "..."))

  # For R 4.0 we can download directly
  if (r_version >= "4.0" && r_version < "4.2") {
    temp_file <- tempfile(fileext = ".exe")
    download.file(rtools_url, temp_file, mode = "wb")

    message("Installing Rtools... (this may take a few minutes)")
    message("NOTE: If a dialog appears, please click through the installer")

    # Run installer
    system2(temp_file, args = c("/VERYSILENT", "/NORESTART"))

    # Clean up
    unlink(temp_file)

    # Verify installation
    Sys.sleep(5) # Wait for installation to complete

    if (check_rtools()) {
      message("Rtools installed successfully!")
      return(TRUE)
    } else {
      warning(
        "Rtools installation may not have completed. Please install manually from:"
      )
      warning(rtools_url)
      return(FALSE)
    }
  } else {
    # For R 4.2+ we need to direct user to download
    message("Please install Rtools manually from:")
    message(rtools_url)
    message("After installation, restart R and run this script again.")
    return(FALSE)
  }
}

# Function to get conda environment library path
get_conda_lib_path <- function() {
  # Get all library paths
  lib_paths <- .libPaths()

  # Find the conda path (usually contains "conda" or is the first path)
  # If in conda environment, the first path should be the conda env
  conda_path <- lib_paths[1]

  # Clean the path: remove any trailing/leading quotes and normalize
  # This fixes issues where .libPaths() returns paths with quotes
  conda_path <- gsub("^['\"]|['\"]$", "", conda_path)  # Remove leading/trailing quotes
  conda_path <- normalizePath(conda_path, winslash = "/", mustWork = FALSE)

  message(paste("Target library path:", conda_path))
  return(conda_path)
}

# Function to install prioritizr from archive
install_prioritizr <- function(version = "8.0.4", lib_path = NULL) {
  if (is.null(lib_path)) {
    lib_path <- get_conda_lib_path()
  }

  message(paste0("Installing prioritizr version ", version, " from source..."))

  # URL for archived version
  url <- paste0(
    "https://cran.r-project.org/src/contrib/Archive/prioritizr/prioritizr_",
    version,
    ".tar.gz"
  )

  # Install from URL
  install.packages(
    url,
    repos = NULL,
    type = "source",
    lib = lib_path,
    dependencies = TRUE
  )

  message("prioritizr installation complete!")
}

# Function to install Rsymphony
install_rsymphony <- function(lib_path = NULL) {
  if (is.null(lib_path)) {
    lib_path <- get_conda_lib_path()
  }

  message("Installing Rsymphony...")

  # On Windows, we can use binary if available
  if (.Platform$OS.type == "windows") {
    # Try binary first
    tryCatch(
      {
        install.packages(
          "Rsymphony",
          repos = "https://cran.r-project.org",
          type = "win.binary",
          lib = lib_path
        )
        message("Rsymphony installed from binary!")
      },
      error = function(e) {
        # Fall back to source
        message("Binary not available, installing from source...")
        install.packages(
          "Rsymphony",
          repos = "https://cran.r-project.org",
          type = "source",
          lib = lib_path
        )
      }
    )
  } else {
    # Linux/Mac: install from source
    install.packages(
      "Rsymphony",
      repos = "https://cran.r-project.org",
      type = "source",
      lib = lib_path
    )
  }

  message("Rsymphony installation complete!")
}

# Main installation workflow
installDependencies <- function() {
  message("=== prioritizr Package Dependency Installation ===")
  message(paste("R version:", R.version.string))
  message(paste("Platform:", .Platform$OS.type))
  message("")

  # Show current library paths
  message("Current library paths:")
  for (i in seq_along(.libPaths())) {
    message(paste0("  [", i, "] ", .libPaths()[i]))
  }
  message("")

  # Get target library path
  lib_path <- get_conda_lib_path()

  # Step 1: Check/Install Rtools (Windows only)
  if (.Platform$OS.type == "windows") {
    if (!check_rtools()) {
      message("Rtools is required for prioritizr source package installation.")

      # If running non-interactively (via Rscript), automatically install
      # If running interactively, ask the user
      if (!interactive()) {
        message("Running in non-interactive mode, automatically installing Rtools...")
        response <- "y"
      } else {
        response <- readline("Would you like to install Rtools now? (y/n): ")
      }

      if (tolower(response) == "y") {
        install_rtools()

        # Check again
        if (!check_rtools()) {
          stop(
            "Rtools installation failed. Please install manually and try again."
          )
        }
      } else {
        stop(
          "Rtools is required. Please install manually from: https://cran.r-project.org/bin/windows/Rtools/"
        )
      }
    } else {
      message("✓ Rtools is installed")
    }

    # Add Rtools to PATH for this R session
    message("Adding Rtools to PATH...")
    rtools_path <- "C:\\rtools40\\usr\\bin;C:\\rtools40\\mingw64\\bin"
    Sys.setenv(PATH = paste(rtools_path, Sys.getenv("PATH"), sep = ";"))
    message("✓ Rtools added to PATH")
  }

  # Step 2: Install required dependencies
  message("\nInstalling package dependencies...")

  required_packages <- c("assertthat", "slam", "RcppArmadillo", "codetools")
  for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      message(paste("Installing", pkg, "..."))

      # Use binary installation on Windows, source on other platforms
      pkg_type <- if (.Platform$OS.type == "windows") "win.binary" else "source"

      install.packages(
        pkg,
        repos = "https://cran.r-project.org",
        lib = lib_path,
        type = pkg_type
      )
    } else {
      message(paste("✓", pkg, "already installed"))
    }
  }

  # Step 3: Install prioritizr
  if (!requireNamespace("prioritizr", quietly = TRUE)) {
    install_prioritizr(version = "8.0.4", lib_path = lib_path)
  } else {
    # Check version
    current_version <- packageVersion("prioritizr")
    if (current_version != "8.0.4") {
      message(paste("Current prioritizr version:", current_version))

      # If running non-interactively, automatically reinstall correct version
      if (!interactive()) {
        message("Running in non-interactive mode, automatically reinstalling prioritizr 8.0.4...")
        response <- "y"
      } else {
        response <- readline("Reinstall prioritizr 8.0.4? (y/n): ")
      }

      if (tolower(response) == "y") {
        tryCatch(
          {
            remove.packages("prioritizr", lib = lib_path)
          },
          error = function(e) {
            message("Note: Package removal encountered an issue, proceeding with installation...")
          }
        )
        install_prioritizr(version = "8.0.4", lib_path = lib_path)
      }
    } else {
      message("✓ prioritizr 8.0.4 already installed")
    }
  }

  # Step 4: Install Rsymphony
  if (!requireNamespace("Rsymphony", quietly = TRUE)) {
    install_rsymphony(lib_path = lib_path)
  } else {
    message("✓ Rsymphony already installed")
  }

  # Step 5: Verify installations
  message("\n=== Verification ===")

  tryCatch(
    {
      library(prioritizr, lib.loc = lib_path)
      message(paste(
        "✓ prioritizr",
        packageVersion("prioritizr"),
        "loaded successfully"
      ))
    },
    error = function(e) {
      message("✗ Failed to load prioritizr:", e$message)
    }
  )

  tryCatch(
    {
      library(Rsymphony, lib.loc = lib_path)
      message("✓ Rsymphony loaded successfully")
    },
    error = function(e) {
      message("✗ Failed to load Rsymphony:", e$message)
    }
  )

  message("\n=== Installation Complete ===")
  message("You can now use the prioritizr package with Rsymphony solver.")
  message("")
  message("Library location:", lib_path)
}

# Run main function
if (!interactive()) {
  installDependencies()
} else {
  message("Run installDependencies() to start the installation process")
}
