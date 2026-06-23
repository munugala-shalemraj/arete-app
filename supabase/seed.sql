-- =============================================================
-- ARETE APP — SEED DATA
-- Run this AFTER schema.sql in Supabase SQL editor
-- =============================================================

-- ── TOPIC ────────────────────────────────────────────────────
INSERT INTO topics (id, title, description, icon_name, order_index) VALUES
(1, 'Python for Data Science',
 'A complete undergraduate course in Python programming for data analysis and visualisation.',
 'code', 1);

-- ── LESSONS ──────────────────────────────────────────────────

INSERT INTO lessons (topic_id, title, content, level_tier, order_index, xp_reward) VALUES
(1, 'Variables & Data Types',
$L1$
# Variables & Data Types in Python

In Python, a **variable** is a named label that points to a value stored in memory. Python is *dynamically typed* — you do not declare a type upfront; Python infers it from the value you assign. This makes code fast to write, but understanding types is still essential for data science work where incorrect types can cause silent errors in calculations.

## Assigning Variables

Use the `=` operator to assign values. Variable names must start with a letter or underscore, can contain letters, digits, and underscores, and are case-sensitive. By convention, Python programmers use `snake_case` for variable names.

```python
# Integers — whole numbers
student_count = 142
birth_year = 2003

# Floats — decimal numbers
average_grade = 72.5
pi = 3.14159

# Strings — text in single or double quotes
module_name = "Python for Data Science"
university = 'Newcastle University'

# Booleans — True or False (capital first letter)
is_enrolled = True
has_submitted = False

# NoneType — represents the absence of a value
result = None
```

## Checking Types with type()

The built-in `type()` function returns the type of any value. This is useful when debugging unexpected behaviour in data pipelines.

```python
print(type(42))           # <class 'int'>
print(type(3.14))         # <class 'float'>
print(type("hello"))      # <class 'str'>
print(type(True))         # <class 'bool'>
print(type(None))         # <class 'NoneType'>
```

## Type Casting

You can explicitly convert between types using `int()`, `float()`, `str()`, and `bool()`. In data science, type casting is common when loading data from CSV files where numbers may be read as strings.

```python
# String to integer
age_str = "21"
age_int = int(age_str)
print(age_int + 1)          # 22

# Integer to float
items = 7
ratio = float(items) / 2
print(ratio)                # 3.5

# Number to string (for concatenation or display)
score = 88
label = "Score: " + str(score)
print(label)                # Score: 88

# Truthy and falsy values
print(bool(0))              # False
print(bool(-1))             # True  — any non-zero number is truthy
print(bool(""))             # False — empty string is falsy
print(bool("data"))         # True
```

## f-Strings (Formatted String Literals)

Introduced in Python 3.6, f-strings are the modern way to embed variable values inside strings. They are more readable and faster than older approaches like `%` formatting or `.format()`.

```python
name = "Priya"
grade = 91.4
year = 2

print(f"Student: {name}")
print(f"Grade: {grade:.1f}%")          # 1 decimal place
print(f"Year {year} student at Newcastle")

# Expressions work inside {}
a, b = 10, 3
print(f"{a} divided by {b} = {a/b:.2f}")  # 10 divided by 3 = 3.33
```

Understanding data types is foundational. When you load a CSV into Pandas, numeric columns may arrive as `object` (string) dtype — knowing how to identify and cast types is one of the first data cleaning tasks you will face on every real project.
$L1$, 'foundations', 1, 15),

(1, 'Control Flow',
$L2$
# Control Flow in Python

Control flow refers to the order in which Python executes statements. By default, code runs line by line from top to bottom. Control flow structures — conditionals and loops — let you make decisions and repeat actions, turning simple scripts into powerful data processing programs.

## Comparison Operators

Comparison operators evaluate a relationship between two values and return a Boolean (`True` or `False`). These form the foundation of all decision-making in code.

```python
x = 10
print(x == 10)   # True  — equal to
print(x != 5)    # True  — not equal to
print(x > 8)     # True  — greater than
print(x < 8)     # False — less than
print(x >= 10)   # True  — greater than or equal
print(x <= 9)    # False — less than or equal
```

## Logical Operators

Logical operators combine multiple Boolean expressions. `and` requires both sides to be True, `or` requires at least one, and `not` inverts the result.

```python
score = 72
attendance = 85

# Student passes if score >= 40 AND attendance >= 75
if score >= 40 and attendance >= 75:
    print("Pass")

# Alert if score is very high or very low
if score >= 90 or score < 40:
    print("Review needed")

# not inverts a boolean
is_late = False
if not is_late:
    print("On time — well done!")
```

## if / elif / else Statements

The `if` statement evaluates a condition. If the condition is True, its indented block runs. `elif` (else-if) adds further conditions, and `else` catches everything remaining.

```python
mark = 65

if mark >= 70:
    grade = "Distinction"
elif mark >= 60:
    grade = "Merit"
elif mark >= 40:
    grade = "Pass"
else:
    grade = "Fail"

print(f"Grade: {grade}")   # Grade: Merit
```

## for Loops

`for` loops iterate over any *iterable* — a list, string, range, or dictionary. The `range()` function generates a sequence of numbers.

```python
# Iterate over a range
for i in range(5):
    print(i)    # prints 0, 1, 2, 3, 4

# Iterate over a list
modules = ["Python", "Statistics", "Machine Learning"]
for module in modules:
    print(f"Module: {module}")

# range with start, stop, step
for i in range(0, 20, 5):
    print(i)    # 0, 5, 10, 15
```

## while Loops and Loop Control

`while` loops run as long as a condition is True. `break` exits the loop immediately; `continue` skips the rest of the current iteration and moves to the next; `pass` is a no-operation placeholder.

```python
count = 0
while count < 5:
    print(count)
    count += 1

# break — exit early
for n in range(10):
    if n == 4:
        break
    print(n)     # prints 0, 1, 2, 3

# continue — skip even numbers
for n in range(8):
    if n % 2 == 0:
        continue
    print(n)     # prints 1, 3, 5, 7
```

Mastering control flow is essential in data science. You will use loops to iterate over rows, conditions to filter data, and combination of both to build data validation pipelines.
$L2$, 'foundations', 2, 15),

