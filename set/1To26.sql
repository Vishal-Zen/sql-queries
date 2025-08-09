
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
    
   union all
   SELECT
    'AP' AS JOURNAL,    

    ACT.GLAcctID AS GLACCTID,
    ACT.GLAccountAcctName AS GLACCOUNTACCTNAME,
    ACT.GLAccountNickName AS GLACCOUNTNICKNAME,
    ACT.GLAccountStatus AS GLACCOUNTSTATUS,
    ACT.GLAccountCategory AS GLACCOUNTCATEGORY,

    COMM.TBankCommInfDate AS GBANKCOMMINFDATE,

    0 AS DEBITAMOUNT,
    ALLOC.GBankAllocInfAmount AS CREDITAMOUNT,

    INV.APInvoiceExpl AS EXPLANATION

FROM PCLAW_APInv INV
JOIN PCLAW_GBAlloc ALLOC 
    ON INV.APInvoiceID = ALLOC.GBankAllocInfCheckID

JOIN PCLAW_GLAcct ACT 
    ON ALLOC.GBankAllocInfGLID = ACT.GLAcctID

LEFT JOIN PCLAW_ActCode ACTC
    ON ALLOC.GBankAllocInfActivityID = ACTC.ActivityCodesID

LEFT JOIN PCLAW_MattInf MAT 
    ON ALLOC.MatterID = MAT.MatterID

LEFT JOIN PCLAW_TBComm COMM
    ON ALLOC.GBankAllocInfCheckID = COMM.TBankCommInfSequenceID

WHERE INV.APInvoiceStatus = 0



union all
SELECT 
    'AP' AS JOURNAL,    

    ACCT.GLAcctID AS GLACCTID,
    ACCT.GLAccountAcctName AS GLACCOUNTACCTNAME,
    ACCT.GLAccountNickName AS GLACCOUNTNICKNAME,
    ACCT.GLAccountStatus AS GLACCOUNTSTATUS,
    ACCT.GLAccountCategory AS GLACCOUNTCATEGORY,

    COMM.TBankCommInfDate AS GBANKCOMMINFDATE,

    0 AS DEBITAMOUNT,
    ALLOC.GBankAllocInfAmount AS CREDITAMOUNT,

    INV.APInvoiceExpl AS EXPLANATION

FROM PCLAW_APInv INV
JOIN PCLAW_GBAlloc ALLOC 
    ON INV.APInvoiceID = ALLOC.GBankAllocInfCheckID

JOIN PCLAW_GLAcct ACCT 
    ON ACCT.GLAccountNickName = '22010'

LEFT JOIN PCLAW_ActCode ACT 
    ON ALLOC.GBankAllocInfActivityID = ACT.ActivityCodesID

LEFT JOIN PCLAW_MattInf MAT 
    ON ALLOC.MatterID = MAT.MatterID

LEFT JOIN PCLAW_TBComm COMM
    ON ALLOC.GBankAllocInfCheckID = COMM.TBankCommInfSequenceID

WHERE INV.APInvoiceStatus = 0




union all
SELECT 
    'AP' AS JOURNAL,    

    ACCT.GLAcctID AS GLACCTID,
    ACCT.GLAccountAcctName AS GLACCOUNTACCTNAME,
    ACCT.GLAccountNickName AS GLACCOUNTNICKNAME,
    ACCT.GLAccountStatus AS GLACCOUNTSTATUS,
    ACCT.GLAccountCategory AS GLACCOUNTCATEGORY,

    COMM.TBankCommInfDate AS GBANKCOMMINFDATE,

    0 AS DEBITAMOUNT,
    ALLOC.GBankAllocInfAmount AS CREDITAMOUNT,

    INV.APInvoiceExpl AS EXPLANATION

FROM PCLAW_APInv INV 
JOIN PCLAW_GBAlloc ALLOC 
    ON INV.APInvoiceID = ALLOC.GBankAllocInfCheckID

JOIN PCLAW_GLAcct ACCT 
    ON ALLOC.GBankAllocInfGLID = ACCT.GLAcctID

LEFT JOIN PCLAW_ActCode ACT 
    ON ALLOC.GBankAllocInfActivityID = ACT.ActivityCodesID

