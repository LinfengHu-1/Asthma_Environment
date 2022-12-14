#' ---
#' title: "calscreening2018"
#' author: "Group 21; Group name: 21 and me; Members: Pluto Zhang, Linfeng Hu, Cynthia Ma"
#' date: "2022-10-26"
#' output: pdf_document
#' ---
#' 
## ----------------------------------------------------------------------
library(rstudioapi)
library(tidyverse)
library(gam)
library(splines)
library(splines2)  
library(dplyr)
library(tidyr)
library(broom)
library(dslabs)
library(ggplot2)
library(ggthemes)
library(ggrepel)
library(data.table)
library(nnet)
library(VGAM)
library(rgl)
library(rayshader)
library(plotly)
library(glmnet)
library(splines2)
library(foreign)
library(gam)
library(Hmisc)
library(MASS)

#' 
## ----------------------------------------------------------------------
data_cal <- read_csv('calenviroscreen-3.0-results-june-2018-update.csv')
#data_cal

#' 
#' 
## ----------------------------------------------------------------------
summary(data_cal)

#' 
## ----------------------------------------------------------------------
#names(data_cal)
colnames(data_cal) <- gsub(" ", "", colnames(data_cal))
colnames(data_cal) <- gsub("\n", "", colnames(data_cal))
#names(data_cal)

#' ***
#' columns for diseases: Asthma LowBirthWeight CardiovascularDisease
#' 
#' columns for socio-economic elements:
#' ducation LinguisticIsolation Poverty Unemployment HousingBurden Pop.Char.
#' 
#' columns for air pollution elements: 
#' Ozone PM2.5 DieselPM DrinkingWater Pesticides Tox.Release
#' Traffic CleanupSites GroundwaterThreats Haz.Waste Imp.WaterBodies
#' SolidWaste PollutionBurden
#' *****
#' 
## ----------------------------------------------------------------------
air_pollutants_vec <- names(data_cal)[12:38]
air_pollutants_vec

disease_vec <- names(data_cal)[39:44]
disease_vec

soecon_vec <- names(data_cal)[45:57]
soecon_vec

#' 
#' # EDA
#' 
#' ## EDA for Pollution factors
## ----------------------------------------------------------------------
#histograms for the air pollution factors
hist(data_cal$Ozone, main='Histogram of state-level Ozone concentration in the air' )

hist(data_cal$PM2.5, main='Histogram of state-level PM 2.5 concentration in the air' )

hist(data_cal$DieselPM, main='Histogram of state-level Diesel Particle concentration in the air' )

hist(data_cal$Pesticides, main='Histogram of state-level Pesticides concentration in the air' )

hist(data_cal$Tox.Release, main='Histogram of state-level Toxin concentration in the air' )


pairs(Asthma ~ Ozone + PM2.5 + DieselPM + Pesticides + Tox.Release , dat = data_cal)

#' 
#' # for other diseases
#' 
## ----------------------------------------------------------------------
#histograms for the other diseases factors
hist(data_cal$Asthma, main='Histogram of state-level Asthma rate(age-adjusted)' )

hist(data_cal$LowBirthWeight, main='Histogram of Low Birth Weight Prevalence' )

hist(data_cal$CardiovascularDisease, main='Histogram of state-level Cardiovascular Diseases Prevalence' )


pairs(Asthma ~ LowBirthWeight + CardiovascularDisease , dat = data_cal)

#' 
#' 
#' #for socioeconomic factors
## ----------------------------------------------------------------------
pairs(Asthma ~ Education + LinguisticIsolation + Poverty + Unemployment + HousingBurden, dat = data_cal)
#pairs(Pop.Char.~ Education + LinguisticIsolation + Poverty + Unemployment + HousingBurden, dat = data_cal)

