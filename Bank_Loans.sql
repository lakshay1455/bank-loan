USE others;

SELECT * FROM financial_loan;
SELECT * FROM state_codes;

DESCRIBE financial_loan;

# Find the top 5 states with the highest average loan amount, but only include states with more than 1000 loans and show their ranks

WITH big_5 as
(
SELECT			state, ROUND(AVG(loan_amount),2) as loan_amount, COUNT(1) as number_of_loans
FROM			financial_loan a
LEFT JOIN		state_codes b
ON				a.address_state = b.abb
GROUP BY		state
HAVING			number_of_loans > 1000
ORDER BY		2 desc
LIMIT			5
)
SELECT			RANK() OVER(ORDER BY loan_amount desc) as Position, state, loan_amount, number_of_loans
FROM			big_5;

# For each loan status, calculate the difference between the average annual income and the median annual income

SELECT			a.*, median_income, ROUND((avg_annual_income - median_income),2) difference
FROM			(
					SELECT			loan_status, ROUND(AVG(annual_income),2) as avg_annual_income
					FROM			financial_loan
					GROUP BY 		loan_status
                ) a
JOIN			(
					WITH ranked_income_2 as
					(
					WITH ranked_income as
					(
					SELECT			ROW_NUMBER() OVER(PARTITION BY loan_status ORDER BY annual_income) as Position, loan_status, annual_income
					FROM			financial_loan
					)
					SELECT			position, loan_status, annual_income, MAX(position) OVER(PARTITION BY loan_status) highest_position
					FROM			ranked_income
					ORDER BY		2, 1
					)
					SELECT			loan_status, AVG(annual_income) as median_income
					FROM			ranked_income_2
					WHERE			CASE WHEN highest_position%2 != 0 then position = (highest_position + 1)/2
										 ELSE position = highest_position/2 or position = (highest_position/2) + 1
										 END
					GROUP BY		loan_status
				) b
ON				a.loan_status = b.loan_status;

# Identify the grade with the highest default rate (i.e., the ratio of ‘Charged Off’ loans to the total number of loans)

SELECT			grade,
				SUM(CASE WHEN loan_status = "Charged Off" then 1
					     ELSE 0
                         END) as no_of_bad_loans,
				COUNT(1) as total_loans,
                (SUM(CASE WHEN loan_status = "Charged Off" then 1
					     ELSE 0
                         END)/COUNT(1))*100 as `default_rate(%)`
FROM			financial_loan
GROUP BY		grade
ORDER BY		4 desc;

# For each home ownership type, calculate the average loan amount, but only include home ownership types where the total number of loans is above the overall average

SELECT			home_ownership, AVG(loan_amount) as avg_loan_amount
FROM			financial_loan
GROUP BY		home_ownership
HAVING			COUNT(1) > (SELECT		    AVG(total_count)
							FROM			(SELECT		COUNT(1) as total_count
											FROM		financial_loan
											GROUP BY	home_ownership) a);
                                            
# Month on month changes in loan applications

WITH month_data_2 AS
(
WITH month_data AS
(
SELECT 			DATE_FORMAT(CAST(STR_TO_DATE(issue_date, '%d-%m-%Y') as DATE), '%b %Y') AS month_year, COUNT(1) as no_of_applications,
				DATE_FORMAT(CAST(STR_TO_DATE(issue_date, '%d-%m-%Y') as DATE), '%m %Y') AS month_year_2
FROM 			financial_loan
GROUP BY		1, 3
ORDER BY		3
)
SELECT			month_year, no_of_applications, LAG(no_of_applications) OVER(ORDER BY month_year_2) prev_month_applications
FROM			month_data
)
SELECT			month_year, no_of_applications, CONCAT(CAST(ROUND((no_of_applications - prev_month_applications)*100/prev_month_applications,2) as CHAR), " %") as month_on_month_change
FROM			month_data_2;

# Month on month changes in funded amount

WITH month_data_2 AS
(
WITH month_data AS
(
SELECT 			DATE_FORMAT(CAST(STR_TO_DATE(issue_date, '%d-%m-%Y') as DATE), '%b %Y') AS month_year, SUM(loan_amount) as total_loan_amount,
				DATE_FORMAT(CAST(STR_TO_DATE(issue_date, '%d-%m-%Y') as DATE), '%m %Y') AS month_year_2
FROM 			financial_loan
GROUP BY		1, 3
ORDER BY		3
)
SELECT			month_year, total_loan_amount, LAG(total_loan_amount) OVER(ORDER BY month_year_2) prev_month_amount
FROM			month_data
)
SELECT			month_year, total_loan_amount, CONCAT(CAST(ROUND((total_loan_amount - prev_month_amount)*100/prev_month_amount,2) as CHAR), " %") as month_on_month_change
FROM			month_data_2;

