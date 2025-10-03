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
            'annual_salary': str(self.annual_salary()),
        }

    def to_dict_with_department(self) -> Dict:
        d = self.to_shallow_dict()
        d['department'] = {'departmentNo': str(self.department.departmentNo), 'name': self.department.name}
        d['yearsOfEmployment'] = self.years_of_employment()
        return d


# Data loader
def load_data_from_file(path: str = 'hr_data.json'):
    """Load departments and employees from a JSON file and construct objects.
    Enforces: every employee's department must exist. If headEmployeeNo is present,
    the referenced employee must belong to that department; otherwise a warning is issued
    and the head is left as None.
    """
    with open(path, 'r') as f:
        raw = json.load(f)

    # Create Department objects keyed by departmentNo (string)
    dept_map: Dict[str, Department] = {}
    for d in raw.get('departments', []):
        dept_no = d['departmentNo']
        dept = Department(int(dept_no), d.get('name', ''), employees=[], head=None)
        dept_map[dept_no] = dept

    # Create Employee objects
    emp_map: Dict[str, Employee] = {}
    employees: List[Employee] = []
    for e in raw.get('employees', []):
        dept_no = e['departmentNo']
        if dept_no not in dept_map:
            raise ValueError(f"Employee {e['employeeNo']} references unknown department {dept_no}")

        dept = dept_map[dept_no]
        emp = Employee(
            e['employeeNo'],
            e['firstName'],
            e['lastName'],
            date.fromisoformat(e['dateOfBirth']),
            date.fromisoformat(e['dateOfEmployment']),
            Decimal(str(e['biweeklySalary'])),
            department=dept,
        )
        dept.employees.append(emp)
        emp_map[emp.employeeNo] = emp
        employees.append(emp)

    # Assign heads if valid
    for d in raw.get('departments', []):
        dept_no = d['departmentNo']
        head_emp_no = d.get('headEmployeeNo')
        if head_emp_no:
            head = emp_map.get(head_emp_no)
            if head and head.department.departmentNo == int(dept_no):
                dept_map[dept_no].head = head
            else:
                # Head reference invalid: either employee doesn't exist or belongs to different dept
                print(f"Warning: headEmployeeNo {head_emp_no} for department {dept_no} is invalid or not in that department; leaving head as None")

    departments = list(dept_map.values())
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
    deps, emps = load_data_from_file('hr_data.json')

    print('\n--- Departments (sorted by total annual salary desc) ---\n')
    print(departments_json(deps))

    print('\n--- Employees (sorted by years employed desc, lastName asc) ---\n')
    print(employees_json(emps))
