---
layout: default
title: Getting started
permalink: /getting_started
---

# Getting started with **prioritizr** 

To get started working with **prioritizr** SyncroSim for building and solving conservation planning problems, begin by:

1. <a href="#installing-syncrosim">Installing SyncroSim</a>
2. <a href="#installing-R-package-dependencies">Installing R package dependencies</a>
3. <a href="#installing-the-prioritizr-syncrosim-package">Installing the **prioritizr** SyncroSim package</a>

<br>

## **Installing SyncroSim**

Running **prioritizr** requires that **SyncroSim** be installed on your computer. Download the latest version of SyncroSim [here](https://syncrosim.com/download/){:target="_blank"} and follow the installation prompts. For more on SyncroSim, please refer to the SyncroSim Docs for an [overview](https://docs.syncrosim.com/getting_started/overview.html){:target="_blank"} and a [quickstart tutorial](https://docs.syncrosim.com/getting_started/quickstart.html){:target="_blank"}.

<br>

## **Installing R package dependencies**

Running **prioritizr** requires the following R packages be installed in your computer:
- prioritizr [8.0.4](https://cran.r-project.org/src/contrib/Archive/prioritizr/prioritizr_8.0.4.tar.gz)
- symphony [0.1.1](https://cran.r-project.org/src/contrib/symphony_0.1.1.tar.gz)
- Rsymphony [0.1-33](https://cran.r-project.org/src/contrib/Rsymphony_0.1-33.tar.gz)
- rsyncrosim [2.0.1](https://cran.r-project.org/src/contrib/rsyncrosim_2.0.1.tar.gz)
- stringr [1.4.1](https://cran.r-project.org/src/contrib/Archive/stringr/stringr_1.4.1.tar.gz)
- terra [1.7-29](https://cran.r-project.org/src/contrib/Archive/terra/terra_1.7-29.tar.gz)
- tidyr [1.2.1](https://cran.r-project.org/src/contrib/Archive/tidyr/tidyr_1.2.1.tar.gz)
- dplyr [1.1.1](https://cran.r-project.org/src/contrib/Archive/dplyr/dplyr_1.1.1.tar.gz) 

<br>

## **Installing the prioritizr SyncroSim package**

1\. Open **SyncroSim Studio**.

2\. Navigate to **File > Local Packages**.

<img align="center" style="padding: 13px" width="250" src="assets/images/screenshot1.png">

3\. The *Local Packages* window will open, listing all the SyncroSim packages installed on your computer. If you do not have any packages installed yet, this window will be empty. To install a new package from the Package Server, click on **Install from Server...**. 

<img align="center" style="padding: 13px" width="600" src="assets/images/screenshot2.png">

4\. A new window will open listing the packages available to install from the Package Server. To install **prioritizr**, click the checkbox beside the package name and select **OK**. 

<img align="center" style="padding: 13px" width="600" src="assets/images/screenshot3.png">

5\. The **prioritizr** SyncroSim package uses Conda to manage the package dependencies. Upon installing the package, you will be prompted to install Conda (if it is not already installed on your computer). Then, you will be prompted to create or update the Conda environment for **prioritzr**. Click **Yes**.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot4.png">

6\. Return to the *Local Packages* window. **prioritizr** will now be listed along with the other installed packages and the Conda checkbox will be marked.

<img align="center" style="padding: 13px" width="600" src="assets/images/screenshot5.png">

<br>

## **Next steps**

Once the requirements have been installed, the following tutorials will cover the basics of **prioritizr** SyncroSim for building and solving conservation planning problems: 
1. <a href="./tutorials/spatial_formulation">Spatial conservation prioritization with prioritizr SyncroSim<a>
2. <a href="./tutorials/tabular_formulation">Tabular conservation prioritization with prioritizr SyncroSim</a>
3. <a href="./tutorials/climate_refugia_prioritization">Climate refugia prioritization with prioritizr SyncroSim</a>
4. <a href="./tutorials/multicost_prioritization">Multi-cost prioritization with prioritizr SyncroSim</a>

<img align="center" style="padding: 13px" width="900" src="assets/images/screenshot23-3.png">

<br><br><br>
