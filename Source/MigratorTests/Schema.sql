SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Addresses]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Addresses](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[City] [varchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Street] [varchar](100) COLLATE Latin1_General_CI_AS NULL,
 CONSTRAINT [PK_Addresses] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Contacts]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Contacts](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[FirstName] [varchar](50) COLLATE Latin1_General_CI_AS NULL,
	[LastName] [varchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AddressId] [int] NULL,
 CONSTRAINT [PK_Contacts] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Contacts]') AND name = N'IX_Contacts_AddressId')
CREATE UNIQUE NONCLUSTERED INDEX [IX_Contacts_AddressId] ON [dbo].[Contacts] 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SchemaMigrations]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[SchemaMigrations](
	[Version] [varchar](50) COLLATE Latin1_General_CI_AS NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[ValidStreetAddress]'))
EXEC dbo.sp_executesql @statement = N'
CREATE TRIGGER ValidStreetAddress
   ON  Addresses
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Some awsome code to test if the street address is valid.    

END
' 
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Contacts_Addresses]') AND parent_object_id = OBJECT_ID(N'[dbo].[Contacts]'))
ALTER TABLE [dbo].[Contacts]  WITH CHECK ADD  CONSTRAINT [FK_Contacts_Addresses] FOREIGN KEY([AddressId])
REFERENCES [Addresses] ([Id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Contacts_Addresses]') AND parent_object_id = OBJECT_ID(N'[dbo].[Contacts]'))
ALTER TABLE [dbo].[Contacts] CHECK CONSTRAINT [FK_Contacts_Addresses]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CombineContactName]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE FUNCTION [dbo].[CombineContactName]
(
	@FirstName VARCHAR(50),
	@LastName VARCHAR(50)
)
RETURNS VARCHAR(100)
AS
BEGIN
	RETURN @LastName + '', '' + @FirstName; 
END
' 
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[AddressView]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[AddressView]
AS
SELECT     dbo.Addresses.*
FROM         dbo.Addresses
' 
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[ContactsView]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[ContactsView]
AS
SELECT     dbo.Contacts.*
FROM         dbo.Contacts
' 
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[ContactsWithCityView]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[ContactsWithCityView]
AS
SELECT     dbo.ContactsView.*, dbo.AddressView.City
FROM         dbo.AddressView CROSS JOIN
                      dbo.ContactsView
' 
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AddressContactInsert]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[AddressContactInsert]
	@FirstName VARCHAR(50),
	@LastName VARCHAR(50),
	@City VARCHAR(50),
	@Street VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Call other stored procs.
	DECLARE @AddressId INT;
	EXEC @AddressId = AddressInsert @City, @Street;
	EXEC ContactInsert @FirstName, @LastName, @AddressId;
	
END
' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AddressInsert]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[AddressInsert]
	@City VARCHAR(50),
	@Street VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO Addresses(City, Street)
	VALUES (@City, @Street);
	
	Return SCOPE_IDENTITY();
	
END
' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ContactInsert]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[ContactInsert]
	@FirstName VARCHAR(50),
	@LastName VARCHAR(50),
	@AddressId INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO Contacts (FirstName, LastName, AddressId)
	VALUES (@FirstName, @LastName, @AddressId)
	
END
' 
END
GO
-- Migrations --
Insert Into SchemaMigrations Values ('20101118122220');
Insert Into SchemaMigrations Values ('20101118122225');
Insert Into SchemaMigrations Values ('20101118122227');
