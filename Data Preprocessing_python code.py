## Acounting Final Project Code Part 1


import pandas as pd

# Load the dataset
file_path = 'C:/Users/aadel/OneDrive/Documents/Mcgill Masters/3. Winter Term/Winter 2/Accounting/Final Project/CEO Dismissal Data 2021.02.03.xlsx'  # Adjusted to the uploaded file path in this environment
data = pd.read_excel(file_path)

# Keep only the specified columns
columns_to_keep = ['coname', 'gvkey', 'exec_fullname', 'Departure Code', 'The fiscal year during which the CEO exited - for clarity', 'leftofc']
data = data[columns_to_keep]

# Rename 'the fiscal year during which' to 'year'
data.rename(columns={'The fiscal year during which the CEO exited - for clarity': 'year'}, inplace=True)
data.rename(columns={'leftofc': 'day'}, inplace=True)


# Delete any rows with missing values
data.dropna(inplace=True)

# Keep only the rows where 'year' is between 2014 and 2021
data = data[data['year'].between(2014, 2021)]

# Display the cleaned data
data.head()


# Dummify the 'departure code' column
departure_dummies = pd.get_dummies(data['Departure Code'], prefix='departure_code').astype(int)

# Concatenate the dummy DataFrame with the original DataFrame
data_with_dummies = pd.concat([data, departure_dummies], axis=1)

# Optionally, you can drop the original 'departure code' column if you no longer need it
data_with_dummies.drop('Departure Code', axis=1, inplace=True)

# Display the DataFrame to verify the new dummy columns
print(data_with_dummies.head())


# Specify the path and name for the new Excel file
output_file_path = 'C:/Users/aadel/OneDrive/Documents/Mcgill Masters/3. Winter Term/Winter 2/Accounting/Final Project/Cleaned_data_CEO_departure.xlsx'

# Save the DataFrame to an Excel file
data_with_dummies.to_excel(output_file_path, index=False)

print(f'Data saved to {output_file_path}')


############# PART 2

#This section is done in SAS. It cleans the compustat data

#### Step 3

import pandas as pd

# Step 1: Read the Excel files
ceo_data = pd.read_excel('C:/Users/aadel/OneDrive/Documents/Mcgill Masters/3. Winter Term/Winter 2/Accounting/Final Project/Cleaned_data_CEO_departure.xlsx')
compustat_data = pd.read_excel('C:/Users/aadel/OneDrive/Documents/Mcgill Masters/3. Winter Term/Winter 2/Accounting/Final Project/Compustat_data-winsorized.xlsx')

# Rename and clean Compustat data
compustat_data.rename(columns={
    'FYEAR': 'year',
    'GVKEY': 'gvkey',
    'PRCC_C': 'stock_price'}, inplace=True)
compustat_data = compustat_data.dropna(subset=['year'])
compustat_data['year'] = compustat_data['year'].astype(int)

# Calculate year-over-year changes for each financial metric in Compustat data
metrics = ['ROE', 'ROA', 'TAT', 'stock_price']
for metric in metrics:
    compustat_data[f'change_in_{metric}'] = compustat_data.groupby('gvkey')[metric].diff()

# Merge year-over-year changes with CEO data
# We shift the year in Compustat data by -1 to align the changes with the CEO departure year
compustat_data['year'] = compustat_data['year'] + 1
merged_data = pd.merge(ceo_data, compustat_data, on=['gvkey', 'year'], how='left', suffixes=('', '_compustat'))

merged_data = merged_data.dropna(subset=['change_in_ROE', 'change_in_ROA', 'change_in_TAT', 'change_in_stock_price'])

merged_data = merged_data[merged_data['departure_code_9.0'] != 1]

# Specify the path and name for the new Excel file
output_file_path_2 = 'C:/Users/aadel/OneDrive/Documents/Mcgill Masters/3. Winter Term/Winter 2/Accounting/Final Project/Merged_final_data.xlsx'

# Save the DataFrame to an Excel file
merged_data.to_excel(output_file_path_2, index=False)

print(f'Data saved to {output_file_path_2}')


## Step 4 - CREATE MODELS (TO BE CHANGED)

#import pandas as pd
#import statsmodels.api as sm

# Assuming merged_data contains the necessary dummified departure code columns
# If not, you may need to merge or concatenate them from ceo_data

# Define the target variable (dependent variable) and independent variables
#target = 'change_in_TAT'
#target = 'change_in_ROE'
#target = 'change_in_ROA'
#target = 'change_in_stock_price'
#independent_variables = [col for col in merged_data.columns if 'departure_code_' in col]  # Adjust this list as necessary

# Adding a constant to the model for the intercept
#X = sm.add_constant(merged_data[independent_variables])
#y = merged_data[target]

# Fit the linear regression model
#model = sm.OLS(y, X, missing='drop').fit()  # 'missing='drop'' automatically drops any rows with NaN values

# Print the coefficients
#print(model.summary())

# If you specifically want just the coefficients
#print("\nCoefficients:")
#print(model.params)


