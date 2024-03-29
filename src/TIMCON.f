      SUBROUTINE TIMCON (AMASS,TIMCST,TIMCMN)

C     SUBROUTINE TIMCON CALCULATES THE TIME CONSTANT FOR AN ANIMAL
C     BASED ON A ONE LUMP MODEL (UNIFORM BODY TEMPERATURE) AS 
C     DESCRIBED BY PORTER ET AL (1973).  CONVECTION, RADIATION AND
C     CONDUCTION ARE ALL INCLUDED.  IF ANY TERM IS ZERO, IT IS 
C     CONSIDERED A 1 IN THE NUMERATOR AND A ZERO IN THE DENOMINATOR.
C     BASED ON THE ONE LUMP MODEL OF PORTER ET AL, 1973.
C     IT INCORPORATES HEAT LOSSES DUE TO CONVECTION, RADIATION AND
C     CONDUCTION

      Implicit None

      Real AMASS,ANDENS,ASILP,CAP,CP
      REAL EMISSB,EMISSK,FLUID,G,GCONV,GRAD
      Real QSOLR,TA,Tskin,TIMCST,TOBJ,TRAD,TSKY,ptcond_orig
      Real R,WEVAP,TR,ALT,BP,Rconv,Rrad,H2O_BalPast
      Real AL,VEL,PTCOND,SUBTK,DEPSUB,TIMCMN,TSUBST
      Real QSOLAR,QIRIN,QMETAB,QRESP,QSEVAP,QIROUT,QCONV,QCOND

      Integer IHOUR,MICRO,IDAY 

      COMMON/FUN1/QSOLAR,QIRIN,QMETAB,QRESP,QSEVAP,QIROUT,QCONV,QCOND      
      COMMON/FUN3/AL,TA,VEL,PTCOND,SUBTK,DEPSUB,TSUBST,ptcond_orig
      COMMON/FUN4/Tskin,R,WEVAP,TR,ALT,BP,H2O_BalPast
      COMMON/WDSUB1/ANDENS,ASILP,EMISSB,EMISSK,FLUID,G,IHOUR
      COMMON/WDSUB2/MICRO,QSOLR,TOBJ,TSKY 
c     for debugging
      COMMON/DAYITR/IDAY    

c     J/kg-C      
      CP = 4185.
c     J/C
      CAP = AMASS*CP

C     Temperatures in C
      TRAD = (TSKY+Tsubst)/2.
      
      GCONV = QCONV/(Tskin - TA)
      Rconv = 1/gconv
      
      GRAD = Qirout/(Tskin - TRAD)
      Rrad = 1/grad
c     (J/C)/(J/s-C) = s
      TIMCST = (CAP*Rconv*Rrad)/(Rconv + Rrad)
C     TIME CONSTANT (MINUTES)
      TIMCMN = TIMCST/60.

      RETURN
      END
