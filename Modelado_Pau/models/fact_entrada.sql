-- Tabla fact principal, registra las entradas

CREATE PROCEDURE [dbo].[sp_fact_entrada]
AS
BEGIN
    SELECT 
        UPPER(TRIM(e.[Folio])) AS Folio,
        UPPER(TRIM(ISNULL(e.[Cliente], 'No proporcionado'))) AS ClienteID,
        -- En caso de que VendedorID sea NULL o esta vacio, se escribe NO PROPORCIONADO
        CASE 
            WHEN UPPER(TRIM(ISNULL(e.[Vendedor], ''))) = '' THEN 'NO PROPORCIONADO'
            ELSE UPPER(TRIM(e.[Vendedor]))
        END AS VendedorID,
        UPPER(TRIM(d.[Articulo])) AS ArticuloID,
        UPPER(TRIM(ISNULL(d.[DescripcionArticulo], 'No proporcionado'))) AS Descripcion_Articulo,
        UPPER(TRIM(ISNULL(d.[CodigoAlternoArticulo], 'No proporcionado'))) AS Codigo_Articulo,
        CAST(CONVERT(varchar(8), Fecha, 112) AS INT) AS TimeID,

        UPPER(TRIM(e.[Empresa])) AS Empresa,
        UPPER(TRIM(d.[Almacen])) AS Almacen,
        UPPER(TRIM(d.[Ubicacion])) AS Ubicacion,
        d.[Partida],
        UPPER(TRIM(e.[Operacion])) AS Operacion,

        UPPER(TRIM(e.[Moneda])) AS Moneda,
        d.[Cantidad],
        d.[Precio] AS Precio_Unitario,
        UPPER(TRIM(ISNULL(d.[UMedPartida], 'No proporcionado'))) AS Unidad,
        d.[CantidadUMedInv] AS Cantidad_Unidad,

        d.[pctDescuento] AS Pct_Descuento, 
        ISNULL(e.[pctDescuentoGlobal], 0) AS Pct_Descuento_Global,
        d.[pctImpuesto] AS Pct_Impuesto,

        e.[TotalDescuento] AS Total_Descuento,
        d.[TotalDescuento] AS Total_Descuento_D,

        e.[TotalImporte] AS Total_Importe,
        d.[TotalImporte] AS Total_Importe_D,

        e.[TotalImpuesto] AS Total_Impuesto,
        d.[TotalImpuesto] AS Total_Impuesto_D,

        e.[Total] AS Total,
        d.[Total] AS Total_D,

        1 AS Contar_Partidas
    FROM [AutopartesO2025].[dbo].[EntradaEncabezado] e

    LEFT JOIN [AutopartesO2025].[dbo].[EntradaDetalle] d
        ON e.Folio = d.Folio
END;