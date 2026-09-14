SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_AetherSync_UpsertClient]
    @Id UNIQUEIDENTIFIER,
    @ClientCode VARCHAR(50),
    @BusinessName VARCHAR(200),
    @CommercialName VARCHAR(200),
    @IdentificationType VARCHAR(20),
    @TaxIdentification VARCHAR(50),
    @ClientType VARCHAR(50),
    @Acronym VARCHAR(50),
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON; -- Previene el envío de mensajes de filas afectadas, mejorando el rendimiento en red

    BEGIN TRY
        -- Utilizamos MERGE para realizar Upsert (Insert/Update) de forma atómica y eficiente
        MERGE INTO dbo.Clients WITH (HOLDLOCK) AS Target
        USING (
            SELECT
                @Id AS Id,
                @ClientCode AS ClientCode,
                @BusinessName AS BusinessName,
                @CommercialName AS CommercialName,
                @IdentificationType AS IdentificationType,
                @TaxIdentification AS TaxIdentification,
                @ClientType AS ClientType,
                @Acronym AS Acronym,
                @IsActive AS IsActive
        ) AS Source
        ON Target.tax_identification = Source.TaxIdentification
           OR Target.client_code = Source.ClientCode -- Llaves lógicas de deduplicación

        WHEN MATCHED THEN
            UPDATE SET
                business_name = Source.BusinessName,
                commercial_name = Source.CommercialName,
                client_type = Source.ClientType,
                is_active = Source.IsActive,
                updated_at = GETDATE() -- Auditoría automática

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                id, client_code, business_name, commercial_name,
                identification_type, tax_identification, client_type,
                acronym, is_active, created_at
            )
            VALUES (
                Source.Id, Source.ClientCode, Source.BusinessName, Source.CommercialName,
                Source.IdentificationType, Source.TaxIdentification, Source.ClientType,
                Source.Acronym, Source.IsActive, GETDATE()
            );

    END TRY
    BEGIN CATCH
        -- Lanzamos el error hacia Python para que el UnitOfWork haga el Rollback del lote
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO