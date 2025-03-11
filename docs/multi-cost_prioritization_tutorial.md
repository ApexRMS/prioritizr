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

## **Multi-cost prioritization with prioritizr SyncroSim**

This tutorial provides an overview of working with **prioritizr** in SyncroSim Studio to demonstrate how to integrate multiple cost-layers into a lake conservation problem. It covers the following steps:

1. <a href="#step-1">Creating a prioritizr SyncroSim library</a>
2. <a href="#step-2">Visualizing and comparing results across scenarios</a>

<br>

<p id="step-1"> <h3><b>Step 1. Creating a prioritizr SyncroSim library</b></h3> </p>

In SyncroSim, a library is a file with extension *.ssim* that stores all the model's inputs and outputs in a format specific to a given package. To load the pre-configured library:

1\. Open **SyncroSim Studio**.

2\. Select **File > New > From Online Template...**.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot7.png">

<div class=indentation>
  a. From the list of packages, select <b>prioritizr</b>. 
  <!-- Add screenshots of this step !--> 
  <br><br>
  b. From the list of template libraries, select the <b>Multi-Cost Lake Prioritization (Ontario, Canada)</b> template library.
  <!-- Add screenshots of this step !--> 
  <br><br>
  c. If desired, you may edit the <i>File name</i>, and change the <i>Folder</i> by clicking on the <b>Browse</b> button.
  <br><br>
  d. When done, click <b>OK</b>.
</div>

<br>

A new library has been created based on the selected template, and SyncroSim will have automatically opened and displayed it in the *Explorer* window.

<img align="center" style="padding: 13px" width="800" src="assets/images/screenshot79.png">

3\.	Double-click on the library name, **Multi-Cost Lake Prioritization (Ontario, Canada)**, to open the library properties window. You may also right-click on the library name and select **Open** from the context menu.

<img align="center" style="padding: 13px" width="600" src="assets/images/screenshot80.png">

4\.	The **Summary** datasheet contains the metadata for the library.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot81.png">

5\.	Next, navigate to the **Systems** tab, **Options** node, **General** datasheet, and mark the checkbox for *Use conda*.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot82.png">

6\.	Close the library properties window.

<br>

Next, you will review the target feature data for the conservation prioritization problem.

7\. From the *Explorer* window, right-click on **Definitions** and select **Open** from the context menu.

8\. Under the **Prioritizr** tab, select the **Features** datasheet, which lists the variables that will be taken into account in the prioritization process. Here, the feature data corresponds to two lake property variables: *MeanDepth* and *SurfaceArea*.

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot83.png">

9\. Next, open the **Cost variables** datasheet, which lists the cost variables that will be taken into account in the prioritization process. Here, all are binary variables that represent whether a lake (*i.e.*, planning unit) has a protection cost (1) or not (0).

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot84.png">

<br>

Now you will review the inputs for the **No costs** scenario, which provides a baseline where *no* costs are considered in the prioritization. In SyncroSim, each scenario contains the model inputs and outputs associated with a model run.

10\.	In the *Explorer* window, select the pre-configured scenario **No costs** and double-click it to open its properties. You may also right-click on the scenario name and select **Open** from the context menu.

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot85.png">

11\.	Navigate to the **Pipeline** datasheet. Pipeline stages call on a transformer (*i.e.*, script) which takes the inputs from SyncroSim, runs a model, and returns the results to SyncroSim. Under the *Stage* column, note that a single pipeline stage is set, called *Base Prioritization*.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot86.png">

12\. Navigate to the **Prioritizr** tab, and expand the **Base Prioritization > Data** nodes. 

<div class=indentation>
  a. Open the <b>Input Format</b> datasheet and notice that <i>Data Type</i> is set to <i>Tabular</i> in order to generate a tabular formulation of the conservation problem.
</div>

<img align="center" style="padding: 13px" width="450" src="assets/images/screenshot87.png">

