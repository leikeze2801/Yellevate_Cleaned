/****************************************** DATA CLEANING AND FILTERING *****************************************/

SELECT * FROM yellevate_invoices;

-- getting total number of rows
SELECT COUNT(*) FROM yellevate_invoices;

-- getting unique data
SELECT DISTINCT country
FROM yellevate_invoices;

-- detecting NULL VALUES
SELECT * FROM yellevate_invoices
WHERE NOT(yellevate_invoices IS NOT NULL);

-- Checking duplicates
SELECT country, 
    invoice_number, 
    invoice_date,
    invoice_amount_usd
FROM yellevate_invoices
GROUP BY 1,2,3,4
HAVING COUNT(*) > 1;

-- creating zscore
SELECT country,
    invoice_date,
    invoice_amount_usd,
    (invoice_amount_usd - AVG(invoice_amount_usd) over()) / STDDEV(invoice_amount_usd) over() AS zscore
FROM yellevate_invoices; 

-- Detecting zscore
SELECT *
FROM (SELECT country,
        invoice_date,
        invoice_amount_usd,
        (invoice_amount_usd - AVG(invoice_amount_usd) over()) / STDDEV(invoice_amount_usd) over() AS zscore
     FROM yellevate_invoices ) AS outliers
WHERE zscore >2.576 OR zscore <-2.576
ORDER BY zscore;


/****************************************** DATA ANALYSIS GOALS *****************************************/


--1) The processing time in which invoices are settled (average # of days rounded to a whole number) 

--as a whole(with and without disputes)
SELECT ROUND(AVG(days_to_settle),0) AS invoice_processing_time
FROM yellevate_invoices;

--excluding dispute claims
SELECT ROUND(AVG(days_to_settle),0) AS invoice_processing_time
FROM yellevate_invoices
WHERE disputed = 0;

--late settlements
SELECT
ROUND(AVG(due_date - settled_date),0) AS invoice_processing_time
FROM yellevate_invoices;

--2) The processing time for the company to settle disputes (average # of days rounded to a whole number)

--dispute claims as a WHOLE
SELECT ROUND(AVG(days_to_settle),0) AS dispute_processing_time
FROM yellevate_invoices
WHERE disputed = 1;

--lost dispute claims ONLY
SELECT ROUND(AVG(days_to_settle),0) AS dispute_processing_time
FROM yellevate_invoices
WHERE dispute_lost = 1;

--3) Percentage of disputes received by the company that were lost (within two decimal places)

-- count of disputed
SELECT COUNT (disputed)
FROM yellevate_invoices
WHERE disputed = 1;

-- count of lost dispute
SELECT COUNT(dispute_lost)
FROM yellevate_invoices
WHERE dispute_lost = 1;

-- getting the percentage
SELECT SUM(dispute_lost) AS count_of_lost_dispute,
     SUM(disputed) AS count_of_dispute,
     ROUND(SUM(dispute_lost) / SUM(disputed) * 100,2) AS lost_dispute_percentage
FROM yellevate_invoices;

--4) Percentage of revenue lost from disputes (within two decimal places)

-- overall total of revenue
SELECT SUM(invoice_amount_usd)
FROM yellevate_invoices;

-- total of lost revenue from dispute
SELECT SUM(invoice_amount_usd)
FROM yellevate_invoices
WHERE dispute_lost = 1;

-- getting the percentage
SELECT 
ROUND(
        (
        (SELECT SUM(invoice_amount_usd)FROM yellevate_invoices WHERE dispute_lost = 1) / SUM(invoice_amount_usd) * 100
        ),
    2) AS revenue_lost_percentage
FROM yellevate_invoices;

--5) The country where the company reached the highest losses from lost disputes (in USD)

SELECT country,
       SUM(invoice_amount_usd) AS total_lost
FROM yellevate_invoices
WHERE dispute_lost = 1
GROUP BY 1
ORDER BY total_lost DESC;