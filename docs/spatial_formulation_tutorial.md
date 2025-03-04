---
layout: default
title: Tutorials
permalink: /spatial_formulation
---

<!-- Update template library so that only scenario 1 comes added to scenario results (i.e., selected, bold) !-->

<style>
  .indentation {
    margin-left: 1rem;
    margin-top: 1rem; 
    margin-bottom: 1rem; 
  }
</style>

## **Spatial conservation prioritization with prioritizr SyncroSim**

This tutorial provides an overview of working with **prioritizr** in SyncroSim Studio to create and solve a spatial conservation problem. It covers the following steps:

1. <a href="#step-1">Creating a prioritizr SyncroSim library</a>
2. <a href="#step-2">Visualizing and comparing results across scenarios</a>

<br>

<p id="step-1"> <h3><b>Step 1. Creating a prioritizr SyncroSim library</b></h3> </p>

In SyncroSim, a library is a file with extension *.ssim* that stores all the model's inputs and outputs in a format specific to a given package. To create a new **prioritizr** library:

1\. Open SyncroSim Studio.

2\. In this example, you will review a pre-configured library. To do so, select **File > New > From Online Template...**

<!-- Add screenshot of step 2 !-->

<div class=indentation>
a. From the list of packages, select <b>prioritizr</b>. 
<br><br>
b. Three template library options will be available: Spatial Formulation Example, Tabular Formulation Example, and Climate Refugia Prioritization (Muskoka, Ontario). Select the <b>Spatial Formulation Example</b> template library.
<br><br>
c.  If desired, you may edit the <i>File name</i>, and change the <i>Folder</i> by clicking on the <b>Browse</b> button. 
<br><br>
d. When done, click <b>OK</b>.
</div>

<!--Insert image of template library window-->
<!--img align="center" style="padding: 13px" width="500" src=".assets/images/screenshot8.png"-->

<br>