LEFT JOIN PCLAW_MattInf MAT 
    ON ALLOC.MatterID = MAT.MatterID

LEFT JOIN PCLAW_TBComm COMM 
    ON ALLOC.GBankAllocInfCheckID = COMM.TBankCommInfSequenceID

WHERE 
    INV.APInvoiceStatus = 0 
    AND MAT.MatterID <> 0

union all

select 
    
    'AP' AS JOURNAL,    

    ACCT.GLAcctID AS GLACCTID,
    ACCT.GLAccountAcctName AS GLACCOUNTACCTNAME,
    ACCT.GLAccountNickName AS GLACCOUNTNICKNAME,
    ACCT.GLAccountStatus AS GLACCOUNTSTATUS,
    ACCT.GLAccountCategory AS GLACCOUNTCATEGORY,

    Inv.APInvoiceEntryDate AS GBANKCOMMINFDATE,

    0 AS DEBITAMOUNT,
    ALLOC.GBankAllocInfAmount AS CREDITAMOUNT,

    Inv.APInvoiceExpl AS EXPLANATION
    
from PCLAW_APInv Inv join PCLAW_GBAlloc Alloc on Inv.APInvoiceID = Alloc.GBankAllocInfCheckID
	join PCLAW_GLAcct ACCT on ACCT.GLAccountNickName = '12010'
	left join PCLAW_ActCode Act on Alloc.GBankAllocInfActivityID = Act.ActivityCodesID
	left join PCLAW_MattInf Mat on Alloc.MatterID = Mat.MatterID
where Inv.APInvoiceStatus = 0 and Mat.MatterID <> 0
union all
select 
    'pp' as journal,
    acct.glacctid as glacctid,
    acct.glaccountacctname as glaccountacctname,
    acct.glaccountnickname as glaccountnickname,
    acct.glaccountstatus as glaccountstatus,
    acct.glaccountcategory as glaccountcategory,
    inv.arinvoicedate as gbankcomminfdate,
    0 as debitamount,
    spl.arlawyersplitamount as creditamount,
    law.lawinfnickname as explanation
from pclaw_arinv inv
join pclaw_arlwyspl spl 
    on inv.invoiceid = spl.invoiceid
join pclaw_glacct acct 
    on spl.arlawyersplitlawyerid = acct.glaccountforlawyer
   and acct.glaccountspecacct = 13
   and acct.glaccountstatus = 0
join pclaw_lawinf law 
    on spl.arlawyersplitlawyerid = law.lawyerid
where inv.arinvoicestatus = 0
  and spl.arlawyersplitentrytype = 3
  and spl.arlawyersplitstatus = 0

union all

select 
    'AR' as journal,
    acct.glacctid as glacctid,
    acct.glaccountacctname as glaccountacctname,
    acct.glaccountnickname as glaccountnickname,
    acct.glaccountstatus as glaccountstatus,
    acct.glaccountcategory as glaccountcategory,
    law.arlawyersplitdate as arlawyersplitdate,
    law.arlawyersplitamount as debitamount,
    0 as creditamount,
    inf.lawinfnickname as lawinfnickname
from pclaw_arinv inv
join pclaw_arlwyspl law 
    on inv.invoiceid = law.invoiceid
join pclaw_glacct acct
    on acct.glaccountnickname = '12020'
join pclaw_lawinf inf
    on law.arlawyersplitlawyerid = inf.lawyerid
where inv.arinvoicestatus = 0 
  and law.arlawyersplitentrytype = 3 
  and law.arlawyersplitstatus = 0 
  and law.arlawyersplitamount <> 0
union all
select   
    'wo' as journal,
    acct.glacctid as glacctid,
    acct.glaccountacctname as glaccountacctname,
    acct.glaccountnickname as glaccountnickname,
    acct.glaccountstatus as glaccountstatus,
    acct.glaccountcategory as glaccountcategory,
    spl.arlawyersplitdate as arlawyersplitdate,
    spl.arlawyersplitamount * -1.0 as debitamount,
    0.00 as creditamount,
    wo.arwriteoffexplanation as explanation
from pclaw_arinv inv
join pclaw_arlwyspl spl 
    on inv.invoiceid = spl.invoiceid
join pclaw_tranidx idx 
    on spl.woid = idx.tranindexsequenceid
