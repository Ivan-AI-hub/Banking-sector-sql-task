use BankingSector

SELECT Banks.Id AS 'BankId', Banks.Name AS 'BankName'
FROM Cities
	JOIN Cities_Banks on Cities.Id = CitieId
	JOIN Banks on Banks.Id = BankId
Where Cities.Name = 'City         2'