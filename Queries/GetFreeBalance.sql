use BankingSector

SELECT 
	Accounts.Id AS 'Account id',
	IsNull(Accounts.Balance - SUM(BankCards.Balance), Accounts.Balance) AS 'Free balance'
FROM BankCards
	RIGHT JOIN Accounts on Accounts.Id = AccountId
GROUP BY Accounts.Id, Accounts.Balance