#' 
#' 
## ----------------------------------------------------------------------
#forward selection
require(broom)
data_cal1 <- na.omit(data_cal)
data_cal_old <- data_cal1
#forward selection procedure using AIC values 
lm1 <- lm(Asthma ~ 1, data=data_cal1)
stepModel <- step(lm1, direction="forward",
scope=(~ Ozone + PM2.5 + DieselPM+ DrinkingWater+Pesticides+Tox.Release+Traffic +CleanupSites + GroundwaterThreats+ Haz.Waste + Imp.WaterBodies + 
SolidWaste + Education+LinguisticIsolation+Poverty+Unemployment+HousingBurden+ LowBirthWeight+CardiovascularDisease), data=data_cal1)


#' The desired model: 
#' Asthma ~ CardiovascularDisease + Poverty + Ozone + LowBirthWeight + 
#'     LinguisticIsolation + DieselPM + DrinkingWater + Unemployment + 
#'     GroundwaterThreats + Tox.Release + PM2.5 + CleanupSites + 
#'     PollutionBurden + Imp.WaterBodies + HousingBurden + Traffic + 
#'     Pesticides + Haz.Waste
#'     
## ----------------------------------------------------------------------
#stepwise selection
lm_stepwise <- lm(Asthma ~ Ozone + PM2.5 + DieselPM+ DrinkingWater+Pesticides+Tox.Release+Traffic +CleanupSites + GroundwaterThreats+ Haz.Waste + Imp.WaterBodies + 
SolidWaste + PollutionBurden + Education+LinguisticIsolation+Poverty+Unemployment+HousingBurden+LowBirthWeight+CardiovascularDisease, data=data_cal1)
stepModel <- step(lm_stepwise, direction="both")

#' 
#' The stepwise model selection method and forward selection method outputs match each other. Combined with our subject matter knowledge, we will proceed with modeling using the following covariates: Ozone + PM2.5 + DieselPM + DrinkingWater + Pesticides + 
#'     Tox.Release + Traffic + CleanupSites + GroundwaterThreats + 
#'     Haz.Waste + Imp.WaterBodies + PollutionBurden + LinguisticIsolation + 
#'     Poverty + Unemployment + HousingBurden + LowBirthWeight + 
#'     CardiovascularDisease
#' 
#' #### Missing Data
## ----------------------------------------------------------------------
#check for missing data
anyNA(data_cal)
colnames(data_cal)[colSums(is.na(data_cal)) > 0]
sum(is.na(data_cal$PM2.5))

#' covariates with missing data: CES 3.0 Score, PM2.5, DrinkingWater, Traffic, LowBirthWeight, Education, LinguisticIsolation, Poverty, Unemployment, HousingBurden, Population characteristics.
## ----------------------------------------------------------------------
#look at rows with missing data
dat_NA <- data_cal[!complete.cases(data_cal), ]
rowSums(is.na(dat_NA))
#look at missing pattern
library(ggmice)
dat <- data_cal[,c("Asthma", "Ozone", "PM2.5", "DieselPM","Poverty", "Unemployment",  "LowBirthWeight")]
plot_pattern(dat)

## ----------------------------------------------------------------------
#Attempt Multivariate Imputation
library(mice)
tempData = mice(dat, m = 5, maxit = 10, seed = 210)
summary(tempData)
#complete(tempData,action=1)

## ----------------------------------------------------------------------
lm_pureLinear = lm(AsthmaPctl ~ Ozone + PM2.5 + DieselPM + DrinkingWater + Pesticides + Tox.Release + Traffic + CleanupSites + GroundwaterThreats + Haz.Waste + Imp.WaterBodies + PollutionBurden + LinguisticIsolation + Poverty + Unemployment + HousingBurden + LowBirthWeight + CardiovascularDisease, data=data_cal1)
summary(lm_pureLinear)
confint(lm_pureLinear)
#Evaluation for this simple linear model
plot(lm_pureLinear)

