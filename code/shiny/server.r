library(shiny)
library(ggvis)
library(ggbiplot)
library(ggExtra)
library(FactoMineR)
library(factoextra)
library(data.table)
library(shinyWidgets)

shinyServer(function(input, output, session) {
  
  # read data into data.frame
  
  data <- reactive({
    
    if(input$path == 'train')
    {
      file.data <- readRDS('data.rds')
      file.data[1:min(input$nrow, 1460),]
    }
    else
    {
      file.data <- readRDS('data.rds')
      file.data[1460:min(input$nrow + 1460, nrow(file.data)),]
    }
  })
  
  output$ui_obj1 <- renderUI({
    
    option = list()
    data_type = sapply(data(), class)
    
    for(idx in colnames(data()))
    {
      if(idx != 'Id')
      {
        if(data_type[idx] == 'integer')
        {
          option[paste(idx, '(i)', sep = '')] = idx
        }
        else
        {
          option[paste(idx, '(c)', sep = '')] = idx
        }
      }
    }
    selectInput("attr1", "Attribute1", choices = option)
  })
  
  output$ui_obj2 <- renderUI({
    
    option = list()
    data_type = sapply(data(), class)
    
    for(idx in colnames(data()))
    {
      if(idx != 'Id')
      {
        if(data_type[idx] == 'integer')
        {
          option[paste(idx, '(i)', sep = '')] = idx
        }
        else
        {
          option[paste(idx, '(c)', sep = '')] = idx
        }
      }
    }
    
    if(input$set1 == 2)
    {
      selectInput("attr2", "Attribute2", choices = option)
    }
  })
  
  output$ui_obj3 <- renderUI({
    
    options = c()
    cols = colnames(data())
    data_type = sapply(data(), class)
    
    for(i in (2:length(cols)))
    {
      if(data_type[i] == 'integer')
      {
        options = c(options, cols[i])
      }
    }
    
    if(input$analysis_type == 'pca')
    {
      multiInput("target_column", label = "column :", choices = options, selected = options[1:2])
    }
    else
    {
      multiInput("target_column", label = "column :", choices = options, selected = options[1:3])
    }
    
  })
  
  output$vis1 <- renderPlot({
    
    data_type = sapply(data(), class)
    
    if(input$set1 == 1)
    {
      attr = input$attr1
      if((as.character(data_type[attr]) == 'integer'))
      {
        graph = ggplot(data(), aes_string(x = attr))
        graph = graph + geom_density(aes_string(fill = factor(1)), alpha = 0.5) +
                labs(title = paste("pdf plot of", attr, sep = ' '))
        
        print(graph)
      }
      else
      {
        graph = ggplot(data(), aes_string(attr)) + 
                geom_histogram(aes_string(x = attr), width = 0.5, stat = "count", fill = "tomato3") +
                labs(title = paste("histgram of", attr, sep = ' '))
        theme(axis.text.x = element_text(angle = 65, vjust = 0.6))
        
        print(graph)
      }
    }
    else
    {
      attr1 = input$attr1
      attr2 = input$attr2
      
      if((as.character(data_type[attr1]) == 'integer') & (as.character(data_type[attr2]) == 'integer'))
      {
        title = paste("Scatter plot of", attr1, sep = ' ')
        title = paste(title, 'and', sep = ' ')
        title = paste(title, attr2, sep = ' ')
        
        theme_set(theme_bw())
        graph = ggplot(data(), aes_string(x = attr1, y = attr2))
        graph = graph + geom_point() + 
        geom_smooth(method = "lm", se = F) +
        labs(title = title)
        graph = ggMarginal(graph, type = "histogram", fill = "transparent")
        
        print(graph)
      }
      if((as.character(data_type[attr1]) == 'integer') & (as.character(data_type[attr2]) == 'factor'))
      {
        title = paste("Histogram of", attr1, sep = ' ')
        title = paste(title, 'and', sep = ' ')
        title = paste(title, attr2, sep = ' ')
        
        graph = ggplot(data(), aes_string(x = attr1)) + scale_fill_brewer(palette = "Spectral")
        graph = graph + geom_histogram(aes_string(fill = attr2), binwidth = 10, col = "black", size = .1)
        graph = graph + labs(title = title)
        
        plot(graph)
      }
      if((as.character(data_type[attr1]) == 'factor') & (as.character(data_type[attr2]) == 'integer'))
      {
        title = paste("Histogram of", attr1, sep = ' ')
        title = paste(title, 'and', sep = ' ')
        title = paste(title, attr2, sep = ' ')
        
        graph = ggplot(data(), aes_string(x = attr2)) + scale_fill_brewer(palette = "Spectral")
        graph = graph + geom_histogram(aes_string(fill = attr1), binwidth = 10, col = "black", size = .1)
        graph = graph + labs(title = title)
        
        plot(graph)
      }
      if((as.character(data_type[attr1]) == 'factor') & (as.character(data_type[attr2]) == 'factor'))
      {
        title = paste("Bubble plot of", attr1, sep = ' ')
        title = paste(title, 'and', sep = ' ')
        title = paste(title, attr2, sep = ' ')
        
        theme_set(theme_bw())
        graph = ggplot(data(), aes_string(x = attr1, y = attr2))
        graph = graph + geom_count(col = "orange") + labs(title = title)
        
        print(graph)
      }
    }
  })
  
  output$vis2 <- renderPlot({
    
    data_type = sapply(data(), class)
    
    if(input$set1 == 1)
    {
      attr = input$attr1
      if((as.character(data_type[attr]) == 'integer'))
      {
        graph = ggplot(data(), aes_string(x = attr, fill = '1'))
        graph = graph + geom_step(stat = "ecdf", color = '#1b9e77', linetype = 2) +
                labs(title = paste("cdf plot of", attr, sep = ' '))
        
        print(graph)
      }
      else
      {
        df = data.frame(table(data()[attr]))
        colnames(df) = c('cate', 'freq')
        graph = ggplot(df, aes(x = "", y = freq, fill = cate)) + 
                geom_bar(width = 1, stat = "identity")
        graph = graph + coord_polar("y", start=0) + labs(title = paste("Pie chart of", attr, sep = ' '))
        
        print(graph)
      }
    }
    else
    {
      attr1 = input$attr1
      attr2 = input$attr2
      
      if((as.character(data_type[attr1]) == 'integer') & (as.character(data_type[attr2]) == 'integer'))
      {
        title = paste("Smoothed scatter plot of", attr1, sep = ' ')
        title = paste(title, 'and', sep = ' ')
        title = paste(title, attr2, sep = ' ')
        
        theme_set(theme_bw())
        graph = ggplot(data(), aes_string(x = attr1, y = attr2))
        graph = graph + geom_point() + 
                geom_smooth(method = "loess", se = T) +
                labs(title = title)
        graph = ggMarginal(graph, type = "boxplot", fill = "transparent")
        
        print(graph)
      }
      if((as.character(data_type[attr1]) == 'integer') & (as.character(data_type[attr2]) == 'factor'))
      {
        title = paste("Box plot of", attr1, sep = ' ')
        title = paste(title, 'group by', sep = ' ')
        title = paste(title, attr2, sep = ' ')
        
        graph = ggplot(data = data(), mapping = aes_string(x = attr2, y = attr1))
        graph = graph + geom_boxplot(alpha = 0, outlier.shape = 'star')
        graph = graph + geom_jitter(alpha = 0.8, color = "tomato3") + labs(title = title)
        
        print(graph)
      }
      if((as.character(data_type[attr1]) == 'factor') & (as.character(data_type[attr2]) == 'integer'))
      {
        title = paste("Box plot of", attr2, sep = ' ')
        title = paste(title, 'group by', sep = ' ')
        title = paste(title, attr1, sep = ' ')
        
        graph = ggplot(data = data(), mapping = aes_string(x = attr1, y = attr2))
        graph = graph + geom_boxplot(alpha = 0, outlier.shape = 'star')
        graph = graph + geom_jitter(alpha = 0.8, color = "tomato3") + labs(title = title)
        
        print(graph)
      }
      if((as.character(data_type[attr1]) == 'factor') & (as.character(data_type[attr2]) == 'factor'))
      {
        title = paste("Pie chart of", attr2, sep = ' ')
        title = paste(title, 'group by', sep = ' ')
        title = paste(title, attr1, sep = ' ')
        
        df = data.frame(table(data()[c(attr1, attr2)]))
        df = data.frame(cate = paste(df[, 1], df[, 2], sep = '-'), freq = df[, 3])
        colnames(df) = c('cate', 'freq')
        
        graph = ggplot(df, aes(x = "", y = freq, fill = cate)) + 
                geom_bar(width = 1, stat = "identity")
        graph = graph + coord_polar("y", start=0) + labs(title = title)
        
        print(graph)
      }
    }
  })
  
  output$analysis1 <- renderPlot({
    
    if(input$analysis_type == 'pca')
    {
      sub_data = data()[1:input$nsam, input$target_column]
      sub_data.pca = prcomp(sub_data, choices = c(1, 2), center = TRUE, scale. = TRUE)

      graph <- ggbiplot(sub_data.pca, obs.scale = 1, var.scale = 1)
      graph <- graph + scale_color_discrete(name = '')
      graph <- graph + theme(legend.direction = 'horizontal', legend.position = 'top')
      graph
    }
    else
    {
      sub_data = data()[1:input$nsam, input$target_column]
      sub_data.ca = CA(sub_data, 2, graph = FALSE)
      fviz_ca_biplot(sub_data.ca, repel = TRUE)
    }
  })
  
  output$analysis2 <- renderPlot({
    
    if(input$analysis_type == 'pca')
    {
      sub_data = data()[1:input$nsam, input$target_column]
      sub_data.pca = prcomp(sub_data, choices = c(1, 2), center = TRUE, scale. = TRUE)

      graph = fviz_eig(sub_data.pca)
      graph
    }
    else
    {
      sub_data = data()[1:input$nsam, input$target_column]
      sub_data.ca <- CA(sub_data, 2, graph = FALSE)
      fviz_ca_col(sub_data.ca, col.col = "cos2", gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"), repel = TRUE)
    }
  })
})
