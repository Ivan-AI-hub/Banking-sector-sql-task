use BankingSector

SELECT 
	   Accounts.Id AS 'Account id',
	   Accounts.Balance As 'Account balance',
	   COUNT(BankCards.Balance) As 'Cards count',
	   IsNull(SUM(BankCards.Balance), 0) AS 'Cards balance',
	   IsNull(Accounts.Balance - SUM(BankCards.Balance), Accounts.Balance) AS 'Free balance'
FROM BankCards
	RIGHT JOIN Accounts on Accounts.Id = AccountId
GROUP BY Accounts.Id, Accounts.Balance
Having Accounts.Balance != SUM(BankCards.Balance)