(1, 'Functions',
$L3$
# Functions in Python

A **function** is a named, reusable block of code that performs a specific task. Functions are fundamental to writing clean, maintainable code — they allow you to avoid repetition (the DRY principle: Do not Repeat Yourself) and to organise complex programs into logical, testable units.

## Defining and Calling Functions

Use the `def` keyword, followed by the function name, parentheses for parameters, and a colon. The body is indented. Call the function by its name followed by parentheses.

```python
def greet():
    print("Welcome to Python for Data Science!")

greet()    # Welcome to Python for Data Science!

# Function with parameters
def greet_student(name):
    print(f"Hello, {name}! Ready to learn?")

greet_student("Priya")    # Hello, Priya! Ready to learn?
```

## Parameters, Arguments, and Return Values

Functions can accept multiple parameters and use `return` to send a value back to the caller. Once `return` is reached, the function exits immediately.

```python
def calculate_grade(score, max_score):
    percentage = (score / max_score) * 100
    return percentage

result = calculate_grade(72, 100)
print(f"Grade: {result:.1f}%")    # Grade: 72.0%

# Multiple return values (returned as a tuple)
def stats(numbers):
    return min(numbers), max(numbers), sum(numbers) / len(numbers)

low, high, avg = stats([55, 72, 88, 91, 64])
print(f"Min: {low}, Max: {high}, Mean: {avg:.1f}")
```

## Default Parameters and Keyword Arguments

Parameters can have default values, making them optional when calling the function. You can also pass arguments by name (keyword arguments) for clarity.

```python
def power(base, exponent=2):
    return base ** exponent

print(power(5))        # 25  — uses default exponent=2
print(power(2, 10))    # 1024
print(power(base=3, exponent=3))  # 27 — keyword arguments

def describe_dataset(name, rows, cols, source="unknown"):
    print(f"{name}: {rows} rows x {cols} cols (source: {source})")

describe_dataset("Iris", 150, 5, source="UCI Repository")
```

## Docstrings

A docstring is a string literal placed immediately after the `def` line. It documents what the function does, its parameters, and its return value. You can access it with `help(function_name)`.

```python
def calculate_bmi(weight_kg, height_m):
    """
    Calculate Body Mass Index (BMI).

    Parameters:
        weight_kg (float): Weight in kilograms.
        height_m  (float): Height in metres.

    Returns:
        float: BMI rounded to 2 decimal places.
    """
    bmi = weight_kg / (height_m ** 2)
    return round(bmi, 2)

print(calculate_bmi(70, 1.75))    # 22.86
```

## Scope

Variables created inside a function are *local* — they only exist within that function. Variables outside functions are *global*. Use the `global` keyword only as a last resort; prefer returning values instead.

```python
total = 0    # global variable

def add_to_total(value):
    global total
    total += value

add_to_total(10)
add_to_total(25)
print(total)    # 35
```

## Lambda Functions

Lambda functions are small, anonymous one-line functions. They are commonly used with `sorted()`, `map()`, and `filter()` in data processing.

```python
# Normal function
def square(x):
    return x ** 2

# Equivalent lambda
square = lambda x: x ** 2
print(square(7))    # 49

# Lambda in sorted()
students = [("Alice", 72), ("Bob", 88), ("Carol", 65)]
by_score = sorted(students, key=lambda s: s[1], reverse=True)
print(by_score)    # [('Bob', 88), ('Alice', 72), ('Carol', 65)]
```

Functions are the primary mechanism for code reuse in Python. In data science workflows, you will write functions to clean columns, compute metrics, and plot charts — making your notebooks reproducible and your pipelines testable.
$L3$, 'foundations', 3, 15),

(1, 'Lists & Dictionaries',
$L4$
# Lists & Dictionaries in Python

Lists and dictionaries are Python's two most-used data structures. Understanding them deeply is essential because Pandas DataFrames, JSON API responses, and database query results are all built on top of these primitives.

## Lists

A **list** is an ordered, mutable sequence that can hold items of any type. Lists are defined with square brackets `[]` and support indexing from `0` (first element) or `-1` (last element).

```python
scores = [72, 88, 65, 91, 77]

print(scores[0])     # 72   — first element
print(scores[-1])    # 77   — last element
print(scores[1:4])   # [88, 65, 91] — slice

# Common list methods
scores.append(85)         # add to end
scores.insert(0, 60)      # insert at index 0
scores.remove(65)         # remove first occurrence of 65
popped = scores.pop()     # remove and return last element
scores.sort()             # sort in place (ascending)
scores.sort(reverse=True) # sort descending
print(len(scores))        # number of elements
print(sum(scores))        # sum all elements
```

## List Comprehensions

List comprehensions provide a concise, Pythonic way to create new lists by applying an expression to each element, optionally filtering with a condition.

```python
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# Square each number
squares = [n ** 2 for n in numbers]
print(squares)    # [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]

# Filter: only even numbers
evens = [n for n in numbers if n % 2 == 0]
print(evens)    # [2, 4, 6, 8, 10]

# Normalise scores to 0-1 range
raw_scores = [55, 72, 88, 91, 64]
max_s = max(raw_scores)
normalised = [s / max_s for s in raw_scores]
print([round(n, 2) for n in normalised])
```

## Dictionaries

A **dictionary** stores key-value pairs. Keys must be unique and immutable (strings and numbers are most common). Values can be anything. Dictionaries are unordered in Python < 3.7; from 3.7+ they preserve insertion order.

```python
student = {
    "name": "Alice",
    "age": 21,
    "modules": ["Python", "Statistics"],
    "grade": 78.5
}

# Access values
print(student["name"])          # Alice
print(student.get("age"))       # 21 — safe access (returns None if key missing)

# Modify
student["grade"] = 82.0
student["year"] = 2

# Remove a key
del student["age"]

# Iterate
for key, value in student.items():
    print(f"{key}: {value}")

# Keys, values, items
print(list(student.keys()))     # ['name', 'modules', 'grade', 'year']
print(list(student.values()))
```

## Nested Structures

Real data is often nested — dicts inside lists, or lists inside dicts. This mirrors JSON data from APIs and databases.

```python
dataset = [
    {"id": 1, "name": "Alice", "score": 88, "tags": ["active", "scholarship"]},
    {"id": 2, "name": "Bob",   "score": 72, "tags": ["active"]},
    {"id": 3, "name": "Carol", "score": 91, "tags": ["active", "distinction"]},
]

# Access nested data
print(dataset[0]["name"])          # Alice
print(dataset[2]["tags"][1])       # distinction

# List comprehension over nested structure
high_achievers = [d["name"] for d in dataset if d["score"] >= 85]
print(high_achievers)    # ['Alice', 'Carol']

# Build a dict from a list
score_lookup = {d["name"]: d["score"] for d in dataset}
print(score_lookup)    # {'Alice': 88, 'Bob': 72, 'Carol': 91}
```

Lists and dicts are the building blocks of data manipulation. When you call `df.to_dict()` in Pandas or parse a JSON API response, you are working with these exact structures — so becoming fluent with them will make your data science code both faster to write and easier to debug.
$L4$, 'foundations', 4, 15),

