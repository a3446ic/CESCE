CREATE OR REPLACE PROCEDURE "EXT"."SP_CARGA_MASIVA_INICIAL" (IN_FILENAME Varchar(120)) LANGUAGE SQLSCRIPT SQL SECURITY DEFINER DEFAULT SCHEMA "EXT" AS
BEGIN

-- Versiones --------------------------------------------------------------------------------------------------------
-- v01 - Versión inicial
---------------------------------------------------------------------------------------------------------------------


--Declaración de variables
DECLARE io_contador Number := 0;
DECLARE i_Tenant VARCHAR(127);
DECLARE cVersion CONSTANT VARCHAR(2) := '01';
DECLARE cReportTable CONSTANT VARCHAR(50) := 'SP_CARGA_MASIVA_INICIAL';
DECLARE i_rev Number := 0; -- Número de ejecución
DECLARE user_name VARCHAR(50);

--Gestión de errores
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN 
	
    CALL LIB_GLOBAL_CESCE :w_debug (
    	i_Tenant,
    	cReportTable || '. SQL ERROR_MESSAGE: ' || IFNULL( ::SQL_ERROR_MESSAGE, '') || '. SQL_ERROR_CODE: ' ||  ::SQL_ERROR_CODE,
    	cReportTable,
    	io_contador
	);
    RESIGNAL;

END;


--Obtenemos tenant
SELECT TENANTID INTO i_Tenant FROM CS_TENANT;

--Obtenemos usuario logueado
-- SELECT IFNULL(USER_NAME, '')  
-- -- INTO user_name 
-- FROM SYS.M_CONNECTIONS WHERE CONNECTION_ID = CURRENT_CONNECTION;


-- CALL LIB_GLOBAL_CESCE :w_debug(
--     i_Tenant,
--     'STARTING with SESSION_USER: ' || SESSION_USER || ' version ' || cVersion,
--     cReportTable,
--     io_contador
-- );


--Borramos registros que sean del fichero
DELETE FROM EXT.EXT_CARGA_MASIVA_LOAD WHERE BATCHNAME = IN_FILENAME;

--Insertamos los registros que vienen de la tabla LOAD	
INSERT INTO EXT.EXT_CARGA_MASIVA_LOAD 
SELECT t.*,IN_FILENAME,SESSION_USER,CURRENT_TIMESTAMP
FROM EXT.EXT_CARGA_MASIVA_LOAD_TEMP t;


CALL LIB_GLOBAL_CESCE :w_debug (
    i_Tenant,
    'Insertados ' || To_VARCHAR(::ROWCOUNT) || ' registros del archivo ' || IN_FILENAME,
    cReportTable,
    io_contador
);

CALL EXT.SP_CARGA_MASIVA(IN_FILENAME);

END;

CALL EXT.SP_CARGA_MASIVA_INICIAL('FICHERO');
select * from ext.EXT_carga_masiva_load;
