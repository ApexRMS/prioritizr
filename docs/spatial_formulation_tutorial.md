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

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot7.png">

<div class=indentation>
a. From the list of packages, select <b>prioritizr</b>. 
<br><br>
b. Three template library options will be available: Spatial Formulation Example, Tabular Formulation Example, and Climate Refugia Prioritization (Muskoka, Ontario). Select the <b>Spatial Formulation Example</b> template library.
<br><br>
c.  If desired, you may edit the <i>File name</i>, and change the <i>Folder</i> by clicking on the <b>Browse</b> button. 
<br><br>
d. When done, click <b>OK</b>.
</div>

<img align="center" style="padding: 13px" width="600" src="assets/images/screenshot8.png">

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

Now, you will review the inputs for the **Initial problem** scenario, which sets up the initial problem formulation out of which the other scenarios are built. In SyncroSim, each scenario contains the model inputs and outputs associated with a model run. 

9\.	In the *Explorer* window, select the pre-configured scenario **Initial problem** and double-click it to open its properties. You may also right-click on the scenario name and select **Open** from the context menu.

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot14.png">

10\.	Navigate to the **Pipeline** datasheet. Pipeline stages call on a transformer (*i.e.*, script) which takes the inputs from SyncroSim, runs a model, and returns the results to SyncroSim. Under the *Stage* column, note that a single pipeline stage is set, called *Base Prioritization*.

<img align="center" style="padding: 13px" width="800" src="assets/images/screenshot14-2.png">

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
    <br><br>
  <img align="center" style="padding: 13px" width="500" src="assets/images/screenshot16-2.png">
    <br><br>
    ii. <i>Features</i> – a multi-layer raster file of the conservation feature data (i.e., bird species). Layers describe the spatial distribution of each bird species, where cell values denote the relative abundance of individuals.
    <br><br>
  <img align="center" style="padding: 13px" width="800" src="assets/images/screenshot16-3.png">
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
  b. Open the <b>Target</b> datasheet, and review the following inputs:
  <br>
  <div class=indentation>
    i. <i>Function</i> – is set to <i>Relative</i> so that the target may be defined as a proportion (between 0 and 1) of the desired level of feature representation in the study area.
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

1\. In the *Explorer* window, expand the **Initial Problem > Results** node to reveal the **Inital Problem** results scenario.

2\. Collapse the scenario node by clicking on the downward facing arrow beside the scenario name.

3\. Navigate to the **Maps** tab, and double click on the pre-configured **Solution** map.

<img align="center" style="padding: 13px" width="600" src="assets/images/screenshot21-2.png">

The *Solution* map shows which planning units have been selected for prioritization given the input data and parameters. Although this solution helps meet the representation targets, it does not account for existing protected areas inside the study area.

4\. Close the results panels.

<br>

Now, you will review the additional scenarios and explore how they differ from the *Initial problem*.

5\. In the *Explorer* window, expand the **Add locked in constraints > Dependencies** node to reveal the **Initial problem** scenario dependency.

<img align="center" style="padding: 13px" width="300" src="assets/images/screenshot22.png">

6\.	Select the pre-configured scenario **Add locked in constraints** and double-click it to open its properties. You may also right-click on the scenario name and select **Open** from the context menu.

7\. Navigate to the **Prioritizr** tab, expand the **Base Prioritization > Data** node, and open the **Input Format** datasheet. Notice that this information cannot be edited (<i>i.e.</i>, greyed out) and the *"Inherit values from '[9] Initial Problem'"* checkbox in the bottom left corner is marked. This indicates that values within this datasheet are derived from the **Initial Problem** result scenario acting as a dependency.

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot22-2.png">

8\.  Navigate to the **Prioritizr** tab, expand the **Parameters > Advanced > Constraints** nodes, and open the **Locked In** datasheet to review the following inputs:

<div class=indentation>
  i. <i>Add constraint</i> – set to <i>Yes</i>, ensuring that specific planning units area selected in the solution.
  <br><br>
  ii. <i>Data</i> – contains the spatial data (<i>i.e.</i>, raster) specifying locations of areas to be locked in (<i>e.g.</i>, protected areas).
  </div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot23.png">

9\. In the *Explorer* window, right-click on the **Add locked in constraints** scenario, and select **Add to Results** from the context menu. 

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot23-2.png">

10\. Navigate to the **Maps** tab, and double click on the pre-configured **Solution** map. Notice that the **Add locked in constrains** results were added. This solution now accounts for existing protected areas inside the study area.

<img align="center" style="padding: 13px" width="900" src="assets/images/screenshot23-3.png">

<br>

By running the **Add locked in constrains** scenario, we generate an improved solution. However, there are some places in the study area that are not available for protected area establishment (*e.g.*, due to land tenure). Consequently, the solution might not be practical for implementation because it might select some places that are not available for protection. 

<br>

The **Add locked out constraints** scenario addresses this issue by importing spatial data representing which planning units are *not* available for protection, and adding constraints to the problem to ensure they are not selected by the solution.

<br>

11\.	In the *Explorer* window, expand the **Add locked out constraints > Dependencies** node to reveal the **Add locked in constraints** scenario dependency.

<img align="center" style="padding: 13px" width="300" src="assets/images/screenshot24.png">

<br>

12\.  Select the pre-configured scenario **Add locked out constraints** and double-click it to open its properties. You may also right-click on the scenario name and select **Open** from the context menu.

