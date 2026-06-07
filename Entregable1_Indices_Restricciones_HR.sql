--==============================================================================
-- Trabajo: Indices y restricciones en Oracle - Esquema HR
-- Asignatura: Bases de Datos Avanzadas (UNIR)
-- Tema 8 - Actividades
-- Autor:  <Apellidos>, <Nombre>
-- Fecha:  2026-06-07
-- Ambiente sugerido por el profesor: Oracle Database 21c XE + SQL Developer.
--   El enunciado pide Oracle 11g + esquema HR; el flujo es identico en 21c XE,
--   que es la version disponible hoy desde la web de Oracle.
-- Recomendaciones del profesor incorporadas (Transcripcion 557614 y 559189):
--   * No trabajar con SYSTEM/SYS/SYSDBA; usar el usuario propio del esquema (hr).
--   * En SQL Developer, usar "Nombre de servicio" = XEPDB1 (no SID).
--   * Activar SET TIMING ON; y SET AUTOTRACE ON EXPLAIN STATISTICS;
--   * Verificar la instalacion HR listando las 7 tablas del esquema.
--   * Entregar el(los) script(s) en un repositorio y poner el enlace en la memoria.
--==============================================================================

-- Habilitar feedback temporal y rastreo, recomendado en la sesion 557614.
SET SERVEROUTPUT ON;
SET TIMING ON;
SET FEEDBACK ON;
-- SET AUTOTRACE ON EXPLAIN STATISTICS;   -- requiere rol PLUSTRACE; descomentar si esta disponible.

-- =============================================================================
-- 0. VERIFICACION DE CONEXION Y DE QUE EL ESQUEMA HR ESTA INSTALADO
-- =============================================================================
-- Confirmar usuario y esquema activo
SELECT USER AS usuario_actual, SYS_CONTEXT('USERENV','CON_NAME') AS pdb FROM dual;

-- El profesor (559189) indico: la forma mas facil de verificar HR es ver sus 7 tablas.
SELECT table_name
FROM   user_tables
ORDER BY table_name;
-- Esperado: COUNTRIES, DEPARTMENTS, EMPLOYEES, JOBS, JOB_HISTORY, LOCATIONS, REGIONS.


-- =============================================================================
-- 1. CONSULTA DE INDICES SOBRE employees Y departments
--    Vistas del diccionario: USER_INDEXES, USER_IND_COLUMNS.
-- =============================================================================

-- 1.1 Indices definidos por el propietario actual (HR) sobre las dos tablas.
SELECT index_name,
       table_name,
       uniqueness,
       index_type,
       status
FROM   user_indexes
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER BY table_name, index_name;

-- 1.2 Columnas que componen cada indice (orden y posicion).
SELECT ic.table_name,
       ic.index_name,
       ic.column_position,
       ic.column_name,
       ic.descend
FROM   user_ind_columns ic
WHERE  ic.table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER BY ic.table_name, ic.index_name, ic.column_position;

-- 1.3 Relacion indice <-> restriccion (las PK/UNIQUE crean indice automatico).
SELECT c.table_name,
       c.constraint_name,
       c.constraint_type,         -- P=PK, U=UNIQUE, R=FK, C=Check/NOT NULL
       c.index_name
FROM   user_constraints c
WHERE  c.table_name IN ('EMPLOYEES','DEPARTMENTS')
  AND  c.constraint_type IN ('P','U')
ORDER BY c.table_name, c.constraint_type;


-- =============================================================================
-- 2. CONSULTA DE RESTRICCIONES DE employees Y departments
-- =============================================================================

-- 2.1 Restricciones declaradas en las dos tablas.
SELECT table_name,
       constraint_name,
       constraint_type,           -- P=PK, U=UNIQUE, R=FK, C=Check (incluye NOT NULL), O=read only
       search_condition,          -- texto del CHECK / NOT NULL
       r_constraint_name,         -- a que PK referencia el FK
       delete_rule,
       status,
       deferrable,
       validated
FROM   user_constraints
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER BY table_name, constraint_type, constraint_name;

-- 2.2 Columnas que participan en cada restriccion.
SELECT cc.table_name,
       cc.constraint_name,
       cc.column_name,
       cc.position
FROM   user_cons_columns cc
WHERE  cc.table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER BY cc.table_name, cc.constraint_name, cc.position;


-- =============================================================================
-- 3. DESACTIVACION DE RESTRICCIONES
--    Orden obligatorio: primero las FK que apuntan a la PK, luego la PK.
--    NOT NULL se desactiva por columna con ALTER TABLE ... MODIFY ... NULL.
-- =============================================================================

-- 3.1 Otras tablas del esquema HR que referencian a EMPLOYEES o DEPARTMENTS
--     y cuyas FK debemos desactivar primero (vital para poder desactivar la PK).
SELECT  fk.table_name        AS tabla_hija,
        fk.constraint_name   AS fk_nombre,
        pk.table_name        AS tabla_padre,
        pk.constraint_name   AS pk_nombre
FROM    user_constraints fk
JOIN    user_constraints pk ON pk.constraint_name = fk.r_constraint_name
WHERE   fk.constraint_type = 'R'
  AND   pk.table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER BY tabla_padre, tabla_hija;

-- 3.2 Desactivar FKs en hijas que apuntan a EMPLOYEES (DEPT_MGR_FK y JHIST_*).
ALTER TABLE departments DISABLE CONSTRAINT dept_mgr_fk;
ALTER TABLE job_history DISABLE CONSTRAINT jhist_emp_fk;

-- 3.3 Desactivar FKs en hijas que apuntan a DEPARTMENTS (EMP_DEPT_FK y JHIST_*).
ALTER TABLE employees   DISABLE CONSTRAINT emp_dept_fk;
ALTER TABLE job_history DISABLE CONSTRAINT jhist_dept_fk;

-- 3.4 Desactivar FKs propias de EMPLOYEES (jefe y job).
ALTER TABLE employees DISABLE CONSTRAINT emp_manager_fk;
ALTER TABLE employees DISABLE CONSTRAINT emp_job_fk;

-- 3.5 Desactivar FK propia de DEPARTMENTS (loc).
ALTER TABLE departments DISABLE CONSTRAINT dept_loc_fk;

-- 3.6 Desactivar PRIMARY KEYs (con CASCADE por seguridad si quedara alguna FK viva).
ALTER TABLE employees   DISABLE CONSTRAINT emp_emp_id_pk      CASCADE;
ALTER TABLE departments DISABLE CONSTRAINT dept_id_pk          CASCADE;

-- 3.7 Desactivar UNIQUE de EMPLOYEES (email).
ALTER TABLE employees DISABLE CONSTRAINT emp_email_uk;

-- 3.8 Desactivar CHECK de EMPLOYEES (salario > 0).
ALTER TABLE employees DISABLE CONSTRAINT emp_salary_min;

-- 3.9 NOT NULL: no se desactiva con DISABLE CONSTRAINT; se elimina permitiendo NULL.
--     (Ojo: esto altera la definicion de la columna; en el punto 5 se restaura.)
ALTER TABLE employees   MODIFY (last_name      NULL);
ALTER TABLE employees   MODIFY (email          NULL);
ALTER TABLE employees   MODIFY (hire_date      NULL);
ALTER TABLE employees   MODIFY (job_id         NULL);
ALTER TABLE departments MODIFY (department_name NULL);

-- 3.10 Verificacion: todas las restricciones deben quedar en estado DISABLED.
SELECT table_name, constraint_name, constraint_type, status
FROM   user_constraints
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER BY table_name, status, constraint_type;


-- =============================================================================
-- 4. INSERCIONES QUE INCUMPLEN RESTRICCIONES (aprovechando que estan desactivadas)
--    Cada INSERT viola una restriccion distinta. Comentario indica cual.
-- =============================================================================

-- 4.1 Viola PK (employee_id duplicado: 100 ya existe).
INSERT INTO employees (employee_id, last_name, email, hire_date, job_id)
VALUES (100, 'DUPLICADO_PK', 'duplicado1@dup.com', SYSDATE, 'IT_PROG');

-- 4.2 Viola NOT NULL (last_name, email, hire_date, job_id nulos).
INSERT INTO employees (employee_id, last_name, email, hire_date, job_id)
VALUES (9001, NULL, NULL, NULL, NULL);

-- 4.3 Viola UNIQUE de email (SKING ya existe en HR).
INSERT INTO employees (employee_id, last_name, email, hire_date, job_id)
VALUES (9002, 'CopiaEmail', 'SKING', SYSDATE, 'IT_PROG');

-- 4.4 Viola CHECK (salary > 0).
INSERT INTO employees (employee_id, last_name, email, hire_date, job_id, salary)
VALUES (9003, 'SalNegativo', 'sneg@dup.com', SYSDATE, 'IT_PROG', -500);

-- 4.5 Viola FK (department_id 9999 no existe en departments; manager 9999 tampoco).
INSERT INTO employees (employee_id, last_name, email, hire_date, job_id, department_id, manager_id)
VALUES (9004, 'FKInexistente', 'fkinex@dup.com', SYSDATE, 'IT_PROG', 9999, 9999);

-- 4.6 Viola PK en departments (10 ya existe).
INSERT INTO departments (department_id, department_name)
VALUES (10, 'DEPT_DUPLICADO');

-- 4.7 Viola NOT NULL en department_name.
INSERT INTO departments (department_id, department_name) VALUES (9101, NULL);

-- 4.8 Viola FK en departments (location_id 5555 no existe).
INSERT INTO departments (department_id, department_name, location_id)
VALUES (9102, 'DEPT_LOC_FAKE', 5555);

COMMIT;

-- 4.9 Verificacion: los registros violatorios entraron porque las restricciones
--     estaban desactivadas.
SELECT employee_id, last_name, email, salary, department_id, manager_id
FROM   employees
WHERE  employee_id IN (100, 9001, 9002, 9003, 9004)
   OR  email = 'SKING'
ORDER BY employee_id;

SELECT department_id, department_name, location_id
FROM   departments
WHERE  department_id IN (10, 9101, 9102)
ORDER BY department_id;


-- =============================================================================
-- 5. REACTIVACION DE RESTRICCIONES
--    Si reactivamos con ENABLE VALIDATE (por defecto) y hay datos violatorios,
--    Oracle lanza ORA-02293/ORA-02437/ORA-02298 segun el caso. Hay dos
--    estrategias: (a) limpiar los datos invalidos y luego ENABLE, o
--                 (b) ENABLE NOVALIDATE (valida solo datos nuevos).
-- =============================================================================

-- 5.1 Estrategia (a): borrar las tuplas invalidas insertadas en el paso 4.
DELETE FROM employees
WHERE employee_id IN (9001, 9002, 9003, 9004)
   OR (employee_id = 100 AND last_name = 'DUPLICADO_PK');

DELETE FROM departments
WHERE department_id IN (9101, 9102)
   OR (department_id = 10 AND department_name = 'DEPT_DUPLICADO');

COMMIT;

-- 5.2 Reponer la obligatoriedad NOT NULL.
ALTER TABLE employees   MODIFY (last_name      NOT NULL);
ALTER TABLE employees   MODIFY (email          NOT NULL);
ALTER TABLE employees   MODIFY (hire_date      NOT NULL);
ALTER TABLE employees   MODIFY (job_id         NOT NULL);
ALTER TABLE departments MODIFY (department_name NOT NULL);

-- 5.3 Habilitar primero las PRIMARY KEYs (necesarias para que las FK referencien).
ALTER TABLE employees   ENABLE CONSTRAINT emp_emp_id_pk;
ALTER TABLE departments ENABLE CONSTRAINT dept_id_pk;

-- 5.4 UNIQUE y CHECK de EMPLOYEES.
ALTER TABLE employees ENABLE CONSTRAINT emp_email_uk;
ALTER TABLE employees ENABLE CONSTRAINT emp_salary_min;

-- 5.5 FKs.
ALTER TABLE employees   ENABLE CONSTRAINT emp_dept_fk;
ALTER TABLE employees   ENABLE CONSTRAINT emp_job_fk;
ALTER TABLE employees   ENABLE CONSTRAINT emp_manager_fk;
ALTER TABLE departments ENABLE CONSTRAINT dept_mgr_fk;
ALTER TABLE departments ENABLE CONSTRAINT dept_loc_fk;
ALTER TABLE job_history ENABLE CONSTRAINT jhist_emp_fk;
ALTER TABLE job_history ENABLE CONSTRAINT jhist_dept_fk;

-- 5.6 Verificacion final: todas ENABLED.
SELECT table_name, constraint_name, constraint_type, status, validated
FROM   user_constraints
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS','JOB_HISTORY')
ORDER BY table_name, status, constraint_type;

-- 5.7 Alternativa (b) cuando no se quieren borrar datos: ENABLE NOVALIDATE
--     respeta las filas existentes pero exige el cumplimiento en las nuevas.
--     Sintaxis de referencia:
--     ALTER TABLE employees ENABLE NOVALIDATE CONSTRAINT emp_email_uk;


-- =============================================================================
-- 6. CREACION DE departments2 COMO DUPLICADO DE departments
--    CTAS (CREATE TABLE AS SELECT) copia estructura + datos, pero NO copia:
--      - PRIMARY KEY, UNIQUE, FOREIGN KEY, CHECK
--      - Indices secundarios, defaults complejos, triggers, grants.
--    Si solo se requiere la estructura: AS SELECT * FROM departments WHERE 1=2;
-- =============================================================================

DROP TABLE departments2 CASCADE CONSTRAINTS;     -- idempotente; si no existe, omitir.

CREATE TABLE departments2
AS
SELECT * FROM departments;

-- Verificar que copio estructura y datos.
SELECT COUNT(*) AS filas_copiadas FROM departments2;

-- Verificar que NO copio constraints ni indices.
SELECT table_name, constraint_name, constraint_type, status
FROM   user_constraints WHERE table_name = 'DEPARTMENTS2';

SELECT table_name, index_name, uniqueness
FROM   user_indexes    WHERE table_name = 'DEPARTMENTS2';
-- Esperado: 0 filas en ambas consultas.


-- =============================================================================
-- 7. INSERCION DE TRES TUPLAS EN departments2
-- =============================================================================

INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (300, 'Investigacion y Desarrollo', 200, 1700);

INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (310, 'Innovacion Digital', 201, 1800);

INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (320, 'Analitica de Datos', NULL, 1500);

COMMIT;

SELECT * FROM departments2
WHERE  department_id IN (300, 310, 320)
ORDER BY department_id;


-- =============================================================================
-- 8. CIERRE DE SESION
--    En SQL Developer: pestaña "Conexiones" > clic derecho en HR > Desconectar.
--    Por SQL*Plus / scripts equivalentes:
-- =============================================================================
-- DISCONNECT;
-- EXIT;


-- =============================================================================
-- 9. CONSULTA POSTERIOR DE departments2 (tras reconectar)
--    Si el COMMIT del paso 7 se hizo, los registros persisten.
--    Si se hubiera salido sin COMMIT, SQL Developer hace ROLLBACK implicito
--    al cerrar la conexion (segun comportamiento por defecto), perdiendo los
--    cambios no confirmados.
-- =============================================================================
SELECT department_id, department_name, manager_id, location_id
FROM   departments2
ORDER BY department_id;


