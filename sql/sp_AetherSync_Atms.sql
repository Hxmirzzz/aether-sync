SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_AetherSync_UpsertAtm]
    @Id UNIQUEIDENTIFIER,
    @InternalCode VARCHAR(50),
    @ClientCode VARCHAR(50),
    @Name VARCHAR(150),
    @Brand VARCHAR(100),
    @Model VARCHAR(100),
    @ClientName VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        MERGE INTO dbo.Atms WITH (HOLDLOCK) AS Target
        USING (
            SELECT
                @Id AS Id,
                @InternalCode AS InternalCode,
                @ClientCode AS ClientCode,
                @Name AS Name,
                @Brand AS Brand,
                @Model AS Model,
                @ClientName AS ClientName
        ) AS Source
        ON Target.internal_code = Source.InternalCode

        WHEN MATCHED THEN
            UPDATE SET
                name = Source.Name,
                brand = Source.Brand,
                model = Source.Model,
                client_code = Source.ClientCode,
                client_name = Source.ClientName,
                updated_at = GETDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                -- Campos dinámicos
                id, internal_code, client_code, name,
                brand, model, client_name,

                -- Campos heredados/estáticos
                is_active, installation_date, created_at
            )
            VALUES (
                Source.Id, Source.InternalCode, Source.ClientCode, Source.Name,
                Source.Brand, Source.Model, Source.ClientName,

                -- Valores por defecto
                1, GETDATE(), GETDATE()
            );

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO