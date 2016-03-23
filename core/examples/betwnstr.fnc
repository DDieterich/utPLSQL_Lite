create or replace FUNCTION betwnStr (
   string_in IN VARCHAR2,
   start_in  IN INTEGER,
   end_in    IN INTEGER
)
RETURN VARCHAR2
IS
BEGIN
   RETURN (
      SUBSTR (
         string_in,
         start_in,
         end_in - start_in + 1
      )
   );
END;