<div class=indentation>
  b. Open the <b>Spatial Inputs</b> datasheet, and review the following input:
  <br>
  <div class=indentation>
    i. <i>Planning Units</i> – a raster of the different lakes of interest in Ontario, Canada.
  </div>
</div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot88.png">

<div class=indentation>
  c. Open the <b>Tabular Inputs</b> datasheet, and review the following inputs:
  <br>

  <img align="center" style="padding: 13px" width="600" src="assets/images/screenshot88-2.png">

  <br>

  <div class=indentation>
    i. <i>Planning Units</i> – a data table of the different lakes of interest in Ontario, Canada. Each lake has an unique ID. A cost column, here called <i>PA_target</i>, is also provided and set to <i>1</i> for all lakes.
    <br>
      <img align="center" style="padding: 13px" width="250" src="assets/images/screenshot89.png">
    <br>
    ii. <i>Features</i> – a data table listing the feature variables. These are listed under the column <i>name</i>, with an associated ID.
    <br>
      <img align="center" style="padding: 13px" width="250" src="assets/images/screenshot90.png">
    <br>
    iii. <i>Planning units vs. Features</i> – a data table listing for each lake (under the <i>pu</i> column), the value associated with each feature variable (under the <i>species</i> column).
    <br>
      <img align="center" style="padding: 13px" width="300" src="assets/images/screenshot91.png">
    <br>
    iv. <i>Cost column</i> – corresponds to the column in the <i>Plannin Units</i> input representing the cost variable.
    <br>
    <img align="center" style="padding: 13px" width="600" src="assets/images/screenshot92.png">
  </div>
</div>

13\. Expand the **Parameters** node. 

<div class=indentation>
  a. Open the <b>Objective</b> datasheet, and review the following inputs:
  <br>
  <div class=indentation>
    i. <i>Function</i> – this input sets the objective of the conservation planning problem. In this example, it is set to <i>Minimum shortfall</i> which aims to minimize the fraction of each target that remains unmet for as many features as possible while staying within a fixed budget.
    <br><br>
    ii. <i>Budget</i> – this number represents the maximum allowed cost of the prioritization. Here, the budgets is used to ensure that 30% of lakes in the study area are represented in the solution, which corresponds to <i>226</i>.
  </div>
</div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot93.png">

<div class=indentation>
  b. Open the <b>Target</b> datasheet, and review the following inputs:
  <br>
  <div class=indentation>
    i. <i>Function</i> – is set to <i>Relative</i> so that the target may be defined as a proportion (between 0 and 1) of the desired level of feature representation in the study area.
    <br><br>
    ii. <i>Amount</i> – specifies the desired level of feature representation in the study area. In this example, it is set to 1.0, so that each feature would ideally have 100% of its distribution covered by the prioritization.
  </div>
</div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot94.png">

<div class=indentation>
  c. Open the <b>Decision Types</b> datasheet, and review the following input:
  <br>
  <div class=indentation>
    i. <i>Function</i> – the decision type is set to <i>Binary</i>, so that planning units are either selected or not for prioritization (<i>i.e.</i>, to prioritize or not prioritize a lake). 
  </div>
</div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot95.png">

<div class=indentation>
  d. Open the <b>Solver</b> datasheet, and review the following inputs:
  <br>
  <div class=indentation>
    i. <i>Function</i> – is set to <i>Default</i>. This specifies that the best solver currently available in your computer should be used to solve the conservation planning problem. 
    <br><br>
    ii. <i>Gap</i> – represents the gap to optimality and is set to a value of <i>0</i>. This gap is relative and expresses the acceptable deviance from the optimal objective. In this example, a value of 0 will result in the solver only stopping when it has found the best possible solution.
  </div>
</div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot96.png">

14\. Expand the **Output Options** node and open the **Performance** datasheet to review the following inputs set to *Yes*:

  <div class=indentation>
    i. <i>Number Summary</i> – calculates the number of lakes selected within the solution to the conservation planning problem.
    <br><br>
    ii. <i>Feature representation summary</i> – calculates how well features (<i>i.e.</i>, lake depth and surface area) are represented by the solution to the conservation planning problem. 
  </div>

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot97.png">

