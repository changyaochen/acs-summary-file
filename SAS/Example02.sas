
/************************************************************************************************************************/
/* Program Name: Example Program for Summary File Prototype (Advanced)					               					*/
/* Version 2, Jun 12 2021                                                                             					*/      
/* Output: This program produces 1 SAS data set for every table in the input directory       							*/
/*        but only keeping estimates from the tract level geographies (Summary Level 140)		      					*/
/* ACS Summary File Website: 																							*/
/*		https://www.census.gov/programs-surveys/acs/technical-documentation/summary-file-documentation.html  			*/
/* Program Documentation:																								*/
/*		https://www2.census.gov/programs-surveys/acs/summary_file/2018/prototype/program/documentation					*/  
/************************************************************************************************************************/

/*------------ADD INPUT HERE------------*/
%let Summary_Level 	=140;
%let Data_Dir 		=/data/prt03/test/2020Sumfile/5YRData;		*Must be absolute path;
%let Output_Dir		=./output; 				
%let Temp_Dir 		=./temp;				
/*---------------------------------------*/



resetline;
option nonotes nodate nonumber ls=129 ps=32767;

libname out "&Output_Dir."; 

/*Pipe allows SAS to execute non SAS programs that has standard input output*/
filename tmp pipe "ls -mlR --full-time -1 &Data_Dir./";

/*Extract all data sets names with file paths from tmp */
data wantnames;
	infile tmp dlm="¬";
	length dir_line $2000;
	input dir_line;
run;

/*Extract all sas data sets names and separate them from directory paths */

data namelist (keep= names);
    length names $ 30.;
	set wantnames;

	zipfile=index(dir_line,'.zip');
	if zipfile > 0 then delete;

	a=index(dir_line,'acsdt5y2019');
	names=substr(dir_line,a);
	b=index(names,'-');
	names=substr(names,b+1);
	names=tranwrd(names,'.dat','');
	if names=" " then delete;

run;

/*Creat a macro var that contains all data file names as a string*/
proc sql noprint;
select names into : fnames separated by ' ' from namelist;
quit;

%put fnames=&fnames;

/*&fnames is the dataset name of each SAS data file*/


%macro tabinput(TBID);

proc printto log="&Temp_Dir./&TBID.inputcode.log" new; 
run; 

options obs=3;
proc import datafile = "&Data_Dir./acsdt5y2019-&TBID..dat"
  out = &TBID.firsttwo
  dbms = dlm
  replace;
  getnames = yes;
  delimiter = '|';
run;

proc printto ; 
DM 'clear log';

/*********************Read back in the log file*****************************************************/
option obs=max;

data readcode;
	infile "&Temp_Dir./&TBID.inputcode.log" truncover;
	length lines $ 150.;
	input lines $150.;
	if index(lines, 'The SAS System') > 0 then delete;
run;

data cleancode;
	set readcode;
	file "&Temp_Dir./&TBID.input.sas";
	/******get the portion of the input code*********/
	retain startline;
	retain endingline;
	if index(lines, 'data WORK') > 0 then do;
   		startline=_N_;
	end;
	if index(lines, 'run;') > 0 then do;
   		endingline=_N_;
	end;
	if  _N_ > startline and _N_> endingline and endingline > startline  then delete; 
	if startline=. then delete;
	drop startline endingline;
    /******strip the ling numbers and invalide characters*********/
	firstblank=index(lines, ' ');
	lines=substr(lines,firstblank);
	lines=tranwrd(lines, "!"," ");
	lines=tranwrd(lines, "FIRSTTWO", "Orig");
	lines=tranwrd(lines, "best12","best15");
	/*******use perl regular expression to set the GEO_ID length to $40.*/
	if index(lines, 'GEO_ID') > 0 then do;    
      lines=prxchange('s/\d+/40/', -1, lines); 
    end;
  
	drop firstblank;
	put lines;
run;
%include "&Temp_Dir./&TBID.input.sas"; 

data out.acsdt5y2019_&TBID.;
	set &TBID.orig;
	If index(GEO_ID,"&Summary_Level")=1;
run;

%mend;


%macro importall;
   
	%do i=1 %to %sysfunc(countw("&fnames",,'s'));
		%let tabname = %scan(&fnames,&i);
        %tabinput(&tabname);
    %end;

%mend;

%importall;


