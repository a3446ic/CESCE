use datasource.CESCEdb;
SELECT COD_MEDIADOR || '-' || SUBCLAVE || ' ' || NUM_IDENTIFICACION || ' ' || IFNULL(NOMBRE, '') || ' ' || "APELLIDO/RAZON_SOCIAL" as mediador
FROM EXT.MODIFICAR_MEDIADOR 
WHERE COD_MEDIADOR IS NOT NULL 
AND LOWER(COD_MEDIADOR || '-' || SUBCLAVE || ' ' || NUM_IDENTIFICACION || ' ' || IFNULL(NOMBRE, '') || ' ' || "APELLIDO/RAZON_SOCIAL") LIKE LOWER('%$!{searchPhrase}%')
AND DIR_TERRITORIAL LIKE CASE WHEN '$!{currentUser.getDepartment()}' = 'central_cesce' THEN '%' ELSE '$!{currentUser.getDepartment().getName().toUpperCase()}' END
AND UPPER(GERENTE_CANAL) LIKE CASE WHEN '$!{currentUser.getUserType()}' = 'gerente_canal' THEN '$!{currentUser.getName().toUpperCase()}' ELSE '%' END