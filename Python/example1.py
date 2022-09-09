
import pandas as pd


def get_data(tblid, year, dataset, state):
    #define urls for data and geography
    data_url = f"https://www2.census.gov/programs-surveys/acs/summary_file/{year}/prototype/{dataset}YRData/acsdt{dataset}y{year}-{tblid}.dat"
    geo_url = f"https://www2.census.gov/programs-surveys/acs/summary_file/{year}/prototype/Geos{year}{dataset}YR.csv"

    #read data into dataframe
    data = pd.read_csv(data_url, sep='|', index_col="GEO_ID")
    geos = pd.read_csv(geo_url, sep='|', index_col="DADSID")

    #add geo file names and search for state
    data = data.join(geos[["NAME", "STUSAB"]])
    data = data.loc[data["STUSAB"]==state]

    #output
    data.to_csv(f"{tblid}.dat", sep="|")
    print(f"Done. {tblid}.dat created")





get_data("b19001", 2021, 1, "CA")
