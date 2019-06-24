#svr
# input args processing
args = commandArgs(trailingOnly = TRUE)
# print(args)
Function_Name = c("--input","--output")
Index_of_Function = c(which(args=="--input"),which(args=="--output"))
Number_of_Each_Function = c(length(which(args=="--input")),length(which(args=="--output")))
Fun_Information = data.frame(Function_Name,Index_of_Function,Number_of_Each_Function)
Idx_Sort = sort(Index_of_Function)
Number_Function_Input = c(Idx_Sort[c(2:length(Idx_Sort))] - Idx_Sort[c(1:length(Idx_Sort)-1)]-1,length(args)-Idx_Sort[length(Idx_Sort)])
data_tmp = Fun_Information[order(Fun_Information$Index_of_Function),]
data_tmp$Number_Function_Input = Number_Function_Input
Fun_Information = data_tmp[order(row.names(data_tmp)),]
Error_Detect = function(index,number,name){
  if(length(index)<2){
    stop("--input,--output doesn't exist.",call. = TRUE)
  }else if(length(index)>5){
    stop("The number of --fold, --train, --test, --report, --predict is out of range.",call.=TRUE)
  }else{
    for(i in 1:length(number)){
      if(number[i]==1){
        # continue
      }else{
        stop(paste("The number of function",name[i],"is wrong."),call. = TRUE)
      }
    }
  }
}
Error_Detect(Index_of_Function,Number_of_Each_Function,Function_Name)

#Input Data
dlt_train<- readRDS(args[Fun_Information[Function_Name=="--input","Index_of_Function"]+1])
#讀取資料
homeprice_data <- dlt_train
homeprice_test <- homeprice_data[1461:dim(homeprice_data)[1],-1] #儲存測試資料
homeprice_data <- homeprice_data[1:1460,-1]                      #刪除ID變數及測試資料
homeprice_data_y <- homeprice_data$SalePrice                     #儲存SALEPRICE
n_obs = dim(homeprice_data)[1]                                   #儲存觀測值數量
n_feature = dim(homeprice_data[,-dim(homeprice_data)[2]])[2]     #儲存變數數量
#建立validation資料
#重新排序資料
set.seed(2019)
ind <- sample(1:n_obs,size = n_obs,replace = F)
#建立validation fold
k = 10 # fold 的數量
# 建立fold
fold <- list()
for (i in 1:k){
  if ( i == 1 ){
    fold[[i]] = homeprice_data[ind[1:floor(i*n_obs/10)],]
  }else{
    fold[[i]] = homeprice_data[ind[(floor((i-1)*n_obs/10)+1):floor(i*n_obs/10)],]
  }
}
# 建立訓練驗證集
train = list()
val = list()
for (i in 1:k){
  ind_tmp = c(1:10)
  train_ind = ind_tmp[!ind_tmp == i]
  for (j in 1:9){
    if (j == 1){
      train[[i]] = fold[[train_ind[[j]]]]
    }else{
      train[[i]] = rbind(train[[i]],fold[[train_ind[[j]]]])
    }
  }
  val[[i]] = fold[[i]]
}


# RMSE&RMSLE 計算函數
rmse = function(y,y_pred){
  n = length(y)
  return(sqrt(sum((y-y_pred)**2)/n))
}
rmsle = function(y,y_pred){
  n = length(y)
  return(sqrt(sum((log((y_pred+1)/(y+1)))**2)/n))
}

# 建立SVR 模型
library("e1071")

# model train
SVR_model = list()
k = 10
for(i in 1:k){
  SVR_model[[i]] = svm(SalePrice ~.,data=train[[i]],type="eps-regression",kernel = "radial",cost = 3.4,gamma = 0.002)
}

# get train performance
train_rmse = c()
train_rmsle = c()
for(i in 1:k){
  y = train[[i]]$SalePrice
  y_pred = predict(SVR_model[[i]],train[[i]])
  train_rmse = c(train_rmse,rmse(y,y_pred))
  train_rmsle = c(train_rmsle,rmsle(y,y_pred))
}
train_rmse_mean = mean(train_rmse)
train_rmsle_mean = mean(train_rmsle)

