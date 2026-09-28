SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_AetherSync_UpsertPoint]
    @Id UNIQUEIDENTIFIER,
    @Code VARCHAR(50),
    @Name VARCHAR(150),
    @Address VARCHAR(200),
    @BranchName VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- 1. DESGLOSAR EL CÓDIGO (Ej: "88-PRA11")
        DECLARE @DashIndex INT = CHARINDEX('-', @Code);
        DECLARE @ClienteId INT = 0;
        DECLARE @CodPuntoCliente NVARCHAR(255) = @Code;

        IF @DashIndex > 0
        BEGIN
            SET @ClienteId = TRY_CAST(SUBSTRING(@Code, 1, @DashIndex - 1) AS INT);
            SET @CodPuntoCliente = SUBSTRING(@Code, @DashIndex + 1, LEN(@Code));
        END

        -- 2. RESOLVER LLAVES FORÁNEAS (Lookups para Sucursal y Ciudad)
        DECLARE @SucursalId INT = 1; -- Fallback a BOGOTA
        SELECT TOP 1 @SucursalId = Id FROM dbo.AdmSucursales WHERE NombreSucursal = @BranchName;

        DECLARE @CiudadId INT = 11001; -- Fallback a BOGOTA
        SELECT TOP 1 @CiudadId = Id FROM dbo.AdmCiudades WHERE NombreCiudad = @BranchName;

        -- 3. CÁLCULO DEL CONSECUTIVO (CodPuntoVatco) PARA NUEVOS REGISTROS
        -- Busca el valor numérico más alto para ese cliente. Si no tiene puntos, inicia en ClienteId * 10000.
        DECLARE @NextCodPuntoVatco NVARCHAR(255);
        SELECT @NextCodPuntoVatco = CAST(ISNULL(MAX(TRY_CAST(CodPuntoVatco AS INT)), @ClienteId * 10000) + 1 AS NVARCHAR(255))
        FROM dbo.AdmPuntos 
        WHERE ClienteId = @ClienteId AND TRY_CAST(CodPuntoVatco AS INT) IS NOT NULL;

        -- 4. INSTRUCCIÓN MERGE
        MERGE INTO dbo.AdmPuntos WITH (HOLDLOCK) AS Target
        USING (
            SELECT 
                @Code AS CodigoPunto,
                @ClienteId AS ClienteId,
                @CodPuntoCliente AS CodPuntoCliente,
                @Name AS Nombre,
                @Address AS Direccion,
                @SucursalId AS SucursalId,
                @CiudadId AS CiudadId
        ) AS Source
        ON Target.CodigoPunto = Source.CodigoPunto

        WHEN MATCHED THEN
            UPDATE SET 
                NombrePunto = Source.Nombre,
                NombreCorto = Source.Nombre,
                PuntoFacturacion = Source.Nombre,
                Direccion = Source.Direccion,
                SucursalId = Source.SucursalId,
                CiudadId = Source.CiudadId
                -- CodPuntoVatco NO se actualiza para no alterar el consecutivo histórico

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                CodigoPunto, CodPuntoVatco, ClienteId, CodPuntoCliente, CodClientePrincipal,
                NombrePunto, NombreCorto, PuntoFacturacion, Direccion, Telefono,
                Responsable, CargoResponsable, CorreoResponsable, SucursalId, CiudadId,
                Latitud, Longitud, RadioPunto, BaseCambio, LlavesPunto, SobresPunto,
                ChequesPunto, FondoPunto, CodigoFondo, TrasladoPunto, CoberturaPunto,
                FechaIngreso, FechaRetiro, TipoPunto, TipoNegocio, DocumentosPunto,
                ExistenciasPunto, PrediccionPunto, CustodiaPunto, OtrosValoresPunto,
                Otros, LiberacionEfectivoPunto, EscalaInterurbanos, CodCas4u, NivelRiesgo,
                CodigoRango, InfoRangoAtencion, Bateria, BateriaAtm, LocalizacionAtm,
                EmergenciaAtm, PrimeraProvision, MarcaAtm, ModalidadAtm, SeteoId,
                Divisa, SolicitudWsAtm, TipoAtm, PorcentajeAgotamiento, CriticidadAtm,
                Consignacion, CodigoComposicion, Estado, CartaInclusion, RutaId, BaseCambioId
            )
            VALUES (
                Source.CodigoPunto, @NextCodPuntoVatco, Source.ClienteId, Source.CodPuntoCliente, 0,
                Source.Nombre, Source.Nombre, Source.Nombre, Source.Direccion, NULL,
                NULL, NULL, NULL, Source.SucursalId, Source.CiudadId,
                NULL, NULL, '100', 0, 0, 0,
                0, 0, NULL, 0, 'U',
                CAST(GETDATE() AS DATE), NULL, 0, 7, 0,
                0, 0, 0, 0,
                NULL, 0, 0, NULL, NULL,
                NULL, NULL, 0, NULL, NULL,
                0, NULL, NULL, NULL, NULL,
                NULL, 0, NULL, NULL, NULL,
                NULL, NULL, 1, NULL, 1, NULL -- RutaId asume un valor por defecto (1) para cumplir con el Unchecked
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