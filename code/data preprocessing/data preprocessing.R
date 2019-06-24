setwd("C:/Users/user/Desktop")
library(shiny)
library(DMwR)
library(ggplot2)
library(corrplot)
library(scales)
train <- read.csv("train.csv",header = T)
test <- read.csv("test.csv",header = T)
test$SalePrice <- NA
data <- rbind(train,test)

na <- sapply(data,function(x) sum(is.na(x)))
na1 <- sort(na, decreasing=T)
na2 <- na1[na1>0]
na3 <- data.frame(na2)           
barplot(na2,names = row.names(na3),col = c(2,3,4,5,6,7))
na4 <- names(data)%in%c("PoolQC","MiscFeature","Alley","Fence","FireplaceQu","Utilities")
data <- data[!na4]
Garage <- c("GarageType","GarageQual","GarageCond","GarageFinish")
Bsmt <- c("BsmtExposure","BsmtFinType2","BsmtQual","BsmtCond","BsmtFinType1")
for (x in Garage){
  data[[x]] <- factor(data[[x]], levels= c(levels(data[[x]]),c('None')))
  data[[x]][is.na(data[[x]])] <- "None"
}
for (x in Bsmt){
  data[[x]] <- factor(data[[x]], levels= c(levels(data[[x]]),c('None')))
  data[[x]][is.na(data[[x]])] <- "None"
}
data$GarageYrBlt[is.na(data$GarageYrBlt)] <- data$YearBuilt[is.na(data$GarageYrBlt)]
BsmtGarage <- c("BsmtFullBath","BsmtHalfBath","BsmtFinSF1","BsmtFinSF2","BsmtUnfSF","TotalBsmtSF","GarageCars","GarageArea")
for (x in BsmtGarage ){
  data[[x]][is.na(data[[x]])] <- 0
}
data$MSSubClass <- factor(data$MSSubClass)

features <- c("MSSubClass","MSZoning","Street","LotConfig","Neighborhood","Condition1","Condition2","BldgType",
              "HouseStyle","RoofStyle","RoofMatl","Exterior1st","Exterior2nd","MasVnrType","Foundation",
              "Heating","Electrical","GarageType","SaleType","SaleCondition")
for (i in features){
  data[,i]<-factor(data[,i])
}

aslevel <- function(x,levels) {as.ordered(levels[x])}

data$LotShape <- aslevel(data$LotShape,levels=c("IR3"=0,"IR2"=1,"IR1"=2,"Reg"=3))

data$LandContour <- aslevel(data$LandContour,levels=c("Low"=0,"HLS"=1,"Bnk"=2,"Lvl"=3))

data$LandSlope <- aslevel(data$LandSlope,levels=c("Sev"=0,"Mod"=1,"Gtl"=2))

features <- c("ExterQual","ExterCond","BsmtQual","BsmtCond","HeatingQC","KitchenQual","GarageQual","GarageCond")
levels <- c("None"=0,"Po"=1,"Fa"=2,"TA"=3,"Gd"=4,"Ex"=5)
for (i in features){
  data[,i]<-aslevel(data[,i],levels=levels)
}

data$BsmtExposure <- aslevel(data$BsmtExposure,levels=c("None"=0,"No"=1,"Mn"=2,"Av"=3,"Gd"=4))

data$BsmtFinType1 <- aslevel(data$BsmtFinType1,levels=c("None"=0,"Unf"=1,"LwQ"=2,"Rec"=3,"BLQ"=4,"ALQ"=5,"GLQ"=6))

data$BsmtFinType2 <- aslevel(data$BsmtFinType2,levels=c("None"=0,"Unf"=1,"LwQ"=2,"Rec"=3,"BLQ"=4,"ALQ"=5,"GLQ"=6))

data$CentralAir <- aslevel(data$CentralAir,levels=c("N"=0,"Y"=1))

data$Functional <- aslevel(data$Functional,levels=c("Sal"=0,"Sev"=1,"Maj2"=2,"Maj1"=3,"Mod"=4,"Min2"=5,"Min1"=6,"Typ"=7))

data$GarageFinish <- aslevel(data$GarageFinish,levels=c("None"=0,"Unf"=1,"RFn"=2,"Fin"=3))

data$PavedDrive <- aslevel(data$PavedDrive,levels=c("N"=0,"P"=1,"Y"=2))

data2 <-  knnImputation(data,k=10,meth = "median")
saveRDS(data2,"C:/Users/user/Desktop/data2.rds")
data3 <- data2[1:1460,]
ggplot(data = data3, aes(x = SalePrice)) +
  geom_histogram(fill="red", binwidth = 10000) +
  scale_x_continuous(breaks= seq(0, 1000000, by=100000))
numericVars <- which(sapply(data3, is.numeric)) #index vector numeric variables
numericVarNames <- names(numericVars) #saving names vector for use later on
cat('There are', length(numericVars), 'numeric variables')
data1_numVar <- data3[, numericVars]
cor_numVar <- cor(data1_numVar, use="pairwise.complete.obs") #correlations of all numeric variables

#sort on decreasing correlations with SalePrice
cor_sorted <- as.matrix(sort(cor_numVar[,'SalePrice'], decreasing = TRUE))
#select only high corelations
CorHigh <- names(which(apply(cor_sorted, 1, function(x) abs(x)>0.5)))
cor_numVar <- cor_numVar[CorHigh, CorHigh]

corrplot.mixed(cor_numVar, tl.col="black", tl.pos = "lt")

freq_var<-function(x){
  df<-data.frame(table(data3[,x][1:1460]))
  names(df)[1]<-x
  return (df)
}
a<-freq_var("OverallQual")
ggplot(data3[1:1460,],aes(factor(OverallQual),data3$SalePrice,color=I("blue"),fill=I("lightblue")))+geom_boxplot()+scale_y_continuous(labels=comma)+
  geom_text(aes(x=OverallQual,y=2000,label=Freq),data=a,color="red",cex=5)+guides(fill=FALSE)+xlab("OverallQual")
a<-freq_var("OverallCond")
ggplot(data3[1:1460,],aes(factor(OverallCond),data3$SalePrice,color=I("blue"),fill=I("lightblue")))+geom_boxplot()+scale_y_continuous(labels=comma)+
  geom_text(aes(x=OverallCond,y=2000,label=Freq),data=a,color="red",cex=5)+guides(fill=FALSE)+xlab("OverallCond")
