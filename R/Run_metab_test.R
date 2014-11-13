#setwd("~/Documents/R/CRmix")
#install.packages("zoo")
#install.packages("plyr")
source("ByeShort.R")
source("Chunks.R")
require("zoo")

jData <- read.csv("MetabolismTestData.csv")
source('~/Documents/R/CRmix/Metabolism_LM_v3.2.R', echo=TRUE)
ExpectedFreq=288
WindHeight=2
SondeZ=0.7
AtmPress=0.942*760
Dt=1
X2 = TRUE
Metabolism_LM(X=jData)