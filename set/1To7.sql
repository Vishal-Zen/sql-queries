SELECT
    'JE'                            AS JOURNAL,
    ACCT.GLACCTID                   AS GLACCTID,
    ACCT.GLACCOUNTACCTNAME          AS GLACCOUNTACCTNAME,
    ACCT.GLACCOUNTNICKNAME          AS GLACCOUNTNICKNAME,
    ACCT.GLACCOUNTSTATUS            AS GLACCOUNTSTATUS,
    ACCT.GLACCOUNTCATEGORY          AS GLACCOUNTCATEGORY,
    ENTRY.GJEntryDate               AS ENTRYDATE,
    


    /* DEBIT AMOUNT */
    CASE
        WHEN ALLOC.GJAllocationAmount > 0
            THEN ALLOC.GJAllocationAmount
        ELSE 0
    END AS DEBITAMOUNT,

    /* CREDIT AMOUNT */
    CASE
        WHEN ALLOC.GJAllocationAmount < 0
            THEN ALLOC.GJAllocationAmount
        ELSE 0
    END AS CREDITAMOUNT,
    ENTRY.GJEntryExpl                as EXPLANATION

FROM PCLAW_GJENTRY ENTRY
JOIN PCLAW_GJALLOC ALLOC 
    ON ENTRY.GJENTRYID = ALLOC.GJALLOCATIONGJID
JOIN PCLAW_GLACCT ACCT
    ON ALLOC.GJALLOCATIONGJID = ACCT.GLACCTID
JOIN PCLAW_TRANIDX TRAN
    ON ENTRY.GJENTRYID = TRAN.TRANINDEXSEQUENCEID

WHERE TRAN.TRANINDEXSTATUS = 0

union all
select 
    'PP'                          AS JOURNAL,
    ACCT.GLAcctID                 AS GLACCTID,
    ACCT.GLAccountAcctName        AS GLACCOUNTACCTNAME,
    ACCT.GLAccountNickName        AS GLACCOUNTNICKNAME,
    ACCT.GLAccountStatus          AS GLACCOUNTSTATUS,
    ACCT.GLAccountCategory        AS GLACCOUNTCATEGORY,
    COMM.GBankCommInfDate         AS GBANKCOMMINFDATE,
    /* Debit amount */
    CASE
        WHEN Comm.GBankCommInfEntryType IN (1300,1301,1303)
             THEN Comm.GBankCommInfAmount
        ELSE 0
    END AS DEBITAMOUNT,
    /* Credit amount */
    CASE
        WHEN COMM.GBankCommInfEntryType IN (1300,1301,1303)
             THEN 0
        ELSE  COMM.GBankCommInfAmount
    END AS CREDITAMOUNT,
    COMM.GBankCommInfPaidTo       as EXPLANATION

 
from PCLAW_GBComm COMM join PCLAW_GBAcctI ACCT_1 
on Comm.GBankCommInfAccountID = ACCT_1.GBankAcctInfBankAccountID
 join PCLAW_GLAcct ACCT 
    on ACCT_1.GBankAcctInfGLAccountID = ACCT.GLAcctID
where COMM.GBankCommInfStatus = 0 and COMM.GBankCommInfEntryType >1200 and COMM.GBankCommInfEntryType <1500

union all

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
  
  union all
  
  SELECT
    'CER'                             AS JOURNAL,
    ACCT.GLAcctID                     AS GLACCTID,
    ACCT.GLAccountAcctName            AS GLACCOUNTACCTNAME,
    ACCT.GLAccountNickName            AS GLACCOUNTNICKNAME,
    ACCT.GLAccountStatus              AS GLACCOUNTSTATUS,
    ACCT.GLAccountCategory            AS GLACCOUNTCATEGORY,
    COMM.GBankCommInfDate             AS ENTRYDATE,
    CAST(0 AS NUMBER(18,2))           AS DEBITAMOUNT,
    ALLOC.GBankAllocInfAmount         AS CREDITAMOUNT,
    ALLOC.GBankAllocInfExplanation    AS EXPLANATION
FROM   ( PCLAW_GBAlloc ALLOC
         JOIN PCLAW_GLAcct  ACCT
           ON ALLOC.GBankAllocInfGLID = ACCT.GLAcctID
       )
JOIN   PCLAW_GBComm  COMM
  ON   ALLOC.GBankAllocInfCheckID = COMM.GBankCommInfID
LEFT JOIN PCLAW_TranIDX TRAN
  ON   ALLOC.GBankAllocInfAllocID = TRAN.TranIndexSequenceID
