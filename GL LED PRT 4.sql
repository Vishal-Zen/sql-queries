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