-- =============================================================================
-- 10. BLOQUE ANONIMO PL/SQL: inicio y fin de transaccion sobre departments2
-- =============================================================================
SET SERVEROUTPUT ON;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- INICIO DE TRANSACCION sobre DEPARTMENTS2 ---');

    INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
    VALUES (330, 'Gobierno del Dato', 205, 1700);

    UPDATE departments2
       SET department_name = 'Innovacion Digital y Cloud'
     WHERE department_id   = 310;

    DELETE FROM departments2
     WHERE department_id   = 320;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Transaccion confirmada con COMMIT.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM || '. Transaccion deshecha con ROLLBACK.');
END;
/

SELECT * FROM departments2 ORDER BY department_id;


-- =============================================================================
-- 11. EJEMPLO DE DESHACER UNA TRANSACCION CON ROLLBACK
--    Mecanismo: Oracle escribe en los Undo Segments y en los Redo Logs;
--    ROLLBACK lee los UNDO y restaura el valor anterior siempre que NO se
--    haya hecho COMMIT.
-- =============================================================================

-- Estado actual (antes de la prueba)
SELECT department_id, department_name FROM departments2 WHERE department_id = 330;

UPDATE departments2
   SET department_name = 'Cambio temporal (sera deshecho)'
 WHERE department_id   = 330;

SELECT department_id, department_name FROM departments2 WHERE department_id = 330;

ROLLBACK;

SELECT department_id, department_name FROM departments2 WHERE department_id = 330;
-- El valor original vuelve porque no se hizo COMMIT.

-- Variante con SAVEPOINT (rollback parcial).
INSERT INTO departments2 (department_id, department_name, location_id) VALUES (340, 'Prueba SP1', 1700);
SAVEPOINT sp1;
INSERT INTO departments2 (department_id, department_name, location_id) VALUES (341, 'Prueba SP2', 1700);
ROLLBACK TO SAVEPOINT sp1;       -- deshace solo el segundo INSERT
COMMIT;                          -- confirma el primero
SELECT department_id, department_name FROM departments2 WHERE department_id IN (340,341);
-- Esperado: solo 340.


-- =============================================================================
-- 12. REDO LOGS Y MODO DE FUNCIONAMIENTO (NOARCHIVELOG / ARCHIVELOG)
--    Vistas del diccionario dinamicas: V$DATABASE, V$LOG, V$LOGFILE, V$LOG_HISTORY.
--    Requieren privilegio de lectura sobre V$. Si HR no lo tiene, ejecutar con
--    un usuario que herede SELECT_CATALOG_ROLE o, en su defecto, pedirlo al DBA.
-- =============================================================================

-- 12.1 Modo de archivado de la base (NOARCHIVELOG por defecto en 21c XE).
SELECT name, log_mode, open_mode, database_role
FROM   v$database;

-- 12.2 Grupos de redo log online: estado y tamano.
SELECT group#, thread#, sequence#, bytes/1024/1024 AS mb, members, status
FROM   v$log
ORDER BY group#;

-- 12.3 Archivos fisicos que componen cada grupo (multiplexado).
SELECT group#, member, type, status
FROM   v$logfile
ORDER BY group#;

-- 12.4 Historial de cambios de log (forzar uno opcionalmente: ALTER SYSTEM SWITCH LOGFILE; requiere DBA).
SELECT recid, sequence#, first_change#, first_time
FROM   v$log_history
ORDER BY recid DESC
FETCH FIRST 5 ROWS ONLY;
-- Si el motor es 11g (sin FETCH FIRST), reemplazar por:
-- SELECT * FROM (SELECT ... ORDER BY recid DESC) WHERE ROWNUM <= 5;


--==============================================================================
-- FIN DEL SCRIPT
--==============================================================================
