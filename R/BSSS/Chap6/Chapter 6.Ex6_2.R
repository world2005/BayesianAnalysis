#-----------------------------------------------------------------------------------------
# EXAMPLE 6.2: BAYESIAN MULTIPLE REGRESSION WITH INFORMATIVE PRIORS
#             Program Steps
# Same as Example 6.1 except now priors are specified for the regression coefficients 
# b0 and precisions B0.
#-----------------------------------------------------------------------------------------



# data --------------------------------------------------------------------



#  Read in data PISA2009.csv

datafile <- read.csv(file.choose(),header=T)
datafile9 <- subset(datafile, select=c(rcomb1, gender, native,  slang,  ESCS,
                                       JOYREAD, DIVREAD, MEMOR, ELAB, CSTRAT))
# head(datafile9)
# nrow(datafile9)
datafile9<-na.omit(datafile9)
# nrow(datafile9)


# MCMCpack ----------------------------------------------------------------
require(MCMCpack)
require(coda)
require (BMA)

FullModel_inf <- MCMCregress(rcomb1~gender+native+ slang +  ESCS+
       JOYREAD+ DIVREAD+ MEMOR+ ELAB+ CSTRAT,data=datafile9,
       marginal.likelihood="Chib95",mcmc=10000, 
b0=c(491.2, 12.9, 3.4, 21.4, 32.6, 22.9, 0.01, -18.6, -11.1, 22.8),
B0=c(0.0173, 0.0932, 0.0141, 0.0216, 0.3354, 0.3210, 0.3245, 0.2101, 0.2111, 0.1707))

pdf('FullModel_inf.trace.pdf')
plot(FullModel_inf) # Produces the convergence plots and the posterior densities
pdf('FullModel_inf.acf.pdf')
autocorr.plot(FullModel_inf)
dev.off()
summary(FullModel_inf)

geweke.diag(FullModel_inf, frac1=0.1, frac2=0.5) 
heidel.diag(FullModel_inf,eps=0.1,pvalue=0.05)  
raftery.diag(FullModel_inf,q=0.5,r=0.05,s=0.95,converge.eps=0.001)  

# stan --------------------------------------------------------------------

library(rstan)
library(ggmcmc)
df  <- datafile9
N   <- as.numeric(nrow(df))
K   <- as.numeric(ncol(df))-1
y   <- df$rcomb1
x   <- as.matrix(df[ ,2:10])
pm  <- c(12.9, 3.4, 21.4, 32.6, 22.9, 0.01, -18.6, -11.1, 22.8)
pse <- c(0.0932, 0.0141, 0.0216, 0.3354, 0.3210, 0.3245, 0.2101, 0.2111, 0.1707)
datlist <- c('N', 'K','y', 'x', 'pm', 'pse')

stan.fullmod.inf <- '
data{
  int<lower=0> N;      // number of cases
  int<lower=0> K;      // number of predictors
  vector[N] y;         // outcome
  matrix[N,K] x;       // matrix of predictors
  vector[K] pm;
  vector[K] pse;
}
parameters {
  real beta0;                    // intercept
  vector[K] beta;                // vector of regression coefficients
  real<lower=0,upper=100> sigma; // residual sum of squares
}
model {
  beta0 ~ normal(491.2, 0.0173);
  beta[K] ~ normal(pm[K], pse[K]);
  y ~ normal(beta0 + x * beta, sigma); // likelihood
}
'


stan.fullfit.inf <- stan(model_code = stan.fullmod.inf, data=datlist, iter=10000,
                     chains=2)

rstan::traceplot(stan.fullfit.inf)
stan.fullfit.inf
fit <- stan.fullfit.inf
ggmcmc(ggs(fit), file=NULL, plot='ggs_autocorrelation')
s <- s <- mcmc.list(lapply(1:ncol(fit), function(x) mcmc(as.array(fit)[,x,])))
geweke.diag(s, frac1=0.1, frac2=0.5)
geweke.plot(s, frac1=.1, frac2=.5)
autocorr.plot(s)
acfplot(s)
gelman.plot(s)
densplot(s)
densityplot(s)
crosscorr.plot(s)
levelplot(s)
HPDinterval(s)
