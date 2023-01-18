USE BankingSector;
GO

DROP TRIGGER BankCardsValidateUpdateTrigger
GO

CREATE TRIGGER BankCardsValidateUpdateTrigger ON BankCards
FOR UPDATE
AS
BEGIN
	 IF UPDATE(Balance)
	 BEGIN
		 DECLARE @AccountBalance MONEY, @CardsBalance MONEY

		 SELECT @AccountBalance = Accounts.Balance, @CardsBalance = SUM(BankCards.Balance)
		 FROM Accounts JOIN BankCards ON Accounts.Id = BankCards.AccountId
		 WHERE Accounts.Id IN ( Select AccountId from inserted)
		 GROUP BY Accounts.Balance

		 IF @CardsBalance > @AccountBalance
		  BEGIN
			   ROLLBACK TRANSACTION
			   PRINT 'There are not enough funds on the account. It is not possible to increase the funds on the card.';
		  END
	  END
END
Go

SELECT Accounts.Id, BankCards.Id, Sum(BankCards.Balance) AS 'card balance', Accounts.Balance
FROM Accounts JOIN BankCards ON Accounts.Id = AccountId
GROUP BY Accounts.Id, BankCards.Id,  Accounts.Balance
Go 

Update BankCards
Set Balance = 300
Where Id = 1001
GO

SELECT Accounts.Id, BankCards.Id, Sum(BankCards.Balance) AS 'card balance', Accounts.Balance
FROM Accounts JOIN BankCards ON Accounts.Id = AccountId
GROUP BY Accounts.Id, BankCards.Id,  Accounts.Balance
Go 