CREATE OR REPLACE PROCEDURE EXT.SP_CARGAR_POLIZAS_TRASPASO
LANGUAGE SQLSCRIPT 	SQL SECURITY DEFINER	DEFAULT SCHEMA EXT AS
BEGIN
	--Declaración de variables
	DECLARE i_Tenant VARCHAR(4);
	DECLARE vProcedure VARCHAR(127) = 'SP_CARGAR_POLIZAS_TRASPASO';
	DECLARE io_contador NUMBER = 0;
	DECLARE cVersion VARCHAR(2) = '01';
	DECLARE batchname VARCHAR(255);
	
----------------------- CONTROL DE EXCEPCIONES -----------------------------
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'SQL_ERROR_MESSAGE: ' || 
    		IFNULL(::SQL_ERROR_MESSAGE,'') || 
	        '. SQL_ERROR_CODE: '||::SQL_ERROR_CODE, vProcedure , io_contador);
	END;

-----------------------FIN CONTROL DE EXCEPCIONES -----------------------------	

	SELECT TENANTID INTO i_Tenant FROM CS_TENANT;
	
	--Genera batchname CLGC_YYYYMMDD_HHMMSS_PolizasTraspaso.txt
	SELECT 'CLGC_' || TO_VARCHAR( CURRENT_TIMESTAMP, 'YYYYMMDD_HH24MISS' ) || '_PolizasTraspaso.txt' INTO batchname FROM DUMMY;
	
	CALL EXT.LIB_GLOBAL_CESCE:w_debug(i_Tenant, 'INICIO PROCEDIMIENTO with SESSION_USER ' || SESSION_USER || ' version ' || cVersion, vProcedure, io_contador);
	

	-- detectar aquellas polizas que no están incluidas
	INSERT INTO TCMP.CS_STAGEGENERICCLASSIFIER(TENANTID, BATCHNAME, CLASSIFIERID, GENERICCLASSIFIERTYPENAME, EFFECTIVESTARTDATE, EFFECTIVEENDDATE, CATEGORYTREENAME, CATEGORYNAME, BUSINESSUNITNAME, GENERICCLASSIFIERNAME, DESCRIPTION)
	SELECT DISTINCT 
		:i_Tenant AS TENANTID,
		:batchname AS BATCHNAME,
		LPAD( mvc.NUM_POLIZA, 8, '0' ) AS CLASSIFIERID,
		'Forma de Pago' AS GENERICCLASSIFIERTYPENAME,
		'2022-01-01' AS EFFECTIVESTARTDATE,
		'2200-01-01' AS EFFECTIVEENDDATE,
		'Polizas Traspaso Tree' AS CATEGORYTREENAME,
		'Polizas Traspaso' AS CATEGORYNAME,
		CASE
			WHEN mvc.IDPAIS = '116' THEN 'Spain'
			WHEN mvc.IDPAIS = '151' THEN 'Portugal'
			ELSE ''
		END AS BUSINESSUNITNAME,
		LPAD( mvc.IDMODALIDAD, 3, '0' ) AS GENERICCLASSIFIERNAME,
		mvc.BATCHNAME AS BATCHNAME_ORIGEN
	FROM EXT.EXT_MOVIMIENTO_CARTERA_CREDITO_HIST AS mvc
	WHERE TRIM(FECHA_TRASPASO_POL_O) <> ''
		AND (DESC_SIT_POL_O IN ('FINALIZADO', 'CONFIRMADO'))
		AND ((LPAD(IDMODALIDAD, 3, '0'), LPAD(NUM_POLIZA, 8, '0')) NOT IN (
			SELECT DISTINCT 
				clas.NAME AS NUEVA_MODALIDAD,
				clas.CLASSIFIERID AS NUEVA_POLIZA
			FROM 
			cs_classifier AS clas,
			cs_genericclassifier AS cgc,
			cs_genericclassifiertype AS cgct
			WHERE clas.classifierseq = cgc.classifierseq
				AND clas.selectorid = cgct.genericclassifiertypeseq
				AND cgct.NAME = 'Forma de Pago')
		);
	CALL EXT.LIB_GLOBAL_CESCE:w_debug( i_Tenant, 'INSERTADOS ' || To_Varchar(::ROWCOUNT) || ' REGISTROS EN LA TABLA CS_STAGEGENERICCLASSIFIER', vProcedure, io_contador );
	
	CALL EXT.LIB_GLOBAL_CESCE:w_debug( i_Tenant, 'INSERT TABLA VIRTUAL ', vProcedure, io_contador );
	
	INSERT INTO "EXT"."VT_PipelineRuns"("Command", "StageType", "TraceLevel", "SkipAnalyzeSchema", "SqlLogging", "DebugContext", "UserId", "RunMode", "BatchName", "Module", "ProcessingUnit", "CalendarName", "StartDateScheduled")
	SELECT 
			'Import' AS "Command",
			'ValidateAndTransfer' AS "StageType",
			'status' AS "TraceLevel",
			null AS "SkipAnalyzeSchema",
			null AS "SqlLogging",
			null AS "DebugContext",
			'data_integration_service_account' AS "UserId",
			'all' AS "RunMode",
			batchname AS "BatchName",
			'ClassificationData' AS "Module",
			NULL AS "ProcessingUnit",
			'Main Monthly Calendar' AS "CalendarName",
			add_seconds( current_utctimestamp, 2 ) AS "StartDateScheduled"
		FROM Dummy;

	CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'FIN PROCEDIMIENTO with SESSION_USER ' || SESSION_USER, vProcedure, io_contador);
END;