#' This simple linear model is unsatisfactory. We can see from the plot of Residuals vs. Fitted that there's fanning trend, no equal variance above and below the line. The QQ-plot also shows non-normality with clear deviation from the diagonal line on both ends of the fitted curve.
#' 
#' - pesticides, traffic, hazard waste are not statistically significant. We may consider removing these covariates.
#' 
#' - Housing burden as a lower significance level (higher p-value) compared to other covariates may consider removing it from linear model as well.
#' 
#' 
## ----------------------------------------------------------------------
#remove coefficients with lower significance level, include only if coefficients are coded "***" significant
lm_rmSig = lm(AsthmaPctl ~ Ozone + PM2.5 + DieselPM + DrinkingWater + Tox.Release + CleanupSites + GroundwaterThreats + Imp.WaterBodies + PollutionBurden + LinguisticIsolation + Poverty + Unemployment + LowBirthWeight + CardiovascularDisease, data=data_cal1)
summary(lm_rmSig)
confint(lm_rmSig)
#Evaluation for this simple linear model
plot(lm_rmSig)

#' 
## ----------------------------------------------------------------------
#leave coefficients with significant level <2e-16
lm_highSig = lm(AsthmaPctl ~ Ozone + PM2.5 + DieselPM + DrinkingWater + LinguisticIsolation + Poverty + Unemployment + LowBirthWeight + CardiovascularDisease, data=data_cal1)
summary(lm_highSig)
confint(lm_highSig)
#Evaluation for this simple linear model
plot(lm_highSig)

#' 
#' #### Modeling
## ----------------------------------------------------------------------
#vector of covariates of interest
vec_cov <- c("Ozone", "PM2.5", "DieselPM", "LinguisticIsolation", "Poverty", "Unemployment", "LowBirthWeight")

#model with only covariates of interest
data_cal <- data_cal[,c("CensusTract", "TotalPopulation", "CaliforniaCounty", "ZIP", "NearbyCity(tohelpapproximatelocationonly)", "Longitude", "Latitude", "Ozone", "PM2.5", "DieselPM", "Asthma","AsthmaPctl", "LowBirthWeight","LinguisticIsolation", "Poverty", "Unemployment" )]
data_cal1 <- na.omit(data_cal)

#check proportion of missing values
sum(!complete.cases(data_cal))/nrow(data_cal)

#' 
#' 
#' ##### Linear, additive, or other models (LASSO, ridge)
## ----------------------------------------------------------------------
library(glmnet)
library(vip)
#define outcome variable
y <- data_cal1[,"AsthmaPctl"] |> as.matrix()
#define matrix of predictor variables
x <- data_cal1[, c("Ozone", "PM2.5", "DieselPM", "LinguisticIsolation",  "Poverty", "Unemployment", "LowBirthWeight")] |> as.matrix()
elasticnet.mod = glmnet(x,y,alpha=0.5,family="gaussian")
vip(elasticnet.mod, num_features=10, geom = "point")
#now we look at the Variable importance (vip) for factors excluding Ozone
x_noOzone <- data_cal1[, c("PM2.5", "DieselPM", "LinguisticIsolation",  "Poverty", "Unemployment", "LowBirthWeight")] |> as.matrix()
elasticnet.mod.noOzone = glmnet(x_noOzone,y,alpha=0.5,family="gaussian")
vip(elasticnet.mod.noOzone, num_features=10, geom = "point")


#' 
## ----------------------------------------------------------------------
#linear model with all linear terms for 7 covariates of interest
lm_7linear = lm(AsthmaPctl ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + Poverty + Unemployment + LowBirthWeight, data=data_cal1)
summary(lm_7linear)
plot(lm_7linear)

#' 
## ----------------------------------------------------------------------
library(splines2)
library(foreign)
library(gam)
library(Hmisc)
#add spline term to every term with significance level <2e-16 & PM2.5
model_spline=lm(AsthmaPctl ~ bSpline(Ozone,df=4) + bSpline(PM2.5, df=4) + bSpline(DieselPM, df=4) + bSpline(LinguisticIsolation, df=4) + bSpline(Poverty, df=4) + bSpline(Unemployment, df=4) + bSpline(LowBirthWeight, df=4), data=data_cal1)
summary(model_spline)
#model evaluation
plot(model_spline)

