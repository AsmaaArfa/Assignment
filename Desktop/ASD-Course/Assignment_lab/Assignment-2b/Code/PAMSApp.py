from typing import Any, List, Dict
import pandas as pd
from datetime import date, datetime

class main():
    data = "/Users/asmaahesham/Desktop/ASD-Course/Assignment_lab/Assignment-2b"
    df = pd.DataFrame()

    @classmethod
    def read_data(cls):
        cls.df = pd.read_csv(f'{cls.data}/data.csv')
        print (cls.df.head())

    @classmethod
    def calc_age(cls, birthdate: date) -> int:
        today = date.today()
        age = today.year - birthdate.year

        return age
    @classmethod
    def print_in_json(cls):
        cls.df['DateofBirth'] = pd.to_datetime(cls.df['DateofBirth'])
        cls.df['age'] = cls.df['DateofBirth'].apply(cls.calc_age)
        df_out = cls.df.sort_values(['age'], ascending=False)
        df_out.to_json(f'{cls.data}/data_json.json', orient='records', indent=4)

main.read_data()
main.print_in_json()