join pclaw_glacct acct 
    on spl.arlawyersplitglid = acct.glacctid
left join pclaw_lawinf inf 
    on spl.arlawyersplitlawyerid = inf.lawyerid
join pclaw_arwo wo 
    on spl.woid = wo.woid
where idx.tranindexstatus = 0

union all
select 
    'wo' as journal,
    acct.glacctid as glacctid,
    acct.glaccountacctname as glaccountacctname,
    acct.glaccountnickname as glaccountnickname,
    acct.glaccountstatus as glaccountstatus,
    acct.glaccountcategory as glaccountcategory,
    law.arlawyersplitdate as arlawyersplitdate,
    law.arlawyersplitamount * -1.0 as debitamount,
    0.00 as creditamount,
    wo.arwriteoffexplanation as explanation
from pclaw_arinv inv
join pclaw_arlwyspl law 
    on inv.invoiceid = law.invoiceid
join pclaw_tranidx t
    on law.woid = t.tranindexsequenceid
join pclaw_glacct acct 
    on acct.glaccountnickname = '12020'
left join pclaw_lawinf inf
    on law.arlawyersplitlawyerid = inf.lawyerid
join pclaw_arwo wo 
    on law.woid = wo.woid
where t.tranindexstatus = 0
union all
SELECT 
    'AR Disbs' AS journal,
    acct.GLAcctID AS glacctid,
    acct.GLAccountAcctName AS glaccountacctname,
    acct.GLAccountNickName AS glaccountnickname,
    acct.GLAccountStatus AS glaccountstatus,
    acct.GLAccountCategory AS glaccountcategory,
    inv.ARInvoiceDate AS arinvoicedate,
    inv.ARInvoiceDisbs AS debitamount,
    0.00 AS creditamount,
    'AR Invoice Disbs for Invoice: ' || inv.ARInvoiceInvNumber AS explanation
FROM PCLAW_ARInv inv
JOIN PCLAW_GLAcct acct 
    ON acct.GLAccountNickName = '12020'
WHERE inv.ARInvoiceStatus = 0 
  AND inv.ARInvoiceDisbs <> 0

union all
SELECT 
    'AR HST Fees' AS journal,
    acct.GLAcctID AS glacctid,
    acct.GLAccountAcctName AS glaccountacctname,
    acct.GLAccountNickName AS glaccountnickname,
    acct.GLAccountStatus AS glaccountstatus,
    acct.GLAccountCategory AS glaccountcategory,
    inv.ARInvoiceDate AS arinvoicedate,
    inv.ARInvoiceGSTFees AS debitamount,
    0.00 AS creditamount,
    'AR Invoice HST Fees for Invoice: ' || inv.ARInvoiceInvNumber AS explanation
FROM PCLAW_ARInv inv
JOIN PCLAW_GLAcct acct 
    ON acct.GLAccountNickName = '12020'
WHERE inv.ARInvoiceStatus = 0 
  AND inv.ARInvoiceGSTFees <> 0


union all
SELECT 
    'AR HST Disbs' AS journal,
    acct.GLAcctID AS glacctid,
    acct.GLAccountAcctName AS glaccountacctname,
    acct.GLAccountNickName AS glaccountnickname,
    acct.GLAccountStatus AS glaccountstatus,
    acct.GLAccountCategory AS glaccountcategory,
    inv.ARInvoiceDate AS arinvoicedate,
    inv.ARInvoiceGSTDisbs AS debitamount,
    0.00 AS creditamount,
    'AR Invoice HST Disbs for Invoice: ' || inv.ARInvoiceInvNumber AS explanation
FROM PCLAW_ARInv inv
JOIN PCLAW_GLAcct acct 
    ON acct.GLAccountNickName = '12020'
WHERE inv.ARInvoiceStatus = 0 
  AND inv.ARInvoiceGSTDisbs <> 0

union all
SELECT 
    'AR HST Fees' AS journal,
    acct.GLAcctID AS glacctid,
    acct.GLAccountAcctName AS glaccountacctname,
    acct.GLAccountNickName AS glaccountnickname,
    acct.GLAccountStatus AS glaccountstatus,
    acct.GLAccountCategory AS glaccountcategory,
    inv.ARInvoiceDate AS arinvoicedate,
    0.00 AS debitamount,
    inv.ARInvoiceGSTFees AS creditamount,
    'AR Invoice HST Fees for Invoice: ' || inv.ARInvoiceInvNumber AS explanation