#' 
## ----------------------------------------------------------------------
#Ridge
library(dplyr)
library(MASS)
fit = lm.ridge(AsthmaPctl ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + Poverty + Unemployment + LowBirthWeight, data_cal1, lambda = seq(0, .4, 1e-3))
#view summary of model
summary(fit)

#' 
#' More flexible modeling:
## ----------------------------------------------------------------------
#interaction terms
lm_interAir = lm(AsthmaPctl ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + Poverty + Unemployment + LowBirthWeight + Ozone*PM2.5, data=data_cal1)
lm_interDiesel = lm(AsthmaPctl ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + Poverty + Unemployment + LowBirthWeight + Ozone*DieselPM, data=data_cal1)
lm_interLing = lm(AsthmaPctl ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + Poverty + Unemployment + LowBirthWeight + Ozone*LinguisticIsolation, data=data_cal1)
lm_interPov = lm(AsthmaPctl ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + Poverty + Unemployment + LowBirthWeight + Ozone*Poverty, data=data_cal1)
lm_interEmp = lm(AsthmaPctl ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + Poverty + Unemployment + LowBirthWeight + Ozone*Unemployment, data=data_cal1)
lm_interWgt = lm(AsthmaPctl ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + Poverty + Unemployment + LowBirthWeight + Ozone*LowBirthWeight, data=data_cal1)
lm_interSoc = lm(AsthmaPctl ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + Poverty + Unemployment + LowBirthWeight + Poverty*Unemployment, data=data_cal1)

#quadratic terms
lm_quadOzone = lm(AsthmaPctl ~ Ozone + I(Ozone)^2+PM2.5 + DieselPM + LinguisticIsolation + Poverty + Unemployment + LowBirthWeight, data=data_cal1)
lm_quadWgt = lm(AsthmaPctl ~ Ozone + I(LowBirthWeight)^2 + PM2.5 + DieselPM + LinguisticIsolation + Poverty + Unemployment + LowBirthWeight, data=data_cal1)

#' 
#' Model comparison:
## ----------------------------------------------------------------------
mods_linear <- list(lm_7linear, model_spline, lm_interWgt, lm_interEmp, lm_interPov, lm_interLing, lm_interDiesel, lm_interSoc, lm_interAir, lm_quadOzone, lm_quadWgt)
mod_names <- c("7Linear", "spline", "interWgt", "interEmp", "interPov", "interLing", "interDiesel", "internSoc", "interAir", "quadOzon", "quadWgt")

library(AICcmodavg)
aictab(cand.set = mods_linear, modnames = mod_names)

r_square <- c(summary(lm_7linear)$adj.r.squared, summary(model_spline)$adj.r.squared, summary(lm_interWgt)$adj.r.squared, summary(lm_interEmp)$adj.r.squared, summary(lm_interPov)$adj.r.squared, summary(lm_interLing)$adj.r.squared, summary(lm_interDiesel)$adj.r.squared, summary(lm_interSoc)$adj.r.squared, summary(lm_interAir)$adj.r.squared, summary(lm_quadOzone)$adj.r.squared, summary(lm_quadWgt)$adj.r.squared)
cbind(mod_names,r_square)

f_score <- c(summary(lm_7linear)$fstatistic[1], summary(model_spline)$fstatistic[1], summary(lm_interWgt)$fstatistic[1], summary(lm_interEmp)$fstatistic[1], summary(lm_interPov)$fstatistic[1], summary(lm_interLing)$fstatistic[1], summary(lm_interDiesel)$fstatistic[1], summary(lm_interSoc)$fstatistic[1], summary(lm_interAir)$fstatistic[1], summary(lm_quadOzone)$fstatistic[1], summary(lm_quadWgt)$fstatistic[1])
cbind(mod_names, f_score)

