
WITH
src AS
(
SELECT employee_id emp_id, last_name name, manager_id mgr_id
FROM employees
WHERE employee_id<110
),
mgrs AS
(SELECT emp_id, name, mgr_id, rownum m_n
FROM src
WHERE emp_id IN 
          (SELECT mgr_id
          FROM src WHERE mgr_id IS NOT NULL)

ORDER BY emp_id),
emps AS
(SELECT emp_id, name, mgr_id, null m_n,  rownum no_m
FROM src
WHERE emp_id NOT IN 
          (SELECT mgr_id
          FROM src
          WHERE mgr_id IS NOT NULL)),
          
grps AS
(SELECT mgr_id,emp_id,name, RANK() OVER(PARTITION BY mgr_id ORDER BY emp_id) e_n FROM src
GROUP BY mgr_id,emp_id,name),
src2 AS
(SELECT grps.mgr_id, src.name m_name, 
        grps.emp_id, grps.name e_name, e_n lvl, no_m
FROM grps LEFT JOIN emps
ON grps.emp_id=emps.emp_id 
--Здесь LEFT JOIN src чтобы не терялся null King ...
LEFT JOIN src ON src.emp_id=grps.mgr_id
ORDER BY no_m),


brec AS
(SELECT mgr_id, m_name, 
        no_m, 
        emp_id, e_name, 
        lvl
        FROM src2
WHERE no_m=1 AND lvl
=1
),

rec (mgr_id,
emp_id,lvl,
no_m,n
) AS
(SELECT mgr_id, 
        emp_id, 
        0 lvl,
        no_m,1

        FROM src2
WHERE no_m=1 
UNION ALL
SELECT CASE
       WHEN r.mgr_id IS null THEN (SELECT mgr_id FROM src2
                           WHERE src2.no_m=r.no_m+1)
       ELSE (SELECT mgr_id FROM src2 s2 WHERE s2.emp_id=r.mgr_id)
       END,

       CASE
       WHEN r.mgr_id IS null THEN (SELECT emp_id FROM src2
                           WHERE src2.no_m=r.no_m+1)
       ELSE r.mgr_id
       END
       ,
       DECODE(r.mgr_id,null,0, lvl+1) lvl,

       CASE
       WHEN r.mgr_id IS null THEN (SELECT src2.no_m FROM src2
                           WHERE src2.no_m=r.no_m+1)
       ELSE r.no_m END, n+1
                           
FROM rec r
--можно еще на каждом шаге джойнить src2 по условию 
WHERE r.no_m <=(SELECT MAX(no_m) FROM src2) OR (r.no_m IS NOT NULL AND r.mgr_id IS NULL)
),

--для проверки
emps3 AS
(SELECT emp_id, mgr_id, m_n mm FROM mgrs),


src3 AS
(SELECT src2.mgr_id, 
        src2.emp_id,
        lvl
        ,mm
        FROM src2 LEFT JOIN emps3 ON emps3.emp_id=src2.mgr_id)

,brec2 AS
(SELECT mgr_id,
        emp_id,
        lvl
        ,mm
        FROM src3

),
rec2(root, mgr_id,emp_id,lvl, mm) AS
(SELECT mgr_id,mgr_id,
        emp_id,
        lvl
        ,mm
        FROM src3
WHERE lvl=1
AND mgr_id=(SELECT MIN(mgr_id) FROM src2)

UNION ALL 

SELECT CASE
          WHEN mgr_id IS NULL OR (mgr_id=root AND emp_id IS NULL) THEN (SELECT DISTINCT mgr_id FROM src3 WHERE mm=r2.mm+1)

          ELSE root
       END,
       CASE
          WHEN mgr_id IS NULL OR (mgr_id=root AND emp_id IS NULL)  THEN (SELECT mgr_id FROM src3 WHERE mm=r2.mm+1 AND lvl=1)
          WHEN emp_id IS NULL THEN (SELECT mgr_id FROM src2 WHERE emp_id=r2.mgr_id)
          WHEN (SELECT emp_id FROM src2 WHERE mgr_id=r2.emp_id
          AND lvl=1)IS NULL THEN mgr_id
          ELSE emp_id
       END,

       CASE
          WHEN mgr_id IS NULL OR (mgr_id=root AND emp_id IS NULL)  THEN (SELECT emp_id FROM src3 WHERE mm=r2.mm+1 AND lvl=1)
          WHEN emp_id IS NULL 
                THEN (SELECT emp_id FROM src2 WHERE mgr_id=(SELECT mgr_id FROM src2 WHERE emp_id=r2.mgr_id)
              AND 
              lvl=(SELECT lvl FROM src2 WHERE emp_id=r2.mgr_id)+1
              )
          WHEN (SELECT emp_id FROM src2 WHERE mgr_id=r2.emp_id AND lvl=1) IS NULL
                THEN (SELECT emp_id FROM src2 
                      WHERE mgr_id=r2.mgr_id
                            AND lvl=r2.lvl+1)
          ELSE (SELECT emp_id FROM src2 WHERE mgr_id=r2.emp_id AND lvl=1)
       END,              
       CASE
          WHEN mgr_id IS NULL OR (mgr_id=root AND emp_id IS NULL)  THEN 1
          WHEN emp_id IS NULL
              THEN (SELECT lvl FROM src2 WHERE emp_id=r2.mgr_id)+1
          WHEN (SELECT emp_id FROM src2 WHERE mgr_id=r2.emp_id AND lvl=1) IS NULL
                THEN r2.lvl+1
          ELSE 1
       END

       ,CASE
          WHEN mgr_id IS NULL OR (mgr_id=root AND emp_id IS NULL)  THEN r2.mm+1

          ELSE mm
       END
       
FROM rec2 r2
WHERE (mgr_id IS NOT NULL OR emp_id IS NOT NULL OR root IS NOT NULL)--AND lvl<10
) 
SELECT LISTAGG (e_name||
CASE
WHEN rec.mgr_id IS NULL THEN '('||cnt||', не имеет начальника)'
WHEN src2.no_m IS NOT NULL THEN '(0, не имеет подчиненных)'
ELSE '('||cnt||')'
END
,'->') WITHIN GROUP (ORDER BY n) 
FROM rec JOIN src2 ON src2.emp_id=rec.emp_id LEFT JOIN (SELECT root,COUNT(emp_id) cnt --
FROM rec2
GROUP BY root) nums ON nums.root=rec.emp_id
WHERE src2.emp_id IS NOT NULL
GROUP BY rec.no_m
;
