/* This query calculates 20% of the outgoing ACH debit volume
over the last 60 days from the most recent transfer. This value
represents the required collateral each platform_id must maintain
to protect Column against fraudulent ACH transactions
*/


/* In my SELECT, given that the amounts are monetary values,
I multiplied the sum of the amounts by 1.0 to convert 
the sum into a float before I performed further operations to maintain
the accuracy of the amounts. 
Then, I used printf to format the resulting collateral as USD to the nearest cent
*/

SELECT platform_id, printf('$%.2f',(SUM(amount)*1.0/1000000)*.2) AS required_collateral_USD 
FROM ach_transfers

/*This WHERE filters the transfers to only 
include those that are outgoing, debits, and happened in the last 60 days.*/
WHERE effective_on >= DATE( 
      (SELECT MAX(effective_on) 
      FROM ach_transfers), '-60 days') 
  AND is_incoming = 0 
  AND type = 'debit'
GROUP BY platform_id; 