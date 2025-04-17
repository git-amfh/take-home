 /* To solve this problem I continued to use the filtered population of outgoing debits in the last 60 days.
 I focused on making sure the LEFT JOIN included the platform_ids which did not have unauthorized returns,
but did have returns for outgoing ACH debits in the last 60 days.*/
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