-- Tabla con todos los vendedores

CREATE PROCEDURE sp_dim_vendedor
AS
BEGIN
	SELECT DISTINCT
		UPPER(TRIM(v.[Clave])) as VendedorID,
		UPPER(TRIM(v.[Nombre])) AS Nombre

	FROM [AutopartesO2025].[dbo].[Vendedor] v
END;