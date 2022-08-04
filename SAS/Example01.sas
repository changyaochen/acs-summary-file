
/************************************************************************************************************************/
/* Program Name: Example Program for Summary File Prototype (Basic)					                  					*/
/* Version 3, Aug 04 2022                                                                             					*/      
/* Output: Data for any given 1-year table for all geographies and sub-geographies of the given state 					*/
/* ACS Summary File Website: 																							*/
/*		https://www.census.gov/programs-surveys/acs/technical-documentation/summary-file-documentation.html  			*/
/* Program Documentation:																								*/
/*		https://www2.census.gov/programs-surveys/acs/summary_file/2018/prototype/program/documentation					*/  
/************************************************************************************************************************/


/*------------ADD INPUT HERE ------------*/
%let Table_ID =b19001;
%let State  =ca;
%let Data_Dir =../../5YRData;
%let Geo_File =../../Geos20215YR.csv;
/*---------------------------------------*/

libname out ".";

/** Import Data **/
proc import datafile = "&Data_Dir./acsdt5y2021-&Table_ID..dat"
  out = out.&Table_ID
  dbms = dlm
  replace;
  getnames = yes;
  delimiter = '|';
  GUESSINGROWS=10000;
run;


/* import geography labels */
proc import datafile="&Geo_File"
    out=Geos
    dbms=dlm
    replace;
    getnames=yes;
    delimiter = '|';
	GUESSINGROWS=10000;
run;


/* merge data with geography labels and output */
proc sql;
	create table out.&Table_ID as 
	select geo.name, tbl.*
    from out.&Table_ID as tbl 
	left join Geos as geo
	on tbl.GEO_ID = geo.geo_id
	where geo.stusab = upcase("&State");
quit;

