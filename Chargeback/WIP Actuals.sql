SELECT -- transaction overview
       WIP.TRANSNO,
       WIP.TRANSDATE TRANSACTION_DATE,
       WIP.MONTH_BEGIN,
       WIP.MONTH_END,
       TO_NUMBER (TO_CHAR (WIP.TRANSDATE, 'MM')) MO_NO,
       TO_NUMBER (TO_CHAR (WIP.TRANSDATE, 'YYYY')) YR_NO,
       -- resource attributes
       RESOURCES.FULL_NAME RESOURCE_NAME,
       WIP.EMPLYHOMELOCATION RESOURCE_LOCATION,
       WIP.EMPLYHOMEDEPART RESOURCE_DEPARTMENT,
       RESOURCE_CC.UNIQUE_NAME RESOURCE_CC_ID,
       RESOURCE_CC.NAME RESOURCE_CC_NAME,
       RESOURCE_MANAGERS.FULL_NAME RESOURCE_MANAGER_NAME,
       RESOURCES.IS_EXTERNAL RESOURCE_IS_EXTERNAL,
       -- project/task attributes
       PROJECT_CC.NAME PROJECT_DEPARTMENT_TYPE,
       CASE
          WHEN BUSINESS_UNIT.NAME IS NULL
          THEN
             (SELECT SHORTDESC
                FROM WARM01.DEPARTMENTS
               WHERE DEPARTCODE = WIP.PROJECT_DEPARTMENT)
          ELSE BUSINESS_UNIT.NAME
       END
          PROJECT_BUSINESS_UNIT,
       WIP.PROJECT_DEPARTMENT,
       WIP.PROJECT_CODE,
       CURRENT_PROJECTS.NAME PROJECT_NAME,
       PROJECT_TYPES.NAME PROJECT_TYPE,
       TASKS.PRNAME TASK_NAME,
       WIP.QUANTITY TASK_HOURS,
       WIP_VALUES.BILLRATE,
       WIP_VALUES.AMOUNT,
       -- transaction attributes
       WIP.TRANSCLASS TRANSACTION_CLASS,
       -- wip status
       CASE
          WHEN WIP.STATUS = 0 THEN 'Processed'
          WHEN WIP.STATUS = 1 THEN 'Adjusted'
          WHEN WIP.STATUS = 2 THEN 'Reversed'
          WHEN WIP.STATUS = 4 THEN 'Updated'
          WHEN WIP.STATUS = 8 THEN 'Pending'
          ELSE 'Missing'
       END
          STATUS,
       WIP.IN_ERROR,
       WIP.ENTRYDATE CREATED_AT,
       WIP.LASTUPDATEDATE UPDATED_AT,
       CASE
          WHEN WIP.SOURCEMODULE = 50 THEN 'External'
          WHEN WIP.SOURCEMODULE = 51 THEN 'ClarityPPM'
          WHEN WIP.SOURCEMODULE = 52 THEN 'VoucherExpense'
          WHEN WIP.SOURCEMODULE = 53 THEN 'VoucherOther'
          ELSE 'Missing'
       END
          SOURCE
  FROM WARM01.PPA_WIP WIP,
       WARM01.PPA_WIP_VALUES WIP_VALUES,
       WARM01.SRM_RESOURCES RESOURCES,
       WARM01.SRM_RESOURCES RESOURCE_MANAGERS,
       WARM01.INV_INVESTMENTS CURRENT_PROJECTS,
       WARM01.ODF_CA_PROJECT PROJECT_FACTS,
       WARM01.DEPARTMENTS RESOURCE_DPT,
       WARM01.DEPARTMENTS PROJECT_DPT,
       WARM01.PRTASK TASKS,
       (SELECT LOOKUP_CODE, NAME
          FROM WARM01.CMN_LOOKUPS_V
         WHERE LANGUAGE_CODE = 'en' AND PARTITION_CODE = 'cid') PROJECT_TYPES,
       (SELECT UNIT_ID, UNIQUE_NAME, NAME
          FROM WARM01.OBS_UNITS_V
         WHERE DEPTH = 5 AND UNIT_MODE = 'OBS_UNIT_AND_ANCESTORS') RESOURCE_CC,
       (SELECT UNIT_ID, UNIQUE_NAME, NAME
          FROM WARM01.OBS_UNITS_V
         WHERE DEPTH = 1 AND UNIT_MODE = 'OBS_UNIT_AND_ANCESTORS') PROJECT_CC,
       (SELECT UNIT_ID, UNIQUE_NAME, NAME
          FROM WARM01.OBS_UNITS_V
         WHERE DEPTH = 3 AND UNIT_MODE = 'OBS_UNIT_AND_ANCESTORS') BUSINESS_UNIT
 WHERE     WIP.RESOURCE_CODE = RESOURCES.UNIQUE_NAME
       AND RESOURCES.MANAGER_ID = RESOURCE_MANAGERS.USER_ID(+)
       AND WIP.EMPLYHOMEDEPART = RESOURCE_DPT.DEPARTCODE
       AND WIP.PROJECT_DEPARTMENT = PROJECT_DPT.DEPARTCODE
       AND RESOURCE_DPT.OBS_UNIT_ID = RESOURCE_CC.UNIT_ID
       AND PROJECT_DPT.OBS_UNIT_ID = PROJECT_CC.UNIT_ID
       AND PROJECT_DPT.OBS_UNIT_ID = BUSINESS_UNIT.UNIT_ID(+)
       AND WIP.INVESTMENT_ID = CURRENT_PROJECTS.ID
       AND WIP.TASK_ID = TASKS.PRID
       AND WIP.TRANSNO = WIP_VALUES.TRANSNO
       AND CURRENT_PROJECTS.ID = PROJECT_FACTS.ID
       AND PROJECT_FACTS.OBJ_REQUEST_TYPE = PROJECT_TYPES.LOOKUP_CODE
       AND -- wip values for billing
           WIP_VALUES.CURRENCY_TYPE = 'BILLING'
       AND WIP_VALUES.CURRENCY_CODE = 'USD'
       AND -- transactions belonging to CID
           WIP.ENTITY = 'CID'