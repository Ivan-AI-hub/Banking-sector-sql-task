Use BankingSector
go

--Типы товаров
delete Clients_SocialStatuses
delete SocialStatuses
delete BankCards
delete Accounts
delete Clients
delete Cities_Banks
delete Cities
delete Banks
go

DECLARE @OneSideLength Int, @ManySideLength Int, @Iterator Int
Set @OneSideLength = 500
Set @ManySideLength = 1000
 

begin /*Fill One side tables table*/
	Set @Iterator = 0;
	WHILE @Iterator < @OneSideLength
		BEGIN
			Insert into Banks(Name) values('Bank' + str(@Iterator))
			Insert into Cities(Name) values('City' + str(@Iterator))
			Insert into SocialStatuses(Name) values('Status' + str(@Iterator))
			Insert into Clients(FirstName, LastName) values('FirstName' + str(@Iterator), 'LastName' + str(@Iterator))
			Set @Iterator = @Iterator + 1
		END;
end

begin /*Fill Many side tables table*/
	Set @Iterator = 0;
	WHILE @Iterator < @ManySideLength
		BEGIN
			--Fill Cities_Banks table
			insert into Cities_Banks(BankId, CitieId) 
					values
					((SELECT TOP 1 Id FROM Banks order BY NEWID()),
					(SELECT TOP 1 Id FROM Cities order BY NEWID()))
			------------------------------------------

			--Fill Clients_SocialStatuses table
			insert into Clients_SocialStatuses(ClientId, SocialStatusId)
			values 
			((SELECT TOP 1 Id FROM Clients order BY NEWID()),
			(SELECT TOP 1 Id FROM SocialStatuses order BY NEWID()))
			-------------------------------------------			

			--Fill Accounts table
			insert into Accounts(ClientId, BankId, Balance)
			values 
			((SELECT TOP 1 Id FROM Clients order BY NEWID()),
			(SELECT TOP 1 Id FROM Banks order BY NEWID()),
			RAND()*1000)
			-------------------------------------------			

			--Fill BankCards table
			insert into BankCards(AccountId, Balance)
			values 
			((SELECT TOP 1 Id FROM Accounts order BY NEWID()),
			RAND()*10)
			-------------------------------------------	
			Set @Iterator = @Iterator + 1
		END;
end