# Month on month changes in amount received

WITH month_data_2 AS
(
WITH month_data AS
(
SELECT 			DATE_FORMAT(CAST(STR_TO_DATE(issue_date, '%d-%m-%Y') as DATE), '%b %Y') AS month_year, SUM(total_payment) as amount_received,
				DATE_FORMAT(CAST(STR_TO_DATE(issue_date, '%d-%m-%Y') as DATE), '%m %Y') AS month_year_2
FROM 			financial_loan
GROUP BY		1, 3
ORDER BY		3
)
SELECT			month_year, amount_received, LAG(amount_received) OVER(ORDER BY month_year_2) prev_month_amount_received
FROM			month_data
)
SELECT			month_year, amount_received, CONCAT(CAST(ROUND((amount_received - prev_month_amount_received)*100/prev_month_amount_received,2) as CHAR), " %") as month_on_month_change
FROM			month_data_2;

#  Express loan amount as a percentage of annual income for each loan status.

SELECT			loan_status, SUM(loan_amount) as total_loan_amount, ROUND(SUM(annual_income),0) as total_annual_income, ROUND((SUM(loan_amount)/SUM(annual_income)),4)*100 as loan_income_percentage
FROM			financial_loan
GROUP BY		loan_status
ORDER BY		4 desc;

#  Express loan amount as a percentage of annual income for each loan grade

SELECT			grade, SUM(loan_amount) as total_loan_amount, ROUND(SUM(annual_income),0) as total_annual_income, ROUND((SUM(loan_amount)/SUM(annual_income))*100,2) as loan_income_percentage
FROM			financial_loan
GROUP BY		grade
ORDER BY		1;

# Find the total number of loans issued in each state

SELECT			state, COUNT(1) as number_of_loans
FROM			financial_loan a
LEFT JOIN		state_codes b
ON				a.address_state = b.abb
GROUP BY		state
ORDER BY		2 desc;

# Find the total loan amount for each grade.

SELECT			grade, SUM(loan_amount) loan_amount
FROM			financial_loan
GROUP BY		grade
ORDER BY		1;

# Find the average debt to income ratio for each home ownership type
SELECT			home_ownership, ROUND(AVG(dti),2) avg_debt_to_income_ratio
FROM			financial_loan
GROUP BY		home_ownership;

# Find the average installment for each term

SELECT			term, ROUND(AVG(installment),2) avg_installment
FROM			financial_loan
GROUP BY		term
ORDER BY		1;

# KEY PERFROMANCE INDICATORS
# Total Loan Applications
SELECT			COUNT(1) as total_loan_applications
FROM			financial_loan;
# Total Funded Amount
SELECT			SUM(loan_amount) total_funded_amount
FROM			financial_loan;
# Total amount received
SELECT			SUM(total_payment) total_amount_received
FROM			financial_loan;
# Average Interest Rate
SELECT			CONCAT(CAST(ROUND(AVG(int_rate)*100,2) AS char(10)),"%") average_interest_rate
FROM			financial_loan;
# Average Debt to income ratio
SELECT			ROUND(AVG(dti),3) debt_to_income_ratio
FROM			financial_loan;

# BAD LOANS vs GOOD LOANS

WITH debt_status_info AS
(
SELECT			CASE WHEN loan_status = "Charged Off" then "Bad Loans"
					 ELSE "Good Debts"
                     End `Good_or_Bad_Debts`, loan_amount, total_payment
FROM			financial_loan
)
SELECT			Good_or_Bad_Debts, COUNT(1) as no_of_applications, SUM(loan_amount) as funded_amount, SUM(total_payment) as amount_received,
				CONCAT(CAST(ROUND(COUNT(1)*100/(SELECT COUNT(1) FROM financial_loan),2) as char),"%") as application_percentage
FROM			debt_status_info
GROUP BY		1;

# Employment term vs loan default

SELECT			emp_length, SUM(IF(loan_status = "Charged Off", 1,0)) as loans_defaulted, COUNT(1) as total_loans, SUM(IF(loan_status = "Charged Off", 1,0))/COUNT(1) as default_ratio
FROM			financial_loan 
GROUP BY		1
ORDER BY		1;
