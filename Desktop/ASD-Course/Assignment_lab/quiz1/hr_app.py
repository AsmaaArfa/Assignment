from dataclasses import dataclass, field
from datetime import date
from decimal import Decimal, ROUND_HALF_UP
from typing import Optional, List, Dict
import json

@dataclass
class Department:
    departmentNo: int
    name: str
    employees: List['Employee'] = field(default_factory=list)
    head: Optional['Employee'] = None

    def total_annual_salary(self) -> Decimal:
        total = Decimal('0.00')
        for e in self.employees:
            total += e.annual_salary()
        return total.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)

    def to_dict(self) -> Dict:
        return {
            'departmentNo': str(self.departmentNo),
            'name': self.name,
            'head': self.head.to_shallow_dict() if self.head else None,
            'employees': [e.to_shallow_dict() for e in self.employees],
            'totalAnnualSalary': str(self.total_annual_salary())
        }


@dataclass
class Employee:
    employeeNo: str
    firstName: str
    lastName: str
    dateOfBirth: date
    dateOfEmployment: date
    biweeklySalary: Decimal
    department: Department = field(repr=False, default=None)

    def annual_salary(self) -> Decimal:
        annual = self.biweeklySalary * Decimal('26')
        return annual.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)

    def years_of_employment(self, as_of: date = None) -> int:
        if as_of is None:
            as_of = date.today()
        years = as_of.year - self.dateOfEmployment.year - ((as_of.month, as_of.day) < (self.dateOfEmployment.month, self.dateOfEmployment.day))
        return years

    def to_shallow_dict(self) -> Dict:
        return {
            'employeeNo': self.employeeNo,
            'firstName': self.firstName,
            'lastName': self.lastName,
            'dateOfBirth': self.dateOfBirth.isoformat(),
            'dateOfEmployment': self.dateOfEmployment.isoformat(),
            'biweeklySalary': str(self.biweeklySalary),
            'annualSalary': str(self.annual_salary()),
        }

    def to_dict_with_department(self) -> Dict:
        d = self.to_shallow_dict()
        d['department'] = {'departmentNo': str(self.department.departmentNo), 'name': self.department.name}
        d['yearsOfEmployment'] = self.years_of_employment()
        return d


# Sample data builder
def build_sample_data():
    # Departments (using big numeric ids as in the prompt)
    sales = Department(31288741190182539912, 'Sales')
    marketing = Department(29274582650152771644, 'Marketing')
    engineering = Department(1001, 'Engineering')
    hr = Department(1002, 'HR')

    # Employees
    e1 = Employee('000-11-0987', 'Alice', 'Zephyr', date(1985, 4, 12), date(2010, 6, 1), Decimal('2500.75'))
    e2 = Employee('000-61-1234', 'Bob', 'Young', date(1990, 8, 3), date(2015, 9, 15), Decimal('3750.99'))
    e3 = Employee('000-22-3333', 'Carol', 'Xavier', date(1982, 1, 20), date(2005, 3, 20), Decimal('4200.00'))
    e4 = Employee('000-33-4444', 'David', 'Wong', date(1992, 11, 2), date(2018, 1, 10), Decimal('1800.50'))
    e5 = Employee('000-44-5555', 'Eve', 'Vega', date(1979, 7, 9), date(2000, 7, 1), Decimal('5000.00'))

    # Assign departments and add to lists
    for emp, dept in [(e1, sales), (e2, marketing), (e3, engineering), (e4, sales), (e5, engineering)]:
        emp.department = dept
        dept.employees.append(emp)

    # Assign heads (leave HR with no head to show vacancy)
    sales.head = e1        # Alice is head of Sales
    marketing.head = e2    # Bob is head of Marketing
    engineering.head = e5  # Eve is head of Engineering
    # hr.head remains None

    departments = [sales, marketing, engineering, hr]
    employees = [e1, e2, e3, e4, e5]
    return departments, employees


# Feature 1: print departments with employees, head, and total annual salary; sorted desc by dept total annual salary
def departments_json(departments: List[Department]) -> str:
    sorted_depts = sorted(departments, key=lambda d: d.total_annual_salary(), reverse=True)
    data = [d.to_dict() for d in sorted_depts]
    return json.dumps(data, indent=2)


# Feature 2: print all employees with department and years of employment; sorted desc by years, asc by last name
def employees_json(employees: List[Employee]) -> str:
    sorted_emps = sorted(employees, key=lambda e: (-e.years_of_employment(), e.lastName))
    data = [e.to_dict_with_department() for e in sorted_emps]
    return json.dumps(data, indent=2)


if __name__ == '__main__':
    deps, emps = build_sample_data()

    print('\n--- Departments (sorted by total annual salary desc) ---\n')
    print(departments_json(deps))

    print('\n--- Employees (sorted by years employed desc, lastName asc) ---\n')
    print(employees_json(emps))
