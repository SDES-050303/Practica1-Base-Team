-- Tabla con todos los clientes y su tipo

CREATE PROCEDURE dbo.sp_dim_cliente
AS
BEGIN
	SELECT 
		UPPER(TRIM(c.[Clave])) as ClienteID,
		-- Valores bloqueados por privacidad
		UPPER(TRIM(ISNULL(c.[Ciudad], 'No proporcionado'))) AS Ciudad, 
		UPPER(TRIM(ISNULL(c.[Estado], 'No proporcionado'))) AS Estado, 
		UPPER(TRIM(ISNULL(c.[Pais], 'No proporcionado'))) AS Pais,
		UPPER(TRIM(ISNULL(ct.[Descripcion], 'No proporcionado'))) as Tipo_Cliente
	FROM [AutopartesO2025].[dbo].[Cliente] c

	LEFT JOIN [AutopartesO2025].[dbo].[ClienteTipo] ct
		ON c.ClienteTipo = ct.Clave
	
	UNION ALL

    SELECT 
        'NO PROPORCIONADO' AS ClienteID,
        'NO PROPORCIONADO' AS Ciudad,
        'NO PROPORCIONADO' AS Estado,
        'NO PROPORCIONADO' AS Pais,
        'NO PROPORCIONADO' AS Tipo_Cliente;
END;