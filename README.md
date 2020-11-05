# Increment_journals
The main idea of the Increment_journals:
1.  We have got some sources in databases, make metada of source columns for future purpose of finance/actuarial calculations
2.  We want make a calculations very often and fast - so, we need calculate only diff from prev loading. The diff we should calculate if we doesnt have incriment information of source data.
3.  Calculate only portion of data for all finance/actuarial logic (IFRS4, non-life insurance, triangles). 

What is journal? - it's a table with union from sources for future calculations
For example, in insurance exists issued policies journal or written premium.

Database model created in pgModeler. 

Actuarial database architecture for finance and actuarial calculations. Increment journals are contain all information of source data and the differences from prev points. All calculation logic constructed to calculate diff not full source data information. So, the project started from architecture of increment journals (insurance premium, losses, ... ) to architecture of actuarial models: reserves, cash-flow, maturity, sensitivity, and so on. IFRS4, IFRS17, non-life insurance.
