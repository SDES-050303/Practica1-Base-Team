-- Tabla de IDs de salida

CREATE PROCEDURE sp_dim_sub_salida
AS
BEGIN
    SELECT DISTINCT
        UPPER(TRIM(e.[Folio])) AS Folio,
        UPPER(TRIM(ISNULL(e.[Cliente], 'No proporcionado'))) AS ClienteID,
        UPPER(TRIM(ISNULL(e.[Vendedor], 'No proporcionado'))) AS VendedorID,
        UPPER(TRIM(ISNULL(e.[MedioEmbarque], 'No proporcionado'))) AS Embarque,
        CAST(CONVERT(varchar(8), Fecha, 112) AS INT) AS TimeID

    FROM [AutopartesO2025].[dbo].[SalidaEncabezado] e
END;