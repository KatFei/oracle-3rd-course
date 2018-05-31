WITH
src AS
(SELECT '(2x^5+3x^2+15)+(6x^5-(4x^3-3x^2))+20+30' s FROM DUAL),
t0(s,r, 
skob,
skob3
,skob_hist2
,ss
) AS
(SELECT REGEXP_REPLACE(s,'(\+|\-)?\(*(\d*x(\^\d+)?|\d+)\)*','',1,1) s, REGEXP_SUBSTR(s,'(\d*x(\^\d+)?|\d+)') r,

  REGEXP_REPLACE(
  REGEXP_SUBSTR(s,'(\+|\-)?(\d*x(\^\d+)?|\d+)')
  ,'(\d*x(\^\d+)?|\d+)','')
 skob
  
,0 skob3

,REGEXP_REPLACE(
REGEXP_REPLACE(
REGEXP_REPLACE(
REGEXP_REPLACE(
REGEXP_SUBSTR(REGEXP_SUBSTR(s,'(\+|\-)?\(*(\d*x(\^\d+)?|\d+)'),'(\+|\-)?\(+(\d*x(\^\d+)?|\d+)')--надо проматривать уже наденное слагаемое,
--иначе он ищет следующее подходящее
,'(\d*x(\^\d+)?|\d+)','')
,'\+\(','+')
,'\-\(','-')
,'\(','+') skob_hist2
,REGEXP_REPLACE(
REGEXP_REPLACE(
REGEXP_REPLACE(
REGEXP_REPLACE(
REGEXP_SUBSTR(REGEXP_SUBSTR(s,'(\+|\-)?\(*(\d*x(\^\d+)?|\d+)'),'(\+|\-)?\(+(\d*x(\^\d+)?|\d+)')--надо проматривать уже наденное слагаемое,
--иначе он ищет следующее подходящее
,'(\d*x(\^\d+)?|\d+)','')
,'\+\(','+')
,'\-\(','-')
,'\(','+') ss
--REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_SUBSTR
--(s,'(\+|\-)?\(*(\d*x(\^\d+)?|\d+)\)*'),'(\d*x(\^\d+)?|\d+)'),'+(','+'),'-(','-'),'(','+') skob
FROM src
UNION ALL
SELECT REGEXP_REPLACE(s,'(\+|\-)?\(*(\d*x(\^\d+)?|\d+)\)*','',1,1) s, REGEXP_SUBSTR(s,'(\d*x(\^\d+)?|\d+)') r ,

  REGEXP_REPLACE(
  REGEXP_SUBSTR(s,'(\+|\-)?(\d*x(\^\d+)?|\d+)')
  ,'(\d*x(\^\d+)?|\d+)','')
 skob
,REGEXP_COUNT(
REGEXP_SUBSTR(s,'(\+|\-)?\(*(\d*x(\^\d+)?|\d+)\)*'),'\)') skob3
,

SUBSTR(
skob_hist2


,1
,length(skob_hist2)-skob3
--REGEXP_COUNT(REGEXP_SUBSTR(s,'(\+|\-)?\(*(\d*x(\^\d+)?|\d+)\)*'),'\)')
)--*/skob_hist2
||
REGEXP_REPLACE(
REGEXP_REPLACE(
REGEXP_REPLACE(
REGEXP_REPLACE(
REGEXP_SUBSTR(REGEXP_SUBSTR(s,'(\+|\-)?\(*(\d*x(\^\d+)?|\d+)'),'(\+|\-)?\(+(\d*x(\^\d+)?|\d+)')
,'(\d*x(\^\d+)?|\d+)','')
,'\+\(','+')
,'\-\(','-')
,'\(','+')

,
SUBSTR(
skob_hist2--Почему если ss, т е тот же столбец, в котором мы сейчас находимся, то не работает(теряется поледний минус)????

,1
,length(ss)-skob3
) ||
REGEXP_REPLACE(
REGEXP_REPLACE(
REGEXP_REPLACE(
REGEXP_REPLACE(
REGEXP_SUBSTR(REGEXP_SUBSTR(s,'(\+|\-)?\(*(\d*x(\^\d+)?|\d+)'),'(\+|\-)?\(+(\d*x(\^\d+)?|\d+)')
,'(\d*x(\^\d+)?|\d+)','')
,'\+\(','+')
,'\-\(','-')
,'\(','+') ss


FROM t0

WHERE REGEXP_COUNT(s,'(\d*x(\^\d+)?|\d+)')>0)
,
t1 AS 
(SELECT CASE
            WHEN INSTR(r,'x')>0 THEN SUBSTR(r,1,INSTR(r,'x')-1)
            ELSE r
        END k,

CASE
            WHEN INSTR(r,'^')>0 THEN SUBSTR(r,INSTR(r,'x')+2)
            WHEN INSTR(r,'x')>0 THEN '1'
            ELSE '0'
        END p,
       
skob,
ss 
FROM t0)
,tf AS(SELECT SUM(TO_NUMBER(k)*POWER(-1,NVL(REGEXP_COUNT(ss,'-'),0)+DECODE(skob,'-',1,'+',0,0)))||DECODE(p,0,'','x^'||p) s,p
FROM t1
GROUP BY p)
--а теперь надо собрать вcе обратно в строку-многочлен
--используем LISTAGG
SELECT REPLACE(LISTAGG(s,'+')
WITHIN GROUP (ORDER BY p DESC),'+-','-') FROM tf
;