(1, 'File I/O & Modules',
$L5$
# File I/O & Modules in Python

Real data science work involves reading data from files, writing results back to disk, and using Python's rich standard library. This lesson covers file input/output and the `import` system that gives you access to hundreds of built-in and third-party modules.

## Reading Files

Use the built-in `open()` function to open files. Always use the `with` statement (a context manager) — it automatically closes the file even if an error occurs.

```python
# Read entire file as a string
with open("data.txt", "r") as file:
    content = file.read()
    print(content)

# Read line by line (memory-efficient for large files)
with open("students.txt", "r") as file:
    for line in file:
        print(line.strip())    # .strip() removes trailing newline

# Read all lines into a list
with open("scores.txt", "r") as file:
    lines = file.readlines()
    print(lines[0])    # first line
```

## Writing Files

Open a file in write mode `"w"` (creates or overwrites) or append mode `"a"` (adds to the end).

```python
results = [("Alice", 88), ("Bob", 72), ("Carol", 91)]

with open("results.txt", "w") as file:
    file.write("Name, Score\n")
    for name, score in results:
        file.write(f"{name}, {score}\n")

# Append a new result
with open("results.txt", "a") as file:
    file.write("David, 79\n")
```

## Working with CSV Files

CSV (Comma-Separated Values) is the most common format for tabular data. Python's built-in `csv` module handles reading and writing with proper quoting.

```python
import csv

# Writing a CSV
data = [
    ["Name", "Age", "Score"],
    ["Alice", 21, 88],
    ["Bob", 22, 72],
]
with open("students.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerows(data)

# Reading a CSV
with open("students.csv", "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        print(row["Name"], row["Score"])
```

## Importing Modules

Python's `import` statement loads modules — collections of functions and classes you can reuse. The standard library provides `os`, `sys`, `math`, `datetime`, `random`, and many more.

```python
import math
import os
import datetime
import random

# math
print(math.sqrt(144))       # 12.0
print(math.pi)              # 3.141592653589793
print(math.log(100, 10))    # 2.0

# os — interact with the operating system
print(os.getcwd())                       # current working directory
files = os.listdir(".")                  # list files in current dir
os.makedirs("output", exist_ok=True)    # create directory safely

# datetime
now = datetime.datetime.now()
print(now.strftime("%Y-%m-%d %H:%M"))   # e.g. 2024-03-15 14:30

today = datetime.date.today()
print(today.year, today.month, today.day)

# random
print(random.randint(1, 100))           # random integer 1-100
data = [1, 2, 3, 4, 5]
random.shuffle(data)
print(data)
sample = random.sample(data, 3)         # 3 random items without replacement
```

## from ... import and Aliases

You can import specific names from a module, or import a module under an alias. Aliases are a strong convention in data science.

```python
from math import sqrt, pi
print(sqrt(81))    # 9.0 — no need to write math.sqrt

# Aliases (you will see these everywhere in data science)
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# These three lines appear at the top of virtually every data science notebook.
```

Being comfortable with file I/O and the module system is what separates script-writing from real engineering. In your projects, you will read raw data files, process them, and write clean outputs — all while relying on modules to avoid reinventing the wheel.
$L5$, 'data_handling', 5, 20),

(1, 'Pandas DataFrames',
$L6$
# Pandas DataFrames

Pandas is the cornerstone library for data analysis in Python. A **DataFrame** is a two-dimensional, labelled table — like a spreadsheet or SQL table — with rows and columns. Almost every data science project begins with loading data into a DataFrame.

## Loading Data

```python
import pandas as pd

# Read a CSV file
df = pd.read_csv("students.csv")

# Read with options
df = pd.read_csv(
    "data.csv",
    sep=",",             # delimiter
    header=0,            # row number for column names
    index_col="id",      # use 'id' column as row index
    dtype={"age": int},  # enforce column types
)

# Read Excel
df_excel = pd.read_excel("report.xlsx", sheet_name="Sheet1")

# Create a DataFrame from a dictionary
data = {
    "name":  ["Alice", "Bob", "Carol"],
    "age":   [21, 22, 20],
    "score": [88.5, 72.0, 91.0],
}
df = pd.DataFrame(data)
```

## Exploring DataFrames

```python
print(df.shape)          # (rows, columns) e.g. (150, 5)
print(df.head())         # first 5 rows
print(df.tail(3))        # last 3 rows
print(df.info())         # column names, dtypes, non-null counts
print(df.describe())     # count, mean, std, min, quartiles, max
print(df.columns.tolist())
print(df.dtypes)
print(df["score"].value_counts())
```

## Selecting Data — loc and iloc

Pandas provides two indexers: `loc` (label-based) and `iloc` (integer position-based).

```python
# Select a single column (returns Series)
names = df["name"]

# Select multiple columns (returns DataFrame)
subset = df[["name", "score"]]

# loc — use row labels and column names
df.loc[0, "name"]                # single value
df.loc[0:2, "name":"score"]      # slice of rows and columns
df.loc[df["score"] > 80]         # Boolean filter — rows where score > 80

# iloc — use integer positions
df.iloc[0]                       # first row
df.iloc[0:3]                     # first 3 rows
df.iloc[:, 1]                    # all rows, second column
df.iloc[0:3, 0:2]                # first 3 rows, first 2 columns
```

## Filtering and Sorting

```python
# Filter rows — Boolean indexing
high_scorers = df[df["score"] >= 85]
young_students = df[df["age"] < 21]

# Multiple conditions (use & for AND, | for OR, wrap in parentheses)
top_young = df[(df["score"] >= 80) & (df["age"] <= 21)]

# Sort by one column
df_sorted = df.sort_values("score", ascending=False)

# Sort by multiple columns
df_sorted2 = df.sort_values(["age", "score"], ascending=[True, False])
```

## Aggregation and GroupBy

```python
# Simple aggregations on a column
print(df["score"].mean())
print(df["score"].median())
print(df["score"].std())
print(df["score"].max())

# GroupBy — split, apply, combine
grouped = df.groupby("department")["score"].mean()
print(grouped)

# Multiple aggregations
summary = df.groupby("department")["score"].agg(["mean", "std", "count"])
print(summary)

# Adding a new computed column
df["grade_band"] = df["score"].apply(
    lambda s: "Distinction" if s >= 70 else ("Merit" if s >= 60 else "Pass")
)
```

Pandas DataFrames are the lingua franca of Python data science. Every raw dataset you encounter in your dissertation or career will need to be loaded, inspected, and sliced — mastering `read_csv`, `loc`, `iloc`, and `groupby` puts the most powerful tools in your hands.
$L6$, 'data_handling', 6, 20),

(1, 'Data Cleaning',
$L7$
# Data Cleaning with Pandas

In practice, raw data is almost never clean. Missing values, incorrect types, duplicate rows, and inconsistent formatting are the norm, not the exception. Data cleaning is typically 60-80% of a data scientist's time — and Pandas provides an excellent toolkit for it.

## Detecting Missing Values

Missing values appear as `NaN` (Not a Number) in numeric columns and `None` or `NaN` in object columns.

```python
import pandas as pd
import numpy as np

df = pd.read_csv("survey_data.csv")

# Count missing values per column
print(df.isnull().sum())

# Total missing in the entire DataFrame
print(df.isnull().sum().sum())

# Percentage missing per column
missing_pct = (df.isnull().sum() / len(df) * 100).round(2)
print(missing_pct[missing_pct > 0])    # only show columns with missing data

# Visualise missing pattern
print(df.isnull().any())    # True for each column that has any missing value
```

## Handling Missing Values

Choose your strategy based on context: drop, fill with a fixed value, or impute with a statistical estimate.

```python
# Drop rows where ANY column is NaN
df_clean = df.dropna()

# Drop rows where ALL columns are NaN
df_clean = df.dropna(how="all")

# Drop rows that have fewer than 3 non-NaN values
df_clean = df.dropna(thresh=3)

# Drop columns with more than 50% missing
threshold = len(df) * 0.5
df_clean = df.dropna(axis=1, thresh=threshold)

# Fill missing values with a constant
df["age"].fillna(0, inplace=True)
df["city"].fillna("Unknown", inplace=True)

# Fill with column mean (numeric imputation)
df["income"].fillna(df["income"].mean(), inplace=True)

# Fill with forward fill (carry last known value forward — useful for time series)
df["temperature"].fillna(method="ffill", inplace=True)
```

## Removing Duplicates

```python
# Check for duplicate rows
print(df.duplicated().sum())

# View duplicate rows
print(df[df.duplicated()])

# Remove duplicates, keeping first occurrence
df = df.drop_duplicates()

# Remove duplicates based on specific columns
df = df.drop_duplicates(subset=["student_id", "module_code"])
```

## Converting Data Types

CSV files often import numeric columns as strings. Always check and fix dtypes before analysis.

```python
print(df.dtypes)    # inspect current types

# Convert a column to integer
df["age"] = df["age"].astype(int)

# Convert a column to float
df["score"] = df["score"].astype(float)

# Convert to datetime
df["enrollment_date"] = pd.to_datetime(df["enrollment_date"])
df["year"] = df["enrollment_date"].dt.year
df["month"] = df["enrollment_date"].dt.month

# Use errors="coerce" to turn unparseable values into NaN
df["score"] = pd.to_numeric(df["score"], errors="coerce")
```

## Cleaning String Columns

```python
# Strip whitespace from all string columns
df = df.apply(lambda col: col.str.strip() if col.dtype == "object" else col)

# Standardise to lowercase
df["name"] = df["name"].str.lower()

# Replace values
df["gender"] = df["gender"].replace({"M": "Male", "F": "Female", "m": "Male"})

# Extract numeric part from a mixed string column (e.g. "£42,000")
df["salary"] = df["salary_str"].str.replace("[£,]", "", regex=True).astype(float)

# Rename columns for consistency
df.rename(columns={"First Name": "first_name", "DOB": "date_of_birth"}, inplace=True)
```

## A Typical Cleaning Pipeline

```python
def clean_dataframe(df):
    # 1. Standardise column names
    df.columns = df.columns.str.lower().str.replace(" ", "_")
    # 2. Drop high-missingness columns
    df.dropna(axis=1, thresh=int(len(df) * 0.7), inplace=True)
    # 3. Remove duplicates
    df.drop_duplicates(inplace=True)
    # 4. Fix dtypes
    for col in ["age", "score", "year"]:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")
    # 5. Fill remaining missing with median
    num_cols = df.select_dtypes(include="number").columns
    df[num_cols] = df[num_cols].fillna(df[num_cols].median())
    return df
```

A clean dataset is a trustworthy dataset. Presenting findings based on uncleaned data — with hidden duplicates, wrong types, or imputed zeros masquerading as real values — is one of the most common and damaging mistakes in data analysis. Build cleaning pipelines early and document every decision.
$L7$, 'data_handling', 7, 20),

(1, 'NumPy Arrays',
$L8$
# NumPy Arrays

NumPy (Numerical Python) is the foundational library for numerical computing in Python. Its core object, the `ndarray`, is a fast, memory-efficient, multi-dimensional array. Pandas DataFrames are built on NumPy arrays — understanding NumPy makes you a more effective data scientist.

## Creating Arrays

```python
import numpy as np

# From a Python list
a = np.array([1, 2, 3, 4, 5])
print(a)           # [1 2 3 4 5]
print(type(a))     # <class 'numpy.ndarray'>
print(a.dtype)     # int64

# 2D array (matrix)
matrix = np.array([[1, 2, 3],
                    [4, 5, 6]])
print(matrix.shape)    # (2, 3) — 2 rows, 3 columns

# Useful constructors
zeros = np.zeros((3, 4))        # 3x4 array of 0.0
ones  = np.ones((2, 2))         # 2x2 array of 1.0
eye   = np.eye(3)               # 3x3 identity matrix
rng   = np.arange(0, 10, 2)    # [0 2 4 6 8]
lin   = np.linspace(0, 1, 5)   # [0.   0.25 0.5  0.75 1.  ]

# Random arrays
np.random.seed(42)                          # for reproducibility
rand_vals = np.random.rand(3, 3)           # uniform [0, 1)
norm_vals = np.random.randn(100)           # standard normal
int_vals  = np.random.randint(0, 100, 20) # 20 random integers 0-99
```

## Indexing and Slicing

NumPy arrays use the same `[start:stop:step]` slicing syntax as Python lists, but extended to multiple dimensions.

```python
a = np.array([10, 20, 30, 40, 50])
print(a[0])       # 10
print(a[-1])      # 50
print(a[1:4])     # [20 30 40]
print(a[::-1])    # [50 40 30 20 10] — reversed

# 2D indexing [row, col]
m = np.array([[1, 2, 3],
               [4, 5, 6],
               [7, 8, 9]])

print(m[0, 0])      # 1 — top-left
print(m[1, :])      # [4 5 6] — second row
print(m[:, 2])      # [3 6 9] — third column
print(m[0:2, 1:3])  # [[2 3] [5 6]] — sub-matrix

# Boolean indexing
scores = np.array([55, 72, 88, 91, 64, 77])
print(scores[scores >= 80])    # [88 91] — filter values
scores[scores < 60] = 60       # clip: set anything below 60 to 60
```

## Array Operations and Broadcasting

NumPy operations are *vectorised* — they apply element-wise to entire arrays without Python loops, making them orders of magnitude faster than list-based code.

```python
a = np.array([1, 2, 3, 4])
b = np.array([10, 20, 30, 40])

print(a + b)       # [11 22 33 44]
print(a * b)       # [10 40 90 160]
print(a ** 2)      # [ 1  4  9 16]
print(b / a)       # [10. 10. 10. 10.]

# Broadcasting — smaller array "stretches" to match larger
m = np.array([[1, 2, 3],
               [4, 5, 6]])
row = np.array([10, 20, 30])
print(m + row)     # [[11 22 33] [14 25 36]] — added to each row
```

## Mathematical Functions (Universal Functions)

```python
data = np.array([1.0, 4.0, 9.0, 16.0, 25.0])

print(np.sqrt(data))          # [1. 2. 3. 4. 5.]
print(np.log(data))           # natural log
print(np.log10(data))         # base-10 log
print(np.exp(np.array([1, 2, 3])))

# Statistical functions
scores = np.random.randint(40, 100, 50)
print(np.mean(scores))
print(np.median(scores))
print(np.std(scores))
print(np.var(scores))
print(np.percentile(scores, [25, 50, 75]))    # quartiles

# Axis-based operations on 2D arrays
m = np.array([[80, 75, 90],
               [60, 85, 70]])
print(np.mean(m, axis=0))    # mean per column: [70. 80. 80.]
print(np.mean(m, axis=1))    # mean per row:    [81.67 71.67]
```

## Reshaping and Stacking

```python
a = np.arange(12)
m = a.reshape(3, 4)       # reshape to 3x4 without copying data
print(m.shape)            # (3, 4)

flat = m.flatten()        # always copies
flat2 = m.ravel()         # copy only if needed — faster

# Stacking arrays
row1 = np.array([1, 2, 3])
row2 = np.array([4, 5, 6])
stacked = np.vstack([row1, row2])    # [[1 2 3] [4 5 6]]
joined  = np.hstack([row1, row2])   # [1 2 3 4 5 6]
```

NumPy is the engine under the hood of almost every Python data science library. When Pandas computes a column mean, it calls NumPy. When scikit-learn trains a model, the feature matrix is a NumPy array. Investing time in NumPy pays dividends across your entire data science career.
$L8$, 'applied', 8, 25),

(1, 'Matplotlib Visualisation',
$L9$
# Matplotlib Visualisation

Visualisation is how data scientists communicate insights. Matplotlib is Python's primary plotting library — lower-level than Seaborn but highly customisable. Understanding Matplotlib gives you full control over every aspect of your charts, which is essential for publication-quality figures in your dissertation.

## Basic Plot Structure

Every Matplotlib figure follows the same structure: a `Figure` (the whole canvas) containing one or more `Axes` (individual plots). You control the figure programmatically.

```python
import matplotlib.pyplot as plt
import numpy as np

# Quick plot (pyplot interface)
x = np.linspace(0, 2 * np.pi, 100)
y = np.sin(x)

plt.plot(x, y)
plt.xlabel("Angle (radians)")
plt.ylabel("sin(x)")
plt.title("Sine Wave")
plt.grid(True)
plt.show()
```

## Line Charts

```python
months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
sales  = [120, 145, 132, 168, 155, 182]

plt.figure(figsize=(10, 5))
plt.plot(months, sales, color="#C9A84C", linewidth=2,
         marker="o", markersize=6, linestyle="-", label="Monthly Sales")
plt.xlabel("Month", fontsize=12)
plt.ylabel("Units Sold", fontsize=12)
plt.title("2024 Sales Performance", fontsize=14, fontweight="bold")
plt.legend()
plt.tight_layout()
plt.savefig("sales.png", dpi=150)    # save to file
plt.show()
```

## Bar Charts

```python
categories = ["Python", "Statistics", "ML", "Databases", "Viz"]
scores     = [88, 72, 65, 79, 91]
colors     = ["#4F8EF7" if s >= 80 else "#C9A84C" for s in scores]

plt.figure(figsize=(8, 5))
bars = plt.bar(categories, scores, color=colors, edgecolor="white", width=0.6)

# Add value labels on top of each bar
for bar, score in zip(bars, scores):
    plt.text(bar.get_x() + bar.get_width() / 2,
             bar.get_height() + 1,
             str(score), ha="center", va="bottom", fontsize=10)

plt.ylim(0, 105)
plt.ylabel("Average Score (%)")
plt.title("Module Performance Comparison")
plt.tight_layout()
plt.show()
```

## Scatter Plots

```python
np.random.seed(42)
study_hours  = np.random.uniform(0, 10, 50)
exam_scores  = study_hours * 7 + np.random.randn(50) * 5 + 30
module_group = np.random.choice(["A", "B"], 50)

colors_map = {"A": "#4F8EF7", "B": "#C9A84C"}
colors_arr = [colors_map[g] for g in module_group]

plt.figure(figsize=(8, 6))
plt.scatter(study_hours, exam_scores, c=colors_arr,
            s=60, alpha=0.7, edgecolors="white", linewidths=0.5)
plt.xlabel("Study Hours per Week")
plt.ylabel("Exam Score")
plt.title("Study Time vs. Exam Performance")

# Add a trend line
z = np.polyfit(study_hours, exam_scores, 1)
p = np.poly1d(z)
x_line = np.linspace(0, 10, 100)
plt.plot(x_line, p(x_line), "r--", alpha=0.6, label="Trend")
plt.legend()
plt.tight_layout()
plt.show()
```

## Subplots

Subplots let you place multiple charts side-by-side or in a grid on one figure — essential for dashboards and dissertation figures comparing multiple views of the same data.

```python
fig, axes = plt.subplots(1, 3, figsize=(15, 4))

# Plot 1 — Line
x = np.linspace(0, 10, 100)
axes[0].plot(x, np.sin(x), color="#4F8EF7")
axes[0].set_title("Sine Wave")

# Plot 2 — Histogram
data = np.random.normal(70, 15, 200)
axes[1].hist(data, bins=20, color="#C9A84C", edgecolor="white")
axes[1].set_title("Score Distribution")

# Plot 3 — Scatter
axes[2].scatter(np.random.rand(50), np.random.rand(50),
                c="#4CAF50", alpha=0.6)
axes[2].set_title("Random Scatter")

for ax in axes:
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)

plt.suptitle("Data Science Dashboard", fontsize=14, fontweight="bold")
plt.tight_layout()
plt.show()
```

## Histogram and Box Plot

```python
scores = np.random.normal(72, 12, 200).clip(0, 100)

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))

# Histogram
ax1.hist(scores, bins=25, color="#4F8EF7", edgecolor="white", alpha=0.85)
ax1.axvline(np.mean(scores), color="red", linestyle="--", label=f"Mean: {np.mean(scores):.1f}")
ax1.set_xlabel("Score"); ax1.set_title("Score Distribution")
ax1.legend()

# Box plot
ax2.boxplot(scores, patch_artist=True,
            boxprops=dict(facecolor="#C9A84C", alpha=0.7))
ax2.set_ylabel("Score"); ax2.set_title("Score Box Plot")

plt.tight_layout()
plt.show()
```

Effective visualisation is a core skill for any data scientist. Whether you are presenting findings to stakeholders, publishing in a journal, or building a dissertation chapter, well-crafted charts convey insights that tables of numbers cannot. Practise recreating charts you admire — then adapt them for your own data.
$L9$, 'applied', 9, 25),

(1, 'Capstone: Exploratory Data Analysis',
$L10$
# Capstone: Exploratory Data Analysis (EDA)

Exploratory Data Analysis is the process of investigating a dataset to discover patterns, spot anomalies, test hypotheses, and check assumptions — before building any model. This lesson walks you through a complete EDA workflow using UK census-style demographic data, mirroring what you might do in your dissertation.

## The EDA Workflow

A professional EDA follows these stages:
1. **Load and inspect** — understand shape, dtypes, missing values
2. **Clean** — handle missing data, fix types, remove duplicates
3. **Univariate analysis** — distribution of each variable in isolation
4. **Bivariate analysis** — relationships between pairs of variables
5. **Multivariate analysis** — patterns across multiple variables
6. **Summarise findings** — communicate key insights clearly

## Step 1: Load and Inspect

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

plt.style.use("seaborn-v0_8-darkgrid")

# Load data
df = pd.read_csv("ons_census_sample.csv")

print("Shape:", df.shape)
print("\nFirst 5 rows:")
print(df.head())
print("\nData types and non-null counts:")
print(df.info())
print("\nBasic statistics:")
print(df.describe())
```

## Step 2: Clean

```python
# Check missing values
missing = df.isnull().sum()
print("Missing values:\n", missing[missing > 0])

# Drop rows missing critical columns
df.dropna(subset=["age", "income"], inplace=True)

# Fix data types
df["age"] = pd.to_numeric(df["age"], errors="coerce")
df["income"] = pd.to_numeric(df["income"], errors="coerce")
df["region"] = df["region"].str.strip().str.title()

# Remove impossible values
df = df[(df["age"] >= 16) & (df["age"] <= 100)]
df = df[df["income"] >= 0]

# Remove duplicates
before = len(df)
df.drop_duplicates(inplace=True)
print(f"Removed {before - len(df)} duplicates")
```

## Step 3: Univariate Analysis

```python
# Age distribution
fig, axes = plt.subplots(1, 2, figsize=(12, 4))

axes[0].hist(df["age"], bins=30, color="#4F8EF7", edgecolor="white")
axes[0].set_xlabel("Age"); axes[0].set_title("Age Distribution")
axes[0].axvline(df["age"].mean(), color="red", linestyle="--",
                label=f"Mean: {df['age'].mean():.1f}")
axes[0].legend()

# Income distribution (log scale due to skew)
axes[1].hist(df["income"], bins=40, color="#C9A84C", edgecolor="white")
axes[1].set_xlabel("Income (£)"); axes[1].set_title("Income Distribution")
plt.tight_layout(); plt.show()

# Categorical columns
print(df["qualification"].value_counts(normalize=True).round(3) * 100)
print(df["employment_status"].value_counts())
```

## Step 4: Bivariate Analysis

```python
# Income vs. Age scatter
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

axes[0].scatter(df["age"], df["income"], alpha=0.3, s=10, color="#4F8EF7")
axes[0].set_xlabel("Age"); axes[0].set_ylabel("Income (£)")
axes[0].set_title("Age vs. Income")

# Add trend line
z = np.polyfit(df["age"].dropna(), df["income"].dropna(), 1)
x_range = np.linspace(df["age"].min(), df["age"].max(), 100)
axes[0].plot(x_range, np.poly1d(z)(x_range), "r--", alpha=0.8, label="Trend")
axes[0].legend()

# Mean income by qualification level
income_by_qual = df.groupby("qualification")["income"].mean().sort_values(ascending=False)
axes[1].bar(income_by_qual.index, income_by_qual.values, color="#C9A84C", edgecolor="white")
axes[1].set_xlabel("Qualification"); axes[1].set_ylabel("Mean Income (£)")
axes[1].set_title("Mean Income by Qualification")
plt.xticks(rotation=30, ha="right")
plt.tight_layout(); plt.show()

# Correlation matrix
numeric_cols = df.select_dtypes(include="number")
corr = numeric_cols.corr()
print("Correlation matrix:\n", corr.round(2))
```

## Step 5: Multivariate Analysis

```python
# Income by region and qualification — grouped bar chart
pivot = df.groupby(["region", "qualification"])["income"].mean().unstack()

pivot.plot(kind="bar", figsize=(14, 6), colormap="Set2", edgecolor="white")
plt.xlabel("Region"); plt.ylabel("Mean Income (£)")
plt.title("Mean Income by Region and Qualification Level")
plt.legend(title="Qualification", bbox_to_anchor=(1.05, 1))
plt.tight_layout(); plt.show()
```

## Step 6: Summarise Findings

```python
print("=" * 50)
print("EDA SUMMARY REPORT")
print("=" * 50)
print(f"Dataset: {len(df):,} respondents across {df['region'].nunique()} regions")
print(f"Age range: {df['age'].min():.0f} – {df['age'].max():.0f} (mean: {df['age'].mean():.1f})")
print(f"Income range: £{df['income'].min():,.0f} – £{df['income'].max():,.0f}")
print(f"Mean income: £{df['income'].mean():,.0f} | Median: £{df['income'].median():,.0f}")
print(f"\nKey finding: Income is positively correlated with age (r = {corr.loc['age','income']:.2f})")
print(f"Highest earning qualification: {income_by_qual.index[0]}")
print(f"Most represented region: {df['region'].value_counts().index[0]}")
```

This structured EDA workflow — load, clean, univariate, bivariate, multivariate, summarise — is applicable to any dataset you will encounter. For your dissertation evaluation, ensure your EDA section follows this pattern, documents every cleaning decision with justification, and draws evidence-based conclusions from your visualisations rather than speculation.
$L10$, 'applied', 10, 30);


-- ── QUIZ QUESTIONS (5 per lesson, 50 total) ─────────────────

-- Lesson 1: Variables & Data Types
INSERT INTO quiz_questions (lesson_id, question_text, option_a, option_b, option_c, option_d, correct_option, explanation) VALUES
(1, 'What does the expression type(3.14) return in Python?',
 '<class ''int''>', '<class ''float''>', '<class ''double''>', '<class ''number''>',
 'b', 'In Python, 3.14 is a floating-point literal. The float type represents decimal numbers. Python has no ''double'' type — that is a Java/C concept.'),
(1, 'Which of the following is NOT a valid Python variable name?',
 'my_variable', '_count', '2nd_place', 'total_score',
 'c', 'Variable names cannot start with a digit. ''2nd_place'' starts with ''2'', making it a syntax error. Names can start with letters or underscores only.'),
(1, 'What is the result of int("42")?',
 'Error: cannot convert string', '42.0', '42', '"42"',
 'c', 'int() converts a numeric string to an integer. "42" contains only digit characters, so int("42") returns the integer 42.'),
(1, 'What does bool(0) evaluate to in Python?',
 'True', 'False', '0', 'None',
 'b', 'In Python, the integer 0 is falsy. bool(0) returns False. Any non-zero number is truthy and returns True.'),
(1, 'What does the f-string f"Score: {85}" produce?',
 'f"Score: 85"', '"Score: {85}"', '"Score: 85"', 'SyntaxError',
 'c', 'f-strings (formatted string literals) evaluate expressions inside {} at runtime. f"Score: {85}" produces the string "Score: 85".');

-- Lesson 2: Control Flow
INSERT INTO quiz_questions (lesson_id, question_text, option_a, option_b, option_c, option_d, correct_option, explanation) VALUES
(2, 'What is the output of: print(5 > 3 and 2 < 1)?',
 'True', 'False', 'Error', 'None',
 'b', 'The ''and'' operator requires BOTH conditions to be True. 5 > 3 is True, but 2 < 1 is False. True and False evaluates to False.'),
(2, 'Which operator is used to test equality in Python?',
 '=', ':=', '==', '!=',
 'c', 'A single = is the assignment operator. == tests equality and returns True or False. != tests inequality. := is the walrus operator (assignment expression).'),
(2, 'What does the expression not True evaluate to?',
 'True', 'False', '1', 'Error',
 'b', 'The ''not'' operator inverts a Boolean. not True evaluates to False, and not False evaluates to True.'),
(2, 'Given x = 10, what does print("high" if x > 5 else "low") output?',
 '"high"', '"low"', 'True', 'Error',
 'a', 'This is a conditional expression (ternary operator). Since x=10 satisfies x > 5, the expression evaluates to "high".'),
(2, 'Which keyword skips the rest of the current loop iteration and moves to the next?',
 'break', 'next', 'continue', 'pass',
 'c', 'continue skips the remaining code in the current iteration and jumps to the next iteration. break exits the loop entirely. pass does nothing.'),

-- Lesson 3: Functions
(3, 'What keyword is used to define a function in Python?',
 'function', 'func', 'def', 'define',
 'c', 'Python uses the ''def'' keyword to define functions. Other languages use ''function'' (JavaScript) or ''func'' (Go/Swift), but in Python it is always ''def''.'),
(3, 'What does the following return: def add(a, b=5): return a + b — when called as add(3)?',
 'Error: missing argument', '5', '8', '3',
 'c', 'b has a default value of 5. When add(3) is called, a=3 and b uses its default of 5. So 3 + 5 = 8 is returned.'),
(3, 'What is a docstring in Python?',
 'A comment beginning with #', 'A string literal placed after the def line to document a function', 'A type annotation for parameters', 'A special print statement',
 'b', 'A docstring is a string literal (enclosed in triple quotes) placed immediately after the def line. It documents the function''s purpose, parameters, and return value.'),
(3, 'What does a function return if it has no return statement?',
 '0', 'Empty string ""', 'None', 'Error',
 'c', 'If a function has no return statement, or just ''return'' with no value, Python implicitly returns None — the absence of a value.'),
(3, 'Which of the following correctly defines a lambda that squares a number?',
 'lambda x => x**2', 'lambda(x): x**2', 'lambda x: x**2', 'def lambda(x): return x**2',
 'c', 'Lambda syntax is: lambda parameters: expression. There is no colon after ''lambda'', no parentheses are required around parameters, and the body is a single expression.'),

-- Lesson 4: Lists & Dictionaries
(4, 'What is the output of [1, 2, 3, 4, 5][1:4]?',
 '[1, 2, 3]', '[2, 3, 4]', '[2, 3, 4, 5]', '[1, 2, 3, 4]',
 'b', 'Python slicing is [start:stop] where stop is exclusive. [1:4] gives elements at index 1, 2, 3 — which are the values 2, 3, 4.'),
(4, 'Which list method adds an element to the END of a list?',
 'insert()', 'add()', 'append()', 'extend()',
 'c', 'append() adds a single element to the end of the list. insert(i, x) inserts at position i. extend() adds all elements from another iterable.'),
(4, 'What does the list comprehension [x**2 for x in range(4)] produce?',
 '[1, 4, 9, 16]', '[0, 1, 4, 9]', '[0, 1, 2, 3]', '[1, 2, 3, 4]',
 'b', 'range(4) generates 0, 1, 2, 3. Squaring each: 0²=0, 1²=1, 2²=4, 3²=9. So the result is [0, 1, 4, 9].'),
(4, 'How do you safely access a dictionary key that might not exist?',
 'd[key] with a try/except', 'd.get(key)', 'd.fetch(key)', 'd[key] or None',
 'b', 'd.get(key) returns None (or a specified default) if the key does not exist, without raising a KeyError. It is the idiomatic safe access method.'),
(4, 'What does {"a": 1, "b": 2}.items() return?',
 'A list of keys', 'A list of values', 'A view of (key, value) tuples', 'A list of dictionaries',
 'c', '.items() returns a dict_items view object containing (key, value) tuples. You can iterate over it with: for key, value in d.items()'),

-- Lesson 5: File I/O & Modules
(5, 'What is the main advantage of using the "with" statement when opening files?',
 'It makes reading faster', 'It automatically closes the file when the block exits, even on error', 'It allows writing to read-only files', 'It converts the file to UTF-8 automatically',
 'b', 'The ''with'' statement is a context manager. It calls the file object''s __exit__ method, which closes the file automatically — even if an exception occurs inside the block.'),
(5, 'Which file mode string opens a file for APPENDING without overwriting existing content?',
 '"w"', '"r"', '"a"', '"x"',
 'c', '"a" opens for appending. "w" creates or overwrites. "r" opens for reading only. "x" creates a new file but fails if it already exists.'),
(5, 'How do you import only the sqrt function from the math module?',
 'import math.sqrt', 'from math import sqrt', 'include math: sqrt', 'require math sqrt',
 'b', 'The ''from module import name'' syntax imports specific names. After ''from math import sqrt'' you can call sqrt() directly without the math. prefix.'),
(5, 'What does os.getcwd() return?',
 'The list of all files in the OS', 'The current working directory path', 'The operating system name', 'The user''s home directory',
 'b', 'os.getcwd() (get current working directory) returns the full path string of the directory where your Python script is currently running.'),
(5, 'Which standard library module provides functions for working with dates and times?',
 'time_utils', 'calendar', 'datetime', 'clock',
 'c', 'The ''datetime'' module provides datetime, date, time, and timedelta classes for working with dates and times. It is part of Python''s standard library.'),

-- Lesson 6: Pandas DataFrames
(6, 'Which Pandas method shows the first n rows of a DataFrame?',
 'df.top(n)', 'df.first(n)', 'df.head(n)', 'df.start(n)',
 'c', 'df.head(n) returns the first n rows (default 5). df.tail(n) returns the last n rows. These are the standard methods for quick visual inspection.'),
(6, 'What is the difference between df.loc and df.iloc in Pandas?',
 'loc is faster; iloc is safer', 'loc uses label-based indexing; iloc uses integer position-based indexing', 'loc is for columns; iloc is for rows', 'They are identical but loc is deprecated',
 'b', 'loc uses axis labels (column names, row index labels). iloc uses integer positions (0-based). df.loc[0, "name"] vs df.iloc[0, 0] — both can retrieve the same value but using different references.'),
(6, 'How do you filter a DataFrame to only show rows where column "score" is greater than 80?',
 'df.filter(score > 80)', 'df[df.score > 80]', 'df[df["score"] > 80]', 'df.where("score > 80")',
 'c', 'Boolean indexing: df["score"] > 80 creates a boolean Series, then df[...] uses it to filter rows. Using df.score > 80 also works but df["score"] is safer for column names with spaces.'),
(6, 'What does df.describe() show for a numeric DataFrame?',
 'Only the column names and data types', 'Count, mean, std, min, 25th/50th/75th percentile, max', 'The first and last rows only', 'A graphical histogram of each column',
 'b', 'df.describe() computes summary statistics for numeric columns: count, mean, standard deviation, minimum, 25th percentile (Q1), median (50th), 75th percentile (Q3), and maximum.'),
(6, 'Which method reads a CSV file into a Pandas DataFrame?',
 'pd.open_csv()', 'pd.load_csv()', 'pd.read_csv()', 'pd.import_csv()',
 'c', 'pd.read_csv() is the standard function for reading CSV files into a DataFrame. It supports many parameters: sep, header, index_col, dtype, na_values, etc.'),

-- Lesson 7: Data Cleaning
(7, 'Which Pandas method counts missing values (NaN) in each column?',
 'df.missing()', 'df.isnull().sum()', 'df.count_nan()', 'df.null_count()',
 'b', 'df.isnull() creates a boolean DataFrame (True where NaN). .sum() counts the Trues per column. This is the standard idiom for missing-value inspection.'),
(7, 'What does df.dropna(thresh=3) do?',
 'Drops columns with more than 3 NaN values', 'Drops rows that have fewer than 3 non-NaN values', 'Drops the first 3 rows containing NaN', 'Keeps only the 3 rows with fewest NaN values',
 'b', 'thresh=n keeps rows that have at least n non-NaN values. So thresh=3 DROPS rows with fewer than 3 valid values — meaning rows that are more than (cols-3) empty.'),
(7, 'What is the purpose of pd.to_numeric(df["col"], errors="coerce")?',
 'It converts the column to string type', 'It converts values to numbers and replaces unparseable values with NaN', 'It raises an error for any non-numeric value', 'It rounds all values to the nearest integer',
 'b', 'errors="coerce" silently replaces values that cannot be converted to NaN, rather than raising an error. This is ideal for mixed-type columns from real-world CSV data.'),
(7, 'Which method removes duplicate rows from a DataFrame, keeping the first occurrence?',
 'df.remove_duplicates()', 'df.drop_duplicates()', 'df.unique()', 'df.deduplicate()',
 'b', 'df.drop_duplicates() removes duplicate rows. By default, keep="first" retains the first occurrence. You can also specify subset=["col1","col2"] to check specific columns only.'),
(7, 'How do you fill NaN values in a column with the column''s mean?',
 'df["col"].replace(NaN, df["col"].mean())', 'df["col"].fillna(df["col"].mean())', 'df["col"].impute("mean")', 'df["col"].nan_to_mean()',
 'b', 'fillna() replaces NaN values. Passing df["col"].mean() as the argument fills each NaN with the computed mean. This is called mean imputation — a common technique for numeric columns.'),

-- Lesson 8: NumPy Arrays
(8, 'What is the shape of np.zeros((3, 4))?',
 '(4, 3)', '(3, 4)', '(7,)', '(12,)',
 'b', 'np.zeros((3, 4)) creates an array with 3 rows and 4 columns. The shape tuple is always (rows, columns) for 2D arrays, matching the argument passed.'),
(8, 'What is the output of np.array([1, 2, 3]) * 2?',
 'Error: cannot multiply array by scalar', '[1, 2, 3, 1, 2, 3]', '[2, 4, 6]', '[[2], [4], [6]]',
 'c', 'NumPy operations are vectorised — they apply element-wise. Multiplying a 1D array by the scalar 2 doubles every element: [1*2, 2*2, 3*2] = [2, 4, 6].'),
(8, 'What does array[array > 5] return for array = np.array([3, 7, 2, 8, 5])?',
 '[3, 2, 5]', '[7, 8]', '[True, True]', 'Error',
 'b', 'Boolean indexing: array > 5 creates [False, True, False, True, False]. Using this mask to index returns only the elements where True: [7, 8].'),
(8, 'What does np.linspace(0, 1, 5) return?',
 '[0, 1, 2, 3, 4]', '[0.0, 0.25, 0.5, 0.75, 1.0]', '[0.2, 0.4, 0.6, 0.8, 1.0]', '[0, 0.25, 0.5, 0.75]',
 'b', 'np.linspace(start, stop, num) returns num evenly spaced values from start to stop INCLUSIVE. linspace(0, 1, 5) gives 5 values: 0, 0.25, 0.5, 0.75, 1.0.'),
(8, 'Which NumPy function computes the mean along axis=0 (column-wise) of a 2D array?',
 'np.mean(arr, axis=1)', 'np.average(arr)', 'np.mean(arr, axis=0)', 'np.col_mean(arr)',
 'c', 'axis=0 collapses along rows, computing statistics for each column. axis=1 collapses along columns, computing statistics for each row. np.mean(arr, axis=0) gives column means.'),

-- Lesson 9: Matplotlib
(9, 'Which function in Matplotlib saves the current figure to a file?',
 'plt.export()', 'plt.save()', 'plt.savefig()', 'plt.write()',
 'c', 'plt.savefig("filename.png") saves the current figure. You can specify format via the extension (.png, .pdf, .svg) and quality with the dpi parameter.'),
(9, 'What does plt.tight_layout() do?',
 'Compresses the figure to minimum size', 'Adjusts subplot spacing to prevent overlap of labels and titles', 'Locks the figure so it cannot be resized', 'Applies a tight grid to all axes',
 'b', 'plt.tight_layout() automatically adjusts subplot parameters to give specified padding and prevent labels, titles, and colorbars from overlapping each other.'),
(9, 'In a scatter plot, what does the alpha parameter control?',
 'The size of each point', 'The transparency/opacity of the points', 'The colour palette', 'The axis scale',
 'b', 'alpha controls transparency: 0.0 is fully transparent (invisible), 1.0 is fully opaque. Lower alpha values allow overlapping points to be visible, revealing data density.'),
(9, 'What is the correct way to label the x-axis in Matplotlib?',
 'plt.x_label("label")', 'plt.xlabel("label")', 'plt.set_x("label")', 'axes.x_title("label")',
 'b', 'plt.xlabel("label") sets the x-axis label on the current axes. For an Axes object, use ax.set_xlabel("label"). Similarly plt.ylabel() / ax.set_ylabel() for the y-axis.'),
(9, 'How do you create a figure with 2 plots side-by-side?',
 'plt.figure(plots=2)', 'plt.subplots(1, 2)', 'plt.plot(2)', 'plt.axes(side_by_side=True)',
 'b', 'plt.subplots(nrows, ncols) creates a Figure and an array of Axes. plt.subplots(1, 2) gives one row, two columns: fig, (ax1, ax2) = plt.subplots(1, 2)'),

-- Lesson 10: Capstone EDA
(10, 'What is the PRIMARY goal of Exploratory Data Analysis?',
 'To train a machine learning model on the data', 'To investigate the data to discover patterns, anomalies, and relationships before modelling', 'To clean all missing values from the dataset', 'To create a final report for publication',
 'b', 'EDA''s goal is exploration and understanding — not modelling or final reporting. It guides all subsequent decisions: which models to try, which features to engineer, which cleaning steps are needed.'),
(10, 'In the EDA workflow, which stage should come BEFORE bivariate analysis?',
 'Building a predictive model', 'Multivariate analysis', 'Univariate analysis', 'Publishing findings',
 'c', 'The EDA workflow is: Load → Clean → Univariate → Bivariate → Multivariate → Summarise. Understanding each variable individually (univariate) before exploring relationships between pairs (bivariate) is best practice.'),
(10, 'What does df.corr() compute?',
 'The covariance matrix', 'Pairwise Pearson correlation coefficients between numeric columns', 'The number of unique values per column', 'The p-values for each column pair',
 'b', 'df.corr() computes the Pearson correlation matrix by default — pairwise correlation coefficients between all numeric columns. Values range from -1 (perfect negative) to +1 (perfect positive).'),
(10, 'Which of these is an example of MULTIVARIATE analysis?',
 'Plotting a histogram of income', 'Computing the mean age in the dataset', 'Comparing mean income by both region AND qualification level simultaneously', 'Counting missing values per column',
 'c', 'Univariate = one variable. Bivariate = two variables. Multivariate = three or more variables analysed together. Plotting income by region AND qualification jointly is multivariate.'),
(10, 'Why is it important to use pd.to_numeric(col, errors="coerce") during cleaning?',
 'It converts the column to boolean', 'It removes all numeric values from the column', 'It safely converts columns to numeric, turning non-parseable values to NaN rather than crashing', 'It rounds values to the nearest whole number',
 'c', 'Real datasets often have mixed-type columns — e.g., a "salary" column containing "42000" and "N/A". errors="coerce" converts numeric strings and turns anything else into NaN, preventing a ValueError from stopping your pipeline.');


-- ── BADGES ───────────────────────────────────────────────────
INSERT INTO badges (id, name, description, icon_name, criteria_type, criteria_value) VALUES
(1, 'First Step',      'Complete your very first lesson',                   'rocket_launch',   'lessons_completed', 1),
(2, 'Python Padawan',  'Complete all 4 Foundations lessons',                'school',          'lessons_completed', 4),
(3, 'Data Handler',    'Complete all 3 Data Handling lessons',              'table_chart',     'lessons_completed', 7),
(4, 'Data Scientist',  'Complete all 10 lessons — the full course!',        'science',         'lessons_completed', 10),
(5, 'Perfectionist',   'Score 5/5 on any quiz',                             'stars',           'perfect_quiz',      1),
(6, 'On Fire',         'Maintain a 3-day learning streak',                  'local_fire_department', 'streak_days', 3),
(7, 'Week Warrior',    'Maintain a 7-day learning streak',                  'military_tech',   'streak_days',       7),
(8, 'Centurion',       'Earn 100 XP total',                                 'emoji_events',    'total_xp',          100);
