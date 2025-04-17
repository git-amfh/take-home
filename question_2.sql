/*
To find the percentage of returned outgoing debit events in the last 60 days 
I used a COUNT with a CASE WHEN to add the additional filter
of rows with status as 'returned' or 'return_dishonored' or 'return_contested'.
This allowed me to find the subset of returned events within the base population
(established in my WHERE) of outgoing debit events in the last 60 days
 */
SELECT platform_id,
  printf ('%.2f%%',(((COUNT(CASE WHEN status IN
         ('returned', 'return_dishonored','return_contested') 
         THEN 1 END))* 1.0 / (COUNT(*)) * 1.0) * 100)) -- Have to convert values to floats to get accurate percentage
  AS percentage_returned
FROM ach_transfers
  /* My WHERE criteria below established my baseline population of events as 
  those that were performed 1) in the last 60 days from the most recent event
  2) outgoing and 3) debit

  Took this approach as it allowed me to build and test on top of the filter 
  I knew was correct from the last question
  */
WHERE effective_on >= DATE (
      (SELECT MAX(effective_on)
      FROM ach_transfers),
      '-60 days')
  AND is_incoming = 0
  AND type = 'debit'
GROUP BY platform_id;