# get validation performance
val_rmse = c()
val_rmsle = c()
for(i in 1:k){
  y = val[[i]]$SalePrice
  y_pred = predict(SVR_model[[i]],val[[i]])
  val_rmse = c(val_rmse,rmse(y,y_pred))
  val_rmsle = c(val_rmsle,rmsle(y,y_pred))
}
val_rmse_mean = mean(val_rmse)
val_rmsle_mean = mean(val_rmsle)

result_svr = data.frame(SVR = round(c(train_rmse_mean,train_rmsle_mean,val_rmse_mean,val_rmsle_mean),2))

#xgboost
args = commandArgs(trailingOnly=TRUE)

library(xgboost)
# library(readr)
# library(stringr)
library(caret)
# library(car)
library(Matrix)
set.seed(2019)
#str(data)
data=readRDS(args[2])
data$OverallCond=as.factor(data$OverallCond)#先將一些類別型但是型態為整數的轉為factor
data$OverallQual=as.factor(data$OverallQual)
data$YearBuilt=as.factor(data$YearBuilt)
data$YearRemodAdd=as.factor(data$YearRemodAdd)
data$YrSold=as.factor(data$YrSold)


newdata=sparse.model.matrix(~.-1,data=data[,1:74])#將資料轉為可運行xgboost格式(會自動轉換factor型為dummy)
num=sample(1:1460,size=1460,replace = FALSE)#製作亂數列
train=newdata[1:1460,]
response=data$SalePrice[1:1460]
response=response[order(num)]
test=data[1461:2919,]
train=train[order(num),]

ID=list(1:146,147:292,293:438,439:584,585:730,731:876,877:1022,1023:1168,1169:1314,1315:1460)


modellist=list()

# mod=xgboost(data=train,label=response,nrounds = 30)
# pred=predict(mod,newdata = train)
# residual=(pred-response)^2
# plot(residual)
#############################以下為grid search 尋找參數最佳解
# xgb_grid = expand.grid(
#   nrounds =c(50,80),
#   max_depth = c(8,10),
#   eta = c(0.05,0.075,0.1),
#   gamma = 0,               #default=0
#   colsample_bytree = 1,    #default=1
#   min_child_weight = 1,    #default=1
#   subsample = 0.5
#   #lambda=0.5*(1:10)
# )
# xgb_trcontrol= trainControl(
#   method = "cv",
#   number = 10,
#   returnData = FALSE,
#   returnResamp = "all"# save losses across all models
# )
# 
# xgb_train= train(
#   x = train,
#   y = response,
#   trControl = xgb_trcontrol,
#   tuneGrid = xgb_grid,
#   method = "xgbTree"
# )
# 
# xgb_train

#####################################
param = list(eta = 0.075, #用gried search的結果加入模型
             max_depth = 8, 
             subsample = 0.5,
             lambda=3
             
)
table=as.data.frame(matrix(ncol=4,nrow = 11))

for(i in 1:10){#建立cv模型，並生成表現表格
  testID=ID[[i]]
  cvtest=train[testID,]
  cvtrain=train[-testID,]
  model=xgboost(data=cvtrain,label=response[-testID],nrounds = 100,verbose=0,params = param)
  modellist[[i]]=model
  cvtrain_predict=predict(model,newdata=cvtrain)
  cvtest_predict=predict(model,newdata=cvtest)
  train_rmse=sqrt(mean((cvtrain_predict-response[-testID])^2))
  test_rmse=sqrt(mean((cvtest_predict-response[testID])^2))
  train_rmsle=sqrt(mean((log(cvtrain_predict+1)-log(response[-testID]+1))^2))
  test_rmsle=sqrt(mean((log(cvtest_predict+1)-log(response[testID]+1))^2))
  table[i,1]=train_rmse
  table[i,2]=test_rmse
  table[i,3]=train_rmsle
  table[i,4]=test_rmsle
}
table[11,1]=round(mean(table$V1[1:10]),2)
table[11,2]=round(mean(table$V2[1:10]),2)
table[11,3]=round(mean(table$V3[1:10]),2)
table[11,4]=round(mean(table$V4[1:10]),2)

