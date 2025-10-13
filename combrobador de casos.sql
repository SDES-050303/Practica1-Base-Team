/* =============================================================
   3.1 ENTRADAS
============================================================= */

-- 3.1.1 Todos los datos calculados del encabezado y detalle del Folio = 'A003920'
-- DW
SELECT 
  f.Empresa, f.Folio, f.DocumentoNK, f.FechaHora,
  f.Subtotal, f.Impuestos, f.TotalImporte, f.TotalDescuento, f.Total,
  f.Renglon, f.Cantidad_d, f.PrecioUnitario_d, f.Descuento_d, f.Impuesto_d, f.Importe_d,
  a.ArticuloNK, a.Descripcion AS Articulo, a.Marca, a.GrupoDesc, a.TipoDesc, a.ClaseDesc,
  al.AlmacenNK, c.ClienteNK, c.RazonSocial, v.VendedorNK, v.Nombre AS Vendedor,
  m.MonedaNK, m.Nombre AS Moneda
FROM Team_autopartes.dbo.FactEntradas f
LEFT JOIN Team_autopartes.dbo.DimArticulo a ON a.ArticuloKey=f.ArticuloKey
LEFT JOIN Team_autopartes.dbo.DimAlmacen  al ON al.AlmacenKey=f.AlmacenKey
LEFT JOIN Team_autopartes.dbo.DimCliente  c  ON c.ClienteKey=f.ClienteKey
LEFT JOIN Team_autopartes.dbo.DimVendedor v  ON v.VendedorKey=f.VendedorKey
LEFT JOIN Team_autopartes.dbo.DimMoneda   m  ON m.MonedaKey=f.MonedaKey
WHERE f.Folio='A003920';

-- OLTP
SELECT e.Empresa, e.Folio, e.Fecha AS FechaHora,
       e.TotalImporte AS Subtotal, e.TotalImpuesto AS Impuestos, e.TotalDescuento, e.Total,
       d.Partida AS Renglon, d.CantidadUMedInv AS Cantidad_d, d.Precio AS PrecioUnitario_d,
       d.TotalDescuento AS Descuento_d, d.TotalImpuesto AS Impuesto_d, d.Total AS Importe_d,
       d.Articulo, d.Almacen, d.DescripcionArticulo
FROM AutopartesO2025.dbo.EntradaEncabezado e
JOIN AutopartesO2025.dbo.EntradaDetalle   d ON d.Folio=e.Folio
WHERE e.Folio='A003920';


-- 3.1.2 Cantidad de entradas (contar folios) durante el mes de julio de 2018
-- DW
SELECT COUNT(DISTINCT f.DocumentoNK) AS Entradas_Julio_2018
FROM Team_autopartes.dbo.FactEntradas f
JOIN Team_autopartes.dbo.DimFecha d ON d.DateKey=f.DateKey
WHERE d.Anio=2018 AND d.MesNumero=7;

-- OLTP
SELECT COUNT(*) AS Entradas_Julio_2018
FROM AutopartesO2025.dbo.EntradaEncabezado
WHERE YEAR(Fecha)=2018 AND MONTH(Fecha)=7;

-- 3.1.3 Cantidad de entradas (contar folios) el día 12 de agosto de 2017
-- DW
SELECT COUNT(DISTINCT DocumentoNK) AS Entradas_2017_08_12
FROM Team_autopartes.dbo.FactEntradas
WHERE DateKey=20170812;

-- OLTP
SELECT COUNT(*) AS Entradas_2017_08_12
FROM AutopartesO2025.dbo.EntradaEncabezado
WHERE CONVERT(date,Fecha)='2017-08-12';


