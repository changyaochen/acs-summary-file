
/************************************************************************************************************************/
/* Program Name: Example Program for Summary File Prototype (Basic)					                  					*/
/* Version 2, Jan 12 2021                                                                             					*/      
/* Output: Data for any given 1-year table for all geographies and sub-geographies of the given state 					*/
/* ACS Summary File Website: 																							*/
/*		https://www.census.gov/programs-surveys/acs/technical-documentation/summary-file-documentation.html  			*/
/* Program Documentation:																								*/
/*		https://www2.census.gov/programs-surveys/acs/summary_file/2018/prototype/program/documentation					*/  
/************************************************************************************************************************/


/*------------ADD INPUT HERE ------------*/
%let Table_ID =b19001;
%let State  =ca;
%let Data_Dir =../../1YRData;
%let Geo_File =../../Geos20191YR.csv;
/*---------------------------------------*/

libname out ".";

/** Import Data **/
proc import datafile = "&Data_Dir./acsdt1y2019-&Table_ID..dat"
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
    dbms=csv
    replace;
    getnames=yes;
	GUESSINGROWS=10000;
run;


/* merge data with geography labels and output */
proc sql;
	create table out.&Table_ID as 
	select geo.name, tbl.*
    from out.&Table_ID as tbl 
	left join Geos as geo
	on tbl.GEO_ID = geo.DADSID
	where geo.stusab = upcase("&State");
quit;

