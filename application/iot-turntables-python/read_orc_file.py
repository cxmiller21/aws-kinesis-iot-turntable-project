import pandas as pd
import pyarrow.orc as orc

FILE_NAME = "aws-kinesis-iot-turntable.orc"

data = None

with open(FILE_NAME, "rb") as file:
    data = orc.ORCFile(file)
    df = data.read().to_pandas()

print(df)
