/*Project_5605*/
OPTIONS MPRINT MLOGIC SYMBOLGEN;
goptions reset=all;
%let path=C:\Users\Jeff Liu\Desktop\STAT-5605-Applied Statistics II\Project;
libname project "&path";


/*Infile crime raw data*/
data project.crime;
 infile "&path\ucr-crime-index2017.csv" dsd firstobs=2 MISSOVER;
 informat Town $20.;
 informat Year 4.;
 informat Crime_Type $20.;
 informat Measure_Type $30.;
 input    Town  
		  Year  
	      Crime_Type $ 
		  Measure_Type $
	      Value ; 
run;

/*violent crime*/
data project.vc;
	set project.crime;
	if Crime_Type= "Total Violent Crime";
	if Measure_Type="Rate (per 100,000)";
	if year in ("2016" "2017") then delete;
 	if town="Connecticut" then delete;
	drop Measure_Type Crime_Type;
	rename Value=Violent_crime_rate;
run;
proc sort data=project.vc;
	by town;
run;
/*property crime*/
data project.pc;
	set project.crime;
	if Crime_Type= "Total Property Crime";
	if Measure_Type="Rate (per 100,000)";
	if year in ("2016" "2017") then delete;
 	if town="Connecticut" then delete;
	drop Measure_Type Crime_Type;
	rename Value=Property_crime_rate;
run;
proc print data=project.pc(obs=5);run;
PROC SORT DATA=PROJECT.PC;
	BY TOWN;
RUN;

/*Final crime data */

data project.final_crime;
	merge project.pc project.vc;
	by town;
proc print data=project.final_crime(obs=5);
run;

%macro SETCODE(SOURCE=,data=,first=,last=);
	%local year ;
	%do year=&first %to &last;
			data &data&year;
				set &SOURCE ;
				where Year=&year;
			run;
	%end;
		
%mend SETCODE;

%SETCODE(SOURCE=project.final_crime,data=CRIME,first=2010,last=2015)

/*Combine CRIME data */
data project.final_crime ;
	set crime2010-crime2015 ;
	by town;
	year_n=put(year,4.);
	rename year_n=year;
	rename value=Crime_num;
	drop year ;
run;
/*Infile household income Data*/
/*https://portal.ct.gov/DECD/Content/About_DECD/Research-and-Publications/01_Access-Research/Exports-and-Housing-and-Income-Data*/
%macro readraw(data=,first=,last=,firstobs=);
	%local year ;
	%do year=&first %to &last;

			data housholdinc&year;
				infile "&data&year..csv" firstobs=&firstobs dsd missover;
				informat Town $20.;
	 			input 	   Town : $ 
						   Median_household_income ;
				year="&year";	
			run;
			
			proc print data=housholdinc&year;
				title "Household Income for &year";	
			run;
		%end;
%mend readraw;
%readraw(data=C:\Users\Jeff Liu\Desktop\STAT-5605-Applied Statistics II\Project\houinco,first=2010,last=2015,firstobs=2)
%macro sorting(data=,first=,last=,by=);
	%local year ;
	%do year=&first %to &last;

		proc sort data= &data&year;
			by &by;
		run;
	%end;
%mend sorting;

%sorting(data=housholdinc,first=2010,last=2015,by=town)

data project.housinco;
	set housholdinc2010-housholdinc2015;
	by town;
run;

proc sort data=project.final_crime;
	by town;
run;

data project.crime_hous;
	merge project.final_crime project.housinco;
	by town;
run;

data project.pop;
	infile "&path/ProjectX3X7X8.csv" dsd firstobs=2 MISSOVER;
	informat town $15.;
	informat CityType $15.;
	input	 town $	
			 Year $	
			 CityType $	
			 Population	
  			 BirthsRate	
			 DeathsRate;
run;
proc sort data=project.pop;
	by town;
run;

Data project.pop_crime_hous;
	merge project.pop project.crime_hous;
	by town;
run;
	
data project.millrate;
	infile "&path/millrate.csv" dsd missover firstobs=2;
	informat town $20.;
	informat year $20.;
	input Town $ Year $ Mill_Rate;
	if year="SFY 2009-2010" then  year="2010";
	if year="SFY 2010-2011" then  year="2011";
	if year="SFY 2011-2012" then  year="2012";
	if year="SFY 2012-2013" then  year="2013";
	if year="SFY 2013-2014" then  year="2014";
	if year="SFY 2014-2015" then  year="2015";
