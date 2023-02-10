"""Downloads the raw data from US Census Bureau.

https://github.com/uscensusbureau/acs-summary-file
"""
import logging
import os
import sys
from ftplib import FTP
from pathlib import Path
from typing import Union

import pandas as pd

logger = logging.getLogger("__file__")
logger.setLevel(logging.INFO)
logger.addHandler(logging.StreamHandler(sys.stdout))


def download_table_for_summary_level(
    table_id: str,
    year: int,
    aggregation: int,
    summary_level: Union[int, str] = None,
    local_dir: str = "output",
    overwrite: bool = True,
) -> str:
    """Downloads a given ACS (American Community Survey) table at the given
    summary level from the server to local file system.

    For information on this new Summary File format, please visit:
    https://www.census.gov/programs-surveys/acs/data/summary-file.html

    For the semantic of each column (i.e., data dictionary), please visit:
    https://www2.census.gov/programs-surveys/acs/summary_file/{year}/table-based-SF/documentation/ACS{year}{aggregation}YR_Table_Shells.txt

    For example, the first few lines from
    https://www2.census.gov/programs-surveys/acs/summary_file/2021/table-based-SF/documentation/ACS20215YR_Table_Shells.txt
    ```
    Table ID|Line|Indent|Unique ID|Label|Title|Universe|Type
    B01001|1.0|0|B01001_001|Total:|SEX BY AGE|Total population|int
    B01001|2.0|1|B01001_002|Male:|SEX BY AGE|Total population|int
    ...
    ```
    It indicates for the table with id of "b01001", the columns with names of
    "B01001_E002" and "B01001_M002" means the [E]stimate and [M]argin of error
    for "total population of male", respectively.

    Args:
        table_id: The id of the table to be downloaded, e.g., b01001.
        year: Year of the data is released, e.g., 2020.
        aggregation: Either 1 or 5.
        summary_level: The geographical summary level. For details, see:
            https://mcdc.missouri.edu/geography/sumlevs/
        local_dir: Directory where the files will be saved to.
        overwrite: If True, overwrites the local file.

    Returns:
        The local file path.

    Raises:
        RuntimeError: If the file does not exist on the server.
    """

    try:
        os.makedirs(local_dir)
    except FileExistsError as e:
        if not overwrite:
            raise(f"The directory '{local_dir}' already exists. Delete and try again.")

    # Lists all available files for the given table
    ftp_client = FTP(host="ftp2.census.gov")
    ftp_client.login()
    ftp_path = f"programs-surveys/acs/summary_file/{year}/table-based-SF/data/{aggregation}YRData/"
    try:
        ftp_client.cwd(ftp_path)
    except Exception as e:
        raise RuntimeError(f"The given FTP path {ftp_path} does not exist on the server.")
    # Assumes the file name pattern
    files = [x for x in ftp_client.nlst() if x.endswith(f"{table_id}.dat")]

    # Downloads the corresponding files via HTTPS
    num_files = len(files)
    if num_files == 0:
        logger.info("No file is found.")
        return ""

    for i, file in enumerate(files):
        logger.info(f"Downloading {i + 1} of total {num_files} files...")
        file_path_on_server = os.path.join("https://www2.census.gov", ftp_path, file)
        logger.info(file_path_on_server)
        df = pd.read_csv(file_path_on_server, sep="|")

        # Filters with GEO_ID
        # https://mcdc.missouri.edu/geography/sumlevs/
        if summary_level:
            logger.info(f"Filtering for rows at the the {summary_level:03} summary level...")
            df = df[df["GEO_ID"].str.startswith(f"{summary_level:03}")]

        local_file_path = ""
        if not df.empty:
            local_file_path = os.path.join(local_dir, f"{Path(file).stem}_{summary_level}.csv")
            df.to_csv(local_file_path, sep=",", index=False)
        else:
            logger.info(f"No row at the {summary_level:03} summary level is found.")

    logger.info("File download and filtering finished.")

    return local_file_path


if __name__ == "__main__":
    download_table_for_summary_level(
        table_id="b01001",
        year=2021,
        aggregation=5,
        summary_level=860,  # ZCTA level
    )
