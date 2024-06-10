CREATE OR REPLACE PROCEDURE EXT.SP_CARGAR_POLIZAS_TRASPASO_SMM
LANGUAGE SQLSCRIPT SQL SECURITY DEFINER DEFAULT SCHEMA EXT AS
BEGIN
	--Declaración de variables
	DECLARE i_Tenant VARCHAR(4);
	DECLARE vProcedure VARCHAR(127) := 'SP_CARGAR_POLIZAS_TRASPASO_SMM';
	DECLARE io_contador Number := 0;
	DECLARE cVersion CONSTANT VARCHAR(2) := '01';
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
SELECT 'CLGC_' || TO_VARCHAR(CURRENT_TIMESTAMP, 'YYYYMMDD_HH24MISS') || '_PolizasTraspaso.txt' INTO batchname FROM DUMMY;

CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'INICIO PROCEDIMIENTO with SESSION_USER '|| SESSION_USER || ' version ' || cVersion, vProcedure, io_contador);

-- select :i_Tenant from dummy;

--------------------------------- DEBUG ------------------------------------
CREATE COLUMN TABLE "EXT"."EXT_TEMP_SMM"(
	TENANTID VARCHAR(4),
	BATCHNAME VARCHAR(90),
	CLASSIFIERID VARCHAR(127),
	GENERICCLASSIFIERTYPENAME VARCHAR(127),
	EFFECTIVESTARTDATE TIMESTAMP,
	EFFECTIVEENDDATE TIMESTAMP,
	CATEGORYTREENAME VARCHAR(127),
	CATEGORYNAME VARCHAR(127),
	BUSINESSUNITNAME VARCHAR(255),
	GENERICCLASSIFIERNAME VARCHAR(127),
	DESCRIPTION VARCHAR(255)
)
UNLOAD PRIORITY 5 AUTO MERGE;



--------------------------------- FIN DEBUG --------------------------------
-- detectar aquellas polizas que no están incluidas
insert into ext.ext_temp_smm(tenantid,batchname,CLASSIFIERID,GENERICCLASSIFIERTYPENAME,EFFECTIVESTARTDATE,EFFECTIVEENDDATE,CATEGORYTREENAME,CATEGORYNAME,BUSINESSUNITNAME,GENERICCLASSIFIERNAME,DESCRIPTION)
Select distinct :i_Tenant, :batchname from dummy;
/*mvc.IDPAIS, LPAD(mvc.IDMODALIDAD, 3, '0') as IDMODALIDAD, LPAD(mvc.NUM_POLIZA, 8, '0') as NUM_POLIZA , mvc.NUM_POL_O, mvc.FECHA_TRASPASO_POL_O, mvc.DESC_SIT_POL_O, mvc.BATCHNAME as BATCHNAME_ORIGEN 
from EXT.EXT_MOVIMIENTO_CARTERA_CREDITO_HIST mvc where trim(FECHA_TRASPASO_POL_O) <>'' and DESC_SIT_POL_O in ( 'FINALIZADO' , 'CONFIRMADO' )  
and (LPAD(IDMODALIDAD, 3, '0') , LPAD(NUM_POLIZA, 8, '0') ) not in ( 
select distinct clas.NAME as NUEVA_MODALIDAD, clas.CLASSIFIERID as NUEVA_POLIZA 
from  
cs_classifier clas, 
cs_genericclassifier cgc, 
            cs_genericclassifiertype cgct 
where clas.classifierseq = cgc.classifierseq 
            AND clas.selectorid = cgct.genericclassifiertypeseq 
            AND cgct.NAME = 'Forma de Pago' );*/
       
       select 'tabla temporal',* from  ext.ext_temp_smm ;
       
drop table ext.ext_temp_smm;

-- FIN PROCEDIMIENTO
END;

--begin work;
delete from ext.cse_debug where proceso = 'SP_CARGAR_POLIZAS_TRASPASO_SMM';
call ext.SP_CARGAR_POLIZAS_TRASPASO_SMM;

select * from ext.cse_debug where proceso = 'SP_CARGAR_POLIZAS_TRASPASO_SMM';
select * from CS_STAGEGENERICCLASSIFIER;

-- rollback;
-- select from ext.cse_debug where proceso = 'SP_CARGAR_POLIZAS_TRASPASO_SMM';
/* */