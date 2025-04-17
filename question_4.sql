 /* To solve this problem I used the same logic as I did in the previous problem and replaced the unauthorized return codes with the administrative return codes.*/
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