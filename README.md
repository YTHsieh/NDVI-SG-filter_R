# NDVI-SG-filter_R
Realization of Savitzky–Golay filter of NDVI in R.





--Chinese version--  
長期衛星影像可用於分析地景尺度的逐年變化，但大氣條件所造成的資料雜 訊可能造成分析上的困難，並影響後續推論。這些雜訊大多跟水氣得出現有關， 例如雲朵會吸收近紅外光(NIR)、反射紅光(RED)，造成 NDVI 值出現間斷性低谷， 干擾時間序列分析。用於植被指數時間序列的資料降造方法有很多型式，Geng, et al. (2014)綜合比較 8 類降造方法，並提出在多數情況下 Savitzky-Golay (S-G) technique 可以得到較佳的降躁效果。Savitzky-Golay (S-G) technique 由 Chen, et al. (2004)提出，是基於 Savitzky–Golay filter 的時間序列降躁演算法，透過衛星影像 的 cloud-flag 資訊，剔除觀測時有雲朵的圖資，產生平滑的序列曲線。我透過 Google earth engine 下載 Landsat 8 NDVI 時間序列資料，並以 R 語言實作該文提 出的演算法，結果如下圖 1.：




圖 3.中藍線為原始序列，黃線為經過 S-G technique 的平滑曲線，可以發現 黃線的數據點整體而言高於原始序列，並有效平滑化數個序列低谷。 
 
參考文獻： 
1. Chen, J, Jönsson P, Tamura M, Gu ZH, Matsushita B, Eklundh L. 2004. A simple method for reconstructing a high-quality NDVI time-series data set based on the Savitzky– Golay filter. Remote Sens. Environ. 91: 332–344. 
2. Geng L, Ma M, Wang X, Yu W, Jia S, Wang H. 2014. Comparison of eight techniques for reconstructing multi-satellite sensor time-series NDVI data sets in the Heihe River Basin, China. Remote Sens. 6: 2024-2049. 
