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
        -- Mapeos:
        DECLARE @TipoDocumentoId INT = 1; 
        IF @IdentificationType = 'NIT' SET @TipoDocumentoId = 1;
        ELSE IF @IdentificationType = 'CC' SET @TipoDocumentoId = 2;

        DECLARE @TipoClienteId INT = 1;
        DECLARE @NumericId INT = TRY_CAST(@ClientCode AS INT);
        DECLARE @NumericDocument INT = TRY_CAST(@TaxIdentification AS INT);
        DECLARE @CiudadDefecto INT = 11001;
        DECLARE @Siglas VARCHAR(5) = LEFT(@Acronym, 5);

        DECLARE @TargetId INT = NULL;

        IF @NumericId IS NOT NULL
            SELECT TOP 1 @TargetId = Id FROM dbo.AdmClientes WHERE NumeroDocumento = @NumericDocument;

        IF @TargetId IS NULL AND @NumericId IS NOT NULL
            SELECT TOP 1 @TargetId = Id FROM dbo.AdmClientes WHERE Id = @NumericId;

        IF @TargetId IS NOT NULL
        BEGIN
            UPDATE dbo.AdmClientes
            SET 
                NombreCliente = @CommercialName,
                RazonSocial = @BusinessName,
                SiglasCliente = @Siglas,
                TipoDocumento = @TipoDocumentoId,
                NumeroDocumento = @NumericDocument,
                TipoCliente = @TipoClienteId,
                Estado = @IsActive
            WHERE Id = @TargetId;
        END
        ELSE
        BEGIN
            IF @NumericId IS NOT NULL AND  @NumericId > 0
            BEGIN
                SET IDENTITY_INSERT dbo.AdmClientes ON;

                INSERT INTO dbo.AdmClientes (
                    Id, NombreCliente, RazonSocial, SiglasCliente, 
                    TipoDocumento, NumeroDocumento, CiudadId, 
                    TipoCliente, Estado
                ) VALUES (
                    @NumericId, @CommercialName, @BusinessName, @Siglas,
                    @TipoDocumentoId, @NumericDocument, @CiudadDefecto,
                    @TipoClienteId, @IsActive
                );

                SET IDENTITY_INSERT dbo.AdmClientes OFF;
            END
            ELSE
            BEGIN
                INSERT INTO dbo.AdmClientes (
                    NombreCliente, RazonSocial, SiglasCliente, 
                    TipoDocumento, NumeroDocumento, CiudadId, 
                    TipoCliente, Estado
                ) VALUES (
                    @CommercialName, @BusinessName, @Siglas,
                    @TipoDocumentoId, @NumericDocument, @CiudadDefecto,
                    @TipoClienteId, @IsActive
                );
            END
        END
    END TRY
    BEGIN CATCH
        IF OBJECTPROPERTY(OBJECT_ID('dbo.AdmClientes'), 'TableHasIdentity') = 1
            SET IDENTITY_INSERT dbo.AdmClientes OFF;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO