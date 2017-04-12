---
layout: default
title: Using a Jupyter Notebook
---
<div class="alert alert-success" role="alert"> This page describes the 
<strong>
{{ site.cig_text }}
</strong>
solution.
</div> 
## Using a Jupyter Notebook

You can view and execute the R code for this solution in a Jupyter Notebook on the VM by following these instructions. 

## Set Password and Start

On the VM desktop, you will see an icon "Jupyter Set Password...".  Double click this icon and follow the prompts to create a password and then start the Jupyter server.  

HINT: If the window is too small, click on the icon on the upper left corner and use the Properties dialog to enlarge the font size.
       
## Access Jupyter

Once the server is running, open the Mozilla Firefox web browser.  Type the following into the address bar to access Jupyter: 

    https://localhost:9999

You will get a security warning, hit the "Advanced" button and add this to your exceptions to access the Jupyter session.

 There are a number of samples available on the VM server.  You can add the **Campaign Optimization R Notebook** by moving or copying it from **Desktop/Campaign/R** into **C:/`machinename`/notebook** (for example, if your machinename is "dsvm" the path is **C:/dsvm/notebook**).  You will also need to copy the 4 .csv files from the **Desktop/Campaign/Data** folder into the notebook folder.

 Once the Jupyter server is running on your VM, you can also connect to it from another computer by using the Public IP address in the url:

    https://ipaddress:9999
        
The ipaddress can be found in the Azure Portal under the "Network interfaces" section - use the Public IP Address.##

## Using Jupyter

To execute the code in a cell, ` Shift+Enter` when your cursor is in the cell.  Some of the cells may take a minute or two to work, and must be complete before the next cell can execute.  You can also select the Cell>Run All menu item to execute the entire notebook.


<a href="Typical.html#step2">Return to Typical Workflow<a>