year <- '2012'
dosat <- load.ts(paste0('~/Documents/R/CRmix/Data/Crystal_',year,'.dosat'))
doobs <- load.ts(paste0('~/Documents/R/CRmix/Data/Crystal_',year,'.doobs'))

wtr <- load.ts(paste0('~/Documents/R/CRmix/Data/Crystal_',year,'.wtr'))
meta <- ts.meta.depths(wtr, slope = 0.1, seasonal=TRUE, na.rm=FALSE)
irr <- load.ts('~/Documents/R/CRmix/data/CR_par.txt')
irr <- merge(irr,wtr[,1:2],'datetime')[,2]
datetime <- wtr[,1]
z.mix <- meta[,2]
wtr <- wtr[,2]
do.sat = dosat[,2]
do.obs = o2.at.sat.base(wtr, altitude = 450)
wnd <- rnorm(length(wtr),2.5)
wnd[wnd<0.1] <- 0.1
k600 <- k.cole.base(wnd)
k.gas <- k600.2.kGAS.base(k600,temperature = wtr,gas="O2")
u_i <- !is.na(z.mix)

r_dt <- round(datetime, 'days')
plot(r_dt,rep(NA,length(r_dt)), ylim = c(-80,40),'ylab'='metab')
use.dates <- unique(r_dt)
for (i in 1:length(use.dates)){
  u_i <- r_dt %in% use.dates[i] & !is.na(z.mix)
  mtb <- metab.mle(do.obs[u_i], do.sat[u_i], k.gas[u_i], z.mix[u_i], irr[u_i], wtr[u_i], datetime = datetime[u_i])
  if (i == 1){
    metab <- mtb
  } else {
    metab <- rbind(metab,mtb)
  }
  points(use.dates[i],mtb$metab[[1]], pch=4,col = 'green')
  points(use.dates[i],mtb$metab[[2]], pch=8,col = 'red')
  points(use.dates[i],mtb$metab[[3]], pch=8,col = 'blue')
}