A new library has been created based on the selected template and SyncroSim will have automatically opened and displayed it in the *Explorer* window. This library reproduces the example available in the prioritizr R package [documentation](https://prioritizr.net/index.html#usage){:target="_blank"}. 

3\.	Double-click on the library name, **Spatial Formulation Example**, to open the library properties window. You may also right-click on the library name and select **Open** from the context menu.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot9.png">

4\.	The *Summary* datasheet contains the metadata for the library.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot10.png">

5\.	Next, navigate to the **System** tab, **Options** node, **General** datasheet, and mark the checkbox for <i>Use conda</i>.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot12.png">

6\.	Close the library properties window.

<br>

Next, you will review the target feature data for the conservation prioritization problem. 

7\. From the *Explorer* window, right-click on **Definitions** and select **Open** from the context menu. 

8\. Under the **Prioritizr** tab, select the **Features** datasheet, describing the variables that will be taken into account in the prioritization process. In this library, note that the feature data corresponds to different bird species. 

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot13.png">

<br>

Now, you will review the inputs for the *Initial problem* scenario, which sets up the initial problem formulation out of which the other scenarios are built. In SyncroSim, each scenario contains the model inputs and outputs associated with a model run. 

9\.	In the *Explorer* window, select the pre-configured scenario **Initial problem** and double-click it to open its properties. You may also right-click on the scenario name and select **Open** from the context menu.

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot14.png">

10\.	Navigate to the **Pipeline** datasheet. Pipeline stages call on a transformer (*i.e.*, script) which takes the inputs from SyncroSim, runs a model, and returns the results to SyncroSim. Under the *Stage* column, note that a single pipeline stage is set, called *Base Prioritization*.

<!-- Add screenshot !-->

11\. Navigate to the **Prioritizr** tab, and expand the **Base Prioritization > Data** nodes. 

<div class=indentation>
  a. Open the <b>Input Format</b> datasheet and note that <i>Data Type</i> is set to <i>Spatial</i> in order to generate a spatial prioritization.
</div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot15.png">

<div class=indentation>
  b. Open the <b>Spatial Inputs</b> datasheet, and review the following inputs:

  <img align="center" style="padding: 13px" width="500" src="assets/images/screenshot16.png">

  <div class=indentation>
    i. <i>Planning Units</i> – a raster file of Washington (USA) in which each cell represents a different planning unit, and cell values denote land acquisition costs.
    <!-- Add screenshot of raster, which can be taken from the prioritizr R documentation !-->
    <br><br>
    ii. <i>Features</i> – a multi-layer raster file of the conservation feature data (i.e., bird species). Layers describe the spatial distribution of each bird species, where cell values denote the relative abundance of individuals.
    <!-- Add screenshot of raster, which can be taken from the prioritizr R documentation !-->
  </div>
</div>

12\. Expand the **Parameters** node. 

<div class=indentation>
  a. Open the <b>Objective</b> datasheet, and review the following inputs:
  <br>
  <div class=indentation>
    i. <i>Function</i> – this input sets the prioritization objective for the conservation planning problem. In this example, it is set to <i>Minimum shortfall</i>, which aims to minimize the fraction of each target that remains unmet for as many features as possible while staying within a fixed budget.
    <br><br>
    ii. <i>Budget</i> – this number represents the maximum allowed cost of the prioritization. Specifically, this value is set to <i>$8,748.4910</i>, which represents 5% of the total land value in the study area.
  </div>
</div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot17.png">

<div class=indentation>
  b. Open on the <b>Target</b> datasheet, and review the following inputs:
  <br>
  <div class=indentation>
    i. <i>Function</i> – is set to <i>Relative</i>, so that the target may be defined as a proportion (between 0 and 1) of the desired level of feature representation in the study area.
    <br><br>
    ii. <i>Amount</i> – specifies the desired level of feature representation in the study area. In this example, it is set to <i>0.2</i>, so that each feature would have 20% of its distribution covered by the prioritization.
  </div>
</div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot18.png">

<div class=indentation>
  c. Open the <b>Decision Types</b> datasheet, and review the following input:
  <br>
  <div class=indentation>
    i. <i>Function</i> – the decision type is set to <i>Binary</i>, so that planning units are either selected or not for prioritization. 
  </div>
</div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot19.png">

<div class=indentation>
  d. Open the <b>Solver</b> datasheet, and review the following inputs:
  <br>
  <div class=indentation>
    i. <i>Function</i> – is set to <i>Default</i>. This specifies that the best solver currently available in your computer should be used to solve the conservation planning problem. 
    <br><br>
    ii. <i>Gap</i> – represents the gap to optimality, and is set to a default value of <i>0.1</i>. This gap is relative and expresses the acceptable deviance from the optimal objective. In this example, a value of 0.1 will result in the solver stopping when it has found a solution within 10% of optimality. 
  </div>
</div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot20.png">

13\. Expand the **Output Options** node and open the **Performance** datasheet to review the following inputs set to *Yes*:

<div class=indentation>
  <div class=indentation>
    i. <i>Number summary</i> – calculates the number of planning units selected within a solution to the conservation planning problem.
    <br><br>
    ii. <i>Cost Summary</i> – calculates the total cost of the solution to the conservation planning problem.
    <br><br>
    iii. <i>Target Coverage Summary</i> – calculates how well the feature representation targets are met by the solution to the conservation planning problem. 
  </div>
</div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot21.png">

<br>

<p id="step-2"> <h3><b>Step 2. Visualizing and comparing results across scenarios</b></h3> </p>

The *Spatial Formulation Example* template library already contains the results for each scenario. Before exploring additional scenarios, you will view the main results for the **Initial problem** scenario. 

<!-- Turn this into a actionable item and add screenshot of the expanded results folder !-->
1\. In SyncroSim, the results for a scenario are organized into a *Results* folder, nested within its parent scenario.

2\. Collapse the scenario node by clicking on the downward facing arrow beside the scenario name.

3\. Navigate to the **Maps** tab, and double click on the pre-configured **Solution** map.

<!-- Add screenshot !-->

The *Solution* map shows which planning units have been selected for prioritization given the input data and parameters. Although this solution helps meet the representation targets, it does not account for existing protected areas inside the study area.

4\. Close the results panels.

<br>

Now, you will review the additional scenarios and explore how they differ from the *Initial problem*.

<!-- Turn this item into an actionable step !-->
5\. In the *Explorer* window, ... The **Add locked in constraints** scenario is dependent on the **Initial problem** scenario. We can see this in the Explorer window by expanding the **Add locked in constrains > Dependencies** node.*

<img align="center" style="padding: 13px" width="300" src="assets/images/screenshot22.png">

6\.	Select the pre-configured scenario **Add locked in constraints** and double-click it to open its properties. You may also right-click on the scenario name and select **Open** from the context menu.

<!-- First, add an instruction to view the Input Format datasheet to show the information is greyed out and the "Inherit values..." checkbox is marked, explaining what it means (with screenshot to illustrate) !-->
7\. 

8\. Navigate to the **Prioritizr** tab, expand the **Parameters > Advanced > Constraints** nodes, and open the **Locked In** datasheet to review the following inputs:

<div class=indentation>
  i. <i>Add constraint</i> – set to <i>Yes</i>, ensuring that specific planning units area selected in the solution.
  <br><br>
  ii. <i>Data</i> – contains the spatial data (<i>i.e.</i>, raster) specifying locations of areas to be locked in (<i>e.g.</i>, protected areas).
  </div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot23.png">

9\. <!-- Add to results, with screenshot !-->

10\. <!-- View and comment on results, with screenshot !-->

<br>

<!-- Follow the same pattern as above to update the following sections, remembering to update item numbers !-->
By running the **Add locked in constrains** scenario, we generate an improved solution. However, there are some places in the study area that are not available for protected area establishment (*e.g.*, due to land tenure). Consequently, the solution might not be practical for implementation because it might select some places that are not available for protection. 

<br>

The **Add locked out constraints** scenario addresses this issue by importing spatial data representing which planning units are *not* available for protection, and adding constraints to the problem to ensure they are not selected by the solution.

<br>

16\.	In the *Explorer* window, select the pre-configured scenario **Add locked out constraints** and double-click it to open its properties. You may also right-click on the scenario name and select **Open** from the context menu.

> *Note: the **Add locked out constraints** scenario is dependent on the **Add locked in constraints** scenario. We can see this in the Explorer window by expanding the **Add locked out constrains > Dependencies** node.*

<img align="center" style="padding: 13px" width="300" src="assets/images/screenshot24.png">

<br>

17\. Navigate to the **Prioritizr** tab and expand the **Parameters > Advanced > Constraints** node. Open the **Locked Out** window to review the following inputs:

<div class=indentation>
  i. <i>Add constraint</i> - must be set to <i>Yes</i> in order to add constraints to the conservation planning problem to ensure specific planning units area selected (or allocated to a specific zone) in the solution.
  <br><br>
  ii. <i>Data</i> - contains the spatial data (<i>i.e.</i>, raster) specifying locations of areas to be locked out (<i>e.g.</i>, areas not available for protection).
  </div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot25.png">

<br>

By running the **Add locked out constraints** scenario, we generate an even better solution. However, the planning units selected from the solution are fairly fragmented. This can cause issues because fragmentation increases management costs and reduces conservation benefits through edge effects.

<br>

The **Add boundary penalties** scenario addresses this final issue by adding penalties that punish overly fragmented solutions. 

<br>

18\.	In the *Explorer* window, select the pre-configured scenario **Add boundary penalties** and double-click it to open its properties. You may also right-click on the scenario name and select **Open** from the context menu.

> *Note: the **Add boundary penalties** scenario is dependent on the **Add locked out constraints** scenario. We can see this in the Explorer window by expanding the **Add boundary penalties > Dependencies** node.*

<img align="center" style="padding: 13px" width="300" src="assets/images/screenshot26.png">

<br>

19\. Navigate to the **Prioritizr** tab and expand the **Parameters > Advanced > Penalties** node. Open the **Boundary** window to review the following inputs:

<div class=indentation>
  i. <i>Add penalty</i> - must be set to <i>Yes</i> in order to add boundary penalties to the conservation problem to favour solutions that spatially clump planning units together based on the overall boundary length (<i>i.e.</i>, total perimeter).
  <br><br>
  ii. <i>Penalty</i> - a value used to scale the importance of selecting planning units that are spatially clumped together compared to the main problem objective. Higher penalty values prefer solutions with a higher degree of spatial clumping, whereas smaller penalty values prefer solutions that are more spread out. In this example, the penalty is set to <i>0.003</i>.
  <br><br>
  iii. <i>Edge factor</i> - a value used to specify the proportion to scale planning unit edges (borders) that do not have any neighboring planning units. In this example, the edge factor is set to <i>0.5</i>.
  </div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot27.png">

<br>

<!-- Update numbers  and add a bit more of explanation/commentry !-->
1\. Navigate to the **Charts** tab, and double-click on the first pre-configured chart: **Number of planning units**. 

<img align="center" style="padding: 13px" width="300" src="assets/images/screenshot28.png">

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot29.png">

2\. Next, double-click on the second pre-configured chart: **Solution cost**.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot30.png">

3\. Now, double-click on the third pre-configured chart: **Target coverage**

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot31.png">

4\. Navigate to the **Maps** tab, and double click on the pre-configured **Solution** map.

<img align="center" style="padding: 13px" width="300" src="assets/images/screenshot32.png">

<br>

<!-- Add plug for next tutorial !-->