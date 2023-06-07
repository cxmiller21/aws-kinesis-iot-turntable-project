import pandas as pd
import pyarrow.orc as orc

FILE_NAME = "file_name.orc"

with open(FILE_NAME, "rb") as file:
    data = orc.ORCFile(file)
    df = data.read().to_pandas()

print(df)
