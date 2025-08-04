CREATE VIEW [dbo].[VW_TTFORMAT]
AS

/*
SELECT CONVERT(DATE,DT) AS DATE,
CONVERT(TIME,DT) AS TIME,
sitecode, CardID,RTRIM(LTRIM(EmpID)) AS EmpID,empname,case when (InOut=0) then 'In' else 'Out' end as InOut
FROM netXS.DBO.TRANS WITH (NOLOCK)
where empid is not null
and dt>'2024-04-01'

union all
*/

SELECT CAST(DT AS DATE) AS DATE,
CAST(DT AS TIME) AS TIME,
--CONVERT(TIME,DT) AS TIME,
sitecode, CardID,
RTRIM(LTRIM(EmpID)) AS EmpID,
empname,
case when (InOut=0) then 'In' else 'Out' end as InOut
FROM Atten.DBO.TRANS WITH (NOLOCK)
where empid is not null
and dt >= CAST(GETDATE()-20 AS DATE)
--AND CAST(dt AS DATE) = '2024-12-22'

