-- Who are the top 10 highest-spending customers
select c.customer_id, c.customer_name, SUM(t.amount) AS total_spent
from transactions t
join customer c ON t.customer_id = c.customer_id
group by c.customer_id, c.customer_name
order by total_spent desc
limit 10;

-- What is the average transaction amount for each customer
select c.customer_id, c.customer_name, avg(t.amount) as average_amount
from transactions t
join customer c on t.customer_id=c.customer_id
group by c.customer_id,c.customer_name
order by average_amount desc;

-- How does customer income relate to their total spending
select c.customer_id,c.customer_name,c.income, sum(t.amount) as total_spend, round(sum(t.amount)/(c.income), 2) as spend_to_income_ratio
from transactions t
join customer c on t.customer_id=c.customer_id
group by c.customer_id,c.customer_name,c.income
order by spend_to_income_ratio desc;

-- What is the distribution of spending among different age groups
SELECT 
CASE 
when c.age between 18 AND 24 then '18-24'
when c.age between 25 AND 34 then '25-34'
when c.age between 35 AND 44 then '35-44'
when c.age between 45 AND 54 then '45-54'
when c.age between 55 AND 64 then '55-64'
else '65+'
end AS age_group,
COUNT(DISTINCT c.customer_id) AS total_customers,
SUM(t.amount) AS total_spent,
avg(t.amount) AS avg_spent_per_transaction
from transactions t
join customer c ON t.customer_id = c.customer_id
group by age_group
order by age_group;

-- How many transactions does each customer make on average per month
select t.customer_id, c.customer_name,
COUNT(t.transaction_id) / COUNT(DISTINCT DATE_FORMAT(t.transaction_date, '%Y-%m')) AS avg_transactions_per_month
from  transactions t
join customer c ON t.customer_id = c.customer_id
group by t.customer_id, c.customer_name
order by avg_transactions_per_month DESC;

-- Which region has the highest total transaction amount
select c.region,sum(t.amount)  as highest_amount
from transactions t 
join customer c on t.customer_id=c.customer_id
group by c.region
order by highest_amount desc;

-- What is the average transaction amount per region
select c.region,avg(t.amount) as average_amount
from transactions t 
join customer c on t.customer_id=c.customer_id
group by c.region
order by average_amount desc;


-- How does spending behavior vary across regions
select c.region,count(t.transaction_id) as transaction_total, sum(t.amount) as total_spend, avg(t.amount) as avergae_spend,
count(case when t.transaction_type="credit" then 1 end) as cash,
count(case when t.transaction_type="debit" then 1 end) as online_trans
from transactions t 
join customer c on t.customer_id=c.customer_id
group by c.region
order by total_spend;

-- Which region has the most frequent transactions
select c.region,count(t.transaction_id) as total_transaction
from transactions t 
join customer c  on t.customer_id=c.customer_id
group by c.region
order by  total_transaction desc
limit 1;

-- Do high-income customers belong to specific regions
select c.region, COUNT(c.customer_id) AS total_customers, AVG(c.income) AS avg_income,MAX(c.income) AS highest_income
from customer c
group by c.region
order by avg_income DESC;

-- What is the percentage distribution of credit vs. debit transactions
select transaction_type,COUNT(transaction_id) AS total_transactions,
ROUND(COUNT(transaction_id) / (SELECT COUNT(*) FROM transactions)*100, 2) AS percentage
from transactions
where transaction_type IN ('Credit', 'Debit')
group by transaction_type
order by percentage DESC;

-- How does the total transaction amount vary by month?
select date_format(transaction_date, '%y-%m') as transaction_month,sum(amount) as total_amount
from transactions
group by transaction_month
order by total_amount asc;

-- Are there seasonal trends in transaction amounts
select date_format(transaction_date, '%y-%m') as transaction_month,sum(amount) as total_amount
from transactions
group by transaction_month
order by transaction_month desc;

select YEAR(transaction_date) AS year,QUARTER(transaction_date) AS quarter,SUM(amount) AS total_transaction_amount
from transactions
group by year, quarter
order by year ASC, quarter ASC;

-- What is the average amount per transaction type 
select transaction_type,avg(amount) as average_amount
from transactions
group by transaction_type
order by average_amount desc;

-- Which months have the highest and lowest transaction volumes
select MONTH(transaction_date) AS transaction_month, COUNT(transaction_id) AS total_transactions
from transactions
group  by transaction_month
order by total_transactions DESC;

-- What is the total number of transactions per customer segment (low, mid, high spenders)
select customer_id, COUNT(transaction_id) AS total_transactions,
CASE 
	when COUNT(transaction_id) < 5 THEN 'Low'
	when COUNT(transaction_id) BETWEEN 5 AND 10 THEN 'Mid'
	else 'High'
end AS customer_segment
from transactions
group by customer_id
order by total_transactions DESC;

-- Which customers have increased their spending over time
WITH customer_spending AS (
select customer_id, DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,SUM(amount) AS total_spent
    from transactions
    group by  customer_id, transaction_month
),
spending_trend AS (
    select 
c1.customer_id,
c1.transaction_month,
c1.total_spent,
LAG(c1.total_spent) OVER (PARTITION BY c1.customer_id ORDER BY c1.transaction_month) AS previous_spent
from customer_spending c1
)
select
customer_id,
transaction_month,
total_spent,
previous_spent,
(total_spent - previous_spent) AS spending_difference
from spending_trend
where total_spent > previous_spent
order by customer_id, transaction_month;

-- How many customers have made only one transaction
with one_time_customers as(
SELECT c.customer_id, c.customer_name
FROM customer c
JOIN transactions t ON c.customer_id = t.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(t.transaction_id) = 1)
SELECT *, 
       (SELECT COUNT(*) FROM one_time_customers) AS total_single_transaction_customers
FROM one_time_customers
limit 10;

-- What percentage of customers account for 80% of total spending
WITH customer_spending AS (
select customer_id, SUM(amount) AS total_spent
FROM transactions
GROUP BY customer_id
), ranked_customers AS (
select customer_id, total_spent,
SUM(total_spent) OVER (ORDER BY total_spent DESC) AS running_total,
SUM(total_spent) OVER () AS grand_total
from customer_spending
)
select COUNT(customer_id) AS top_customers,
    ROUND(COUNT(customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM transactions) * 100, 2) AS percentage_of_customers
from  ranked_customers
where running_total <= 0.8 * grand_total;

-- Which customer age group is the most active in terms of transactions
select 
CASE 
	WHEN c.age BETWEEN 18 AND 25 THEN '18-25'
	WHEN c.age BETWEEN 26 AND 35 THEN '26-35'
	WHEN c.age BETWEEN 36 AND 45 THEN '36-45'
	WHEN c.age BETWEEN 46 AND 60 THEN '46-60'
	ELSE '60+'
    END AS age_group,
    COUNT(t.transaction_id) AS total_transactions
from transactions t
join customer c ON t.customer_id = c.customer_id
group by age_group
order by total_transactions DESC;
