# < Title of your final project >

### Groups
* < 陳庭偉, 104304041 >
* < 陳柏勳, 107354001 >
* < 楊博安, 107354003 >
* < 林威均, 108354005 >
* < 周　平, 106356007 >

### Goal

To help the bank and house buyer evaluate the value of house, and make better investment, the goal of our project is to predict the house price through the attributes of house.

### Demo

You can pull the repository, and then run the command below to replicate our outcome:

```R
Rscript code/group_9.R --input data/data.rds --output results/performance.tsv
```
We also provide interative data visualization at shinyapp.io link below:

<a href = "https://pingchou.shinyapps.io/shiny/?fbclid=IwAR3Wi6-ZC2quD7R2bB7YCFNt86d1CN2pPJOdhkEFNL7eJw3pfR-XQD1AB8o">Click me to redirect to shinyapp.io</a>

![](./img/shinyapp.png)

## Folder organization and its related information

### docs

* Our project introduction document is placed at the path below
  * 'docs/1072_datascience_FP_nccu_stat_mis.pptx'
  * 'docs/1072_datascience_FP_nccu_stat_mis.pdf'

### data

* Source: Kaggle competition '<a href = "House Prices: Advanced Regression Techniques">House Prices: Advanced Regression Techniques'</a>
* Input format: The format and structure of the data is displayed below:

![](./img/data_format.png)

In the data, each row of the data is a sample house with price label, with columns of attributes. In other words, figure out the relationship between each attribute and house price through machine learning technique is our main task.

* Preprocessing: Due to large number of variable, please refer to the inserted .pdf file in the introduction document.

### code

* Which method do you use?
* What is a null model for comparison?
* How do your perform evaluation? ie. Cross-validation, or extra separated data

### results

* Which metric do you use 
  * precision, recall, R-square
* Is your improvement significant?
* What is the challenge part of your project?

## Reference
* Code/implementation which you include/reference (__You should indicate in your presentation if you use code for others. Otherwise, cheating will result in 0 score for final project.__)
* Packages you use
* Related publications