FROM PCLAW_ARInv inv
JOIN PCLAW_GLAcct acct 
    ON acct.GLAccountNickName = '22060'
WHERE inv.ARInvoiceStatus = 0 
  AND inv.ARInvoiceGSTFees <> 0


union all
SELECT 
    'AR HST Disbs' AS journal,
    acct.GLAcctID AS glacctid,
    acct.GLAccountAcctName AS glaccountacctname,
    acct.GLAccountNickName AS glaccountnickname,
    acct.GLAccountStatus AS glaccountstatus,
    acct.GLAccountCategory AS glaccountcategory,
    inv.ARInvoiceDate AS arinvoicedate,
    0.00 AS debitamount,
    inv.ARInvoiceGSTDisbs AS creditamount,
    'AR Invoice HST Disbs for Invoice: ' || inv.ARInvoiceInvNumber AS explanation
FROM PCLAW_ARInv inv
JOIN PCLAW_GLAcct acct 
    ON acct.GLAccountNickName = '22060'
WHERE inv.ARInvoiceStatus = 0 
  AND inv.ARInvoiceGSTDisbs <> 0

union all
SELECT 
    'AR Retainer Usage' AS journal,
    acct.GLAcctID AS glacctid,
    acct.GLAccountAcctName AS glaccountacctname,
    acct.GLAccountNickName AS glaccountnickname,
    acct.GLAccountStatus AS glaccountstatus,
    acct.GLAccountCategory AS glaccountcategory,
    r.GBankARRcptAllocDate AS arinvoicedate,
    0.00 AS debitamount,
    r.GBankARRcptAllocAmount AS creditamount,
    'AR Invoice Retainers Used for Invoice: ' || inv.ARInvoiceInvNumber AS explanation
FROM PCLAW_ARInv inv
JOIN PCLAW_GBRcptA r 
    ON inv.InvoiceID = r.GBankARRcptAllocInvID
JOIN PCLAW_GLAcct acct 
    ON acct.GLAccountNickName = '12020'
WHERE inv.ARInvoiceStatus = 0 
  AND r.GBankARRcptAllocEntryType = 6

union all
SELECT 
    'AR Disbs' AS journal,
    acct.GLAcctID AS glacctid,
    acct.GLAccountAcctName AS glaccountacctname,
    acct.GLAccountNickName AS glaccountnickname,
    acct.GLAccountStatus AS glaccountstatus,
    acct.GLAccountCategory AS glaccountcategory,
    inv.ARInvoiceDate AS arinvoicedate,
    0.00 AS debitamount,
    inv.ARInvoiceDisbs AS creditamount,
    'AR Invoice Disbs for Invoice: ' || inv.ARInvoiceInvNumber AS explanation
FROM PCLAW_ARInv inv
JOIN PCLAW_GLAcct acct 
    ON acct.GLAccountNickName = '12010'
WHERE inv.ARInvoiceStatus = 0 
  AND inv.ARInvoiceDisbs <> 0

union all
SELECT 
    'AR Retainer Usage' AS journal,
    acct.GLAcctID AS glacctid,
    acct.GLAccountAcctName AS glaccountacctname,
    acct.GLAccountNickName AS glaccountnickname,
    acct.GLAccountStatus AS glaccountstatus,
    acct.GLAccountCategory AS glaccountcategory,
    r.GBankARRcptAllocDate AS arinvoicedate,
    r.GBankARRcptAllocAmount AS debitamount,
    0.00 AS creditamount,
    'AR Invoice Retainers Used for Invoice: ' || inv.ARInvoiceInvNumber AS explanation
FROM PCLAW_ARInv inv
JOIN PCLAW_GBRcptA r 
    ON inv.InvoiceID = r.GBankARRcptAllocInvID
JOIN PCLAW_GLAcct acct 
    ON acct.GLAccountNickName = '12010'
WHERE inv.ARInvoiceStatus = 0 
  AND r.GBankARRcptAllocEntryType = 2