-- 3.1.4 Total, de entradas en dólares
-- DW
WITH doc_E_USD AS (
  SELECT DocumentoNK, MonedaKey, MAX(Total) AS Total
  FROM Team_autopartes.dbo.FactEntradas
  GROUP BY DocumentoNK, MonedaKey
)
SELECT SUM(d.Total) AS Total_USD
FROM doc_E_USD d
JOIN Team_autopartes.dbo.DimMoneda m ON m.MonedaKey=d.MonedaKey
WHERE UPPER(m.MonedaNK) IN ('USD','US','DLLS') OR UPPER(m.Nombre) LIKE '%DOLAR%';

-- OLTP
SELECT SUM(e.Total) AS Total_USD
FROM AutopartesO2025.dbo.EntradaEncabezado e
JOIN AutopartesO2025.dbo.Moneda m ON m.Clave=e.Moneda
WHERE UPPER(m.Clave) IN ('USD','US','DLLS') OR UPPER(m.Descripcion) LIKE '%DOLAR%';


-- 3.1.5 Total, de entradas en pesos
-- DW
WITH doc_E_MXN AS (
  SELECT DocumentoNK, MonedaKey, MAX(Total) AS Total
  FROM Team_autopartes.dbo.FactEntradas
  GROUP BY DocumentoNK, MonedaKey
)
SELECT SUM(d.Total) AS Total_Pesos
FROM doc_E_MXN d
JOIN Team_autopartes.dbo.DimMoneda m ON m.MonedaKey=d.MonedaKey
WHERE UPPER(m.MonedaNK) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Nombre) LIKE '%PESO%';

-- OLTP
SELECT SUM(e.Total) AS Total_Pesos
FROM AutopartesO2025.dbo.EntradaEncabezado e
JOIN AutopartesO2025.dbo.Moneda m ON m.Clave=e.Moneda
WHERE UPPER(m.Clave) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Descripcion) LIKE '%PESO%';


-- 3.1.6 Cantidad de entradas (contar folios) y total en pesos del cliente con identificador 5031
-- DW
WITH doc_E_5031 AS (
  SELECT DocumentoNK, ClienteKey, MonedaKey, MAX(Total) AS Total
  FROM Team_autopartes.dbo.FactEntradas
  GROUP BY DocumentoNK, ClienteKey, MonedaKey
)
SELECT COUNT(*) AS CantEntradas, SUM(d.Total) AS TotalPesos
FROM doc_E_5031 d
JOIN Team_autopartes.dbo.DimCliente c ON c.ClienteKey=d.ClienteKey
JOIN Team_autopartes.dbo.DimMoneda  m ON m.MonedaKey=d.MonedaKey
WHERE c.ClienteNK='5031'
  AND (UPPER(m.MonedaNK) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Nombre) LIKE '%PESO%');

-- OLTP
SELECT COUNT(*) AS CantEntradas, SUM(e.Total) AS TotalPesos
FROM AutopartesO2025.dbo.EntradaEncabezado e
JOIN AutopartesO2025.dbo.Moneda m ON m.Clave=e.Moneda
WHERE e.Cliente='5031'
  AND (UPPER(m.Clave) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Descripcion) LIKE '%PESO%');


-- 3.1.7 Cantidad de entradas y total en dólares sin ningún cliente asociado
-- DW
WITH doc_E_SinCli_USD AS (
  SELECT DocumentoNK, ClienteKey, MonedaKey, MAX(Total) AS Total
  FROM Team_autopartes.dbo.FactEntradas
  GROUP BY DocumentoNK, ClienteKey, MonedaKey
)
SELECT COUNT(*) AS CantEntradasSinCliente, SUM(Total) AS TotalUSD
FROM doc_E_SinCli_USD d
JOIN Team_autopartes.dbo.DimMoneda m ON m.MonedaKey=d.MonedaKey
WHERE d.ClienteKey=-1
  AND (UPPER(m.MonedaNK) IN ('USD','US','DLLS') OR UPPER(m.Nombre) LIKE '%DOLAR%');

