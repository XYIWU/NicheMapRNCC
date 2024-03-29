C      ===================================================================================
C      PRINT R-MESSAGES
C     ===================================================================================
C     THIS IS PART OF THE DOPRI INTEGRATOR

      SUBROUTINE DBLEPR_K(LABEL, NCHAR, DATA, NDATA)
      INTEGER NCHAR, NDATA
      CHARACTER*(*) LABEL
      DOUBLE PRECISION DATA(NDATA)
      INTEGER NC
       NC = NCHAR
       IF(NC .LT. 0) NC = LEN(LABEL)
C       CALL DBLEP0K(LABEL, NC, DATA, NDATA)
      END SUBROUTINE


      SUBROUTINE INTPR_K(LABEL, NCHAR, DATA, NDATA)
      INTEGER NCHAR, NDATA
      CHARACTER*(*) LABEL
      INTEGER DATA(NDATA)
      INTEGER NC
       NC = NCHAR
       IF(NC .LT. 0) NC = LEN(LABEL)
C       CALL INTP0K(LABEL, NC, DATA, NDATA)
      END SUBROUTINE

C     JUST A STRING
      SUBROUTINE RPRINT(MSG)
      CHARACTER (LEN=*) MSG
C           CALL DBLEPR(MSG, -1, 0, 0)
      END SUBROUTINE


C     PRINTING WITH ONE INTEGER AND A DOUBLE
      SUBROUTINE RPRINTID(MSG, I1, D1)
      CHARACTER (LEN=*) MSG
      DOUBLE PRECISION D1
      INTEGER I1
C        CALL DBLEPR(MSG, -1, D1, 1)
C        CALL INTPR(' ', -1, I1, 1)
      END SUBROUTINE

      SUBROUTINE RPRINTD4(MSG, D1, D2, D3, D4)
      CHARACTER (LEN=*) MSG
      DOUBLE PRECISION DBL(4), D1, D2, D3, D4
      INTEGER I1
        DBL(1) = D1
        DBL(2) = D2
        DBL(3) = D3
        DBL(4) = D4

C     CALL DBLEPR(MSG, -1, DBL, 4)
      END SUBROUTINE

      SUBROUTINE RPRINTD3(MSG, D1, D2, D3)
      CHARACTER (LEN=*) MSG
      DOUBLE PRECISION DBL(3), D1, D2, D3
        DBL(1) = D1
        DBL(2) = D2
        DBL(3) = D3

C     CALL DBLEPR(MSG, -1, DBL, 3)
      END SUBROUTINE

C     PRINTING WITH ONE DOUBLE
      SUBROUTINE RPRINTD1(MSG, D1)
      CHARACTER (LEN=*) MSG
      DOUBLE PRECISION D1, DBL(1)
        DBL(1) = D1
        CALL DBLEPR_K(MSG, -1, DBL, 1)
      END SUBROUTINE

C     PRINTING WITH TWO DOUBLES
      SUBROUTINE RPRINTD2(MSG, D1, D2)
      CHARACTER (LEN=*) MSG
      DOUBLE PRECISION DBL(2), D1, D2
        DBL(1) = D1
        DBL(2) = D2
        CALL DBLEPR_K(MSG, -1, DBL, 2)
      END SUBROUTINE

C     PRINTING WITH ONE INTEGER
      SUBROUTINE RPRINTI1(MSG, I1)
      CHARACTER (LEN=*) MSG
      INTEGER IN(1), I1
        IN(1) = I1
        CALL INTPR_K(MSG, -1, IN, 1)
      END SUBROUTINE

      SUBROUTINE RPRINTI2(MSG, I1, I2)
      CHARACTER (LEN=*) MSG
      INTEGER IN(2), I1, I2
        IN(1) = I1
        IN(2) = I2
        CALL INTPR_K(MSG, -1, IN, 2)
      END SUBROUTINE

      SUBROUTINE RPRINTI3(MSG, I1, I2, I3)
      CHARACTER (LEN=*) MSG
      INTEGER IN(3), I1, I2, I3
        IN(1) = I1
        IN(2) = I2
        IN(3) = I3
        CALL INTPR_K(MSG, -1, IN, 3)
      END SUBROUTINE