union all
select  	Case when alloc.GBankAllocInfEntryType in (1103) then 'RU'
		when alloc.GBankAllocInfEntryType in (1104) then 'PD'
		when alloc.GBankAllocInfEntryType in (2000,2001) then 'TL'
		else 'PP' end as Journal, 
    acct.GLAcctID AS glacctid,
    acct.GLAccountAcctName AS glaccountacctname,
    acct.GLAccountNickName AS glaccountnickname,
    acct.GLAccountStatus AS glaccountstatus,
    acct.GLAccountCategory AS glaccountcategory,
    comm.GBankCommInfDate AS arinvoicedate,
    alloc.GBankAllocInfAmount AS debitamount,
    0.00 AS creditamount,
    alloc.GBankAllocInfExplanation AS explanation
FROM PCLAW_GBAlloc alloc
JOIN PCLAW_GLAcct acct 
    ON acct.GLAccountNickName = '22070'
JOIN PCLAW_GBComm comm 
    ON alloc.GBankAllocInfCheckID = comm.GBankCommInfID
WHERE alloc.GBankAllocInfStatus = 0
  AND alloc.GBankAllocInfEntryType IN (2000, 2001)

union all
SELECT  
    CASE 
        WHEN alloc.GBankAllocInfEntryType IN (1103) THEN 'RU'
        WHEN alloc.GBankAllocInfEntryType IN (1104) THEN 'PD'
        WHEN alloc.GBankAllocInfEntryType IN (2000, 2001) THEN 'TL'
        ELSE 'PP' 
    END AS Journal, 

    acct.GLAcctID AS glacctid,
    acct.GLAccountAcctName AS glaccountacctname,
    acct.GLAccountNickName AS glaccountnickname,
    acct.GLAccountStatus AS glaccountstatus,
    acct.GLAccountCategory AS glaccountcategory,

    comm.GBankCommInfDate AS arinvoicedate,
    alloc.GBankAllocInfAmount AS debitamount,
    0.00 AS creditamount,
    alloc.GBankAllocInfExplanation AS explanation

FROM PCLAW_GBAlloc alloc

JOIN PCLAW_GLAcct acct 
    ON acct.GLAccountNickName = '22070'

JOIN PCLAW_GBComm comm 
    ON alloc.GBankAllocInfCheckID = comm.GBankCommInfID

WHERE alloc.GBankAllocInfStatus = 0
  AND alloc.GBankAllocInfEntryType IN (2000, 2001)


union all
SELECT  
    /* JOURNAL TYPE */
    CASE 
        WHEN alloc.GBankAllocInfEntryType IN (1103) THEN 'RU'
        WHEN alloc.GBankAllocInfEntryType IN (1104) THEN 'PD'
        WHEN alloc.GBankAllocInfEntryType IN (2000, 2001) THEN 'TL'
        ELSE 'PP' 
    END AS journal,

    /* ACCOUNT DETAILS */
    acct.GLAcctID AS glacctid,
    acct.GLAccountAcctName AS glaccountacctname,
    acct.GLAccountNickName AS glaccountnickname,
    acct.GLAccountStatus AS glaccountstatus,
    acct.GLAccountCategory AS glaccountcategory,

    /* DATE */
    comm.GBankCommInfDate AS gldate,

    /* DEBIT AMOUNT */
    CASE
        WHEN alloc.GBankAllocInfAmount > 0 THEN CAST(alloc.GBankAllocInfAmount AS NUMBER(15,2))
        ELSE 0
    END AS debitamount,

    /* CREDIT AMOUNT */
    CASE
        WHEN alloc.GBankAllocInfAmount < 0 THEN CAST(alloc.GBankAllocInfAmount AS NUMBER(15,2))
        ELSE 0
    END AS creditamount,

    /* COMMENT */
    alloc.GBankAllocInfExplanation AS explanation

FROM PCLAW_GBAlloc alloc

JOIN PCLAW_GLAcct acct 
    ON acct.GLAccountNickName = '22070'

JOIN PCLAW_GBComm comm 
    ON alloc.GBankAllocInfCheckID = comm.GBankCommInfID

WHERE alloc.GBankAllocInfStatus = 0
  AND alloc.GBankAllocInfEntryType IN (2000, 2001)
