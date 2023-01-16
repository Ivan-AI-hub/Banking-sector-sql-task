use BankingSector

SELECT 
	   Accounts.Id AS 'Account id',
	   Accounts.Balance As 'Account balance',
	   COUNT(BankCards.Balance) As 'Cards count',
	   SUM(BankCards.Balance) AS 'Cards balance',
	   Accounts.Balance - SUM(BankCards.Balance) AS 'Free balance'
FROM BankCards
	JOIN Accounts on Accounts.Id = AccountId
GROUP BY Accounts.Id, Accounts.Balance