-- OLTP
SELECT COUNT(*) AS CantEntradasSinCliente, SUM(e.Total) AS TotalUSD
FROM AutopartesO2025.dbo.EntradaEncabezado e
JOIN AutopartesO2025.dbo.Moneda m ON m.Clave=e.Moneda
WHERE (e.Cliente IS NULL OR LTRIM(RTRIM(e.Cliente))='')
  AND (UPPER(m.Clave) IN ('USD','US','DLLS') OR UPPER(m.Descripcion) LIKE '%DOLAR%');


-- 3.1.8 Cantidad de entradas y total en pesos sin ningún cliente asociado
-- DW
WITH doc_E_SinCli_MXN AS (
  SELECT DocumentoNK, ClienteKey, MonedaKey, MAX(Total) AS Total
  FROM Team_autopartes.dbo.FactEntradas
  GROUP BY DocumentoNK, ClienteKey, MonedaKey
)
SELECT COUNT(*) AS CantEntradasSinCliente, SUM(Total) AS TotalPesos
FROM doc_E_SinCli_MXN d
JOIN Team_autopartes.dbo.DimMoneda m ON m.MonedaKey=d.MonedaKey
WHERE d.ClienteKey=-1
  AND (UPPER(m.MonedaNK) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Nombre) LIKE '%PESO%');

-- OLTP
SELECT COUNT(*) AS CantEntradasSinCliente, SUM(e.Total) AS TotalPesos
FROM AutopartesO2025.dbo.EntradaEncabezado e
JOIN AutopartesO2025.dbo.Moneda m ON m.Clave=e.Moneda
WHERE (e.Cliente IS NULL OR LTRIM(RTRIM(e.Cliente))='')
  AND (UPPER(m.Clave) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Descripcion) LIKE '%PESO%');


-- 3.1.9 Cantidad de DEFENSA DEL GOLF GTI en la orden de entrada Folio = 'A003933'
-- DW
SELECT SUM(f.Cantidad_d) AS CantDefensas
FROM Team_autopartes.dbo.FactEntradas f
JOIN Team_autopartes.dbo.DimArticulo a ON a.ArticuloKey=f.ArticuloKey
WHERE f.Folio='A003933'
  AND UPPER(a.Descripcion) LIKE '%DEFENSA DEL GOLF GTI%';

-- OLTP
SELECT SUM(d.CantidadUMedInv) AS CantDefensas
FROM AutopartesO2025.dbo.EntradaDetalle d
WHERE d.Folio='A003933'
  AND UPPER(d.DescripcionArticulo) LIKE '%DEFENSA DEL GOLF GTI%';


-- 3.1.10 Total en pesos de artículos marca Chevrolet para Folio IN ('CF000077','A003938')
-- DW
SELECT SUM(f.Importe_d) AS TotalPesos_Chevrolet
FROM Team_autopartes.dbo.FactEntradas f
JOIN Team_autopartes.dbo.DimArticulo a ON a.ArticuloKey=f.ArticuloKey
JOIN Team_autopartes.dbo.DimMoneda  m ON m.MonedaKey=f.MonedaKey
WHERE f.Folio IN ('CF000077','A003938')
  AND (UPPER(m.MonedaNK) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Nombre) LIKE '%PESO%')
  AND UPPER(a.Marca) LIKE 'CHEVROLET%';

-- OLTP
SELECT SUM(d.Total) AS TotalPesos_Chevrolet
FROM AutopartesO2025.dbo.EntradaEncabezado e
JOIN AutopartesO2025.dbo.EntradaDetalle   d ON d.Folio=e.Folio
JOIN AutopartesO2025.dbo.Moneda m ON m.Clave=e.Moneda
WHERE e.Folio IN ('CF000077','A003938')
  AND (UPPER(m.Clave) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Descripcion) LIKE '%PESO%')
  AND UPPER(d.DescripcionArticulo) LIKE 'CHEVROLET%';


/* =============================================================
   3.2 SALIDAS
============================================================= */

-- 3.2.1 Todos los datos calculados del encabezado y detalle del Folio = 'A0020955'
-- DW
SELECT 
  f.Empresa, f.Folio, f.DocumentoNK, f.FechaHora,
  f.Subtotal, f.Impuestos, f.TotalImporte, f.TotalDescuento, f.Total,
  f.Renglon, f.Cantidad_d, f.PrecioUnitario_d, f.Descuento_d, f.Impuesto_d, f.Importe_d,
  a.ArticuloNK, a.Descripcion AS Articulo, a.Marca,
  al.AlmacenNK, c.ClienteNK, c.RazonSocial, v.VendedorNK, v.Nombre AS Vendedor,
  m.MonedaNK, m.Nombre AS Moneda,
  cp.Descripcion AS CondicionPago, me.Descripcion AS MedioEmbarque
FROM Team_autopartes.dbo.FactSalidas f
LEFT JOIN Team_autopartes.dbo.DimArticulo      a  ON a.ArticuloKey=f.ArticuloKey
LEFT JOIN Team_autopartes.dbo.DimAlmacen       al ON al.AlmacenKey=f.AlmacenKey
LEFT JOIN Team_autopartes.dbo.DimCliente       c  ON c.ClienteKey=f.ClienteKey
LEFT JOIN Team_autopartes.dbo.DimVendedor      v  ON v.VendedorKey=f.VendedorKey
LEFT JOIN Team_autopartes.dbo.DimMoneda        m  ON m.MonedaKey=f.MonedaKey
LEFT JOIN Team_autopartes.dbo.DimCondicionPago cp ON cp.CondicionPagoKey=f.CondicionPagoKey
LEFT JOIN Team_autopartes.dbo.DimMedioEmbarque me ON me.MedioEmbarqueKey=f.MedioEmbarqueKey
WHERE f.Folio='A0020955';

-- OLTP
SELECT s.Empresa, s.Folio, s.Fecha AS FechaHora,
       s.TotalImporte AS Subtotal, s.TotalImpuesto AS Impuestos, s.TotalDescuento, s.Total,
       d.Partida AS Renglon, d.CantidadUMedInv AS Cantidad_d, d.Precio AS PrecioUnitario_d,
       d.TotalDescuento AS Descuento_d, d.TotalImpuesto AS Impuesto_d, d.Total AS Importe_d,
       s.Cliente, s.Vendedor, s.Moneda, s.CondicionPago, s.MedioEmbarque,
       d.Articulo, d.Almacen, d.DescripcionArticulo
FROM AutopartesO2025.dbo.SalidaEncabezado s
JOIN AutopartesO2025.dbo.SalidaDetalle   d ON d.Folio=s.Folio
WHERE s.Folio='A0020955';


-- 3.2.2 Cantidad de salidas (contar folios) durante abril de 2015
-- DW
SELECT COUNT(DISTINCT DocumentoNK) AS Salidas_Abr_2015
FROM Team_autopartes.dbo.FactSalidas f
JOIN Team_autopartes.dbo.DimFecha d ON d.DateKey=f.DateKey
WHERE d.Anio=2015 AND d.MesNumero=4;

-- OLTP
SELECT COUNT(*) AS Salidas_Abr_2015
FROM AutopartesO2025.dbo.SalidaEncabezado
WHERE YEAR(Fecha)=2015 AND MONTH(Fecha)=4;


-- 3.2.3 Cantidad de salidas (contar folios) el día 1 de julio de 2019
-- DW
SELECT COUNT(DISTINCT DocumentoNK) AS Salidas_2019_07_01
FROM Team_autopartes.dbo.FactSalidas
WHERE DateKey=20190701;

-- OLTP
SELECT COUNT(*) AS Salidas_2019_07_01
FROM AutopartesO2025.dbo.SalidaEncabezado
WHERE CONVERT(date,Fecha)='2019-07-01';


-- 3.2.4 Total, de salidas en dólares
-- DW
WITH doc_S_USD AS (
  SELECT DocumentoNK, MonedaKey, MAX(Total) AS Total
  FROM Team_autopartes.dbo.FactSalidas
  GROUP BY DocumentoNK, MonedaKey
)
SELECT SUM(d.Total) AS Total_USD
FROM doc_S_USD d
JOIN Team_autopartes.dbo.DimMoneda m ON m.MonedaKey=d.MonedaKey
WHERE UPPER(m.MonedaNK) IN ('USD','US','DLLS') OR UPPER(m.Nombre) LIKE '%DOLAR%';

-- OLTP
SELECT SUM(s.Total) AS Total_USD
FROM AutopartesO2025.dbo.SalidaEncabezado s
JOIN AutopartesO2025.dbo.Moneda m ON m.Clave=s.Moneda
WHERE UPPER(m.Clave) IN ('USD','US','DLLS') OR UPPER(m.Descripcion) LIKE '%DOLAR%';


-- 3.2.5 Total, de salidas en pesos
-- DW
WITH doc_S_MXN AS (
  SELECT DocumentoNK, MonedaKey, MAX(Total) AS Total
  FROM Team_autopartes.dbo.FactSalidas
  GROUP BY DocumentoNK, MonedaKey
)
SELECT SUM(d.Total) AS Total_Pesos
FROM doc_S_MXN d
JOIN Team_autopartes.dbo.DimMoneda m ON m.MonedaKey=d.MonedaKey
WHERE UPPER(m.MonedaNK) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Nombre) LIKE '%PESO%';

-- OLTP
SELECT SUM(s.Total) AS Total_Pesos
FROM AutopartesO2025.dbo.SalidaEncabezado s
JOIN AutopartesO2025.dbo.Moneda m ON m.Clave=s.Moneda
WHERE UPPER(m.Clave) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Descripcion) LIKE '%PESO%';


-- 3.2.6 Cantidad de salidas (contar folios) y total en pesos del cliente '5733'
-- DW
WITH doc_S_5733 AS (
  SELECT DocumentoNK, ClienteKey, MonedaKey, MAX(Total) AS Total
  FROM Team_autopartes.dbo.FactSalidas
  GROUP BY DocumentoNK, ClienteKey, MonedaKey
)
SELECT COUNT(*) AS CantSalidas, SUM(d.Total) AS TotalPesos
FROM doc_S_5733 d
JOIN Team_autopartes.dbo.DimCliente c ON c.ClienteKey=d.ClienteKey
JOIN Team_autopartes.dbo.DimMoneda  m ON m.MonedaKey=d.MonedaKey
WHERE c.ClienteNK='5733'
  AND (UPPER(m.MonedaNK) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Nombre) LIKE '%PESO%');

-- OLTP
SELECT COUNT(*) AS CantSalidas, SUM(s.Total) AS TotalPesos
FROM AutopartesO2025.dbo.SalidaEncabezado s
JOIN AutopartesO2025.dbo.Moneda m ON m.Clave=s.Moneda
WHERE s.Cliente='5733'
  AND (UPPER(m.Clave) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Descripcion) LIKE '%PESO%');


-- 3.2.7 Cantidad de salidas (contar folios) y total en pesos sin cliente asociado
-- DW
WITH doc_S_SinCli_MXN AS (
  SELECT DocumentoNK, ClienteKey, MonedaKey, MAX(Total) AS Total
  FROM Team_autopartes.dbo.FactSalidas
  GROUP BY DocumentoNK, ClienteKey, MonedaKey
)
SELECT COUNT(*) AS CantSinCliente, SUM(Total) AS TotalPesos
FROM doc_S_SinCli_MXN d
JOIN Team_autopartes.dbo.DimMoneda m ON m.MonedaKey=d.MonedaKey
WHERE d.ClienteKey=-1
  AND (UPPER(m.MonedaNK) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Nombre) LIKE '%PESO%');