#' Further interpretation of lm_interAir
## ----------------------------------------------------------------------
summary(lm_interAir)
plot(lm_interAir)

#' 
#' 
#' 
#' ##### Poisson
## ----------------------------------------------------------------------

library(dplyr)
library(tidyverse)
#round the Asthma rate to make sure that it's integers
dataint <- data_cal_old |> mutate(Asthma = round(Asthma))

mod.poisson.full <- glm(Asthma ~ Ozone + PM2.5 + DieselPM + DrinkingWater + Pesticides + 
    Tox.Release + Traffic + CleanupSites + GroundwaterThreats + 
    Haz.Waste + Imp.WaterBodies + PollutionBurden + LinguisticIsolation + 
    Poverty + Unemployment + HousingBurden + LowBirthWeight + 
    CardiovascularDisease, data=dataint, family=quasipoisson)
summary(mod.poisson.full)


sort(coef(mod.poisson.full) , decreasing = TRUE)
plot(mod.poisson.full)


#' 
#' 
#' 
#' From the summary statistics of the full model, the Cardiovascular Disease, Low Birth Weight and PM 2.5 are the three major contributors to Asthma rate, using Poisson models. 
#' While Ozone is the factor that is negatively correlated with Asthma rate, as is shown in the linear model. 
#' 
#' Since pesticides, traffic, Haz.waste, Imp.WaterBodies, PollutionBurden and Housing burden variables have both relatively lower p-values and small 
#' Since drinking water, cleanup sites and Ground Water threats have relatively very low coefficients, we exclude their effects for the next round of analysis.  
#' 
#' Thus, what we keep for the next round of analysis are 8 variables: PM2.5, Ozone, DieselPM, Unemployment, Poverty, Linguistic Isolation, Low Birth Weight and Cardiovascular Diseases.
#' 
#' 
#' 
#' checking for dispersion:
#' 
## ----------------------------------------------------------------------
deviance(mod.poisson.full)/mod.poisson.full$df.residual

#' Since the quotient is greater than 1, 
#' There exists some form of overdispersion in the data.
#' 
#' First, we look at the model with the air pollution factors:
#' We want to approximate the effects of Pmm 2.5 and Asthma
## ----------------------------------------------------------------------
mod.p_base <- glm(Asthma ~ PM2.5, data=dataint, family=quasipoisson)
summary(mod.p_base)
exp(coef(mod.p_base)[2])

deviance(mod.p_base)/mod.p_base$df.residual

#' 
#' The model with Pm 2.5 alone has very great overdispersion. 
#' 
#' From the summary statistics: we can see that with every 1 more unit increase in PM 2.5 concentration is estimated to be associated with, on average, 2% increase in the incidence rate of asthma among individuals that live in the counties with the current level of PM2.5 concentration.
#' 
#' 
## ----------------------------------------------------------------------
mod.p_pmd <- glm(Asthma ~ PM2.5 + DieselPM, data=dataint, family=poisson())
summary(mod.p_pmd)
exp(coef(mod.p_pmd)[2])
exp(coef(mod.p_pmd)[3])

#' From the summary statistics: we can see that with every 1 more unit increase in PM 2.5 concentration is estimated to be associated with, on average, 1.3% increase in the incidence rate of asthma among individuals that live in the counties with the current level of PM2.5 concentration.
#' 
#' Diesel is likely a confonder for the effects of PM 2.5, because dieselPM contributes to a portion of PM 2.5, while the total PM2.5 amount doesn't directly lead to DieselPM. 
#' The changes in coefficient of PM 2.5:
#' (0.02-0.013)/0.013 = 53.8% > 10%
#' Thus, diesel PM satisfies the confounding effect. 
#' 
#' Then we test the effect modifying of DieselPM:
#' The interaction terms has a p-value below the significant threshold. SO we can conclude that it is an effect modifier of PM 2.5. 
## ----------------------------------------------------------------------
mod.p_pmdinter <- glm(Asthma ~ PM2.5 * DieselPM, data=dataint, family=poisson())
summary(mod.p_pmdinter)
exp(coef(mod.p_pmdinter)[2])
exp(coef(mod.p_pmdinter)[3])