WHERE  TRAN.TranIndexStatus = 0
  AND  ALLOC.GBankAllocInfEntryType IN (1400,1600)
  AND  ALLOC.MatterID <> 0
  
 union all
 
 select  
     'CER'                          AS JOURNAL,
    ACCT.GLAcctID                 AS GLACCTID,
    ACCT.GLAccountAcctName        AS GLACCOUNTACCTNAME,
    ACCT.GLAccountNickName        AS GLACCOUNTNICKNAME,
    ACCT.GLAccountStatus          AS GLACCOUNTSTATUS,
    ACCT.GLAccountCategory        AS GLACCOUNTCATEGORY,
    COMM.GBankCommInfDate         AS GBANKCOMMINFDATE,
    0.00                          AS DebitAmount,
    Alloc.GBankAllocInfAmount     AS CreditAmount,
    Alloc.GBankAllocInfExplanation AS EXPLAINATION

from PCLAW_GBAlloc Alloc join PCLAW_GLAcct ACCT on ACCT.GLAccountNickName = '12010'
 join PCLAW_GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
 left join PCLAW_TranIDX TRANIDX on Alloc.GBankAllocInfAllocID = TRANIDX.TranIndexSequenceID
where TRANIDX.TranIndexStatus = 0
and Alloc.GBankAllocInfEntryType in (1400,1600)
 and Alloc.MatterID<>0
 
 union all
 
 SELECT
    CASE 
        WHEN COMM.TBankCommInfEntryType IN (2050, 2054) THEN 'TD'
        ELSE 'TC'
    END AS JOURNAL,    
    ACCT.GLAcctID AS GLACCTID,
    ACCT.GLAccountAcctName AS GLACCOUNTACCTNAME,
    ACCT.GLAccountNickName AS GLACCOUNTNICKNAME,
    ACCT.GLAccountStatus AS GLACCOUNTSTATUS,
    ACCT.GLAccountCategory AS GLACCOUNTCATEGORY,
    COMM.TBankCommInfDate AS ENTRYDATE,
    CASE
        WHEN COMM.TBankCommInfEntryType IN (2050, 2054) THEN COMM.TBankCommInfAmount
        ELSE 0
    END AS DEBITAMOUNT,
    CASE
        WHEN COMM.TBankCommInfEntryType IN (2050, 2054) THEN 0
        ELSE COMM.TBankCommInfAmount
    END AS CREDITAMOUNT,
    COMM.TBankCommInfPaidTo AS EXPLANATION
FROM PCLAW_TBComm COMM
JOIN PCLAW_TBAcctI TB ON COMM.TBankCommInfAccountID = TB.TBankAcctInfBankAccountID
JOIN PCLAW_GLAcct ACCT ON TB.TBankAcctInfGLAccountID = ACCT.GLAcctID
WHERE COMM.TBankCommInfStatus = 0
  AND COMM.TBankCommInfEntryType NOT IN (1552, 1553, 2501)
  
  union all
  
SELECT
    CASE 
        WHEN COMM.TBankCommInfEntryType IN (2050) THEN 'TD'
        ELSE 'TC'
    END AS JOURNAL,    
    ACCT.GLAcctID AS GLACCTID,
    ACCT.GLAccountAcctName AS GLACCOUNTACCTNAME,
    ACCT.GLAccountNickName AS GLACCOUNTNICKNAME,
    ACCT.GLAccountStatus AS GLACCOUNTSTATUS,
    ACCT.GLAccountCategory AS GLACCOUNTCATEGORY,
    COMM.TBankCommInfDate AS GBANKCOMMINFDATE,
    
    CASE
        WHEN ALLOC.TBankAllocInfoEntryType IN (2050, 2054) THEN 0
        ELSE ALLOC.TBankAllocInfoAmount
    END AS DEBITAMOUNT,

    CASE
        WHEN ALLOC.TBankAllocInfoEntryType IN (2050, 2054) THEN ALLOC.TBankAllocInfoAmount
        ELSE 0
    END AS CREDITAMOUNT,

    ALLOC.TBankAllocInfExplanation AS EXPLANATION

FROM PCLAW_TBAlloc ALLOC
JOIN PCLAW_GLAcct ACCT 
    ON ACCT.GLAccountNickName = '23010'
JOIN PCLAW_TBComm COMM 
    ON ALLOC.TBankAllocInfoCheckID = COMM.TBankCommInfSequenceID
WHERE 
    ALLOC.TBankAllocInfoStatus = 0
    AND COMM.TBankCommInfEntryType NOT IN (1552, 1553, 2501)
