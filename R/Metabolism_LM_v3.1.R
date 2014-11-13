#Metabolism_LM
#RDB 18-Sept-2012
#Metabolism Model Using the lm() function in R
#original function was used with phytoflash_regress_v0.r.  It just calculated metabolism using LM, and returnedthe daily estimates and the lm() model.
#_v2.0 was used with DO_PAR_PhaseShift_v1 (?).  This version returned 1) the 5-min (fitted) DO, and the 5-min (observed) PAR, and then the daily estimates.  However, the main change was that the fitted DO values could be generated from a series of 'adjustments' to the coefficients in the linear metabolism model--- i.e, the relationship between PAR and GPP and between Temp and R could be independently adjusted by some series of factors.
#_v2.1 Now metabolism is estimated daily.  I basically copied the approach taken in Phytoflash_Regress_v0.R.  This wasn't hard--- just used the ByeShort.R and Chunks.R functions.  It was hard, however, to store all of the info in the right way, and to make sure that the simulated time series was continuous across days (well, not that hard, but more challenging because there was a different model for each day).
#v2.2 In v2.0 I was interested in manipulating the 2 model coefficients (which were related to GPP and R).  Now I'm interested in monitoring and manipulating K, because I think this might be influencing the DO-PAR phase shift.  Clearly this function is serving a non-generic purpose now, but it's convenient,and the older, more generic versions are saved.  Plus  upgrades have been made along the way (fitting for individual days is going to be nice, as doing the daily fitting outside the function is awkward when the function returns a list [you don't get a 2-element list containing estimates and obs, e.g.... ran into this problem in Phytoflash_Regress_v0.R where the function is invoked for separately for each day of data]).  Wow, nice run-on sentence (and parenthetical statements [and things in brackets]).
#3.0 Cutting the crap.  I like how this function could set the ID's and estimate metabolism.  I'm removing all the simulation stuff.
#v3.1 Added options for what to return (Estimates, Fitted, Models).  Now the output of the function is a list by default, rather than a data.frame.
Metabolism_LM <- function(X, X2=NULL, Dt=1, AtmPress=0.942*760, SondeZ=0.7, WindHeight=2, ExpectedFreq=288, ReturnEstimates=TRUE, ReturnFitted=FALSE, ReturnModels=FALSE){
	#For Model="...", always have "dDO~...".  For predictors in X, look below for their names.  For predictors in X2, simply index the column vector to be used, but do not adjust for the size of Dt.  E.g., Model="dDO ~ I(PAR*X2[,1]) + Temp -1" if I wanted the first coefficient to represent the effect of the product of PAR and the variable in the first column of X2.  Note that I do not have to correct for the size of Dt, atmospheric exchange, etc.  This might only make sense to me, but at least then I'll know it makes sense to someone... if I tried to guess what you'd like, then I might get it wrong and it wouldn't make sense to anybody :D
	#If Model has 2 or more predictors, the first 2 predictors will be interpretted as GPP and R, respectively.  The fitted values of the model will be interpretted as NEP.
	#Only provide data for which there is a full day's worth of observations (complete diel cycle).  The function does not check for this.

	#Need these packages
	require("zoo")
	require("plyr")
	setwd("~/Documents/R/CRmix")
	source("ByeShort.R")
	source("Chunks.R")
	
	#Check order na names of columns in X
	# XnamesDefault <- c("Year","DoY", "DOsat", "Temp", "PAR", "Zmix", "Wind")
	# cOrder <- order(XnamesDefault) == order(colnames(X))
	# cNames <- XnamesDefault[order(XnamesDefault)] == colnames(X)[order(colnames(X))]
	
	X <- ByeShort(X, Expected=ExpectedFreq)
	X <- data.frame(X, "DepID"=Chunks(X[,"DoY"], Sub=ExpectedFreq))


	#Unpack variables in X
	Year0 <- X[,1]
	DoY0 <- X[,2]
	DOsat0 <- X[,3]
	Temp0 <- X[,4]
	PAR0 <- X[,5]
	Zmix0 <- X[,6]
	Wind0 <- X[,7]
	DepID0 <- X[,8]
	
	#Identify a couple useful numbers
	nobs <- nrow(X) #length of the time series... before I cut into it
	F_01 <- as.numeric(SondeZ <= Zmix0) #F_01 will be 0 when the sonde is below the mixed layer, and 1 when it is above, effectively acting as an on-off switch for atmospheric exchange.
	Freq <- trunc(1/median(diff(DoY0))) #number of samples per day
	# which(round(diff(DoY0),7)!=round((1/Freq),7))
	#Excise observations on days where the total number of observations is less than Freq
	# Days0 <- tabulate(
	
	RemEnd <- ((nobs-(Dt-1)):nobs) #indices of observations that will need to be cut off the end of covariates due to the size of Dt
	
	Year <- X[,1]
	DoY <- X[,2]
	DOsat <- X[,3]
	Temp <- X[,4]
	PAR <- X[,5]
	Zmix <- X[,6]
	Wind <- X[,7]
	DepID <- X[,8]
	
	
	
	Conc2Sat <- function(SDO2conc, SDtemp){  
		SDO2mgL=SDO2conc/1000*(15.999*2)
		SDO2sat=(SDO2mgL*100)/(-0.00000002057759*SDtemp^5 + 0.000002672016*SDtemp^4 + -0.0001884085*SDtemp^3 + 0.009778012*SDtemp^2 + -0.4147241*SDtemp + 14.621)
		return(SDO2sat)
	}
	KO2 <- function(Temp, Frequency, Wind, WindHeight){
		#Taken from pieces of code in Coloso/MCV matlab prog.
		#Translated to R and re-worked into a function by RDB
		schmidt <- (1800.6-120.1*Temp)+(3.7818*Temp^2)-0.047608*Temp^3
		Wind10 <- Wind/(WindHeight/10)^0.15 #wind at 10m, from wind at 2m
		#k600 <- 0.4 #.4
		k600 <- (2.07+0.215*Wind10^(1.7))/100 *24 #k600 in m/day
		k02 <-k600*(schmidt/600)^-0.5 #.4 is k600 estimate
		k02 <- (k02/Frequency)
		return(k02)#the k value for a "Frequency" time step in minutes.
	}
	Sat2Conc <- function(SDO2sat, SDtemp){
		SDO2mgL=(SDO2sat/100)*(-0.00000002057759*SDtemp^5+0.000002672016*SDtemp^4+(-0.0001884085)*SDtemp^3+0.009778012*SDtemp^2+(-0.4147241)*SDtemp+14.621)
		SDO2uM=SDO2mgL*1000/(15.999*2)
	return(SDO2uM)
	}
	SatdConc <- function(celcius, mmHg){
		# Weiss 1970 Deep Sea Res. 17:721-735
		#ln DO = A1 + A2 100/T + A3 ln T/100 + A4 T/100...
		#   + S [B1 + B2 T/100 + B3 (T/100)2]
		#where DO is ml/L; convert to mg/L by mult by 1.4276
		#where
		A1=-173.4292 
		A2=249.6339 
		A3=143.3483 
		A4 = -21.8492
		#and 
		B1= -0.033096 
		B2=0.014259 
		B3=-0.001700
		#and T = temperature degrees K (C + 273.15) S=salinity (g/kg, o/oo)
		T=celcius+273.15
		DOt=(exp(((A1 + (A2*100/T) + A3*log(T/100) + A4*(T/100)))))
		#pressure correction:
		#from USGS memo #81.11 and 81.15 1981, based on empiracal data in Handbook
		#of Chemistry and Physics, 1964.
		u=10^(8.10765 - (1750.286/(235+celcius)))
		DOsat=(DOt*((mmHg-u)/(760-u))) #ml/L
		DOsat=DOsat/1000 #L/L
		#conversion factor
		#convert using standard temperature and pressure.  Similar to calculating
		#saturation DO at STP in ml/L, converting to mg?L (at STP), and then doing
		#the above temperature and pressure conversions.
		R=0.082057 # L atm deg-1 mol-1
		O2molwt=15.999*2
		convfactor=O2molwt*(1/R)*(1/273.15)*(760/760) #g/L
		DOmgL=DOsat*convfactor*1000 #mg/L
		DOuM=DOmgL*1000/(15.999*2) #convert to ?M
		return(DOuM)
	}

	K <- KO2(Temp0, (Freq*Dt), Wind0, WindHeight)
	DOsatd <- SatdConc(Temp0, AtmPress)
	BioDO <- Sat2Conc(DOsat0, Temp0) - F_01*(K*(SatdConc(Temp0, AtmPress)-Sat2Conc(DOsat0, Temp0))/Zmix0) #The concentration of O2 after 1/(288*dt) days of equilibrating at a constant rate.  I.e., the O2 concentration you would expect to see at the next time step if there was no biology.  The rate is that which would be calculated given the inital O2 concentration.  More likely to overshoot equilibrium if the time step is large.  F_01 will be 0 when the sonde is below the mixed layer, and 1 when it is above, effectively acting as an on-off switch for atmospheric exchange.
	
	# if(ZeroNEP){
	# 	ZeroLM <- lm(BioDO~I(1:length(BioDO)))
	# 	FlatBioDO <- BioDO - (ZeroLM$coef[2]*(1:length(BioDO)))
	# 	BioDO <- FlatBioDO
	# }
	
	
	#**** prolly need to start "each-day" loop here*******
		#Calculate the daily rates
	dailyRate <- function(x) colMeans(x[,!(colnames(x)%in%c("Year","DoY"))])/Dt*Freq #remove the first column b/c that should be DoY, and the function is for finding daily rates of metabolism
	LM <- list()
	
	for(d in 1:max(DepID)){
		ID <- which(DepID == unique(DepID)[d])
		# oldID <- which(DepID == unique(DepID)[d-1])
		RemEnd <- ((length(ID)-(Dt-1)):length(ID))
		Xd <- X[ID,][-RemEnd,]
		Xd <- as.data.frame(as.matrix(Xd))

		dDO <- diff(BioDO[ID], Dt) #change in molar oxygen concentration; the response variable for the model
		# lnTemp <- (Temp)
		# LMd <- lm(formula(Model), data=Xd)#Calculate metabolism!!
		LMd <- lm(dDO~Xd[,"PAR"]+log(Xd[,"Temp"]) -1)
		LM[[d]] <- LMd
		
		#Convert model results into estimates of the metabolic parameters
		# Metab_raw <- data.frame("DoY"=paste("day",trunc(DoY),sep=""))
		Metab_rawd <- data.frame("Year"=Year[ID][-RemEnd], "DoY"=trunc(DoY[ID][-RemEnd]))
		GPP_raw <- LMd$coef[[1]] * Xd[,"PAR"] #LMd$model[,2]
		R_raw <- LMd$coef[[2]] * log(Xd[,"Temp"]) #LMd$model[,3]
		NEP_raw <-  GPP_raw + R_raw #fitted(LMd)
		Metab_rawd <- cbind(Metab_rawd, "GPP_raw"=GPP_raw, "R_raw"=R_raw, "NEP_raw"=NEP_raw)
		
		Metab_Dailyd <- ddply(Metab_rawd, c("Year","DoY"), .fun=dailyRate) #[-short,] #daily rates of metabolism, in units of uM O2 / day
		if(d==1){
			sBioDOd <- diffinv(Metab_rawd[,"NEP_raw"], Dt)+BioDO[ID][1]
		}else{
			sBioDOd <- diffinv(Metab_rawd[,"NEP_raw"], Dt)+sBioDOd[length(sBioDOd)] #BioDO[ID][1]
		}
		ThisK <- K[ID]
		sDOd <- (1/(1+F_01[ID]*K[ID]/Zmix0[ID]))*(sBioDOd + F_01[ID]*K[ID]/Zmix0[ID]*DOsatd[ID])
		sDOsatd <- Conc2Sat(sDOd, Temp0[ID])
		FittedDatad <- data.frame("DO"=sDOsatd, "PAR"=PAR0[ID])
		if(d==1){
			Metab_raw <- Metab_rawd
			# Metab_Daily <- Metab_Dailyd
			# Metab_Daily <- data.frame(Metab_Dailyd, "sumPAR"=sum(LMd$model[,2]), "meanTemp"=mean(LMd$model[,3]), "meanK"=mean(ThisK), "R2"=summary(LMd)$r.squared)
			Metab_Daily <- data.frame(Metab_Dailyd, "sumPAR"=sum(LMd$model[,2]), "meanTemp"=mean(LMd$model[,3]), "TotalF"=sum(abs(ThisK)), "R2"=summary(LMd)$r.squared)
			FittedData <- FittedDatad
		}else{
			Metab_raw <- rbind(Metab_raw, Metab_rawd)
			# Metab_Daily <- rbind(Metab_Daily, Metab_Dailyd)
			# Metab_Daily <- rbind(Metab_Daily, data.frame(Metab_Dailyd, "sumPAR"=sum(LMd$model[,2]), "meanTemp"=mean(LMd$model[,3]), "meanK"=mean(ThisK), "R2"=summary(LMd)$r.squared))
			Metab_Daily <- rbind(Metab_Daily, data.frame(Metab_Dailyd, "sumPAR"=sum(LMd$model[,2]), "meanTemp"=mean(LMd$model[,3]), "TotalF"=sum(abs(ThisK)), "R2"=summary(LMd)$r.squared))
			FittedData <- rbind(FittedData, FittedDatad)
		}
	}


	
		ReturnList <- list("Estimates"=Metab_Daily, "Fitted"=FittedData, "Models"=LM)[c(ReturnEstimates, ReturnFitted, ReturnModels)]
		return(ReturnList)
		# return(Metab_Daily)
	

}
