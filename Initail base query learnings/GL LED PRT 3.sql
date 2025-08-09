 SELECT
     CASE
        WHEN ALLOC.GBankAllocInfEntryType = 1103                               THEN 'RU'
        WHEN ALLOC.GBankAllocInfEntryType IN (1100,1101,1102,1104)             THEN 'PD'
        WHEN ALLOC.GBankAllocInfEntryType IN (2000,2001)                       THEN 'TL'
        ELSE 'PP'
    END AS JOURNAL,
    ACCT.GLAcctID                 AS GLACCTID,
    ACCT.GLAccountAcctName        AS GLACCOUNTACCTNAME,
    ACCT.GLAccountNickName        AS GLACCOUNTNICKNAME,
    ACCT.GLAccountStatus          AS GLACCOUNTSTATUS,
    ACCT.GLAccountCategory        AS GLACCOUNTCATEGORY,
    COMM.GBankCommInfDate         AS GBANKCOMMINFDATE,

    /* Debit amount */
    CASE
        WHEN ALLOC.GBankAllocInfEntryType IN (1400,2000,2001)
             THEN ALLOC.GBankAllocInfAmount
        ELSE 0
    END AS DEBITAMOUNT,

    /* Credit amount */
    CASE
        WHEN ALLOC.GBankAllocInfEntryType IN (1100,1101,1102,1103,1104,1300,1301)
             THEN ALLOC.GBankAllocInfAmount
        ELSE 0
    END AS CREDITAMOUNT,

    /* Free‑text explanation */
    ALLOC.GBankAllocInfExplanation AS EXPLANATION

FROM   PCLAW_GBCOMM  COMM
JOIN   PCLAW_GBALLOC ALLOC
       ON  ALLOC.GBankAllocInfCheckID = COMM.GBankCommInfID
JOIN   PCLAW_GLACCT  ACCT
       ON  ALLOC.GBankAllocInfGLID   = ACCT.GLAcctID
WHERE  COMM.GBankCommInfStatus = 0
  AND  ALLOC.GBankAllocInfEntryType NOT IN
       (1600,1650,1651,1652,6500,1803,1899,1200)
  AND  COMM.GBankCommInfEntryType  NOT IN
       (1900,1901,1902,1903,1904,1905)
  AND  ALLOC.GBankAllocInfAmount <> 0