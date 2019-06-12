library(ggvis)
shinyUI(fluidPage(
  div(),
  sidebarLayout(
    sidebarPanel(
      selectInput("path", "Source", choices = list("train.csv" = 'train', "test.csv" = 'test')),
      sliderInput("nrow", "Number of points", min = 10, max = 1000, value = 100, step = 1),
      selectInput("set1", "Relation type", choices = list('1-d' = 1, '2-d' = 2)),
      uiOutput("ui_obj1"),
      uiOutput("ui_obj2"),
      width = 3
    ),
    mainPanel(
      fluidRow(
        column(
          6, 
          h3("Visualization1"),
          plotOutput("vis1"),
          align = "center"
        ),
        column(
          6, 
          h3("Visualization2"),
          plotOutput("vis2"),
          align = "center"
        )
      )
    )
  ),
  sidebarLayout(
    sidebarPanel(
      selectInput("analysis_type", "Analysis", choices = list('PCA' = 'pca', 'CA' = 'ca')),
      uiOutput("ui_obj3"),
      sliderInput("nsam", "Number of Sample", min = 10, max = 1000, value = 100, step = 1),
      width = 3
    ),
    mainPanel(
      fluidRow(
        fluidRow(
          column(
            6, 
            h3("Analysis1"),
            plotOutput("analysis1"),
            align = "center"
          ),
          column(
            6, 
            h3("Analysis2"),
            plotOutput("analysis2"),
            align = "center"
          )
        )
      )
    )
  )
))