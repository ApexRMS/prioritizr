# Dependency Management Challenges for SyncroSim prioritizr Package

**Status**: ✅ RESOLVED (2025-10-27)
**Solution**: Hybrid Binary/Source installation script with automated Rtools setup
**Script**: `src/installDependencies.R`

---

## Current Situation

The SyncroSim prioritizr package requires two critical R packages:

- **prioritizr** (version 8.0.4 specifically)
- **Rsymphony** (latest version)

Currently, when running the package:

- ✓ The package **works** functionally
- ✗ `prioritizr` and `Rsymphony` **do not appear** in `conda list`
- ⚠️ The packages are likely installed in the **user library** (outside conda environment)

## The Problem

### What's Happening

R searches for packages in multiple library paths, in order:

1. **User library** (e.g., `~/Documents/R/win-library/4.1/`)
2. **Conda environment library** (e.g., `~/miniconda3/envs/prioritizrEnv-2-2-2/Lib/R/library/`)
3. **System library**

When packages aren't found in the conda environment, R falls back to the user library. This is why:

- The code runs successfully (packages are found in user library)
- `conda list` doesn't show them (they're not managed by conda)

### Why This Is Problematic

1. **Reproducibility Issues**

   - Other users creating the environment from `prioritizrEnv.yml` won't have these packages
   - Package versions aren't locked or documented in the environment

2. **Distribution Challenges**

   - Cannot reliably distribute this package to other users
   - Docker containers or CI/CD pipelines will fail

3. **Version Control Problems**

   - No guarantee the correct version of prioritizr (8.0.4) is installed
   - Dependency conflicts between user library and conda environment possible

4. **Environment Isolation Broken**
   - The conda environment isn't truly self-contained
   - Defeats the purpose of using conda for dependency management

## The Challenges

### Challenge 1: prioritizr Not Available in conda-forge

**Issue**: The prioritizr package is not available through conda-forge channels for R 4.1.

**Why this matters**:

