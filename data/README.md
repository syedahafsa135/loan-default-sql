# Data

The data is **not** stored in this repository (Kaggle licence, and the files are large). To rebuild it:

1. Download `Loan_default.csv` (255,347 rows, 18 columns) from the Kaggle page **Loan Default Prediction Dataset** by Nikhil:
   <https://www.kaggle.com/datasets/nikhil1e9/loan-default/data>
2. Put it in this `data/` folder.
3. From the repository root, run:

   ```bash
   python src/prepare_data.py     # writes data/Loan_default_cleaned.csv
   python src/load_data.py        # writes data/loans.db, table loans_raw
   ```

`prepare_data.py` is the same script used in [loan-default-classification](https://github.com/syedahafsa135/loan-default-classification). It makes the two record-level fixes from Part 1 of that project:

- Removing apostrophes from Education.
- Capping MonthsEmployed at (Age − 16) × 12 for 17,274 records.

| Column | Meaning |
|---|---|
| LoanID | Unique identifier |
| Age, Income, LoanAmount, CreditScore, MonthsEmployed | Numeric borrower and loan details |
| NumCreditLines, InterestRate, LoanTerm, DTIRatio | Numeric loan terms |
| Education, EmploymentType, MaritalStatus, HasMortgage, HasDependents, LoanPurpose, HasCoSigner | Categorical attributes |
| Default | Target: 1 = defaulted (11.61% of loans), 0 = not defaulted |
