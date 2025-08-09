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