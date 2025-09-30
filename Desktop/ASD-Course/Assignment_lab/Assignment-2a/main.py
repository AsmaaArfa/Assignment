import pandas as pd

class main():

    employee_df = pd.DataFrame()
    plan_df = pd.DataFrame()
    data = []
    path = "/Users/asmaahesham/Desktop/ASD-Course/Assignments/ASD_MIU/Assignment-2a"
    df_out= pd.DataFrame()
    @classmethod
    def read_data(cls):
        cls.employee_df = pd.read_csv(f"{cls.path}/data.csv", 
                                      usecols=['FirstName', 'LastName', 'YearlySalary', 'EmploymentDate','employeeId'])
        cls.plan_df = pd.read_csv(f"{cls.path}/data.csv", 
                                      usecols=['P_Ref_Num', 'EnrollmentDate', 'MonthlyContribution','employeeId'])
        
        # cls.plan_df = cls.plan_df[cls.plan_df['P_Ref_Num']]

        # print (cls.employee_df.head())
        # print (cls.plan_df.head())
    @classmethod
    def print_all(cls):
        cls.df_out = pd.merge(cls.employee_df, cls.plan_df, on='employeeId', how='inner').sort_values(
            by=['LastName', 'YearlySalary'], ascending=[False, True]
        )
        print(cls.df_out)
        cls.df_out.to_json(f'{cls.path}/employee_data.json', orient='records', indent=4)

    @classmethod
    def QuarterlyUpcomingEnroll(cls):
        cls.df_out =( 
            pd.merge(cls.plan_df,cls.employee_df, on='employeeId', how='left')
            .query("P_Ref_Num.isnull()")
            .sort_values(by=['YearlySalary', 'LastName'], ascending=[False, True])
        )
        # print(cls.df_out)
        cls.df_out.to_json(f'{cls.path}/unenrolled_employee.json', orient='records', indent=4)

main.read_data()
main.print_all()
main.QuarterlyUpcomingEnroll()
