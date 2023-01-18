USE BankingSector;
GO

DROP TRIGGER BalanceValidateUpdateTrigger
GO

CREATE TRIGGER BalanceValidateUpdateTrigger ON Accounts
FOR UPDATE
AS
BEGIN
	 IF UPDATE(Balance)
	 BEGIN
		 DECLARE @Balance MONEY, @CardsBalance MONEY

		 SELECT @Balance = inserted.Balance, @CardsBalance = SUM(BankCards.Balance)
		 FROM inserted JOIN BankCards ON inserted.Id = BankCards.AccountId
		 GROUP BY inserted.Balance

		 IF @CardsBalance > @Balance
		  BEGIN 
			   ROLLBACK TRANSACTION
			   PRINT 'There are not enough funds on the account';
		  END
	  END
END
Go

SELECT Accounts.Id, BankCards.Id, Sum(BankCards.Balance) AS 'card balance', Accounts.Balance
FROM Accounts JOIN BankCards ON Accounts.Id = AccountId
GROUP BY Accounts.Id, BankCards.Id,  Accounts.Balance
Go 

Update Accounts
Set Balance = 300
Where Id = 45028
GO

SELECT Accounts.Id, BankCards.Id, Sum(BankCards.Balance) AS 'card balance', Accounts.Balance
FROM Accounts JOIN BankCards ON Accounts.Id = AccountId
GROUP BY Accounts.Id, BankCards.Id,  Accounts.Balance
Go 