#' 
#' 
#' Checking for Pm 2.5 + Ozone as the predictor
#' 
#' 
## ----------------------------------------------------------------------
mod.p_ozone <- glm(Asthma ~ PM2.5 + Ozone, data=dataint, family=poisson())
summary(mod.p_ozone)
exp(coef(mod.p_ozone)[2])
exp(coef(mod.p_ozone)[3])

#' From the summary statistics: we can see that with every 1 more unit increase in ozone concentration is estimated to be associated with, on average, 600% increase in the incidence rate of asthma among individuals that live in the counties with the current level of ozone concentration, holding PM 2.5 constant
#' 
#' Something to note: Ozone showed a very significant positive association with Asthma rate when modeled with Asthma rate alone, but showed negative association in the full model, which is open for later discussion and examinations. 
#' 
#' 
#' Testing whether we can use low birth weight as predictors for Asthma rate:
## ----------------------------------------------------------------------

#coef(mod.p_ozone)
mod.p_diseases <- glm(Asthma ~ LowBirthWeight, data=dataint, family=quasipoisson)
summary(mod.p_diseases)
exp(coef(mod.p_diseases)[2])
#exp(coef(mod.p_diseases)[3])

summary(mod.p_diseases)$dispersion

#' 
#' With every 1 unit increase in percent of population with Low Birth Weight, is estimated to be associated with, on average,13% increase in the incidence rate of asthma among individuals.
#' 
#' Testing whether socioeconomic factors can be prediction factors for Asthma. 
## ----------------------------------------------------------------------
mod.p_soecon <- glm(Asthma ~ Poverty + Unemployment + LinguisticIsolation, data=dataint, family=poisson())
summary(mod.p_soecon)

#' poverty and unemployment both demonstrated positive relationship with Asthma, while linguistic isolation demonstrated negative relationship with Asthma. 
#' 
## ----------------------------------------------------------------------
mod.poisson.sim <- glm(Asthma ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + 
    Poverty + Unemployment+ LowBirthWeight, data=dataint, family=quasipoisson)
summary(mod.poisson.sim)


#' 
#' 
## ----------------------------------------------------------------------
summary(mod.poisson.sim)$dispersion
summary(mod.poisson.full)$dispersion
anova(mod.poisson.full,mod.poisson.sim, test ='Chisq')

#' 
#' 
#' Next, incoporating the quadratic terms of PM2.5, Diesel PM, Ozone into the model:
#' 
#' Hypothesis testing: comparing the linear simple model with the 8 variables, to the model that has the quadratic terms of the three environmental factors PM 2.5, Ozone and DieselPM.
#' 
#' Hypothesis H0: this new model is better in terms of predicting the Asthma compared to the simple model
#' 
#' 
## ----------------------------------------------------------------------

mod.poisson.qua <- glm(Asthma ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + 
    Poverty + Unemployment+ LowBirthWeight  + I(Ozone^2) + I(PM2.5^2) + I(DieselPM ^2), data=dataint, family=quasipoisson)
summary(mod.poisson.qua)

anova(mod.poisson.sim,mod.poisson.qua, test ='Chisq')

#' 
#' 
#' Since the p-value is lower than zero, it's sufficient for us to reject the null hypothesis. Thus, the model with quadratic terms is better in predicting Asthma rate, as compared to the simple model. 
#' 
#' Examining the effects of interactionterms between PM 2.5 and DieselPM:
## ----------------------------------------------------------------------
mod.poisson.qua1 <- glm(Asthma ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + 
    Poverty + Unemployment+ LowBirthWeight  + I(Ozone^2) + I(PM2.5^2) + I(DieselPM ^2) + PM2.5*DieselPM, data=dataint, family=quasipoisson)
