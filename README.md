
# Asthma Environmental Analysis
I think the california screening dataset's perfect for analysis :) over 8000 rows, with Asthma rate and Cardiovascular prevalence
and lots of air pollution factors and 6 socioeconomic factors

need to change: 1. from 51 states to 1 state with lots of zip codes. Maybe  use zip codes as the identifier


need to ask in OH: HOW DO WE DEAL WITH THE NAs
There are at most 200ish NAs in one of the columns 
and 100ish NAs for a few other columns
In forward selection model these NAs have to be removed


(the AIC is pretty big thou)
The desired model: 
The desired model: 
Asthma ~ CardiovascularDisease + Poverty + Ozone + LowBirthWeight + 
    LinguisticIsolation + DieselPM + DrinkingWater + Unemployment + 
    GroundwaterThreats + Tox.Release + PM2.5 + CleanupSites + 
    PollutionBurden + Imp.WaterBodies + HousingBurden + Traffic + 
    Pesticides + Haz.Waste
   
    
    
