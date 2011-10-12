SELECT
 RESOURCES.ID,
 RESOURCES.UNIQUE_NAME,
 RESOURCES.EXTERNAL_ID,
 USERS.PRUSERTEXT1 PERSONNEL_ID,
 USERS.PRUSERTEXT2 SAP_ID,
 USERS.PRUSERTEXT4 TIME_REPORT_ID,
 RESOURCES.FULL_NAME RESOURCE_NAME,
 ROLES.FULL_NAME ROLE_NAME,
 RESOURCE_FACTS.TRANSCLASS TRANSACTION_CLASS,
 RESOURCES.EMAIL RESOURCE_EMAIL,
 RESOURCES.DATE_OF_HIRE,
 RESOURCES.DATE_OF_TERMINATION,
 RESOURCES.IS_ACTIVE,
 RESOURCES.IS_EXTERNAL,
 USERS.PRISROLE IS_ROLE,
 ORGANIZATIONS.NAME ORGANIZATION_NAME,
 SUB_ORGANIZATIONS.NAME SUB_ORGANIZATION_NAME,
 COST_CENTERS.UNIQUE_NAME COST_CENTER,
 COST_CENTERS.NAME DIVISION_NAME,
 ORGS.DEPARTMENT_NAME TEAM_NAME,
 MANAGERS.FULL_NAME MANAGER_NAME,
 MANAGERS.EMAIL MANAGER_EMAIL
FROM
  WARM01.SRM_RESOURCES RESOURCES,
  WARM01.PRJ_RESOURCES USERS,
  WARM01.SRM_RESOURCES MANAGERS,
  WARM01.SRM_RESOURCES ROLES,
  WARM01.PAC_MNT_RESOURCES RESOURCE_FACTS,
  WARM01.NBI_RESOURCE_ORG_INFO_V ORGS,
  WARM01.DEPARTMENTS,
  (SELECT UNIT_ID, UNIQUE_NAME, NAME
          FROM WARM01.OBS_UNITS_V
         WHERE DEPTH = 5 AND UNIT_MODE = 'OBS_UNIT_AND_ANCESTORS') COST_CENTERS,
  (SELECT UNIT_ID, UNIQUE_NAME, NAME
          FROM WARM01.OBS_UNITS_V
         WHERE DEPTH = 4 AND UNIT_MODE = 'OBS_UNIT_AND_ANCESTORS') SUB_ORGANIZATIONS,
  (SELECT UNIT_ID, UNIQUE_NAME, NAME
          FROM WARM01.OBS_UNITS_V
         WHERE DEPTH = 3 AND UNIT_MODE = 'OBS_UNIT_AND_ANCESTORS') ORGANIZATIONS
WHERE RESOURCES.ID = ORGS.RESOURCE_ID
  AND RESOURCES.ID = RESOURCE_FACTS.ID
  AND RESOURCES.ID = USERS.PRID
  AND USERS.PRPRIMARYROLEID = ROLES.ID
  AND ORGS.DEPARTMENT = DEPARTMENTS.DEPARTCODE
  AND DEPARTMENTS.OBS_UNIT_ID = COST_CENTERS.UNIT_ID
  AND DEPARTMENTS.OBS_UNIT_ID = SUB_ORGANIZATIONS.UNIT_ID
  AND DEPARTMENTS.OBS_UNIT_ID = ORGANIZATIONS.UNIT_ID
  AND RESOURCES.MANAGER_ID = MANAGERS.USER_ID(+)
  AND RESOURCES.ENTITY_CODE = 'CID'