summary(mod.poisson.qua1)


#' The interaction term of PM2.5 and DieselPM does not have a p-value as significant as the other terms, butthe chisq test betweeb the model with the interaction vs not has a p-value under the significance leve, which indicates that it's not sufficient to reject the null hypothesis that the interaction term is significant in terms of predicting the Asthma rate .
#' 
## ----------------------------------------------------------------------
anova(mod.poisson.qua,mod.poisson.qua1, test ='Chisq')

#' 
#' Check for overdispersion:
## ----------------------------------------------------------------------
summary(mod.poisson.qua)$dispersion
summary(mod.poisson.qua1)$dispersion
summary(mod.poisson.sim)$dispersion

#' The quadratic model has smaller overdispersion quotient than the linear model, which indicates that it has better goodness of fit. 
#' 
#' Next: to remedy for the overdispersion effects, we consider incorporating the negative binomial model: 
#' 
## ----------------------------------------------------------------------
nbin1 <- MASS::glm.nb(Asthma ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + 
    Poverty + Unemployment+ LowBirthWeight +  I(Ozone^2) + I(PM2.5^2) + I(DieselPM ^2) + PM2.5 * DieselPM, data = dataint)
summary(nbin1)

## ----------------------------------------------------------------------
summary(nbin1)$dispersion

#' The negative binomial model has dispersion quotient of 1, and all the terms are statistically significant with p-values much smaller than the 0.05 threshold. Thus, it's a desirable model at this step. 
#' 
#' 
#' Multinomial Regression Testing:
#' 
## ----------------------------------------------------------------------
#multinomial regression
data_cal <- data_cal %>% mutate(asthma_cat = case_when(
  AsthmaPctl <=25 ~ 1,
  AsthmaPctl <=50 ~ 2,
  AsthmaPctl <=75 ~ 3,
  AsthmaPctl <=100 ~ 4
))

summ.MNfit <- function(fit, digits=3){
  s <- summary(fit)
  for(i in 2:length(fit$lev)) {
##
cat("\nLevel", fit$lev[i], "vs. Level", fit$lev[1], "\n")
##
betaHat <- s$coefficients[(i-1),]
se <- s$standard.errors[(i-1),]
zStat <- betaHat / se
pval <- 2 * pnorm(abs(zStat), lower.tail=FALSE)
##
RRR <- exp(betaHat)
RRR.lower <- exp(betaHat - qnorm(0.975)*se)
RRR.upper <- exp(betaHat + qnorm(0.975)*se)
##
results <- cbind(betaHat, se, pval, RRR, RRR.lower, RRR.upper)
print(round(results, digits=digits))
}
}

mod.multi <- multinom(asthma_cat ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + 
    Poverty + Unemployment + LowBirthWeight, data=data_cal)

summ.MNfit(mod.multi)

mod.ord <- vglm(asthma_cat ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + 
    Poverty + Unemployment + LowBirthWeight, cumulative(parallel=TRUE, reverse=TRUE),data=data_cal)

summary(mod.ord)

mod.ord.npo <- vglm(asthma_cat ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + Poverty + Unemployment + LowBirthWeight, cumulative(parallel=FALSE, reverse=TRUE),data=data_cal)

pchisq(deviance(mod.ord)-deviance(mod.ord.npo), df=df.residual(mod.ord)-df.residual(mod.ord.npo),lower.tail=F)
#proportional odds does not hold --> use multinomial
y

#Predicted value-----------------------------
mod.final <- glm.nb(Asthma ~ Ozone + PM2.5 + DieselPM + LinguisticIsolation + 
                          Poverty + Unemployment+ LowBirthWeight  + I(Ozone^2) + PM2.5*Ozone, data=dataint)
summary(mod.final)
plot(mod.final)

#pm
predict.pm.data <- data.frame(PM2.5 = seq(from = min(dataint$PM2.5), 
                                          to = max(dataint$PM2.5), length.out = 100),
                              Ozone = mean(dataint$Ozone), DieselPM = mean(dataint$DieselPM), 
                              LinguisticIsolation = mean(dataint$LinguisticIsolation), 
                              Poverty = mean(dataint$Poverty), Unemployment = mean(dataint$Unemployment), 
                              LowBirthWeight = mean(dataint$LowBirthWeight))

predict.pm.data <- cbind(predict.pm.data, predict(mod.final, predict.pm.data, type = "link", se.fit = TRUE))
predict.pm.data <- within(predict.pm.data, {
  AsthmaRate <- exp(fit)
  LL <- exp(fit - 1.96*se.fit)
  UL <- exp(fit + 1.96*se.fit)
})
predit.pm.data <- predict.pm.data[order(predict.pm.data$PM2.5),]

ggplot(predict.pm.data, aes(PM2.5, AsthmaRate)) +
  geom_ribbon(aes(ymin = LL, ymax = UL), alpha = .25) +
  geom_line(size = 2) + 
  labs(x = "Annual Mean PM2.5 Concentration", y = "Age-adjusted Rate of Asthma-Related ED Visits by Census Tract")

#ggsave("Predicted PM.png")

#ozone
predict.ozone.data <- data.frame(Ozone = seq(from = min(dataint$Ozone), 
                                          to = max(dataint$Ozone), length.out = 100),
                              PM2.5 = mean(dataint$PM2.5), DieselPM = mean(dataint$DieselPM), 
                              LinguisticIsolation = mean(dataint$LinguisticIsolation), 
                              Poverty = mean(dataint$Poverty), Unemployment = mean(dataint$Unemployment), 
                              LowBirthWeight = mean(dataint$LowBirthWeight))


predict.ozone.data <- cbind(predict.ozone.data, predict(mod.final, predict.ozone.data, type = "link", se.fit = TRUE))
predict.ozone.data <- within(predict.ozone.data, {
  AsthmaRate <- exp(fit)
  LL <- exp(fit - 1.96*se.fit)
  UL <- exp(fit + 1.96*se.fit)
})

ggplot(predict.ozone.data, aes(Ozone, AsthmaRate)) +
  geom_ribbon(aes(ymin = LL, ymax = UL), alpha = .25) +
  geom_line(size = 2) + 
  labs(x = "Maximum Daily 8-hr Ozone Concentration", y = "Age-adjusted Rate of Asthma-Related ED Visits by Census Tract")

#ggsave("Predicted Ozone.png")

#three dimensional plot
predict.observed.data <- data.frame(PM2.5 = dataint$PM2.5,
                              Ozone = dataint$Ozone, DieselPM = mean(dataint$DieselPM), 
                              LinguisticIsolation = mean(dataint$LinguisticIsolation), 
                              Poverty = mean(dataint$Poverty), Unemployment = mean(dataint$Unemployment), 
                              LowBirthWeight = mean(dataint$LowBirthWeight))
predict.observed.data <- cbind(predict.observed.data, predict(mod.final, predict.observed.data, type = "link", se.fit = TRUE))
predict.observed.data <- within(predict.observed.data, {
  AsthmaRate <- exp(fit)
  LL <- exp(fit - 1.96*se.fit)
  UL <- exp(fit + 1.96*se.fit)
})

predicted_matrix <- predict.observed.data %>% dplyr::select(Ozone, PM2.5, AsthmaRate) %>% as.matrix
predicted_tibble <- as_tibble(predicted_matrix)

fig2 <- plot_ly() %>% 
  add_trace(data = predicted_tibble,  x=predicted_tibble$Ozone, y=predicted_tibble$PM2.5, 
            z=predicted_tibble$AsthmaRate, type="mesh3d", color = ~AsthmaRate) 
axx <- list(title = "Ozone")
axy <- list(title = "PM2.5 ")
axz <- list(title = "Predicted Asthma Rate")
fig2 %>% layout(scene = list(xaxis=axx,yaxis=axy,zaxis=axz))
