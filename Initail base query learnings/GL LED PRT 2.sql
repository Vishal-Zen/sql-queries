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