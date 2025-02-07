      SUBROUTINE COND

C     NICHEMAPR: SOFTWARE FOR BIOPHYSICAL MECHANISTIC NICHE MODELLING

C     COPYRIGHT (C) 2018 MICHAEL R. KEARNEY AND WARREN P. PORTER

C     THIS PROGRAM IS FREE SOFTWARE: YOU CAN REDISTRIBUTE IT AND/OR MODIFY
C     IT UNDER THE TERMS OF THE GNU GENERAL PUBLIC LICENSE AS PUBLISHED BY
C     THE FREE SOFTWARE FOUNDATION, EITHER VERSION 3 OF THE LICENSE, OR (AT
C      YOUR OPTION) ANY LATER VERSION.

C     THIS PROGRAM IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL, BUT
C     WITHOUT ANY WARRANTY; WITHOUT EVEN THE IMPLIED WARRANTY OF
C     MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. SEE THE GNU
C     GENERAL PUBLIC LICENSE FOR MORE DETAILS.

C     YOU SHOULD HAVE RECEIVED A COPY OF THE GNU GENERAL PUBLIC LICENSE
C     ALONG WITH THIS PROGRAM. IF NOT, SEE HTTP://WWW.GNU.ORG/LICENSES/.

C     SUBROUTINE FOR CALCULATING HEAT TRANSFER TO THE SUBSTRATE
C     ORIGINALLY DEVELOPED FOR A GARTER SNAKE, THAMNOPHIS ELEGANS

      IMPLICIT NONE

      DOUBLE PRECISION A1,A2,A3,A4,A4B,A5,A6,AL,ALT,AMASS,ANDENS,AREF
      DOUBLE PRECISION ASILP,AT,ATOT,AV,BP,BREF,CREF,CUSTOMGEOM,DEPSEL
      DOUBLE PRECISION DEPSUB,EGGSHP,EGGPTCOND,EMISAN,EMISSB,EMISSK,F12
      DOUBLE PRECISION F13,F14,F15,F16,F21,F23,F24,F25,F26,F31,F32,F41
      DOUBLE PRECISION F42,F51,F52,F61,FATOSB,FATOSK,FLSHCOND,FLUID,G
      DOUBLE PRECISION H2O_BALPAST,HSHSOI,HSOIL,MSHSOI,MSOIL,PHI,PHIMAX
      DOUBLE PRECISION PHIMIN,PSHSOI,PSOIL,PTCOND,PTCOND_ORIG,QCOND
      DOUBLE PRECISION QCONV,QIRIN,QIROUT,QMETAB,QRESP,QSEVAP,QSOLAR,R
      DOUBLE PRECISION RELHUM,RHO1_3,SHP,SIDEX,SIG,SUBTK,TA
      DOUBLE PRECISION TCORES,TOTLEN,TQSOL,TR,TRANS1,TSHSOI,TSKIN
      DOUBLE PRECISION TSOIL,TSUBST,TWING,VEL,WEVAP,WQSOL,XTRY,ZSOIL
      DOUBLE PRECISION TCOND,SHTCOND
      DOUBLE PRECISION, DIMENSION(24) :: V,ED,WETMASS,WETSTORAGE,
     & CUMREPRO,HS,E_S,L_W,CUMBATCH,Q,V_BABY1,E_BABY1,WETGONAD,
     & E_H,EH_BABY1,SURVIV,VOLD,VPUP,EPUP,E_HPUP,
     & PAS,PBS,PCS,PDS,PGS,PJS,PMS,PRS,WETFOOD
      DOUBLE PRECISION TLUNG,DELTAR,EXTREF,RQ,MR_1,MR_2,MR_3,POT
      DOUBLE PRECISION ASEMAJR,BSEMINR,CSEMINR,RAINDRINK,STAGE
      DOUBLE PRECISION POTFREEMASS,GUTFREEMASS,CO2FLUX,O2FLUX
      
      INTEGER IHOUR,GEOMETRY,NODNUM,WINGMOD,WINGCALC,CENSUS,
     & RESET,DEADEAD,STARTDAY,DEAD,VIVIPAROUS,PREGNANT,DEB1,EGGMULT

      DIMENSION TSOIL(10),TSHSOI(10),ZSOIL(10),DEPSEL(25),TCORES(25)
      DIMENSION CUSTOMGEOM(8),SHP(3),EGGSHP(3)
      DIMENSION MSOIL(10),MSHSOI(10),PSOIL(10),PSHSOI(10),HSOIL(10)
     & ,HSHSOI(10),TCOND(10),SHTCOND(10)

      COMMON/FUN1/QSOLAR,QIRIN,QMETAB,QRESP,QSEVAP,QIROUT,QCONV,QCOND
      COMMON/FUN2/AMASS,RELHUM,ATOT,FATOSK,FATOSB,EMISAN,SIG,FLSHCOND
      COMMON/WINGFUN/RHO1_3,TRANS1,AREF,BREF,CREF,PHI,F21,F31,F41,F51
     &,SIDEX,WQSOL,PHIMIN,PHIMAX,TWING,F12,F32,F42,F52
     &,F61,TQSOL,A1,A2,A3,A4,A4B,A5,A6,F13,F14,F15,F16,F23,F24,F25,F26
     &,WINGCALC,WINGMOD
      COMMON/FUN3/AL,TA,VEL,PTCOND,SUBTK,DEPSUB,TSUBST,PTCOND_ORIG,
     & EGGPTCOND,POT
      COMMON/FUN4/TSKIN,R,WEVAP,TR,ALT,BP,H2O_BALPAST
      COMMON/DEPTHS/DEPSEL,TCORES
      COMMON/WDSUB1/ANDENS,ASILP,EMISSB,EMISSK,FLUID,G,IHOUR
      COMMON/WCOND/TOTLEN,AV,AT
      COMMON/SOIL/TSOIL,TSHSOI,ZSOIL,MSOIL,MSHSOI,PSOIL,PSHSOI,HSOIL,
     & HSHSOI,TCOND,SHTCOND
      COMMON/GUESS/XTRY
      COMMON/BEHAV2/GEOMETRY,NODNUM,CUSTOMGEOM,SHP,EGGSHP
      COMMON/DEBMOD/V,ED,WETMASS,WETSTORAGE,WETGONAD,WETFOOD,O2FLUX,
     & CO2FLUX,CUMREPRO,HS,E_S,L_W,CUMBATCH,Q,V_BABY1,E_BABY1,
     & E_H,STAGE,EH_BABY1,GUTFREEMASS,SURVIV,VOLD,VPUP,EPUP,E_HPUP,
     & RAINDRINK,POTFREEMASS,PAS,PBS,PCS,PDS,PGS,PJS,PMS,PRS,CENSUS,
     & RESET,DEADEAD,STARTDAY,DEAD,EGGMULT
      COMMON/VIVIP/VIVIPAROUS,PREGNANT
      COMMON/REVAP1/TLUNG,DELTAR,EXTREF,RQ,MR_1,MR_2,MR_3,DEB1
      COMMON/ELLIPS/ASEMAJR,BSEMINR,CSEMINR
     
C     SOIL THERMAL COND. (SUBTK =0.35W/M-C)
C     WOOD ALSO HAS A THERMAL COND. 0.10-0.35 W/M-C
C     CHANGE EQUATION DEPENDING ON WHETHER IT IS AN EGG OR NOT.

      IF((DEB1.EQ.1).AND.(STAGE.LT.1).AND.(VIVIPAROUS.EQ.0).AND.
     & (AMASS.GT.0.))THEN
       QCOND=AV*(SUBTK/MIN(ASEMAJR,BSEMINR,CSEMINR))*(TSKIN-TSUBST) ! CONDUCTION HEAT FLOW, FROM ACKERMAN ET AL. 1985, EQ. 7, ASSUMING HERE THAT TC = TSKIN
      ELSE
       QCOND=AV*(SUBTK/(2.5/100.))*(TSKIN-TSUBST) ! CONDUCTION HEAT FLOW, FROM SKIN TO 2.5 CM INTO SUBSTRATE
      ENDIF
      RETURN
      END