performance=as.data.frame(matrix(nrow = 4,ncol = 1))
performance[,1]=c(table[11,1],table[11,3],table[11,2],table[11,4])
colnames(performance)=c("XGboost")
#which.min(table[,2])

importance= xgb.importance( model =modellist[[which.min(table[,2])]])#用cv後的模型來找feature importance
importance=importance[order(importance$Gain),]
#print(xgb.plot.importance(importance_matrix = importance, top_n = 30))

test1=sparse.model.matrix(~.-1,data=test[,1:74])
output=predict(modellist[[which.min(table[,2])]],test1)#以kaggle預測集預測y
sub=as.data.frame(cbind(1461:2919,output))
colnames(sub)=c("Id","SalePrice")
#write.csv(sub,"sub.csv",row.names = FALSE)

# random forest & decision tree
# read parameters
args = commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
  stop("USAGE: Rscript code/dtrf.R --input data/data.rds --output results/performance.tsv", call.=FALSE)
}

# parse parameters
i<-1 
while(i < length(args))
{
  if(args[i] == "--input"){
    files<-args[i+1]
    i<-i+1
  }else if(args[i] == "--output"){
    out_f<-args[i+1]
    i<-i+1
  }else{
    stop(paste("Unknown flag", args[i]), call.=FALSE)
  }
  i<-i+1
}


# read files
data <- readRDS(files)
data$Old <- data$YrSold - data$YearBuilt
data$OverallGrd <- as.numeric(data$OverallQual * as.numeric(data$OverallCond))
data$GarageScore <- as.numeric(data$GarageArea * as.numeric(data$GarageQual))
del <- which(names(data) %in% c("YrSold","YearBuilt","OverallQual","OverallCond","GarageArea","GarageQual"))
data <- data[,-del]
idx <- 1:1460
train <- data[idx,]
test <- data[-idx,]



#讀取資料
homeprice_data <- train[,-1]                                     #刪除ID變數
n_obs = dim(homeprice_data)[1]                                   #儲存觀測值數量
n_feature = dim(homeprice_data[,-dim(homeprice_data)[2]])[2]     #儲存變數數量
#建立validation資料
#重新排序資料
set.seed(2019)
ind <- sample(1:n_obs,size = n_obs,replace = F)
#建立validation fold
k = 10 # fold 的數量
# 建立fold
fold <- list()
for (i in 1:k){
  if ( i == 1 ){
    fold[[i]] = homeprice_data[ind[1:floor(i*n_obs/10)],]
  }else{
    fold[[i]] = homeprice_data[ind[(floor((i-1)*n_obs/10)+1):floor(i*n_obs/10)],]
  }
}
# 建立訓練驗證集
tra = list()
val = list()
for (i in 1:k){
  ind_tmp = c(1:10)
  train_ind = ind_tmp[!ind_tmp == i]
  for (j in 1:9){
    if (j == 1){
      tra[[i]] = fold[[train_ind[[j]]]]
    }else{
      tra[[i]] = rbind(tra[[i]],fold[[train_ind[[j]]]])
    }
  }
  val[[i]] = fold[[i]]
}



# regression tree
library(rpart)
library(rpart.plot)
library(rattle)

control <- rpart.control(minsplit=10,minbucket=3,xval=10)
treeorig <- rpart(SalePrice ~ .,data=homeprice_data,method="anova",control=control)
# rpart.plot(treeorig, roundint = FALSE)
# fancyRpartPlot(treeorig)
a <- printcp(treeorig)
pst <- length(which(a[,4] - min(a[,4] + a[,5]) > 0)) + 1
cp <- a[pst,1]
# plotcp(treeorig)
# abline(v=pst, col = "red", lty = 3)

rmset <- c()
rmsee <- c()
rmslt <- c()
rmsle <- c()
for(i in 1:k){
  treeorig <- rpart(SalePrice ~ .,data=tra[[i]],method="anova",control=control)
  prunetree <- prune(treeorig, cp = cp)
  trped <- predict(prunetree,tra[[i]])
  pred <- predict(prunetree,val[[i]])
  rmset[i] <- sqrt(mean((trped-tra[[i]]$SalePrice)^2))
  rmse <- sqrt(mean((pred-val[[i]]$SalePrice)^2))
  rmsee[i] <- sqrt(mean((pred-val[[i]]$SalePrice)^2))
  rmslt[i] <- sqrt(mean((log(trped+1)-log(tra[[i]]$SalePrice+1))^2))
  rmsle[i] <- sqrt(mean((log(pred+1)-log(val[[i]]$SalePrice+1))^2))
  if(i==1){
    prunetreeold <- prunetree
    trpedold <- trped
    predold <- pred
    rmseold <- rmse
    flag <- i
  }
  if(i>1 & rmseold<rmse){
    
  }
  if(i>1 & rmse<=rmseold){
    prunetreeold <- prunetree
    trpedold <- trped
    predold <- pred
    rmseold <- rmse
    flag <- i
  }
  
}
prunetree <- prunetreeold
trped <- trpedold
pred <- predold
rmse <- rmseold
# fancyRpartPlot(prunetree)
trainrmse <- mean(rmset) # 27895.78
trainrmsle <- mean(rmslt) # 0.1376106
validrmse <- mean(rmsee) # 39784.03
validrmsle <- mean(rmsle) # 0.5528808
treeout <- data.frame(train_rmse=trainrmse, train_rmsle=trainrmsle, valid_rmse=validrmse, valid_rmsle = validrmsle)
rownames(treeout) <- "Decision Tree"
treeout # output performance
tppred <- predict(prunetree,test[,-1])
out2 <- cbind(ID=test$Id,SalePrice=tppred)
# write.csv(out2, "submit2.csv", row.names=FALSE)



# randomforest
library(randomForest)
rmset <- c()
rmsee <- c()
rmslt <- c()
rmsle <- c()
for(i in 1:k){
  rf <- randomForest(SalePrice ~ ., data = tra[[i]], importance=TRUE)
  pred <- predict(rf,val[[i]])
  rmse <- sqrt(mean((pred-val[[i]]$SalePrice)^2))
  rmset[i] <- sqrt(mean((rf$predicted-tra[[i]]$SalePrice)^2))
  rmsee[i] <- sqrt(mean((pred-val[[i]]$SalePrice)^2))
  rmslt[i] <- sqrt(mean((log(rf$predicted+1)-log(tra[[i]]$SalePrice+1))^2))
  rmsle[i] <- sqrt(mean((log(pred+1)-log(val[[i]]$SalePrice+1))^2))
  if(i==1){
    rfold <- rf
    predold <- pred
    rmseold <- rmse
    flag <- i
  }
  if(i>1 & rmseold<rmse){
    
  }
  if(i>1 & rmse<=rmseold){
    rfold <- rf
    predold <- pred
    rmseold <- rmse
    flag <- i
  }
  
}
rf <- rfold
pred <- predold
rmse <- rmseold
trainrmse <- mean(rmset) # 27830.7
trainrmsle <- mean(rmslt) # 0.140628
validrmse <- mean(rmsee) # 27577.55
validrmsle <- mean(rmsle) # 0.139985
# plot(rf)
# importance(rf, type = 2)
# Mean Decrease Accuracy - How much the model accuracy decreases if we drop that variable.
# mean decrease in MSE
# varImpPlot(rf, type = 2)
ranforout <- data.frame(train_rmse=trainrmse, train_rmsle=trainrmsle, valid_rmse=validrmse, valid_rmsle = validrmsle)
rownames(ranforout) <- "Random Forest"
ranforout # output performance
# pred <- predict(rf,test)
# out4 <- cbind(ID=test$Id,SalePrice=pred)
# write.csv(out4, "submit4.csv", row.names=FALSE)



out <- t(rbind(treeout,ranforout))

# three model result
row_name = data.frame(src = c("train_rmse","train_rmsle","val_rmse","val_rmsle"))
final_result = cbind(row_name,out,result_svr,performance)
write.table(final_result,file=out_f,row.names = FALSE,quote=F,sep='\t')