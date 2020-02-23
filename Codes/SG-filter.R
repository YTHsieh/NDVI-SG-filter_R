library(ggplot2)
library(dplyr)
library(signal)
library(tidyr)
library(imputeTS)
library(partitions)


theme_set(theme_minimal())  ##Set the default theme

##下方開始寫一個迴圈，實行Chen (2004)的方法。
##sgolay() function >> p = 文章中的d， n = 文章中的 2m+1 (m = (n-1)/2)。
##   2 <= p <= 4; n: c(9, 11, 13, 15), 共有四種選擇。總共有 3*4 = 12 個組合要測試(Chen, 2004)。
##(p, n) = (4, 11) 似乎不錯
##EVIdata為原始data，請讀入時間序列data，格式如example.csv .

####################

nsteps = 200   #疊代次數設定

####################


pos = matrix (nrow = length(EVIdata[,9]), ncol = nsteps+2)
pos[,1] = EVIdata[,9]  ##設定第一欄為原始data


##Step 1: 2進位cloudflag版
item1 = EVIdata
cloudflag = matrix (nrow = length(item1$pixel_qa), ncol = 8)
for (i in 1:length(item1$pixel_qa)){
if(is.na(item1$pixel_qa[i])){

}else{
cloudflag[i,] = tobin(item1$pixel_qa[i], 8)
}
}
cloudShadow = which(cloudflag[,5] == 1)
cloud = which(cloudflag[,3] == 1)
length(union(cloudShadow, cloud))  ##bit3, bit5 其中一個為1的。
dontwant = union(cloudShadow, cloud)
item1[dontwant, 9] = NA; head(item1) ##拔去cloudflag data >> NA

pos[,2] = na_interpolation(item1$NDVI, option = "linear"); head(pos[,2])  ##內插NA值

##查看拔除cloudflag後的結果   
ss = cbind(EVIdata,as.data.frame(pos[, 2]))
##ss[, 8] = na_interpolation(EVIdata$EVI, option = "linear") ##內插NA值
head(ss)
df = ss %>% select(Date, NDVI, `pos[, 2]`) %>% gather(key = "variable", value = "value", -Date)
head(df, 3)
pp = ggplot(df, aes(x = as.Date(Date), y = value)) +
    geom_line(aes(color = variable), size = 1) +
    scale_color_manual(values = c("#00AFBB", "#E7B800")) +
    geom_point(colour = "black") +
	theme_minimal(); pp   





##Step 2 
##Savitzky-Golay filter smooth 1次 EVI值, 填入pos[,3]。日後需補上在4*3種組合裡選出最適合的。
posStep2 = matrix (nrow = length(EVIdata[,9]), ncol = 12)
pn = c(2:4)
nn = c(9, 11, 13, 15)
for (i in 0:2){  ##做出12種S-G filter的組合，選RMSE最小者(the least-squares fitting method)。
	
	for (k in 1:4){
		
		posStep2[,4*i+k] = filter(filt = sgolay(p = pn[i+1], n = nn[k]), x = pos[,2])
		}
	}
RMSE = c() 	
for (i in 1:12){
	RMSE = c(RMSE, sum(((posStep2-pos[,2])^2)[,i]))
	}
i = which(RMSE == min(RMSE)) %/% 4 ##選出RMSE最小者
k = which(RMSE == min(RMSE)) %% 4
if (k == 0){
i = i-1
k = 4}else{
}; i; k
pos[, 3] = filter(filt = sgolay(p = pn[i+1], n = nn[k]), x = pos[,2])    ##(ti, Ni0)-smooth


##Step 3
##計算出每一個ti的weight, Wi。
Wi = matrix(nrow = length(pos[,1]), ncol = nsteps)
Di = pos[,2] - pos[,3]
Dmax = max( abs(pos[,2] - pos[,3]))
Wi[,1] = 1 - (Di/Dmax)
Wi[which( Di >= 0),1] = 1; Wi[,1]  ## Nt0 >= Nt1 >> Wi = 1


##Step 4: 做出(ti, Ni1)
pos[,4] = pos[,3]
pos[which( Di >= 0), 4] = pos[which( Di >= 0), 2]

##Step 6
Fk = data.frame()
Fi = sum(abs(pos[,4] - pos[,2])*Wi[,1]); Fi
Fk = rbind(Fk,Fi)

##Iteration: Step 5 - Step 6

for (i in 2:nsteps-1){

##Step 5
##此時的S-G filter是用來fit variation，而不是get long term trend, 故建議使用較小的m，較大的d
##文章建議(m, d) = c(4, 6) >> (n, p) = c(9, 6)
pos[,i+3] = filter(filt = sgolay(p = 6, n = 9), x = pos[,i+2])
pos[which( (pos[,2] - pos[,i+3]) >= 0) ,i+3] = pos[which( (pos[,2] - pos[,i+3]) >= 0) ,2]

##計算Weight
Dii = pos[,2] - pos[,i+3]
Dmaxx = max( abs(pos[,2] - pos[,i+3]))
Wi[,i] = 1 - (Dii/Dmaxx)
Wi[which( Dii >= 0),i] = 1; Wi[,i]

##Step 6
Fii = sum(abs(pos[,i+3] - pos[,2])*Wi[,i])
Fk = rbind(Fk, Fii)
}
colnames(Fk) = "Fk"



##Step final
##plot疊代結果，選出最終time-series
pFk <- ggplot(Fk, aes(x = seq(1,length(Fk)), y = Fk)) +
	geom_point(colour = "black") +
	geom_line(); pFk
EVIdata2 = cbind(EVIdata, pos[, which(Fk$Fk == min(Fk$Fk))+3])
colnames(EVIdata2)[length(EVIdata2)] = "NEW_NDVI"; head(EVIdata2)  ##將最終結果cbind到EVIdata2

##plot NDVI、NEW_NDVI >>  比較經過smooth後的差異
df = EVIdata2 
df$NDVI = na_interpolation(df$NDVI, option = "linear"); head(df) ##內插NA值
df = df %>% select(Date, NDVI, NEW_NDVI) %>% gather(key = "variable", value = "value", -Date)
head(df, 3)
pp = ggplot(df, aes(x = as.Date(Date), y = value)) +
    geom_line(aes(color = variable), size = 1) +
    scale_color_manual(values = c("#00AFBB", "#E7B800")) +
    geom_point(colour = "black") +
    theme_minimal(); pp
    
    
write.table(EVIdata2 , paste(datdir,"L7-SR_Blackforest_clean.csv",sep=""), sep=",", quote=F, row.names=F, col.names=T)  ##輸出存檔
