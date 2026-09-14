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
        -- Traducción de Sucursal:
        -- Si tu BD local maneja IDs numéricos para las ciudades/sucursales,
        -- lo resolvemos aquí en lugar de hacerlo en Python.
        DECLARE @BranchId INT = 1; -- Valor por defecto seguro
        IF @BranchName = 'BOGOTA' SET @BranchId = 11001;
        ELSE IF @BranchName = 'MEDELLIN' SET @BranchId = 5001;
        -- (Agregar aquí el resto de homologaciones necesarias)

        MERGE INTO dbo.Points WITH (HOLDLOCK) AS Target
        USING (
            SELECT
                @Id AS Id,
                @Code AS Code,
                @Name AS Name,
                @Address AS Address,
                @BranchId AS BranchId
        ) AS Source
        ON Target.code_point = Source.Code

        WHEN MATCHED THEN
            UPDATE SET
                name_point = Source.Name,
                address_point = Source.Address,
                branch_id = Source.BranchId,
                updated_at = GETDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                -- Campos dinámicos que vienen de la API
                code_point, name_point, address_point, branch_id,

                -- Campos heredados/estáticos de tu tabla local (El Modelo Estándar)
                status, active_flag, type_id, config_code,
                route_status, created_at
                -- (Añadir aquí el resto de las 30+ columnas que mostraste en tu estructura)
            )
            VALUES (
                Source.Code, Source.Name, Source.Address, Source.BranchId,

                -- Valores por defecto estructurales
                'U', 1, 100, '1-9997',
                0, GETDATE()
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