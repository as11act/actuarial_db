# Actuarial_db
The purpose of this project is create the database architecture for actuarial and finance calculations.

Actuarial database architecture is created for finance and actuarial calculations. Increment journals are contain all information about source data and the differences from previous points. All calculation logic constructed to calculate differences between loads alternatively to full calculations on full source data information. So, the project started from architecture of increment journals (insurance premium, losses, ... ) to architecture of actuarial models: reserves, cash-flow, maturity, sensitivity, and so on. IFRS4, IFRS17, non-life insurance.

# Increment_journals
The main idea of the Increment_journals:
1.  We have got some sources in databases, we should create meta data of source columns of input journals for future purpose of finance/actuarial calculations
2.  We want to do a calculations very often and fast - so, we need calculate only differences from prev loading. The differences we should calculate if we don't have increment information of source data.
3.  Calculate only portion of data for all finance/actuarial logic (IFRS4, non-life insurance, triangles).

What is journal? - it's a table with union sources for future calculations
For example, in the field of insurance there are exists issued policies journal or written premium, paid losses, ..

Database model created in pgModeler.
