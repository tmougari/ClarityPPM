DROP TABLE WARM01.CID_SP_WARM_FINANCIALS;
CREATE TABLE WARM01.CID_SP_WARM_FINANCIALS AS
SELECT F.UUID,
       F.INVESTMENT_ID,
       I.CODE PROJECT_ID,
       I.NAME PROJECT_NAME,
       F.CLIENTCLASS,
       F.PROJECTCLASS,
       F.WIPCLASS,
       F.DATE_VAL,
       F.DATE_UID,
       F.RESOURCE_CODE,
       F.ISROLE,
       CASE 
         WHEN F.ISROLE = 0 THEN NULL
         WHEN F.ISROLE = 1 AND F.CC IS NULL THEN 'UNDEFINED'
         ELSE F.CC 
       END CC,
       F.PRUSERTEXT1,
       F.PRUSERTEXT2,
       F.PRUSERTEXT3,
       F.PRUSERTEXT4,
       F.RECOVERED_AMOUNT
  FROM (SELECT P.UUID,
               P.INVESTMENT_ID,
               R.CLIENTCLASS,
               R.PROJECTCLASS,
               R.WIPCLASS,
               P.DATE_VAL,
               P.DATE_UID,
               R.RESOURCE_CODE,
               NULL ISROLE,
               NULL CC,
               R.PRUSERTEXT1,
               R.PRUSERTEXT2,
               R.PRUSERTEXT3,
               R.PRUSERTEXT4,
               CASE
                  WHEN R.PROJECTCLASS IN ('FIXED', 'CIOWNER')
                  THEN
                     CASE
                        WHEN P.AMOUNT IS NULL OR P.AMOUNT = 0
                        THEN
                           0
                        ELSE
                           ROUND ( (R.AMOUNT / P.AMOUNT) * NVL (B.AMOUNT, 0),
                                  2)
                     END
                  WHEN R.PROJECTCLASS IN ('TM')
                  THEN
                     R.AMOUNT
                  WHEN R.PROJECTCLASS IN ('BASELINE')
                  THEN
                     0
                  ELSE
                     0
               END
                  RECOVERED_AMOUNT
          FROM CID_SP_PROJECT_ACTUAL_SUM P,
               CID_SP_RESOURCE_ACTUAL_PROJECT R,
               CID_SP_PROJECT_BUDGET_SUM B
         WHERE P.UUID = R.UUID(+) AND P.UUID = B.UUID(+)
               AND P.DATE_VAL <=
                      (SELECT TO_DATE (
                                 CASE
                                    WHEN CYCLE_DY_OF_MO_NO BETWEEN 1 AND 9
                                    THEN
                                       '0' || CYCLE_DY_OF_MO_NO
                                    ELSE
                                       TO_CHAR (CYCLE_DY_OF_MO_NO)
                                 END
                                 || TO_CHAR (CYCLE_YR_NO),
                                 'MMYYYY')
                                 DATE_VAL
                         FROM ODF_CA_CID_FIN_CALENDAR
                        WHERE CODE = TO_CHAR (SYSDATE, 'YYYYMMDD'))
        UNION ALL
        SELECT P.UUID,
               P.INVESTMENT_ID,
               R.CLIENTCLASS,
               R.PROJECTCLASS,
               R.WIPCLASS,
               P.DATE_VAL,
               P.DATE_UID,
               R.RESOURCE_CODE,
               R.ISROLE,
               R.CC,
               R.PRUSERTEXT1,
               R.PRUSERTEXT2,
               R.PRUSERTEXT3,
               R.PRUSERTEXT4,
               CASE
                  WHEN R.PROJECTCLASS IN ('FIXED', 'CIOWNER')
                  THEN
                     CASE
                        WHEN P.AMOUNT IS NULL OR P.AMOUNT = 0
                        THEN
                           0
                        ELSE
                           ROUND ( (R.AMOUNT / P.AMOUNT) * NVL (B.AMOUNT, 0),
                                  2)
                     END
                  WHEN R.PROJECTCLASS IN ('TM')
                  THEN
                     ROUND (R.AMOUNT * V.RATE, 2)
                  WHEN R.PROJECTCLASS IN ('BASELINE')
                  THEN
                     0
                  ELSE
                     0
               END
                  FORECAST_AMOUNT
          FROM CID_SP_PROJECT_FORECAST_SUM P,
               CID_SP_RESOURCE_FORECAST R,
               CID_SP_PROJECT_BUDGET_SUM B,
               (SELECT TO_CHAR (FROMDATE, 'YYYY') YR, NUMVAL1 RATE
                  FROM PPA_MATRIXVALUES) V
         WHERE     P.UUID = R.UUID(+)
               AND P.UUID = B.UUID(+)
               AND TO_CHAR (P.DATE_VAL, 'YYYY') = V.YR
               AND P.DATE_VAL >
                      (SELECT TO_DATE (
                                 CASE
                                    WHEN CYCLE_DY_OF_MO_NO BETWEEN 1 AND 9
                                    THEN
                                       '0' || CYCLE_DY_OF_MO_NO
                                    ELSE
                                       TO_CHAR (CYCLE_DY_OF_MO_NO)
                                 END
                                 || TO_CHAR (CYCLE_YR_NO),
                                 'MMYYYY')
                                 DATE_VAL
                         FROM ODF_CA_CID_FIN_CALENDAR
                        WHERE CODE = TO_CHAR (SYSDATE, 'YYYYMMDD'))) F,
       WARM01.INV_INVESTMENTS I
 WHERE     F.INVESTMENT_ID = I.ID
       AND F.PROJECTCLASS NOT IN ('OVERHEAD');