-- OLTP
SELECT COUNT(*) AS CantSinCliente, SUM(s.Total) AS TotalPesos
FROM AutopartesO2025.dbo.SalidaEncabezado s
JOIN AutopartesO2025.dbo.Moneda m ON m.Clave=s.Moneda
WHERE (s.Cliente IS NULL OR LTRIM(RTRIM(s.Cliente))='')
  AND (UPPER(m.Clave) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Descripcion) LIKE '%PESO%');


-- 3.2.8 Cantidad de salidas (contar folios) y total en pesos sin vendedor asociado
-- DW
WITH doc_S_SinVend_MXN AS (
  SELECT DocumentoNK, VendedorKey, MonedaKey, MAX(Total) AS Total
  FROM Team_autopartes.dbo.FactSalidas
  GROUP BY DocumentoNK, VendedorKey, MonedaKey
)
SELECT COUNT(*) AS CantSinVendedor, SUM(Total) AS TotalPesos
FROM doc_S_SinVend_MXN d
JOIN Team_autopartes.dbo.DimMoneda m ON m.MonedaKey=d.MonedaKey
WHERE d.VendedorKey=-1
  AND (UPPER(m.MonedaNK) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Nombre) LIKE '%PESO%');

-- OLTP
SELECT COUNT(*) AS CantSinVendedor, SUM(s.Total) AS TotalPesos
FROM AutopartesO2025.dbo.SalidaEncabezado s
JOIN AutopartesO2025.dbo.Moneda m ON m.Clave=s.Moneda
WHERE (s.Vendedor IS NULL OR LTRIM(RTRIM(s.Vendedor))='')
  AND (UPPER(m.Clave) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Descripcion) LIKE '%PESO%');

-- 3.2.9 Cantidad de parrillas en la salida con Folio = 'A0020915'
-- DW
SELECT SUM(f.Cantidad_d) AS CantParrillas
FROM Team_autopartes.dbo.FactSalidas f
JOIN Team_autopartes.dbo.DimArticulo a ON a.ArticuloKey=f.ArticuloKey
WHERE f.Folio='A0020915'
  AND UPPER(a.Descripcion) LIKE '%PARRILLA%';

-- OLTP
SELECT SUM(d.CantidadUMedInv) AS CantParrillas
FROM AutopartesO2025.dbo.SalidaDetalle d
WHERE d.Folio='A0020915'
  AND UPPER(d.DescripcionArticulo) LIKE '%PARRILLA%';


-- 3.2.10 Total en pesos y cantidad de artículos marca Ford en folios dados
-- DW
SELECT 
  SUM(f.Importe_d)   AS TotalPesos_Ford,
  SUM(f.Cantidad_d)  AS CantArticulos_Ford
FROM Team_autopartes.dbo.FactSalidas f
JOIN Team_autopartes.dbo.DimArticulo a ON a.ArticuloKey=f.ArticuloKey
JOIN Team_autopartes.dbo.DimMoneda  m ON m.MonedaKey=f.MonedaKey
WHERE f.Folio IN ('A0020927','A0020960','SA0029433')
  AND (UPPER(m.MonedaNK) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Nombre) LIKE '%PESO%')
  AND UPPER(a.Marca) LIKE 'FORD%';

-- OLTP
SELECT 
  SUM(d.Total)           AS TotalPesos_Ford,
  SUM(d.CantidadUMedInv) AS CantArticulos_Ford
FROM AutopartesO2025.dbo.SalidaEncabezado s
JOIN AutopartesO2025.dbo.SalidaDetalle   d ON d.Folio=s.Folio
JOIN AutopartesO2025.dbo.Moneda m ON m.Clave=s.Moneda
WHERE s.Folio IN ('A0020927','A0020960','SA0029433')
  AND (UPPER(m.Clave) IN ('MXN','MEX','PESO','PESOS') OR UPPER(m.Descripcion) LIKE '%PESO%')
  AND UPPER(d.DescripcionArticulo) LIKE 'FORD%';