13\.  Navigate to the **Prioritizr** tab, expand the **Base Prioritization > Data** node, and open the **Input Format** datasheet. Notice that this information cannot be edited (i.e., greyed out) and the *“Inherit values from ‘[10] Add locked in constraints’”* checkbox in the bottom left corner is marked. This indicates that values within this datasheet are derived from the **Add locked in constraints** result scenario acting as a dependency.

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot24-2.png">

14\.  Navigate to the **Prioritizr** tab, expand the **Parameters > Advanced > Constraints** node, and open the **Locked Out** datasheet to review the following inputs:

<div class=indentation>
  i. <i>Add constraint</i> - must be set to <i>Yes</i> in order to add constraints to the conservation planning problem to ensure specific planning units area selected (or allocated to a specific zone) in the solution.
  <br><br>
  ii. <i>Data</i> - contains the spatial data (<i>i.e.</i>, raster) specifying locations of areas to be locked out (<i>e.g.</i>, areas not available for protection).
  </div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot25.png">

15\.  In the **Explorer** window, right-click on the **Add locked out constraints** scenario, and select **Add to Results** from the context menu.

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot25-2.png">

16\.  Navigate to the **Maps** tab, and double click on the pre-configured **Solution** map. Notice that the **Add locked out constraints** results were added. This solution now accounts for existing areas that are *not* available for protection inside the study area.

<img align="center" style="padding: 13px" width="900" src="assets/images/screenshot25-3.png">

<br>

By running the **Add locked out constraints** scenario, we generate an even better solution. However, the planning units selected from the solution are fairly fragmented. This can cause issues because fragmentation increases management costs and reduces conservation benefits through edge effects.

<br>

The **Add boundary penalties** scenario addresses this final issue by adding penalties that punish overly fragmented solutions. 

<br>

17\.	In the *Explorer* window, expand the **Add boundary penalties > Dependencies** node to reveal the **Add locked out constraints** scenario dependency.

<img align="center" style="padding: 13px" width="300" src="assets/images/screenshot26.png">

<br>

18\.  Select the pre-configured scenario **Add boundary penalties** and double-click it to open its properties. You may also right-click on the scenario name and select **Open** from the context menu. 

19\.  Navigate to the **Prioritizr** tab, expand the **Base Prioritization > Data** node, and open the **Input Format** datasheet. Notice that this information cannot be edited (i.e., greyed out) and the *“Inherit values from ‘[11] Add locked in constraints’”* checkbox in the bottom left corner is marked. This indicates that values within this datasheet are derived from the **Add locked out constraints** result scenario acting as a dependency.

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot26-2.png">

20\.  Navigate to the **Prioritizr** tab, expand the **Parameters > Advanced > Penalties** node, and open the **Boundary** datasheet to review the following inputs:

<div class=indentation>
  i. <i>Add penalty</i> - must be set to <i>Yes</i> in order to add boundary penalties to the conservation problem to favour solutions that spatially clump planning units together based on the overall boundary length (<i>i.e.</i>, total perimeter).
  <br><br>
  ii. <i>Penalty</i> - a value used to scale the importance of selecting planning units that are spatially clumped together compared to the main problem objective. Higher penalty values prefer solutions with a higher degree of spatial clumping, whereas smaller penalty values prefer solutions that are more spread out. In this example, the penalty is set to <i>0.003</i>.
  <br><br>
  iii. <i>Edge factor</i> - a value used to specify the proportion to scale planning unit edges (borders) that do not have any neighboring planning units. In this example, the edge factor is set to <i>0.5</i>.
  </div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot27.png">

21\. In the **Explorer** window, right-click on the **Add boundary penalties** scenario, and select **Add to Results** from the context menu. 

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot27-2.png">

22\.  Navigate to the **Maps** tab, and double click on the pre-configured **Solution** map. Notice that the **Add boundary penalties** results were added. This solution now accounts for highly fragmented areas inside the study area.

<img align="center" style="padding: 13px" width="900" src="assets/images/screenshot27-3.png">

<br>

<!-- Update numbers  and add a bit more of explanation/commentry !-->
23\. Navigate to the **Charts** tab, and double-click on the first pre-configured chart: **Number of planning units**. Note that the number of planning units increases until we add the boundary penalties. 

<img align="center" style="padding: 13px" width="300" src="assets/images/screenshot28.png">

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot29.png">

24\. Next, double-click on the second pre-configured chart: **Solution cost**. Here, the solution cost is equal across scenarios since the budget was set at $8,748.4910.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot30.png">

25\. Now, double-click on the third pre-configured chart: **Target coverage**. Here, the target coverage is equal across scenarios.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot31.png">

26\. Navigate to the **Maps** tab, and double click on the pre-configured **Solution** map.

<img align="center" style="padding: 13px" width="300" src="assets/images/screenshot32.png">

<br>

This tutorial demonstrates how *prioritizr* can be used to build and customize conservation problems, and the solve them to generate solutions. Although we explored a few different scenarios for modifying a conservation problem, this package can specify objectives, constraints, penalties, and decision variables in order to build and customize conservation planning problems to suit your planning scenario.

To create and solve a tabular conservation problem, see the next tutorial <a href="/tabular_formulation">Tabular Formulation Example with prioritizr SyncroSim</a>. 