- Cannot simply add `r-prioritizr` to `prioritizrEnv.yml`
- Must install from CRAN (R's package repository)

**Verification**:

```bash
conda search r-prioritizr -c conda-forge
# Returns: No match found
```

### Challenge 2: Specific Version Requirement

**Issue**: The SyncroSim package requires prioritizr version **8.0.4**, not the latest version.

**Why this matters**:

- Version 8.0.4 is archived (no longer the current CRAN version)
- Must install from CRAN archive: `https://cran.r-project.org/src/contrib/Archive/prioritizr/`
- Cannot install archived versions from binaries - **must compile from source**

**Current prioritizr version**: 9.0.0+ (as of 2024)

### Challenge 3: Rtools Requirement for Source Installation

**Issue**: Installing R packages from source on Windows requires **Rtools** (compiler toolchain).

**Why this matters**:

- Rtools is not included in the conda environment
- Rtools is not available as a conda package
- Must be installed separately on the system
- Requires administrative privileges typically

**What Rtools provides**:

- GCC compiler for C/C++ code
- Make utilities
- Other build tools needed for R package compilation

### Challenge 4: Rsymphony Binary vs Source

**Issue**: Rsymphony availability varies by platform:

- **Windows**: Often available as binary (easier)
- **Linux**: Must compile from source (requires compiler + SYMPHONY libraries)

**Additional complexity**:

- Linux version uses `lpsymphony` (Bioconductor) instead
- Different solver packages for different operating systems
- Current code already handles this with OS detection

### Challenge 5: Dependencies of prioritizr

**Issue**: prioritizr has compiled dependencies that also need compilation:

- `slam` (Sparse Linear Algebra)
- `RcppArmadillo` (C++ linear algebra library)
- `assertthat`
- `codetools`

**Why this matters**:

- These must also be compiled from source
- Each has its own compilation requirements
- Increases the complexity of the build process

### Challenge 6: Terra Package Constraints

**Issue**: The conda environment uses an older version of `terra` (1.5-21).

**Why this matters**:

- Terra has been updated significantly since
- Current conda-forge version might conflict with R 4.1
- You've determined this is "the only conda environment that works" after extensive testing
- exactextractr has many dependencies tied to terra version

**Trade-off**: Newer packages vs. stable working environment

## Proposed Solutions

### Solution 1: Programmatic Rtools Installation + Hybrid Binary/Source (Recommended) ✅ IMPLEMENTED

**Approach**: Create an R script that automates the entire process with optimized installation strategy.

**Implementation**:

```r
# Script workflow:
1. Check if Rtools is installed
2. If not, download and install Rtools automatically (no prompts in non-interactive mode)
3. Add Rtools to PATH for the current R session
4. Install dependencies as BINARIES on Windows (assertthat, slam, RcppArmadillo, codetools)
5. Install prioritizr 8.0.4 from CRAN archive (SOURCE - requires Rtools)
6. Install Rsymphony (binary on Windows, source on Linux)
7. Install into conda environment library path
8. Verify installations
```

**Key Improvements** (Updated 2025):

- ✓ **Dependencies install as binaries** - Avoids compilation issues for slam, RcppArmadillo
- ✓ **Auto-adds Rtools to PATH** - Fixes "make not found" errors
- ✓ **Fully non-interactive mode** - No prompts when running via `Rscript`
- ✓ **Error handling** - Graceful handling of package removal issues
- ✓ **Fixed function call bug** - Corrected `main()` → `installDependencies()`

**Pros**:

- ✓ Fully automated (one command: `Rscript installDependencies.R`)
- ✓ Can be documented and shared with users
- ✓ Installs into conda environment (proper isolation)
- ✓ Works with existing conda environment
- ✓ Handles Rtools installation automatically
- ✓ Can check/verify installations
- ✓ **Minimal compilation** - Only prioritizr needs compiling
- ✓ **Fast installation** - Binary packages install in seconds
- ✓ **No user interaction needed** - Perfect for automation

**Cons**:

- ✗ Rtools installation may require admin privileges
- ✗ Rtools is ~400MB download (one-time)
- ✗ Not pure conda solution (mixing package managers)
- ✗ Rtools installer may show UI dialogs (during initial install only)
- ✗ First-time setup is slower (~5-10 minutes including Rtools)

**Best for**:

- Users who need a working solution quickly
- When conda packages aren't available
- Development environments
- Automated CI/CD pipelines

**Created file**: `installDependencies.R` (in `src/` directory)

---

### Solution 2: Pure Binary Installation in Conda Environment

**Approach**: Install pre-compiled binary packages directly into conda library.

**Implementation**:

```r
# For Windows only:
lib_path <- .libPaths()[1]  # Get conda environment path

# Install binary versions
install.packages("Rsymphony",
                 repos = "https://cran.r-project.org",
                 type = "win.binary",
                 lib = lib_path)

# For prioritizr - check if 8.0.4 binary available
install.packages("https://cran.r-project.org/bin/windows/contrib/4.1/prioritizr_8.0.4.zip",
                 repos = NULL,
                 type = "binary",
                 lib = lib_path)
```

**Pros**:

- ✓ No Rtools required
- ✓ Fast installation (no compilation)
- ✓ Still installs to conda environment
- ✓ Fewer dependencies

**Cons**:

- ✗ **Windows only** - doesn't work on Linux
- ✗ Binary for prioritizr 8.0.4 may not be available for R 4.1
- ✗ Docker container (Linux) cannot use this approach
- ✗ Less portable across R versions

**Best for**:

- Windows-only deployments
- When binaries are available for your R version

---

### Solution 3: Install R 4.4+ in Conda + All Binary Packages

**Approach**: Upgrade to latest R version where more packages are available.

**Implementation**:

```yaml
# prioritizrEnv.yml
dependencies:
  - r-base=4.4.* # Latest R
  # ... other dependencies
```

Then install latest prioritizr (9.0+) as binary.

**Pros**:

- ✓ Access to latest packages
- ✓ More binaries available
- ✓ Better performance/features in newer R
- ✓ Fewer compilation issues

**Cons**:

- ✗ **Cannot use prioritizr 8.0.4** (your requirement)
- ✗ Would require code changes to work with new prioritizr API
- ✗ May break compatibility with existing SyncroSim projects
- ✗ Terra/exactextractr may have new dependency issues
- ✗ Would need extensive retesting

**Best for**:

- New projects without version constraints
- When you can update to latest prioritizr

**Not viable**: Because you specifically need version 8.0.4

---

### Solution 4: Docker-Based Distribution Only

**Approach**: Don't fix conda environment; just document that Docker is required.

**Implementation**:
Your existing `Docker/Dockerfile` already handles this:

```dockerfile
RUN Rscript -e "install.packages('https://cran.r-project.org/src/contrib/Archive/prioritizr/prioritizr_8.0.4.tar.gz', repos=NULL, type='source')"
```

**Pros**:

- ✓ Already implemented
- ✓ Fully reproducible
- ✓ All dependencies handled
- ✓ Works on any platform with Docker

**Cons**:

- ✗ Users must use Docker (may not be familiar)
- ✗ Overhead of Docker installation
- ✗ Windows users may have WSL2 requirements
- ✗ Not usable for local development without Docker

**Best for**:

- Production deployments
- Server environments
- Ensuring exact reproducibility

---

### Solution 5: Conda Build Custom Package

**Approach**: Create a conda recipe for prioritizr 8.0.4 and host it locally.

**Implementation**:

```yaml
# meta.yaml for conda recipe
package:
  name: r-prioritizr
  version: 8.0.4

source:
  url: https://cran.r-project.org/src/contrib/Archive/prioritizr/prioritizr_8.0.4.tar.gz

build:
  number: 0
  rpaths:
    - lib/R/lib/

requirements:
  build:
    - r-base
    - r-rcpp
    # ... other build deps
```

Then build and install:

```bash
conda build recipe/
conda install -c local r-prioritizr=8.0.4
```

**Pros**:

- ✓ Pure conda solution
- ✓ Proper dependency management
- ✓ Can version control the recipe
- ✓ Reusable across projects

**Cons**:

- ✗ Requires learning conda-build
- ✗ Must maintain custom recipe
- ✗ Need to build for each platform (Windows/Linux/Mac)
- ✗ Still requires compiler toolchain during build
- ✗ Cannot easily share (would need private conda channel)
- ✗ Significant initial time investment

**Best for**:

- Organizations with existing conda infrastructure
- Multiple projects using same packages
- Long-term maintenance

---

## Recommended Implementation Path

### For Development (Now) ✅ COMPLETED

**Use Solution 1**: Programmatic Rtools + Hybrid Binary/Source Installation

The script has been implemented and optimized with the following features:

- Automatic Rtools installation (no prompts)
- Binary installation for dependencies (faster, no compilation issues)
- Automatic PATH configuration
- Full non-interactive support

**Usage**:

```bash
# Navigate to the src directory
cd src

# Run the installation script (fully automated)
Rscript installDependencies.R
```

**What happens**:

1. ✓ Checks/installs Rtools (if needed) - ~5 min first time, ~10 sec after
2. ✓ Adds Rtools to PATH automatically
3. ✓ Installs dependencies as binaries - ~30 seconds
4. ✓ Compiles prioritizr 8.0.4 from source - ~2-3 minutes
5. ✓ Installs Rsymphony binary - ~10 seconds
6. ✓ Verifies all installations

**Total time**:

- First run (with Rtools): ~10 minutes
- Subsequent runs (Rtools already installed): ~3-5 minutes

**Documentation to add**:

```markdown
## Installation

1. Create conda environment:
   conda env create -f src/prioritizrEnv.yml

2. Activate environment:
   conda activate prioritizrEnv-2-2-2

3. Install prioritizr and Rsymphony (fully automated):
   cd src
   Rscript installDependencies.R

Note: First-time setup may take ~10 minutes as Rtools (~400MB) needs to be downloaded and installed.
```

### For Production/Distribution

**Use Solution 4**: Docker Container

- Already implemented in `Docker/Dockerfile`
- Fully reproducible
- No manual setup required

### Long-term Improvement

**Consider Solution 5**: Custom Conda Package

- Invest time to create proper conda recipe
- Build for Windows (primary platform)
- Host on conda-forge or private channel
- Eliminates need for Rtools on user machines

## Why Packages Install Outside Conda Environment

When you run `install.packages()` in R without specifying `lib` parameter:

```r
# This installs to FIRST library path (usually user library)
install.packages("prioritizr")

# This installs to conda environment
install.packages("prioritizr", lib = .libPaths()[1])
```

**What's happening**:

1. R defaults to installing in user library (writable without admin)
2. Conda environment library is often read-only or second in priority
3. Your installations succeeded but went to user library
4. Code works because R finds them in user library during search

**To verify where packages are**:

```r
# Check library paths
.libPaths()

# Find specific package
find.package("prioritizr")

# Check if in conda environment
grepl("conda", find.package("prioritizr"))
```

## Testing the Solution

After implementing Solution 1, verify:

```r
# 1. Check library paths
.libPaths()
# First path should contain "conda"

# 2. Check package locations
find.package("prioritizr")
find.package("Rsymphony")
# Both should be in conda environment path

# 3. Verify versions
packageVersion("prioritizr")
# Should be exactly 8.0.4

# 4. Test functionality
library(prioritizr)
library(Rsymphony)

# Try creating a simple problem
data(sim_pu_polygons, package = "prioritizr")
data(sim_features, package = "prioritizr")

p <- problem(sim_pu_polygons, sim_features, "cost") %>%
  add_min_set_objective() %>%
  add_relative_targets(0.1) %>%
  add_rsymphony_solver()

s <- solve(p)
# Should complete without error
```

## Summary

| Solution                            | Status             | Pros                                  | Cons                           | Recommended For         |
| ----------------------------------- | ------------------ | ------------------------------------- | ------------------------------ | ----------------------- |
| **1. Programmatic Rtools + Hybrid** | ✅ **IMPLEMENTED** | Automated, fast (binaries), works now | Needs Rtools (~400MB) one-time | ✅ Development & CI/CD  |
| 2. Pure Binary                      | ⚠️ Partial         | Fast, no compiler                     | Windows only, no v8.0.4 binary | Limited cases           |
| 3. Upgrade R                        | ❌ Not viable      | Latest features                       | Cannot use v8.0.4              | ❌ Breaks compatibility |
| **4. Docker Only**                  | ✅ **IMPLEMENTED** | Fully reproducible                    | Requires Docker                | ✅ Production           |
| 5. Custom Conda Package             | 🔮 Future          | Clean solution                        | High effort                    | Long-term maintenance   |

### Implementation Status (2025-01-27)

✅ **Completed**: Solution 1 (Hybrid Binary/Source)

- Script: `src/installDependencies.R`
- Features:
  - Non-interactive mode (no prompts)
  - Auto-installs Rtools with PATH configuration
  - Binary installation for dependencies (avoids compilation issues)
  - Source compilation for prioritizr 8.0.4 only
  - Full error handling and verification
- Status: **Ready for use**

✅ **Completed**: Solution 4 (Docker)

- Location: `Docker/Dockerfile`
- Status: Already working

**Current Recommendation**:

- **Development**: Use `Rscript installDependencies.R` (Solution 1)
- **Production**: Use Docker container (Solution 4)
- **Future**: Consider Solution 5 if project scales to multiple users/teams
