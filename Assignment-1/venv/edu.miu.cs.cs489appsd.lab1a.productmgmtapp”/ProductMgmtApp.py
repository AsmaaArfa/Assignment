import pandas as pd


class main:
    data = pd.read_csv("/Users/asmaahesham/Desktop/ASD-Course/Assignments/Assignment-1/data.csv")
    df = pd.DataFrame(data)
    sorted_df = df
    path = '/Users/asmaahesham/Desktop/ASD-Course/Assignments/Assignment-1'
    @classmethod
    def printProducts(cls):
        cls.sorted_df = cls.df.sort_values(by=['Name', 'UnitPrice'], ascending=[True, False])
        #print(sorted_df)

    @classmethod
    def save(cls):
        cls.sorted_df.to_json(f'{cls.path}/product.json', orient='records', indent=4)
        cls.sorted_df.to_csv(f'{cls.path}/product.csv', index=False)
        cls.sorted_df.to_xml(f'{cls.path}/product.xml', index=False)


main.printProducts()
main.save()

