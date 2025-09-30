from setuptools import setup, find_packages

setup(
    name="employee-pensionplan",       # Your package name
    version="0.1.0",                   # Version number
    packages=find_packages(),          # Automatically find packages
    install_requires=[
        "pandas","pydantic"                      # Add other dependencies here
    ],
    python_requires=">=3.8",
    author="Asmaa Hesham",
    description="Employee-PensionPlan Python package",
    long_description="Employee-PensionPlan Python package",
    long_description_content_type="text/markdown",
    url="https://github.com/AsmaaArfa/ASD_MIU.git",  # GitHub repo URL
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
    ],
)
