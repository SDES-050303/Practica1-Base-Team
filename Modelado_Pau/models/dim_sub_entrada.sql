-- Tabla con todos los IDs

CREATE PROCEDURE sp_dim_sub_entrada
AS
BEGIN
    SELECT DISTINCT
        UPPER(TRIM(e.[Folio])) AS Folio,
        UPPER(TRIM(ISNULL(e.[Cliente], 'No proporcionado'))) AS ClienteID,
        UPPER(TRIM(ISNULL(e.[Vendedor], 'No proporcionado'))) AS VendedorID,
        CAST(CONVERT(varchar(8), Fecha, 112) AS INT) AS TimeID

    FROM [AutopartesO2025].[dbo].[EntradaEncabezado] e
END;