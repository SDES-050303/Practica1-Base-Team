-- Poblado de las tablas

ALTER PROCEDURE dbo.poblar_es
AS BEGIN
	-- Eliminacion de las tablas fact
	DELETE [dbo].[fact_entrada];
	DELETE [dbo].[fact_salida];

	-- Eliminacion de las tablas dim
	DELETE [dbo].[dim_articulo];
	DELETE [dbo].[dim_cliente];
	DELETE [dbo].[dim_sub_entrada];
	DELETE [dbo].[dim_sub_salida];
	DELETE [dbo].[dim_time];
	DELETE [dbo].[dim_vendedor];

	-- Datos de la tabla dim_articulo
	INSERT INTO [dbo].[dim_articulo]
	EXEC [dbo].[sp_dim_articulo]
	PRINT 'Tabla dim_articulo poblada!'

	-- Datos de la tabla dim_cliente
	INSERT INTO [dbo].[dim_cliente]
	EXEC [dbo].[sp_dim_cliente]
	PRINT 'Tabla dim_cliente poblada!'

	-- Datos de la tabla dim_sub_entrada
	INSERT INTO [dbo].[dim_sub_entrada]
	EXEC [dbo].[sp_dim_sub_entrada]
	PRINT 'Tabla dim_sub_entrada poblada!'

	-- Datos de la tabla dim_sub_salida
	INSERT INTO [dbo].[dim_sub_salida]
	EXEC [dbo].[sp_dim_sub_salida]
	PRINT 'Tabla dim_sub_salida poblada!'

	-- Datos de la tabla dim_time
	INSERT INTO [dbo].[dim_time]
	EXEC [dbo].[sp_dim_time]
	PRINT 'Tabla dim_time poblada!'

	-- Datos de la tabla dim_vendedor
	INSERT INTO [dbo].[dim_vendedor]
	EXEC [dbo].[sp_dim_vendedor]
	PRINT 'Tabla dim_time poblada!'

	-- Insercion de un registro "no valido" dentro de dim_vendedor
	INSERT INTO [dbo].[dim_vendedor] (VendedorID, Nombre)
	SELECT 'NO PROPORCIONADO', 'NO PROPORCIONADO'
	WHERE NOT EXISTS (SELECT 1 FROM [dbo].[dim_vendedor] WHERE VendedorID = 'NO PROPORCIONADO');

	-- Insercion de un registro "no valido" dentro de dim_cliente
	INSERT INTO [dbo].[dim_cliente] (ClienteID, Ciudad, Estado, Pais, Tipo_Cliente)
	SELECT 'NO PROPORCIONADO', 'NO PROPORCIONADO', 'NO PROPORCIONADO', 'NO PROPORCIONADO', 'NO PROPORCIONADO'
	WHERE NOT EXISTS (SELECT 1 FROM [dbo].[dim_cliente] WHERE ClienteID = 'NO PROPORCIONADO');

	-- Datos de la tabla fact_entrada
	INSERT INTO [dbo].[fact_entrada]
	EXEC [dbo].[sp_fact_entrada]
	PRINT 'Tabla fact_entrada poblada!'

	-- Datos de la tabla fact_salida
	INSERT INTO [dbo].[fact_salida]
	EXEC [dbo].[sp_fact_salida]
	PRINT 'Tabla fact_salida poblada!'

	PRINT 'Todas las tablas pobladas!!'
END;