run;

proc sort data= project.millrate;
	by town;
run;
data project.com_mi_pop;
	merge project.pop_crime_hous project.millrate;
	by town;
proc print; run;

/*Median of housing price from 2010-2015 by town*/
data project.HOUSING_PRICE;
	infile "&path/2010to2015Medians.csv" dsd missover firstobs=2;
	informat town $20.;
	input  Year $ Town $ HOUSING_PRICE;
RUN;
/*Assessed_Value_Medians*/
DATA project.assessed_value;
	infile "&path/2010to2015MedianAssess.csv" dsd missover firstobs=2;
	informat town $20.;
	input  Year $ Town $ Assessed_Value_Medians;
RUN;
proc sort data=project.assessed_value;
	by town;
run;
proc sort data=project.HOUSING_PRICE;
	by town;
run;


/*Final Dataset*/

data project.final_data;
	merge project.com_mi_pop project.HOUSING_PRICE project.assessed_value;
	by town;
	property_tax=Assessed_Value_Medians*Mill_Rate*0.001;
	price_log=log(HOUSING_PRICE);
	if year="2010" then year_n=0;
	if year="2011" then year_n=1;
	if year="2012" then year_n=2;
	if year="2013" then year_n=3;
	if year="2014" then year_n=4;
	if year="2015" then year_n=5;

	if citytype="Town"      then citytype_n=0;
	if citytype="LargeTown" then citytype_n=1;
	if citytype="City"      then citytype_n=2;

	rename year_n=year;
	rename citytype_n=citytype;
	drop Mill_Rate  Assessed_Value_Medians year CityType;
run;

proc export data=project.final_data
   outfile="&path\Finaldata.csv"
   dbms=csv
   replace;
run;
/*Modeling Selection*/
ods rtf file="&path\Modeling Selection.rtf";
proc glmselect data=training plots=all;
     model  price_LOG  =							  citytype
										                          Year	
															      Population	
																  BirthsRate	
															      DeathsRate		
																  Median_household_income
										                          property_tax
															      Property_crime_rate
													              Violent_crime_rate 
                     / details=all stats=all selection=lasso;
   run;   
ods rtf close;
/*Suggsted Model:price_log =      Population 
													  BirthsRate 
													  DeathsRate 
													  Property_crime_rate 
													  Violent_crime_rate 
													  Median_household_income 
													  property_tax
													  year 
													 */
/*Comparison*/
/*Model-training set from 2010-2014*/
data training;
	set project.final_data;
	if year  in (0 1 2 3 4);

run;
/*Validation set 2015*/
data Validation;
	set project.final_data;
	if year  in (5);
run;
/*MSPR*/
ods rtf file="&path\Validation set 2015.rtf";
	proc reg  DATA=Validation plots=diagnostics(stats=(GMSEP));
		title "Validation set 2015";
		model price_LOG =   Population 
														  BirthsRate 
														  DeathsRate 
														  Property_crime_rate 
														  Violent_crime_rate 
														  Median_household_income 
														  property_tax
														  year 
														  ; 
	run;
ods rtf close;
/*MSE*/
ods rtf file="&path\Model-training set from 2010-2014.rtf";
	proc reg data=training ;
					title Model-training set from 2010-2014;
					model price_LOG =   Population 
														  BirthsRate 
														  DeathsRate 
														  Property_crime_rate 
														  Violent_crime_rate 
														  Median_household_income 
														  property_tax
														  year 
														 ; 
	run;
ods rtf close;

ods graphics on;



   ods graphics off;
/* Multivariate Scatterplot Matrix */
proc sgscatter data=training;
	title multivariate scatterplot matrix;
	matrix price_log year
															      population	
																  birthsrate	
															      deathsrate		
																  median_household_income
										                          property_tax
															      property_crime_rate
													              violent_crime_rate   ;
run;

proc corr data=training;
		title computes correlations between variables;
		var price_log year
															      population	
																  birthsrate	
															      deathsrate		
																  median_household_income
										                          property_tax
															      property_crime_rate
													              violent_crime_rate   ;