<br>

<p id="step-2"> <h3><b>Step 2. Visualizing and comparing results across scenarios</b></h3> </p>

The **Multi-Cost Lake Prioritization (Ontario, Canada)** template library already contains the results for each scenario. Before exploring additional scenarios, you will view the main results for the **No costs** scenario.

1\. Navigate to the **Maps** tab, and double click on the pre-configured **Solution** map. The *Solution* map shows which planning units have been selected for prioritization given the input data and parameters.

<img align="center" style="padding: 13px" width="800" src="assets/images/screenshot98.png">

2\. Navigate to the **Charts** tab, and double click on the pre-configured **Feature representation** chart. The *Feature representation* chart shows the proportion of mean depth and surface area represented in the **No costs** scenario solution. For instance, 51% of all the lakes' mean depth and 83% of all the lakes' surface area was represented in the solution.

<img align="center" style="padding: 13px" width="800" src="assets/images/screenshot99.png">

3\. Close the chart results panel.

<br>

Now, you will review the additional scenarios and explore how they differ from the **No costs** solution, which are built as a dependency of the **No costs** scenario. 

4\. In the *Explorer* window, expand the **All costs, Equal > Dependencies** and **All costs, Hierarchical > Dependencies** nodes to reveal the **No costs** scenario dependency.

<img align="center" style="padding: 13px" width="300" src="assets/images/screenshot100.png">

5\. Select the pre-configured scenario **All costs, Equal** and double-click it to open its properties. You may also right-click on the scenario name and select **Open** from the context menu.

6\. In the **Summary** datasheet, note the *Description* that says that this scenario "integrates five cost layers into the prioritization process, treating all cost layers with equal importance". 

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot100-2.png">

7\. Open the **Pipeline** datasheet and note that the *“Inherit values from ‘[1] No costs’”* checkbox in the bottom left corner is not marked, and new pipeline stage is set, called *Multi-Cost Prioritization*.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot100-3.png">

8\. Navigate to the **Prioritizr** tab, expand the **Base Prioritization > Data** nodes, and open the **Input Format** datasheet. Notice that this information cannot be edited (*i.e.*, greyed out) and the *“Inherit values from ‘[2] No costs’”* checkbox in the bottom left corner is marked. This indicates that values within this datasheet and others are derived from the **No costs** result scenario acting as a dependency.
  
<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot101.png">

9\. Expand the **Multi-Cost Prioritization** node and open the **Data** datasheet to review the following input:

<div class=indentation>
  i. <i>Cost-layers</i> – a data table showing lakes (<i>i.e.</i>, planning units) along the rows and cost variables along the columns, where 1 represents cost and 0 represents no cost.
  <br>
</div>

<img align="center" style="padding: 13px" width="600" src="assets/images/screenshot102-2.png">

10\. Next, open the **Parameters** datasheet and note that *Prioritization method* is set to *Equal*. This specifies how the cost variables will be integrated into the prioritization process; In this case, meaning that minimizing cost is treated with equal importance across all cost variables. Default values are provided for the additional parameters.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot103.png">

11\. Select the pre-configured scenario **All costs, Hierarchical** and double-click it to open its properties. You may also right-click on the scenario name and select **Open** from the context menu.

12\. In the **Summary** datasheet, note the *Description* that says that this scenario "integrates five cost layers into the prioritization process based on the following hierarchy of cost-reduction importance, from most to least important: protected area, lakeshore capacity, sanctuary, Brook Trout regulation, Lake Trout regulation".

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot103-2.png">

13\. Navigate to the **Prioritizr** tab, expand the **Multi-Cost Prioritization** node, and open the **Parameters** datasheet to note that *Prioritization method* is set to *Hierarchical*. All other input and parameters are identical to the **All costs, Equal** scenario.

<img align="center" style="padding: 13px" width="500" src="assets/images/screenshot107.png">

14\. Close the scenario properties.

15\. In the **Explorer** window, hold *Shift* and click on both the **All costs, Equal** and **All costs, Hierarchical**  scenarios to select them. Right-click and select **Add to Results** from the context menu to simultaneously add each scenario to the results.

<img align="center" style="padding: 13px" width="400" src="assets/images/screenshot108.png">

16\. Navigate to the **Charts** tab, and double-click on the pre-configured **Number of selected planning units** chart. This chart displays the total number of planning units in the solution per scenario. In this example, *226* lakes were selected in the solution, showing the budget was met in all scenarios.

<img align="center" style="padding: 13px" width="900" src="assets/images/screenshot112.png">

21\. Next, double-click on the pre-configured **Feature representation** chart. This chart displays the proportion of each feature (*i.e.*, mean lake depth and lake surface area) represented in the solution for each scenario. Note that the cost-optimized scenarios resulted in less feature representation, suggesting an intuitive trade-off between cost restrictions and feature representation.  

<img align="center" style="padding: 13px" width="900" src="assets/images/screenshot111.png">

16\. Next, double-click on the pre-configured **Cost representation** chart. Across all charts, the x-axis represents the five different cost variables and the y-axis represents the solution cost in terms of number of lakes. 

<div class=indentation>
  i. The upper chart, <i>Base Solution Absolute Held</i>, shows the cost represented in the base solution (<i>i.e.</i>, <i>No cost</i> scenario) for each cost variable. These results are generated by the <i>Multi-Cost Prioritization</i> stage based on the output of the <i>No cost</i> scenario - hence, the dependency - and as such, are expected to be absent for the baseline scenario and identical between the cost-optimized scenarios.
  <br><br>
  ii. The middle chart, <i>Cost-Optimized Solution Absolute Held</i>, shows the cost represented in the cost-optimized solutions for each cost variable. For instance, given the lakes selected in the solution to the <i>All costs, Equal</i> scenario, 200 lakes show a <i>RegulationLT</i> cost. The cost is slightly higher under the <i>All costs, Hierarchical</i> scenario. 
  <br><br>
  iii. The bottom chart, <i>Difference Absolute Held</i>, shows the amount of change between the baseline and each cost-optimized scenario. Here, negative values represent a reduction in cost in the cost-optimized solution, and positive values represent an increase in cost. For example, there was a reduction in <i>PA</i> costs of over 30 lakes in both scenarios. In turn, whereas <i>RegulationLT</i> cost decreased under the <i>All costs, Equal</i> scenario, it increased under the <i>All costs, Hierarchical</i> scenario. That is because the <i>Hierarchical</i> method prioritized reducing cost in the most important layer (<i>PA</i>) at the detriment of others. 
</div>

<img align="center" style="padding: 13px" width="900" src="assets/images/screenshot110.png">

23\. Now, navigate to the **Maps** tab, and double-click on the pre-configured **Solution** map. This map displays the lakes that were selected in the solution under each scenario. The package, however, offers a better way to compare the results.

<img align="center" style="padding: 13px" width="1000" src="assets/images/screenshot113.png">

24\. Double-click on the pre-configured **Solution comparison** map. This map is only computed by the *Multi-Cost Prioritization* stage scenarios, so the *No costs* scenario was removed from results. The *Base only* maps display which lakes were only selected under the baseline scenario (*No cost*) and are identical between scenarios. The *Cost-optimized only* maps show which lakes were only selected when the solution was optimized for cost, under the equal or hierarchical prioritization methods. The *Consensus* maps display which lakes were selected in both the baseline and cost-optimized solutions.

<img align="center" style="padding: 13px" width="1000" src="assets/images/screenshot114.png">

<br>

This tutorial demonstrated how **prioritizr** can be used to build tabular formulations of conservation problems, with a spatial visualization of the results, and covered how to account for multiple cost layers in the prioritization process. To explore more with **prioritizr**, see the <a href="/tutorials">tutorials page</a>. 

<br><br><br>