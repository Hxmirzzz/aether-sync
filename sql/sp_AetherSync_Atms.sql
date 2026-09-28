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
        -- 1. DESGLOSAR EL CÓDIGO (Ej: "1-1085")
        DECLARE @DashIndex INT = CHARINDEX('-', @InternalCode);
        DECLARE @ClienteId INT = TRY_CAST(@ClientCode AS INT);
        DECLARE @CodPuntoCliente NVARCHAR(255) = @InternalCode;

        IF @DashIndex > 0
        BEGIN
            SET @CodPuntoCliente = SUBSTRING(@InternalCode, @DashIndex + 1, LEN(@InternalCode));
        END

        IF @ClienteId IS NULL
            SET @ClienteId = TRY_CAST(SUBSTRING(@InternalCode, 1, @DashIndex - 1) AS INT);

        IF @ClienteId IS NULL 
            SET @ClienteId = 0;

        -- 2. CÁLCULO DEL CONSECUTIVO (CodPuntoVatco) PARA NUEVOS REGISTROS
        DECLARE @NextCodPuntoVatco NVARCHAR(255);
        SELECT @NextCodPuntoVatco = CAST(ISNULL(MAX(TRY_CAST(CodPuntoVatco AS INT)), @ClienteId * 10000) + 1 AS NVARCHAR(255))
        FROM dbo.AdmPuntos 
        WHERE ClienteId = @ClienteId AND TRY_CAST(CodPuntoVatco AS INT) IS NOT NULL;

        -- 3. INSTRUCCIÓN MERGE APUNTANDO A AdmPuntos CON TipoPunto = 1
        MERGE INTO dbo.AdmPuntos WITH (HOLDLOCK) AS Target
        USING (
            SELECT 
                @InternalCode AS CodigoPunto,
                @ClienteId AS ClienteId,
                @CodPuntoCliente AS CodPuntoCliente,
                @Name AS Nombre,
                @Brand AS MarcaTexto,
                @Model AS ModeloTexto
        ) AS Source
        ON Target.CodigoPunto = Source.CodigoPunto

        WHEN MATCHED THEN
            UPDATE SET 
                NombrePunto = Source.Nombre,
                NombreCorto = Source.Nombre,
                PuntoFacturacion = Source.Nombre,
                Estado = 1

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
                Source.Nombre, Source.Nombre, Source.Nombre, 'ATM', NULL,
                NULL, NULL, NULL, 1, 11001, 
                NULL, NULL, '100', 0, 0, 0,
                0, 0, NULL, 0, 'U',
                CAST(GETDATE() AS DATE), NULL, 1, 7, 0, 
                0, 0, 0, 0,
                NULL, 0, 0, NULL, NULL,
                NULL, NULL, 0, NULL, NULL,
                0, NULL, NULL, NULL, NULL,
                NULL, 0, NULL, NULL, NULL,
                NULL, NULL, 1, NULL, 1, NULL
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