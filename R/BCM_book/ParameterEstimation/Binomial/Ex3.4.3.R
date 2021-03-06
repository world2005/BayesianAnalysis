# clears workspace: 
rm(list=ls())

library(rstan)
model <- "
// Prior and Posterior Prediction
data {
  int<lower=1> n1; 
  int<lower=1> n2;
  int<lower=0> k;
} 
parameters {
  real<lower=0,upper=1> theta;
  real<lower=0,upper=1> thetaprior;
}
model {
  // Prior on Rate Theta
  theta ~ beta(1, 1);
  thetaprior ~ beta(1, 1);
  // Observed Data
  k ~ binomial(n1, theta);
}
generated quantities {
  int<lower=0> postpredk;
  int<lower=0> priorpredk;
    
  // Posterior Predictive
  postpredk <- binomial_rng(n2, theta);
  // Prior Predictive
  priorpredk <- binomial_rng(n2, thetaprior);
}"

k <- 1
n1 <- 15
n2 <- 25
# Uncomment for Trompetter Data
# k <- 24
# n <- 121

data <- list(k=k, n1=n1, n2=n2) # to be passed on to Stan

myinits <- list(
  list(theta=.5, thetaprior=.5))

# parameters to be monitored:  
parameters <- c("theta", "thetaprior", "postpredk", "priorpredk")

# The following command calls Stan with specific options.
# For a detailed description type "?rstan".
samples <- stan(model_code=model,   
                data=data, 
                init=myinits,  # If not specified, gives random inits
                pars=parameters,
                iter=20000, 
                chains=1, 
                thin=1,
                # warmup = 100,  # Stands for burn-in; Default = iter/2
                # seed = 123  # Setting seed; Default is random seed
                )
# Now the values for the monitored parameters are in the "samples" object, 
# ready for inspection.
  
print(samples)  

######################Plots####################################################
theta   <- extract(samples)$theta
thetaprior  <- extract(samples)$thetaprior 
priorpredk  <- extract(samples)$priorpredk
postpredk   <- extract(samples)$postpredk


layout(matrix(c(1,2),2,1))
layout.show(2)
#Prior and posterior of theta
plot(density(theta, from=0, to=1), zero.line=F, axes=F, main="", xlab="",
             ylab="", xlim=c(0,1), ylim=c(0,6))
axis(1, at=c(0,0.2,0.4,0.6,0.8,1), lab=c("0","0.2","0.4","0.6","0.8","1"),
     cex.axis=0.8)
mtext("Rate", side=1, line=2.25, cex=1.2)
axis(2, at=c(0,2,4,6),cex.axis=0.8)
mtext("Density", side=2, line=2.25, cex=1.2)
lines(density(thetaprior, from=0, to=1), lty=3, col="gray")
legend('topright', c("Prior", "Posterior"), lty=c(3,1), col=c ("grey", "black"))

#Prior and posterior predictive
mybreaks <- seq(from=-.5,to=n2+1,by=1)
my.at    <- seq(from=0,to=n2,by=1)
hist(postpredk,breaks=mybreaks,freq=F, right=F, ylab="", xlab="", ylim=c(0,0.3),
     main="", axes=F )
axis(1, at=my.at,lab=my.at,cex.axis=0.8)
mtext("Success Count", side=1, line=2.25, cex=1.2)
axis(2,at=c(0,0.1,0.2,0.3),lab=c("0","0.1","0.2","0.3"),cex.axis=0.8)
mtext("Mass", side=2, line=2.25, cex=1.2)
hist(priorpredk, breaks=mybreaks,freq=F,right=F,add=T, lty=3,border="grey")
legend('topright', c("Prior", "Posterior"), lty=c(3,1),col=c("grey", "black"))


# Refit -------------------------------------------------------------------

samples <- stan(fit=samples,   
                data=data, 
                init=myinits,  # If not specified, gives random inits
                pars=parameters,
                iter=20000, 
                chains=1, 
                thin=1,
                # warmup = 100,  # Stands for burn-in; Default = iter/2
                # seed = 123  # Setting seed; Default is random seed
)