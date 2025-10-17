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
END;