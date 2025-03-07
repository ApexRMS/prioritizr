---
layout: default
title: Tutorials
permalink: /multicost_prioritization
---

<style>
  .indentation {
    margin-left: 1rem;
    margin-top: 1rem; 
    margin-bottom: 1rem; 
  }
</style>

## **Multi-cost Prioritization with prioritizr SyncroSim**

This tutorial provides an overview of working with **prioritizr** in SyncroSim Studio to demonstrate how to integrate multiple cost-layers into a lake conservation problem in Ontario, Canada. It covers the following steps:

1. <a href="#step-1">Creating and configuring the prioritizr **Multi-cost prioritiation for FMZ10 lakes (Ontario, Canada)** SyncroSim library</a>
2. <a href="#step-2">Visualizing and comparing results across scenarios</a>

<br>

<p id="step-1"> <h3><b>Step 1. Creating and configuring the Multi-cost Lake Prioritiation (Ontario, Canada) library</b></h3> </p>

In SyncroSim, a library is a file with extension *.ssim* that stores all the model's inputs and outputs in a format specific to a given package. To recreate the **Multi-cost Lake Prioritiation (Ontario, Canada)** library:

1\. Open SyncroSim Studio.

2\. In this example, you will review a pre-configured library. To do so, select **File > New > From Online Template...**

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot7.png">

<div class=indentation>
a. From the list of packages, select <b>prioritizr</b>. 

<br><br>

b. Four template library options will be available: Spatial Formulation Example, Tabular Formulation Example, Climate Refugia Prioritization (Muskoka, Ontario), and Multi-cost Lake Prioritization (Onatrio, Canada). Select the <b>Multi-cost Lake Prioritization (Onatrio, Canada)</b> template library.

<br><br>

c. If desired, you may edit the <i>File name</i>, and change the <i>Folder</i> by clicking on the <b>Browse</b> button. 

<br><br>

d. When done, click <b>OK</b>.
</div>

<img align="center" style="padding: 13px" width="800" src="assets/images/screenshot79.png">

<br>

A new library has been created based on the selected template and SyncroSim will have automatically opened and displayed it in the *Explorer* window.

3\.	Double-click on the library name, **Multi-cost Lake Prioritization (Onatrio, Canada)**, to open the library properties window. You may also right-click on the library name and select **Open** from the context menu.

<img align="center" style="padding: 13px" width="600" src="assets/images/screenshot80.png">

<br>

4\.	The **Summary** datasheet contains the metadata for the library.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot81.png">

<br>

5\.	Next, navigate to the **Systems** tab, **Options** node, **General** datasheet, and mark the checkbox for *Use conda*.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot82.png">

<br>

6\.	Close the library properties window.

<br>

Next, you will review the target feature data for the conservation prioritization problem.

7\. From the *Explorer* window, right-click on **Definitions** and select **Open** from the context menu.

8\. Under the **Prioritizr** tab, select the **Features** datasheet, describing the variables that will be taken into account in the prioritization process. Here, our feature data corresponds to different conservation interests including mean lake depth (*i.e.*, MeanDepth), and lake surface area (*i.e.*, SurfaceArea).

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot83.png">

<br>

9\. Open the **Cost variables** datasheet to review the binary variables that represent whether a lake (*i.e.*, planning unit) has a protection cost(1) or not (0).

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot84.png">

<br>

Now you will review the inputs for the **No cost** scenario. In SyncroSim, scenarios contain the model inputs and outputs associated with a model run.

9\.	In the *Explorer* window, select the pre-configured scenario **No cost** and double-click it to open its properties. You may also right-click on the scenario name and select **Open** from the context menu.

This scenario provides a baseline for prioritizing 30% of lakes in Ontario, Canada based on the mean depth and surface area, and using a minimum shortfall objective. Note that, in this scenario, *no* cost layers are considered.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot85.png">

<br>

10\.	Navigate to the **Pipeline** datasheet. Pipeline stages call on a transformer (*i.e.*, script) which takes the inputs from SyncroSim, runs a model, and returns the results to SyncroSim. Under the *Stage* column, note that a single pipeline stage is set called *Base Prioritization*.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot86.png">

<br>

11\. Navigate to the **Prioritizr** tab, and expand the **Base Prioritization > Data** nodes. 

<div class=indentation>
  a. Open the <b>Input Format</b> node and notice that <i>Data Type</i> is set to <i>Tabular</i> in order to generate a tabular prioritization.
</div>

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot87.png">

