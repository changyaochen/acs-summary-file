import pandas as pd
from ftplib import FTP
import os, sys
#get tables for a summary level and output file for each
def table_for_sumlevel(tblid, year, dataset, sumlevel):

    #create output directory. 
    outdir = 'output'
    try:
        os.mkdir(outdir)
    except FileExistsError as e:
        print(f"directory named '{outdir}' already exists. delete it and try again.")
        sys.exit(1)

    dir =f"/programs-surveys/acs/summary_file/{year}/prototype/{dataset}YRData/"

    #go to ftp site
    ftp = FTP("ftp2.census.gov")
    ftp.login("","")
    ftp.cwd(dir)

    #get .dat file based on tblid or all tables
    files = [x for x in ftp.nlst() if f"{tblid}.dat" in x or (tblid=="*" and ".dat" in x)]

    for file in files:
        #read data file and query for summary level (http faster than ftp)
        df = pd.read_csv(f"https://www2.census.gov{dir}{file}", sep="|")
        df = df[ df['GEO_ID'].str.startswith(sumlevel) ]

        #output
        if not df.empty:
            df.to_csv(f"{outdir}/{file}", sep="|", index=False)
            print(f"{outdir}/{file} output.")

#get all tables for all tracts
table_for_sumlevel(tblid = '*', year=2020, dataset=5, sumlevel='140')