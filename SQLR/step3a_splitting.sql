/****** Stored Procedure for splitting the data set into a training and a testing set  ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[splitting]
GO

CREATE PROCEDURE [splitting]  @splitting_percent int
AS
BEGIN
  DROP TABLE IF EXISTS Train_Id;
  DECLARE @sql nvarchar(max);
  SET @sql = N'
     SELECT Lead_Id 
	 INTO Train_Id 
	 FROM CM_AD_N
     WHERE ABS(CAST(BINARY_CHECKSUM(Lead_ID, NEWID()) as int)) % 100 < ' + Convert(Varchar, @splitting_percent);

  EXEC sp_executesql @sql
;
END
GO