run;
/*final result*/
ods rtf file="&path\final result.rtf";
	proc reg data=training  plots=(diagnostics residuals);
					model price_log =         population 
														  birthsrate 
														  deathsrate 
														  property_crime_rate 
														  violent_crime_rate 
														  median_household_income 
														  property_tax
														  year 
														  
	                                                       / vif;
	run;
ods rtf close;

/*Map*/
proc mapimport datafile = "&path\geo_export_b87b8be0-8f07-49fe-baa9-97ddba13430c.shp" out = mapct;
	select Town;
run;

proc print data = mapct (obs = 50);
run;

proc import
	datafile = "&path\Final_data.csv" dbms = csv replace out = final;
	getnames = yes;
	guessingrows = 100;
	proc print data = final (obs = 50);
run;

proc sort data = final out = final;
	by Year;
run;

proc import
	datafile = "&path\2010to2015MedianAssess.csv" dbms = csv replace out = finala;
	getnames = yes;
run;

proc sort data = finala out = finala;
	by Year;
run;

data finalb;
	merge final finala;
	by Year;
	format Town $254.;
	proc print data = finalb (obs = 5);
run;

data finale;
	set finalb;
	proptax = Mill_Rate*Housing_Price*0.001;
run;

proc sort data = finale out = finalyear;
	by Year;
run;

/*Using Different Crime Rates*/

data totcrimea;
	infile "&path\ucr-crime-index2017.csv" delimiter = ',' dsd firstobs = 2;
	informat Town $254.;
	informat Crime_Type $30.;
	informat Measure_Type $30.;
	input Town Year Crime_Type Measure_Type Value;
	proc print data = totcrimea (obs = 50);
run;

data totalrate;
	set totcrimea;
	if Crime_Type ne 'Total Crime' then delete;
	if Measure_Type ne 'Rate (per 100,000)' then delete;
	if Town = 'Connecticut' then delete;
	if Year > 2015 then delete;
	rename Value = Total_Crime;
	drop Crime_Type Measure_Type;
	proc print data = totalrate (obs = 10);
run;

data violentrate;
	set totcrimea;
	if Crime_Type ne 'Total Violent Crime' then delete;
	if Measure_Type ne 'Rate (per 100,000)' then delete;
	if Town = 'Connecticut' then delete;
	if Year > 2015 then delete;
	rename Value = Total_Violent_Crime;
	drop Crime_Type Measure_Type;
	proc print data = violentrate (obs = 10);
run;

data property;
	set totcrimea;
	if Crime_Type ne 'Total Property Crime' then delete;
	if Measure_Type ne 'Rate (per 100,000)' then delete;
	if Town = 'Connecticut' then delete;
	if Year > 2015 then delete;
	rename Value = Total_Property_Crime;
	drop Crime_Type Measure_Type;
	proc print data = property (obs = 50);
run;

/*Append Crime Rates to Final Data Set*/

proc sort data = violentrate out = viosort;
	by Year;
run;

proc sort data = property out = propsort;
	by Year;
run;

proc sort data = totalrate out = totsort;
	by Year;
run;

data finwcrime;
	merge finalyear viosort;
	by Year;
	proc print data = finwcrime (obs = 5);
run;

data finwcrime;
	merge finwcrime propsort;
	by Year;
	proc print data = finwcrime (obs = 5);
run;

data finwcrime;
	merge finwcrime totsort;
	by Year;
	proc print data = finwcrime (obs = 5);
run;

data fin2014;
	set finwcrime;
	if Year ne 2014 then delete;
run;

ods rtf file = 'Demographic_Map_2014.rtf';

legend1 label = (position = top 'Crime Rate (per 100,000)');

proc gmap data = fin2014 map = mapct;
	title 'Crime Distribution in CT for 2014';
	id town;
	choro Total_Crime/ legend = legend1;
run;

quit;

legend1 label = (position = top 'Median Household Income (in dollars)');

proc gmap data = fin2014 map = mapct;
	title 'Median Household Income Distribution in CT for 2014';
	id town;
	choro Median_household_income/ legend = legend1;
run;

quit;

legend1 label = (position = top 'Housing Price (in dollars)');

proc gmap data = fin2014 map = mapct;
	title 'Housing Price Distribution in CT for 2014';
	id town;
	choro Housing_Price/ legend = legend1;
run;

quit;

/*Source: https://data.ct.gov/Government/Town-Boundary-Index-Map/evyv-fqzg*/

ods rtf close;

