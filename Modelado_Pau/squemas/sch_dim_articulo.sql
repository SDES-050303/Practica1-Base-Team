USE [Proyecto_ES]

CREATE TABLE dim_articulo (
	ArticuloID NVARCHAR(50),
	Descripcion NVARCHAR(100),
	Articulo_Tipo NVARCHAR(50),
	Articulo_Grupo NVARCHAR(50),
	Articulo_Clase NVARCHAR(50),
	Precio NUMERIC
);