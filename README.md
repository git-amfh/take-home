
# Customer Engineer Take Home

This repository contains my solutions to the SQL portion of the take-home technical assessment for the Customer Engineer interview process. Each solution is structured to meet the requirements specified in the assessment instructions.

## Table of Contents

- [Overview](#overview)
- [Solutions](#solutions)
  - [Question 1](#question-1)
  - [Question 2](#problem-2)
  - [Question 3](#problem-3)
  - [Question 4](#question-4)
- [How to Run](#how-to-run)
- [Dependencies](#dependencies)
- [Approach & Explanation](#approach--explanation)

---

## Overview

This repository contains the solutions and explanations for a SQL take-home assessment. Below, you will find each problem statement, followed by the solution, and a brief explanation of the approach I used to solve it.

---

## Solutions

### Question 1

#### Problem Statement

At Column, we require our partners to lock up their own funds in a Column reserve account (post collateral) to protect us against fraudulent ACH transactions. The amount they need to post is equal to 20% of their outgoing ACH debit volume over the last 60 days. For each platform_id, how much collateral do they need to post?

#### Solution

This query calculates 20% of the outgoing ACH debit volume
over the last 60 days from the most recent transfer. This value
represents the required collateral each ```platform_id``` must maintain
to protect Column against fraudulent ACH transactions

```mySQL
SELECT platform_id, printf('$%.2f',(SUM(amount)*1.0/1000000)*.2) AS required_collateral_USD --Given collateral is money, I converted amount to float before operations 
FROM ach_transfers 
WHERE effective_on >= DATE( 
      (SELECT MAX(effective_on) 
      FROM ach_transfers), '-60 days') 
  AND is_incoming = 0 
  AND type = 'debit' -- WHERE filters outgoing debits in the last 60 days from most recent date.
GROUP BY platform_id; 
```

#### Approach & Explanation

- **Approach**: Start with all columns in ```ach_transfers``` and try to isolate rows that are both debit and outgoing. Then, add another condition to isolate transfers that happened in the last 60 days from the most recent transfer date. Once I had the subset of rows with the criteria I wanted, I went back to the ```SELECT``` to calculate and put in three different columns the ```SUM``` of ```amount```, the conversion to dollars, and the multiplication by 20% to get the collateral for each ```platform_id```. Finally, I kept the ```platform_id``` and ```required_collateral_USD``` columns, formatted with ```printf``` and rounded to two decimal places.
- **Complexity**: Time and Space Complexity are both O(n) where ```n``` is the number of rows in ```ach_transfers``` 
- **Edge Cases**: Without changing the amount to a float before performing division and multiplication operations, the final collateral amounts would be off, especially so for larger data sets.
- **Assumptions**: Assumed I had to calculate the most recent transfer date in order to obtain the range of the "last 60 days".
---

### Question 2

#### Problem Statement

For each ```platform_id```, calculate the total return percentage over the last 60 days
Formula = Total outgoing debits returned last 60 days / total outgoing debit last 60 days

#### Solution

To find the percentage of returned outgoing debit events in the last 60 days 
I used a ```COUNT``` with a ```CASE WHEN``` to add the additional filter
of rows with ```status``` as ```'returned'``` or ```'return_dishonored'``` or ```'return_contested'```.
This allowed me to find the subset of returned events within the base population
(established in my ```WHERE```) of outgoing debit events in the last 60 days. This approach helped me build and expand on top of the filtered population I assumed correct from Question 1.

```SQL
SELECT platform_id,
  printf ('%.2f%%',(((COUNT(CASE WHEN status IN
         ('returned', 'return_dishonored','return_contested') 
         THEN 1 END))* 1.0 / (COUNT(*)) * 1.0) * 100)) -- Have to convert values to floats to get accurate percentage
  AS percentage_returned
FROM ach_transfers
WHERE effective_on >= DATE (
      (SELECT MAX(effective_on)
      FROM ach_transfers),
      '-60 days')
  AND is_incoming = 0
  AND type = 'debit'
GROUP BY platform_id;

```

#### Approach & Explanation

- **Approach**: I focused on finding the denominator first: total outgoing debits in the last 60 days. I did so using ```COUNT``` and building on query parameters from Question #1. Then, I used ```COUNT``` again, but this time with ```CASE WHEN``` to add 1 to the count every time there a row with ```status``` as ```‘returned’``` OR ```‘return_dishonored’``` OR ```‘return_contested’```. Finally, I converted the calculated numerator and denominator into floats, then calculated the percentage by dividing both counts for each ```platform_id```. Format with ```printf```.
- **Complexity**: Time and Space Complexity are both O(n) where ```n``` is the number of rows in ```ach_transfers``` 
- **Edge Cases**: Similarly to Question 1, in order to get an accurate percentage from these operations, the integers have to turn to floats.
- **Assumptions**: Assumed logic to obtain the population of outgoing debits in the last 60 days calculated in Question 1 was still correct.

---

### Question 3

#### Problem Statement

For each ```platform_id```, calculate the percentage of outgoing ACH debits where returned with unauthorized return codes? Formula = Number of outgoing ACH debits returned with unauthorized return codes last 60 days / total number of outgoing ACH debits last 60 days

#### Solution

To solve this problem I continued to use the filtered population of outgoing debits in the last 60 days.
I focused on making sure the ```LEFT JOIN``` included the ```platform_ids``` which did not have unauthorized returns,
but did have returns for outgoing ACH debits in the last 60 days.
```SQL
SELECT a.platform_id,
        printf('%.2f%%', ( ( (COUNT(CASE WHEN 
        b.return_code IN ('R05', 'R07', 'R10', 'R29', 'R51')
         THEN 1 END) ) * 1.0 / 
         (COUNT( * ) ) * 1.0) * 100) ) 
         AS percentage_returned_unauthorized_codes
FROM ach_transfers a
LEFT JOIN ach_return_events b ON a.ach_transfer_id=b.ach_transfer_id 
        AND b.return_code IN ('R05', 'R07', 'R10', 'R29', 'R51') -- specify codes to avoid including other returned events with the rest of the filters
WHERE a.is_incoming=0 AND a.type='debit'  
        AND a.effective_on >= DATE( (SELECT MAX(effective_on) 
                                FROM ach_transfers), '-60 days')
GROUP BY platform_id;

```


#### Approach & Explanation

- **Approach**: First I focused ond finding how many outgoing debits returned with unauthorized return codes in the last 60 days grouped by platform_id. From this we find out two ```platform_id```’s had returns with unauthorized codes. We already know 6 ```platform_id```’s in total had outgoing ACH debits in the last 60 days, so we want to get the missing four ```platform_ids``` with 0 as their numerator with ```LEFT JOIN``` as well as bring in the denominator for each ```platform_id```. As a final step, I converted the numerator and denominator into floats, then calculated the percentage by dividing both ```COUNTS``` for each ```platform_id```. Format with ```printf```.
- **Complexity**: Because of the space needed for the ```LEFT JOIN```, the complexity is O(n * m). In the worst case, if each row in ```ach_transfers``` has a matching row in ```ach_return_events``` then the space needed is O(n * m).
- **Edge Cases**: I realized that without specifying the codes I wanted in the ```LEFT JOIN```, my total outgoing debits in the last 60 days denominator was off from what I expected because additional rows from ```ach_return_events``` met the criteria, and hence, added to the total value in the denominator.
- **Assumptions**: I assumed that the unauthorized codes were static and that the list given to me contained all the codes.
---

### Question 4

#### Problem Statement

For each ```platform_id```, calculate the percentage of outgoing ACH debits were returned with administrative return codes? Formula = Number of outgoing ACH debits returned with administrative return codes in last 60 days / total number of outgoing ACH debits last 60 days
#### Solution
To solve this problem I used the same logic as I did in the previous problem and replaced the unauthorized return codes with the administrative return codes.
```SQL
SELECT a.platform_id,
        printf('%.2f%%', ( ( (COUNT(CASE WHEN
        b.return_code IN ('R02', 'R03', 'R04') -- return codes correspond with administrative codes
        THEN 1 END) ) * 1.0 / (COUNT( * ) ) * 1.0) * 100))
        AS percentage_returned_admin_codes
FROM ach_transfers a
LEFT JOIN ach_return_events b ON a.ach_transfer_id=b.ach_transfer_id 
        AND b.return_code IN ('R02', 'R03', 'R04')
WHERE a.is_incoming=0 AND a.type='debit'  
        AND a.effective_on >= DATE( (SELECT MAX(effective_on)
        FROM ach_transfers), '-60 days')
GROUP BY platform_id;

```


#### Approach & Explanation

- **Approach**: Leverage the query from Question #3 and replace the unauthorized codes with administrative codes
- **Complexity**: Because of the space needed for the ```LEFT JOIN```, the complexity is O(n * m). In the worst case, if each row in ```ach_transfers``` has a matching row in ```ach_return_events``` then the space needed is O(n * m).
- **Edge Cases**: Need to specify the particular codes desired as an ```AND``` in the```LEFT JOIN``` statement in order to only bring in the rows from table b that we expect / want.
- **Assumptions**: I assumed that the unauthorized codes were static and that the list given to me contained all the codes.
---

## How to Run

1. Clone this repository to your local machine:

   ```bash
   git clone https://github.com/git-amfh/take-home.git
   ```

2. Navigate into the project directory:

   ```bash
   cd repository-name
   ```

3. Install the required dependencies:

   ```bash 
   # For sqlite3:
   pip install sqlite3

   ```

4. Run the solution files as follows:

   ```bash
   # Example for Question 1:
   sqlite3 take-home.db < question_1.sql

   ```

---

## Dependencies

- **Programming Language**: SQL
- **Libraries/Packages**: none
- **Database**: sqlite

---

## Approach & Explanation

### Problem-Solving Approach

For each problem, I applied the following strategy:

1. **Understanding the Problem**: I thoroughly read the problem statement, ensuring I understood the constraints, requirements, and the main ask.
2. **Design**: I created a plan for the solution, focusing on breaking down the problem as much as possible, starting small, and building to get to the solution.
3. **Implementation**: I wrote the solution in SQL, checked my accuracy by running small or partial queries, and built on previously obtained answers/queries.
4. **Edge Case Handling / Testing**: I checked my queries by using other, simpler, queries, often forgoing the ```GROUP BY``` and analyzing the rows themselves when and however possible to double check my approach was in the right direction. 

---

