import pandas as pd
from productmgmtmodel.product import product

class main:
    data = pd.read_csv("/Users/asmaahesham/Desktop/ASD-Course/Assignments/Assignment-1/data.csv")
    df = pd.DataFrame(data)
    sorted_df = df
    path = '/Users/asmaahesham/Desktop/ASD-Course/Assignments/Assignment-1'

    prd = [product(**row.to_dict()) for _,row in df.iterrows()]
    new_df = df
   
    @classmethod
    def prepare_product (cls):
        cls.new_df = pd.DataFrame([p.model_dump() for p in cls.prd])
        # print(cls.new_df.columns)
    @classmethod
    def printProducts(cls):
        cls.prepare_product()
        cls.sorted_df = cls.new_df.sort_values(by=['Name', 'UnitPrice'], ascending=[True, False])
        #print(sorted_df)

    @classmethod
    def save(cls):
        cls.sorted_df.to_json(f'{cls.path}/product.json', orient='records', indent=4)
        cls.sorted_df.to_csv(f'{cls.path}/product.csv', index=False)
        cls.sorted_df.to_xml(f'{cls.path}/product.xml', index=False)


main.printProducts()
main.save()

# main.prepare_product()

