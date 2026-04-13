SELECT
TBC.TBankCommInfDate as Date,
TBC.TBankCommInfPaidTo as Paidto,
TBC.TBankCommInfAccountID as Accnt,
TBC.TBankCommInfCheck as Check_Rec,
TBC.TBankCommInfSequenceID as Entrynum,
TBA.TBankAllocInfExplanation as Explnation,
TBA.MatterID as Matter,
M.MatterInfoFileDesc as Client,
TBC.TBankCommInfEntryType as TypefromTBComm,
TBA.TBankAllocInfoEntryType as TypefromTBAlloc,
Case when TBankAllocInfoEntryType <> '2050' then TBankAllocInfoAmount else 0 end as TBACheque,
Case when TBankAllocInfoEntryType = '2050' then TBankAllocInfoAmount else 0 end as TBARecepit,
TBC.TBankCommInfAmount as TBCEntrytotal



FROM 
PCLAWDB_32130.dbo.TBComm TBC

Left join PCLAWDB_32130.dbo.TBAlloc TBA
on TBC.TBankCommInfSequenceID = TBA.TBankAllocInfoCheckID

Left join  [PCLAWDB_32130].[dbo].[MattInf] AS M
       ON TBA.MatterID = M.MatterID

Where
TBankCommInfSequenceID IN ('1863949','1863951')
and
TBankCommInfDate between 20230701 and 20231231
and 
TBankCommInfAccountID ='4'
and
TBankCommInfCheck <> ''
order by
TBankCommInfDate