<div class=indentation>
  b. Open the <b>Spatial Inputs</b> datasheet, and review the following input:
  <br>
  <div class=indentation>
    i. <i>Planning Units</i> - a raster of the different lakes of interest in Ontario, Canada.
  </div>
</div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot88.png">

<div class=indentation>
  c. Open the <b>Tabular Inputs</b> datasheet, and review the following inputs:
  <br>
  <div class=indentation>
    i. <i>Planning Units</i> - a data table of the different lakes of interest in Ontario, Canada.
    <br><br>
      <img align="center" style="padding: 13px" width="200" src="assets/images/screenshot89.png">
    <br><br>
    ii. <i>Features</i> - a data table of the conservation feature data including mean depth, and surface area.
    <br><br>
      <img align="center" style="padding: 13px" width="200" src="assets/images/screenshot90.png">
    <br><br>
    iii. <i>Planning units vs. Features</i> - a data table of mean depth and surface area features associated with each lake.
    <br><br>
      <img align="center" style="padding: 13px" width="300" src="assets/images/screenshot91.png">
    <br><br>
    iv. <i>Cost column</i> - a column in which the cost is input. <!--not sure if this makes sense - is this simply an empty column in which the cost is input in the results?-->
  </div>
</div>

<img align="center" style="padding: 13px" width="600" src="assets/images/screenshot92.png">

<br>

12\. Expand the **Parameters** node. 

<div class=indentation>
  a. Open the <b>Objective</b> datasheet, and review the following inputs:
  <br>
  <div class=indentation>
    i. <i>Function</i> - this input sets the objective of the conservation planning problem. In this example, it is set to <i>Minimum shortfall</i> which aims to minimize the fraction of each target that remains unmet for as many features as possible while staying within a fixed budget.
    <br><br>
    ii. <i>Budget</i> - this number represents the maximum allowed cost of the prioritization. Specifically, this value is set to <i>$226</i>.
  </div>
</div>

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot93.png">

<div class=indentation>
  b. Open the <b>Target</b> datasheet, and review the following inputs:
  <br>
  <div class=indentation>
    i. <i>Function</i> - since this input is set to <i>Relative</i>, so that the target may be defines as a proportion (between 0 and 1) of the desired level of feature representation (<i>i.e.</i>, mean depth, and surface area) in Ontario, Canada.
    <br><br>
    ii. <i>Amount</i> - specifies the desired level of feature representation in the study area. In this example, it is set to 1.0, so that each feature would have 100% of its distribution covered by the prioritization.
  </div>
</div>

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot94.png">

<div class=indentation>
  c. Open the <b>Decision Types</b> datasheet, and review the following input:
  <br>
  <div class=indentation>
    i. <i>Function</i> - the decision type is set to <i>Binary</i>, so that planning units are either selected or not for prioritization (<i>i.e.</i>, to prioritize or not prioritize a lake). 
  </div>
</div>

<img align="center" style="padding: 13px" width="450" src="assets/images/screenshot95.png">

<div class=indentation>
  d. Open the <b>Solver</b> datasheet, and review the following inputs:
  <br>
  <div class=indentation>
    i. <i>Function</i> - is set to <i>Default</i>. This specifies that the best solver currently available in your computer should be used to solve the conservation planning problem. 
    <br><br>
    ii. <i>Gap</i> - represents the gap to optimality and is set to a value of <i>0</i>. This gap is relative and expresses the acceptable deviance from the optimal objective. In this example, a value of 0 will result in the solver stopping when it has found a solution within 0% of optimality. <!-- does this make sense?-->
  </div>
</div>

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot96.png">

<br>

13\. Expand the **Output Options** node and open the **Performance** datasheet to review the following inputs set to *Yes*:

  <div class=indentation>
    i. <i>Number Summary</i> - calculates the number of lakes selected within a solution to the conservation planning problem.
    <br><br>
    ii. <i>Feature representation summary</i> - calculates how well features (<i>i.e.</i>, lake depth, and surface area) are represented by a solution to the conservation planning problem.
  </div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot97.png">

<br>

<p id="step-2"> <h3><b>Step 2. Visualizing and comparing results across scenarios</b></h3> </p>

The **Multi-cost Lake Prioritiation (Ontario, Canada)** template library already contains the results for each scenario. Before exploring additional scenarios, you will view the main results for the **No costs** scenario.

By running the **No costs** scenario, we generate a baseline solution that prioritizes 30% of lakes in Ontario, Canada based on mean depth and surface area, and using a minimum shortfall objective, without cost layers.

