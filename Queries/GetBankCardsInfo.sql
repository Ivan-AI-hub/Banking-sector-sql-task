use BankingSector

SELECT 
	   BankCards.Id AS 'Card id',
	   BankCards.Balance AS 'Balance',
	   Clients.FirstName + ' ' + Clients.LastName AS 'Client name',
	   Banks.Name AS 'Bank name'
FROM BankCards
	JOIN Accounts on Accounts.Id = AccountId
	JOIN Clients on Clients.Id = ClientId
	JOIN Banks on Banks.Id = BankId