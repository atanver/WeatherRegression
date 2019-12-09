proc import datafile="S:\DAR\PROJECT\randomWeather.csv" out=weather replace;
delimiter=',';
getnames=yes;
run;
*proc print;
*run;

*Summary PrecipType Temperature ApparentTemperature Humidity WindSpeed WindBearing Visibility Pressure;

data weather;
set weather;
drop FormattedDate;
drop CloudCover;
drop DailySummary;
dpt = (PrecipType = 'rain'); 
dpc = (Summary = 'Partly Cloudy');
dmc = (Summary = 'Mostly Cloudy');
do = (Summary = 'Overcast');
df = (Summary = 'Foggy');
run;
*proc print;
*run;

title "TEMP Descriptives";
proc means min p25 p50 p75 max mean std stderr clm;
var Temperature;
run;

title "TEMP DISTRIBUTION";
proc univariate normal;
var Temperature;
histogram/normal (mu=est sigma=est);
run;

title "TEMP VS. ALL SCATTERPLOTS";
proc sgscatter;
matrix dpt dpc dmc do df Temperature ApparentTemperature Humidity WindSpeed WindBearing Visibility Pressure;
run;

Title "TEMP CORR";
proc corr;
run;

Title "FULL MODEL - TEMP REGRESSION";
proc reg;
model Temperature =  dpt dpc dmc do df ApparentTemperature Humidity WindSpeed WindBearing Visibility Pressure/vif;
run;
quit;

proc surveyselect data = weather out = train_test_weather seed = 678456 samprate = 0.80 outall;
run;

data train_test_weather;
set train_test_weather;
if (selected = 1) then train_y = Temperature;
run;

*proc print data = train_test_weather;
*run;

title "Full Model - training set";
proc reg data=train_test_weather;
model train_y =  dpt dpc dmc do df ApparentTemperature Humidity WindSpeed WindBearing Visibility Pressure/ stb vif;
run;
quit;

title "BACKWARD SELECTION Full Model - training set";
proc reg data=train_test_weather;
model train_y =  dpt dpc dmc do df ApparentTemperature Humidity WindSpeed WindBearing Visibility Pressure/selection=backward;
run;
quit;
*USE BACKWARD SELECTION FOR FINAL MODEL;

title "STEPWISE SELECTION Full Model - training set";
proc reg data=train_test_weather;
model train_y =  dpt dpc dmc do df ApparentTemperature Humidity WindSpeed WindBearing Visibility Pressure/selection=stepwise;
run;
quit;


title "Final Model Backward selection- training set";
proc reg data=train_test_weather;
model train_y = dmc do df ApparentTemperature Humidity WindSpeed WindBearing Pressure/stb vif influence r;
run;
quit;

*outliers: 1024, 187;
data train_test_weather;
set train_test_weather;
if _n_ = 187 then delete;
if _n_ = 1024 then delete;
run;

title "Final Model with IO drop- training set";
proc reg data=train_test_weather;
model train_y = dmc do df ApparentTemperature Humidity WindSpeed WindBearing Pressure/stb vif influence r;
plot student.*(dmc do df ApparentTemperature Humidity WindSpeed WindBearing Pressure predicted.);
plot npp.*student.;
run;
quit;

title '5-fold cross validation';
proc glmselect data=weather
plots = (asePlot Criteria);
partition fraction (test = .25);
model Temperature = dmc do df ApparentTemperature Humidity WindSpeed WindBearing Pressure / selection = backward (stop=CV) cvmethod =
split (5) cvdetails = all;
run;

data pred;
input dmc do df ApparentTemperature Humidity WindSpeed WindBearing Pressure;
*11.183, 8.961, 10.911;
datalines;
1 0 0 11.183 0.8 10.8192 163 1008.71
0 1 0 5.777 0.93 23.2162 340 1004.85
0 0 1 10.911 0.86 22.3951 311 1004.61
;
*title 'Predictions data';
*proc print data=pred;
*run;

data prediction;
set pred weather;
run;

/*proc print data=prediction;
	title2 'Predicted Probabilities & 95% Confidence Limits';
run;*/

title 'Predictions regression';
proc reg corr data=prediction;
model Temperature = dmc do df ApparentTemperature Humidity WindSpeed WindBearing Pressure/ p clm cli;
run;
quit;