2\. Collapse the scenario node by clicking on the downward facing arrow beside the scenario name.

3\. Navigate to the **Maps** tab, and double click on the pre-configured **Solution** map.

<img align="center" style="padding: 13px" width="600" src="assets/images/screenshot98.png">

The *Solution* map shows which planning units have been selected for prioritization given the input data and parameters. Although this solution helps meet the representation targets, it does not account for any additional cost layers (*i.e.*, equal or hierarchical).

4\. Close the chart results panel.

5\. Navigate to the **Charts** tab, and double click on the pre-configured **Feature representation** chart.

<img align="center" style="padding: 13px" width="600" src="assets/images/screenshot99.png">

The *Feature representation* chart shows the proportion of mean depth, and surface area represented in the **No costs** scenario solution. For instance, 51% of all the lakes' mean depth, and 83% of all the lakes' surface area is is represented in the solution.

6\. Close the chart results panel.

<br>

Now, you will review the additional scenarios and explore how they differ from the **No costs** solution.

The **No costs** scenario acts as a dependency for the **All costs, Equal** scenario which integrates five cost layers into the prioritization process while treating all cost layers with equal importance. 

7\. In the *Explorer* window, expand the **All costs, Equal > Dependencies** node to reveal the **No costs** scenario dependency.

<img align="center" style="padding: 13px" width="300" src="assets/images/screenshot100.png">

<br>

8\.  Select the pre-configured scenario **All costs, Equal** and double-click it to open its properties. You may also right-click on the scenario name and select **Open** from the context menu.

9\.  Navigate to the **Prioritizr** tab, expand the **Base Prioritization > Data** node, and open the **Input Format** datasheet. Notice that this information cannot be edited (i.e., greyed out) and the *“Inherit values from ‘[2] No costs’”* checkbox in the bottom left corner is marked. This indicates that values within this datasheet are derived from the **No costs** result scenario acting as a dependency.

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot101.png">

<br>

10\.  Expand the **Multi-Cost Prioritization** node, and open the **Data** datasheet to review the following input:

<div class=indentation>
  i. <i>Cost-layers</i> - 
</div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot102.png">

11\.  Next, open the **Parameters** datasheet to review the following inputs:

<div class=indentation>
  i. <i>Prioritization method</i> - 
  <br><br>
  ii. <i>Initial optimality gap</i> - 
  <br><br>
  iii. <i>Cost optimality gap</i> - 
  <br><br>
  iv. <i>Budget increments</i> -
  <br><br>
  v. <i>Budget padding</i> - 
  <br><br>
</div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot103.png">

<br>

Similarly, the **No costs** scenario also acts as a dependency for the **All costs, Hierarchical** scenario which integrates five cost layers into the prioritization process based on the following hierarchy of cost-reduction importance, from most to least important: protected area, lakeshore capacity, sanctuary, Brook Trout regulation, and Lake Trout regulation.

12\. In the *Explorer* window, expand the **All costs, Hierarchical > Dependencies** node to reveal the **No costs** scenario dependency.

<img align="center" style="padding: 13px" width="300" src="assets/images/screenshot104.png">

<br><br>

13\.  Select the pre-configured scenario **All costs, Equal** and double-click it to open its properties. You may also right-click on the scenario name and select **Open** from the context menu.

14\.  Navigate to the **Prioritizr** tab, expand the **Base Prioritization > Data** node, and open the **Input Format** datasheet. Notice that this information cannot be edited (i.e., greyed out) and the *“Inherit values from ‘[2] No costs’”* checkbox in the bottom left corner is marked. This indicates that values within this datasheet are derived from the **No costs** result scenario acting as a dependency.

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot105.png">

<br>

15\.  Expand the **Multi-Cost Prioritization** node, and open the **Data** datasheet to review the following input:

<div class=indentation>
  i. <i>Cost-layers</i> - 
</div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot102.png">

16\.  Next, open the **Parameters** datasheet to review the following inputs:

<div class=indentation>
  i. <i>Prioritization method</i> - 
  <br><br>
  ii. <i>Initial optimality gap</i> - 
  <br><br>
  iii. <i>Cost optimality gap</i> - 
  <br><br>
  iv. <i>Budget increments</i> -
  <br><br>
  v. <i>Bugdte padding</i> - 

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot103.png">

<br>





17\.  In the **Explorer** window, right-click on the **All costs, Equal** scenario, and select **Add to Results** from the context menu.

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot25-2.png">