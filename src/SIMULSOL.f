C     NICHEMAPR: SOFTWARE FOR BIOPHYSICAL MECHANISTIC NICHE MODELLING

C     COPYRIGHT (C) 2020 MICHAEL R. KEARNEY AND WARREN P. PORTER

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

C	  THIS SUBROUTINE SIMULTANEOUSLY SOLVES FOR THE SKIN AND FUR/AIR 
C     INTERFACE TEMPERATURE THAT BALANCES THE HEAT BUDGET FOR A NON-
C     RESPIRING BODY PART, ACCOUNTING FOR DORSAL AND VENTRAL DIFFERENCES
C     AND EVAPOURATION FROM THE SKIN. IT IS THE CORE OF THE ENDOTHERM
C     MODEL

C     FURTST = TEST FOR FUR PRESENCE (ZERO IF NO FUR)

C     TA = AIR TEMPERATURE (C)
C     TCONDSB = SUBSTRATE TEMPERATURE FOR CONDUCTION (MIGHT BE DIFF FROM IR FROM DIGGING A DEPRESSION)
C     D = CHARACTERISTIC DIMENSION FOR CONVECTION
C     CONVAR = AREA FOR CONVECTION, INCLUDING FUR (M2)
C     CONVSK = AREA OF SKIN FOR EVAPORATION BY SWEATING (M2)
C     FLTYPE = FLUID TYPE: 0 = AIR; 1 = FRESH WATER; 2 = SALT WATER

      SUBROUTINE SIMULSOL(DIFTOL,IPT,FURVARS,GEOMVARS,ENVVARS,TRAITS,
     & TFA,SKINW,TSKIN,RESULTS)

      IMPLICIT NONE
      
      DOUBLE PRECISION AK1,AK2,ALT,ASEMAJ,ASQG,BETARA,BG,BL,BP,BR,BS
      DOUBLE PRECISION BSEMIN,BSQG,CD,CF,CONVAR,CONVRES,CONVSK,CSEMIN
      DOUBLE PRECISION CSQG,D,DIFTOL,DV1,DV2,DV3,DV4
      DOUBLE PRECISION DV5,EMIS,ENVVARS,FABUSH,FAGRD,FASKY,FATTHK,FAVEG
      DOUBLE PRECISION FLSHASEMAJ,FLSHBSEMIN,FLSHCSEMIN,FLTYPE,FLYHR
      DOUBLE PRECISION FURTHRMK,FURTST,FURVARS,FURWET,GEOMVARS,HC,HD
      DOUBLE PRECISION HDFREE,IPT,IRPROPout,KEFF,KFUR,KRAD,LEN,NTRY
      DOUBLE PRECISION PCTBAREVAP,PCTEYES,PI,QCOND,QCONV,QENV,QFSEVAP
      DOUBLE PRECISION QGENNET,QR1,QR2,QR3,QR4,QRAD,QRBSH,QRGRD,QRSKY
      DOUBLE PRECISION QRVEG,QSEVAP,QSLR,RESULTS,RFLESH,RFUR,RH,RRAD
      DOUBLE PRECISION RSKIN,SEVAPRES,SHAPE,SIG,SKINW,SOLCT,SOLPRO,SSQG
      DOUBLE PRECISION SUBQFAT,SUCCESS,SURFAR,TA,TBUSH,TC,TCONDSB,TFA
      DOUBLE PRECISION TFACALC,TFADIFF,TFAT1,TFAT2,TFAT3,TFAT4,TLOWER,TR
      DOUBLE PRECISION TRAITS,TRAPPX,TS,TSKCALC,TSKCALC1
      DOUBLE PRECISION TSKCALC2,TSKCALCAV,TSKDIFF,TSKIN,TSKT1,TSKT2
      DOUBLE PRECISION TSKT3,TSKY,TVEG,VEL,VOL,XR,ZFUR,ZL
      DOUBLE PRECISION LHAIR,DHAIR,RHO,REFL,KHAIR
      DOUBLE PRECISION BLCMP,CD1,CD2,CD3,CF1,KFURCMPRS,PCOND,RFURCMP
      DOUBLE PRECISION TFACMP,TFACMPT1,TFACMPT2,TR2
      
      INTEGER I,S
     
      DIMENSION CONVRES(15),SEVAPRES(7),RESULTS(16),BETARA(3)
      DIMENSION FURVARS(15) ! LEN,ZFUR,FURTHRMK,KEFF,BETARA,FURTST, ! NOTE KEFF DEPENDS ON IF SOLAR, AND THEN WHAT SIDE, SET IN R
      DIMENSION GEOMVARS(20) ! SHAPE,SUBQFAT,SURFAR,VOL,D,CONVAR,CONVSK,RFUR,RFLESH,RSKIN,XR,RRAD,ASEMAJ,BSEMIN,CSEMIN,CD,
      DIMENSION ENVVARS(17) ! FLTYPE,TA,TS,TBUSH,TVEG,TLOWER,TSKY,TCONDSB,RH,VEL,BP,ALT,FASKY,FABUSH,FAVEG,FAGRD,QSLR
      DIMENSION TRAITS(9) !TC,AK1,AK2,EMIS,FATTHK,FLYHR,FURWET,PCTBAREVAP,PCTEYES
      DIMENSION IRPROPout(26)

C     CONSTANTS      
      SIG = 5.6697E-8 ! W M-2 K-4
      PI = ACOS(-1.0D0)
      
C     UNPACKING VARIABLES

      LEN=FURVARS(1)
      ZFUR=FURVARS(2)
      FURTHRMK=FURVARS(3)
      KEFF=FURVARS(4)
      BETARA=FURVARS(5:7)
      FURTST=FURVARS(8)
      ZL=FURVARS(9)
      LHAIR=FURVARS(10)
      DHAIR=FURVARS(11)
      RHO=FURVARS(12)
      REFL=FURVARS(13)
      KHAIR=FURVARS(14)
      S=INT(FURVARS(15))
     
      SHAPE=GEOMVARS(1)
      SUBQFAT=GEOMVARS(2)
      SURFAR=GEOMVARS(3)
      VOL=GEOMVARS(4)
      D=GEOMVARS(5)
      CONVAR=GEOMVARS(6)
      CONVSK=GEOMVARS(7)
      RFUR=GEOMVARS(8)
      RFLESH=GEOMVARS(9)
      RSKIN=GEOMVARS(10)
      XR=GEOMVARS(11)
      RRAD=GEOMVARS(12)
      ASEMAJ=GEOMVARS(13)
      BSEMIN=GEOMVARS(14)
      CSEMIN=GEOMVARS(15)
      CD=GEOMVARS(16)
      PCOND=GEOMVARS(17)
      RFURCMP=GEOMVARS(18)
      BLCMP=GEOMVARS(19)
      KFURCMPRS=GEOMVARS(20)
      
      FLTYPE=ENVVARS(1)
      TA=ENVVARS(2)
      TS=ENVVARS(3)
      TBUSH=ENVVARS(4)
      TVEG=ENVVARS(5)
      TLOWER=ENVVARS(6)
      TSKY=ENVVARS(7)
      TCONDSB=ENVVARS(8)
      RH=ENVVARS(9)
      VEL=ENVVARS(10)
      BP=ENVVARS(11)
      ALT=ENVVARS(12)
      FASKY=ENVVARS(13)
      FABUSH=ENVVARS(14)
      FAVEG=ENVVARS(15)
      FAGRD=ENVVARS(16)
      QSLR=ENVVARS(17)
      
      TC=TRAITS(1)
      AK1=TRAITS(2)
      AK2=TRAITS(3)
      EMIS=TRAITS(4)
      FATTHK=TRAITS(5)
      FLYHR=TRAITS(6)
      FURWET=TRAITS(7)
      PCTBAREVAP=TRAITS(8)
      PCTEYES=TRAITS(9)
      
C     INITIALISE
      SOLPRO=1.
      SOLCT=0.
      NTRY=0.
      SUCCESS=1.
      
      IF(FURTST .GT. 0.0000000) THEN
       GO TO 5
      ELSE
       GO TO 120
      ENDIF
      
****************************************************************************************************************
C     BEGIN CALCULATING TSKIN AND TFA VALUES FOR FURRED BODY PARTS
****************************************************************************************************************
5     CONTINUE
      NTRY = NTRY + 1.      
      DO 105, I=1,20
11     CONTINUE
       CALL CONV_ENDO(TS,TA,SHAPE,SURFAR,FLTYPE,FURTST,D,TFA,VEL,ZFUR,
     &  BP,ALT,CONVRES)
       HC=CONVRES(2)
       HD=CONVRES(5)
       HDFREE=CONVRES(6)
       CALL SEVAP_ENDO(BP,TA,RH,VEL,TC,TSKIN,ALT,SKINW,
     & FLYHR,CONVSK,HD,HDFREE,PCTBAREVAP,PCTEYES,ZFUR,FURWET,
     & TFA, CONVAR, SEVAPRES)
       QSEVAP = SEVAPRES(1)
       QFSEVAP = SEVAPRES(7) 
       CALL IRPROP((0.7*TFA+0.3*TS),DHAIR,DHAIR,LHAIR,LHAIR,ZFUR,
     & ZFUR,RHO,RHO,REFL,REFL,ZFUR,0.5,KHAIR,IRPROPout)
       KEFF=IRPROPout(S+1)
       IF(FURTHRMK.GT.0.)THEN
C       USER SUPPLIED FUR THERMAL CONDUCTIVITY VALUE
        KFUR = FURTHRMK
       ELSE
C       NEED A TRAD APPROXIMATION FOR CALCULATING KRAD.
        TRAPPX = (TSKIN*(1.-XR))+(TFA*XR)
        KRAD = (16.0*SIG*(TRAPPX+273.15)**3.)/(3.*BETARA(1)) ! EQ7 IN CONLEY AND PORTER 1986
        KFUR = KEFF+KRAD
       ENDIF
        
       IF(INT(IPT).EQ.1)THEN ! CYLINDER GEOMETRY
        CF=(PCOND*2.*PI*KFURCMPRS*LEN)/(DLOG(RFURCMP/RSKIN))
        IF(PCOND.GT.0.0)THEN
             TFACMP=(CF*TSKIN+CD*TCONDSB)/(CD+CF)
          ELSE
             TFACMP=0.0
        ENDIF
        CD1= (KFURCMPRS/DLOG(RFURCMP/RSKIN))*PCOND+
     &       (KFUR/DLOG(RFUR/RSKIN))*(1.-PCOND)
        CD2= (KFURCMPRS/DLOG(RFURCMP/RSKIN))*PCOND
        CD3= (KFUR/DLOG(RFUR/RSKIN))*(1.-PCOND)
        
        DV1=1.+((2.*PI*LEN*RFLESH**2.*CD1)/(4.*AK1*VOL))+
     &          ((2.*PI*LEN*RFLESH**2.*CD1)/(2.*AK2*VOL))*
     &          DLOG(RSKIN/RFLESH)
	    DV2=((QSEVAP)*((RFLESH**2.*CD1)/(4.*AK1*VOL)))+
     &          (QSEVAP)*((RFLESH**2.*CD1)/(2.*AK2*VOL))*
     &           DLOG(RSKIN/RFLESH)
	    DV3=(((2.*PI*LEN)/DV1)*
     &      (TC*CD1-DV2-TFACMP*CD2-TFA*CD3)*RFLESH**2.)/(2.*VOL)
     
        IF(XR.LT.1.0)THEN
           DV4= CD2+(KFUR/DLOG(RFUR/RRAD))*(1.-PCOND)
           TR = DV3/DV4+((TFACMP*CD2)/DV4)+
     &          (TFA*((KFUR/DLOG(RFUR/RRAD))*(1.-PCOND)))/DV4
        ELSE
           TR = TFA
        ENDIF

       ENDIF
       
       IF(INT(IPT).EQ.2)THEN ! SPHERE GEOMETRY
        CF=(PCOND*4.*PI*KFURCMPRS*RFURCMP*RSKIN)/(RFURCMP-RSKIN)
        IF(PCOND.GT.0.0)THEN
             TFACMP=(CF*TSKIN+CD*TCONDSB)/(CD+CF)
          ELSE
             TFACMP=0.0
        ENDIF
        CD1= ((KFURCMPRS*RFURCMP)/(RFURCMP-RSKIN))*PCOND+
     &       ((KFUR*RFUR)/(RFUR-RSKIN))*(1.-PCOND)
        CD2= ((KFURCMPRS*RFURCMP)/(RFURCMP-RSKIN))*PCOND
        CD3= ((KFUR*RFUR)/(RFUR-RSKIN))*(1.-PCOND)        
        DV1=1.+((4.*PI*RSKIN*RFLESH**2.*CD1)/(6.*AK1*VOL))+
     &          ((4.*PI*RSKIN*RFLESH**3.*CD1)/(3.*AK2*VOL))*
     &         ((RSKIN-RFLESH)/(RFLESH*RSKIN))
	    DV2=((QSEVAP)*((RFLESH**2.*CD1)/(6.*AK1*VOL)))+
     &          (QSEVAP)*((RFLESH**3.*CD1)/(3.*AK2*VOL))*
     &          ((RSKIN-RFLESH)/(RFLESH*RSKIN))
	    DV3=(((4.*PI*RSKIN)/DV1)*
     &      (TC*CD1-DV2-TFACMP*CD2-TFA*CD3)*RFLESH**3.)/(3.*VOL*RRAD)
     
        IF(XR.LT.1.0)THEN
           DV4= CD2+((KFUR*RFUR)/(RFUR-RRAD))*(1.-PCOND)
           TR = DV3/DV4+((TFACMP*CD2)/DV4)+
     &          (TFA*(((KFUR*RFUR)/(RFUR-RRAD))*(1.-PCOND)))/DV4
        ELSE
           TR = TFA
        ENDIF
       ENDIF
       
       IF(IPT.GE.3.)THEN ! ELLIPSOID GEOMETRY
        FLSHASEMAJ=ASEMAJ-FATTHK
        FLSHBSEMIN=BSEMIN-FATTHK
        FLSHCSEMIN=CSEMIN-FATTHK
        IF((INT(SUBQFAT).EQ.1).AND.(FATTHK.GT.0.00))THEN
         ASQG = FLSHASEMAJ**2.
         BSQG = FLSHBSEMIN**2.
         CSQG = FLSHCSEMIN**2.
        ELSE
         ASQG = ASEMAJ**2.
         BSQG = BSEMIN**2.
         CSQG = CSEMIN**2.
        ENDIF
        SSQG = (ASQG*BSQG*CSQG)/(ASQG*BSQG+ASQG*CSQG+BSQG*CSQG)
C       GETTING THE RADIUS IN THE "B" DIRECTION AT THE FLESH:
        IF((INT(SUBQFAT).EQ.1).AND.(FATTHK.GT.0.00))THEN
         BG=FLSHBSEMIN
        ELSE
         BG=BSEMIN
        ENDIF
C       GETTING THE RADIUS IN THE "B" DIRECTION AT THE SKIN. WHEN THERE'S NO SUBQ FAT, BG=BS.
        BS = BSEMIN
C       GETTING THE RADIUS IN THE "B" DIRECTION AT THE FUR-AIR INTERFACE:
        BL=BSEMIN+ZL
        BR=BS+(XR*ZL)
        CF=(PCOND*3.*KFURCMPRS*VOL*BLCMP*BS)/
     &      ((((3.*SSQG)**0.5)**3.)*(BLCMP-BS))
        IF(PCOND.GT.0.0)THEN
             TFACMP=(CF*Tskin+CD*TCONDSB)/(CD+CF)
          ELSE
             TFACMP=0.0
        ENDIF
        
        CD1= ((KFURCMPRS*BLCMP)/(BLCMP-BS))*PCOND+
     &       ((KFUR*BL)/(BL-BS))*(1.-PCOND)
        CD2= ((KFURCMPRS*BLCMP)/(BLCMP-BS))*PCOND
        CD3= ((KFUR*BL)/(BL-BS))*(1.-PCOND)
        
        DV1=1.+((3*BS*SSQG*CD1)/(2.*AK1*(((3*SSQG)**0.5)**3.)))+
     &          ((BS*CD1)/(AK2))*
     &         ((BS-BG)/(BS*BG))
	    DV2=((QSEVAP)*((SSQG*CD1)/(2.*AK1*VOL)))+
     &      (QSEVAP)*(((((3.*SSQG)**0.5)**3.)*CD1)/(3.*AK2*VOL))*
     &          ((BS-BG)/(BS*BG))
	    DV3=((BS/DV1)*
     &      (TC*CD1-DV2-TFACMP*CD2-TFA*CD3))/(BR)
     
        IF(XR.LT.1.0)THEN
           DV4= CD2+((KFUR*BL)/(BL-BR))*(1.-PCOND)
           TR = DV3/DV4+((TFACMP*CD2)/DV4)+
     &          (TFA*(((KFUR*BL)/(BL-BR))*(1.-PCOND)))/DV4
        ELSE
           TR = TFA
        ENDIF
       ENDIF

       TR = TR+273.15
       
C      THESE QR VARIABLES INCORPORATE THE VARIOUS HR VALUES FOR RADIANT EXCHANGE WITH SKY, GROUND, ETC.
       QR1=CONVAR*(FASKY*4.*EMIS*SIG*((TR+(TSKY+273.15))/2.)**3) 
       QR2=CONVAR*(FABUSH*4.*EMIS*SIG*((TR+(TBUSH+273.15))/2.)**3)
       QR3=CONVAR*(FAVEG*4.*EMIS*SIG*((TR+(TVEG+273.15))/2.)**3)
       QR4=CONVAR*(FAGRD*4.*EMIS*SIG*((TR+(TLOWER+273.15))/2.)**3)
       
       IF(PCOND.LT.1)THEN !FOLLOWING CALCULATIONS ARE FOR WHEN THERE IS LESS THAN 100% CONDUCTION
C      INCLUDES TERM  (QFSEVAP) FOR HEAT LOST DUE TO EVAPORATION FROM THE FUR SURFACE TO 
C      CALCULATIONS OF TFA (E.G. WET FUR FROM RAIN)
        IF(INT(IPT).EQ.1)THEN ! CYLINDER GEOMETRY
         IF(XR.LT.1)THEN
          TFAT1=QR1*TSKY+QR2*TBUSH+QR3*TVEG+QR4*TLOWER-
     &       (QR1+QR2+QR3+QR4)*((DV3/DV4)+((TFACMP*CD2)/DV4))
          TFAT2=((2.*PI*LEN)/DV1)*(TC*CD1-DV2-TFACMP*CD2)
          TFAT3=HC*CONVAR*TA-CD*TFACMP+CD*TCONDSB-QFSEVAP+QSLR
          TFAT4=(2.*PI*LEN*CD3)/DV1+(QR1+QR2+QR3+QR4)*
     &        (((KFUR/DLOG(RFUR/RRAD))*(1.-PCOND))/DV4)+HC*CONVAR
          TFACALC=(TFAT1+TFAT2+TFAT3)/TFAT4
          TR2 = DV3/DV4+((TFACMP*CD2)/DV4)+
     &          (TFACALC*((KFUR/DLOG(RFUR/RRAD))*(1.-PCOND)))/DV4          
          ELSE
          TFAT1=QR1*TSKY+QR2*TBUSH+QR3*TVEG+QR4*TLOWER
          TFAT2=((2.*PI*LEN)/DV1)*(TC*CD1-DV2-TFACMP*CD2)
          TFAT3=HC*CONVAR*TA-CD*TFACMP+CD*TCONDSB-QFSEVAP+QSLR
          TFAT4=(2.*PI*LEN*CD3)/DV1+(QR1+QR2+QR3+QR4)+HC*CONVAR
          TFACALC=(TFAT1+TFAT2+TFAT3)/TFAT4
          TR2 = TFACALC
         ENDIF
        ENDIF
       
        IF(INT(IPT).EQ.2)THEN ! SPHERE GEOMETRY
         IF(XR.LT.1.)THEN
          TFAT1=((4.*PI*RSKIN)/DV1)*(TC*CD1-DV2-TFACMP*CD2)
	      TFAT2=QR1*TSKY+QR2*TBUSH+QR3*TVEG+QR4*TLOWER-
     &        (QR1+QR2+QR3+QR4)*((DV3/DV4)+((TFACMP*CD2)/DV4))
          TFAT3=HC*CONVAR*TA-CD*TFACMP+CD*TCONDSB-QFSEVAP+QSLR
          TFAT4=(4.*PI*RSKIN*CD3)/DV1+(QR1+QR2+QR3+QR4)*
     &       ((((KFUR*RFUR)/(RFUR-RRAD))*(1.-PCOND))/DV4)+HC*CONVAR
          TFACALC=(TFAT1+TFAT2+TFAT3)/TFAT4
          TR2 = DV3/DV4+((TFACMP*CD2)/DV4)+
     &          (TFACALC*(((KFUR*RFUR)/(RFUR-RRAD))*(1.-PCOND)))/DV4
          ELSE
          TFAT1=((4.*PI*RSKIN)/DV1)*(TC*CD1-DV2-TFACMP*CD2)
          TFAT2=QR1*TSKY+QR2*TBUSH+QR3*TVEG+QR4*TLOWER
          TFAT3=HC*CONVAR*TA-CD*TFACMP+CD*TCONDSB-QFSEVAP+QSLR
          TFAT4=(4.*PI*RSKIN*CD3)/DV1+(QR1+QR2+QR3+QR4)+HC*CONVAR
          TFACALC=(TFAT1+TFAT2+TFAT3)/TFAT4
          TR2 = TFACALC
         ENDIF
        ENDIF

        IF(IPT.GE.3.)THEN ! ELLIPSOID GEOMETRY
         IF(XR.LT.1.)THEN
          TFAT1=QR1*TSKY+QR2*TBUSH+QR3*TVEG+QR4*TLOWER-
     &        (QR1+QR2+QR3+QR4)*((DV3/DV4)+((TFACMP*CD2)/DV4))
          TFAT2=((3.*VOL*BS)/((((3.*SSQG)**0.5)**3.)*DV1))*
     &     (TC*CD1-DV2-TFACMP*CD2)
          TFAT3=HC*CONVAR*TA-CD*TFACMP+CD*TCONDSB-QFSEVAP+QSLR
          TFAT4=(3.*VOL*BS*CD3)/((((3.*SSQG)**0.5)**3.)*DV1)+
     &       (QR1+QR2+QR3+QR4)*
     &       ((((KFUR*BL)/(BL-BR))*(1-PCOND))/DV4)+HC*CONVAR
          TFACALC=(TFAT1+TFAT2+TFAT3)/TFAT4
          TR2 = DV3/DV4+((TFACMP*CD2)/DV4)+
     &         (TFACALC*(((KFUR*BL)/(BL-BR))*(1.-PCOND)))/DV4
          ELSE
          TFAT1=((3.*VOL*BS)/((((3.*SSQG)**0.5)**3.)*DV1))*
     &          (TC*CD1-DV2-TFACMP*CD2)
          TFAT2=QR1*TSKY+QR2*TBUSH+QR3*TVEG+QR4*TLOWER
          TFAT3=HC*CONVAR*TA-CD*TFACMP+CD*TCONDSB-QFSEVAP+QSLR
          TFAT4=(3.*VOL*BS*CD3)/((((3.*SSQG)**0.5)**3.)*DV1)+
     &        (QR1+QR2+QR3+QR4)+HC*CONVAR
          TFACALC=(TFAT1+TFAT2+TFAT3)/TFAT4
          TR2 = TFACALC
         ENDIF
        ENDIF
       
        QRSKY=QR1*(TR2-TSKY)
        QRBSH=QR2*(TR2-TBUSH)
        QRVEG=QR3*(TR2-TVEG)
        QRGRD=QR4*(TR2-TLOWER)
        QRAD = QRSKY+QRBSH+QRVEG+QRGRD
        QCONV = HC*CONVAR*(TFACALC-TA)
        QCOND = CD*(TFACMP-TCONDSB)
       ELSE !BEGIN CALCULATIONS FOR 100% CONDUCTION. NEED A DIFFERENT SOLUTION APPROACH SINCE THERE IS NO UNCOMPRESSED TFA TO SOLVE FOR
        IF(INT(IPT).EQ.1)THEN ! CYLINDER GEOMETRY
         CF1=(2.*PI*KFURCMPRS*LEN)/(DLOG(RFURCMP/RSKIN))
         DV5=1.+((CF1*RFLESH**2.)/(4.*AK1*VOL))+
     &    ((CF1*RFLESH**2.)/(2.*AK2*VOL))*DLOG(RSKIN/RFLESH)    
        ENDIF
        IF(INT(IPT).EQ.2)THEN ! SPHERE GEOMETRY
          CF1=(4.*PI*KFURCMPRS*RFURCMP)/(RFURCMP-RSKIN)
          DV5=1.+((CF1*RFLESH**2.)/(6.*AK1*VOL))+
     &    ((CF1*RFLESH**3.)/(3.*AK2*VOL))*((RSKIN-RFLESH)/
     &    (RSKIN-RFLESH)) 
        ENDIF
        IF(INT(IPT).EQ.3)THEN ! ELLIPSOID GEOMETRY
          CF1=(3.*KFURCMPRS*VOL*BLCMP*BS)/
     &        ((((3*SSQG)**0.5)**3.)*(BL-BS))
          DV5=1+((CF1*SSQG)/(2*AK1*VOL))+
     &    ((CF1*(((3*SSQG)**0.5)**3.))/(3.*AK2*VOL))*((BS-BG)/
     &    (BS*BG)) 
        ENDIF
          TFACMPT1=(CF1/DV5)*TC+CD*TCONDSB
          TFACMPT2=CD+CF1/DV5
          TFACMP=TFACMPT1/TFACMPT2
          QRAD=0.
          QCONV=0.
          QFSEVAP = 0.
          QSLR = 0.
          QCOND=CD*(TFACMP-TCONDSB)
       ENDIF

       QENV = QRAD+QCONV+QCOND+QFSEVAP-QSLR

       IF(INT(IPT).EQ.1)THEN ! CYLINDER GEOMETRY
        IF(PCOND.LT.1.)THEN
          TSKCALC1 = TC-(((QENV+QSEVAP)*RFLESH**2.)/(4.*AK1*VOL))-
     &        (((QENV+QSEVAP)*RFLESH**2.)/(2.*AK2*VOL))*
     &        DLOG(RSKIN/RFLESH)
          TSKCALC2 =((QENV*RFLESH**2.)/(2.*CD1*VOL))+((TFACMP*CD2)/CD1)+
     &             ((TFACALC*CD3)/CD1)
        ELSE
          TSKCALC1=TC-((QENV*RFLESH**2.)/(4.*AK1*VOL))-
     &            ((QENV*RFLESH**2.)/(2.*AK2*VOL))*
     &            DLOG(RSKIN/RFLESH)
          TSKCALC2=(((QENV*RFLESH**2.)/(2.*KFURCMPRS*VOL))*
     &            DLOG(RFURCMP/RSKIN))+TFACMP
        ENDIF
       ENDIF

       IF(INT(IPT).EQ.2)THEN ! SPHERE GEOMETRY
        IF(PCOND.LT.1.)THEN
          TSKCALC1 = TC-(((QENV+QSEVAP)*RFLESH**2.)/(6.*AK1*VOL))-
     &        (((QENV+QSEVAP)*RFLESH**3.)/(3.*AK2*VOL))*
     &        ((RSKIN-RFLESH)/(RSKIN*RFLESH))
          TSKCALC2 = ((QENV*RFLESH**3.)/(3.*CD1*VOL*RSKIN))+
     &               ((TFACMP*CD2)/CD1)+((TFACALC*CD3)/CD1)
        ELSE
          TSKCALC1=TC-((QENV*RFLESH**2.)/(6.*AK1*VOL))-
     &            ((QENV*RFLESH**3.)/(3.*AK2*VOL))*
     &            ((RSKIN-RFLESH)/(RSKIN*RFLESH))
          TSKCALC2=(((QENV*RFLESH**3.)/(3.*KFURCMPRS*VOL))*
     &            ((RFURCMP-RSKIN)/(RFURCMP*RSKIN)))+TFACMP
        ENDIF
       ENDIF    

       IF(INT(IPT).GE.3)THEN ! ELLIPSOID GEOMETRY
       IF(PCOND.LT.1.)THEN
          TSKCALC1 = TC-(((QENV+QSEVAP)*SSQG)/(2.*AK1*VOL))-
     &       (((QENV+QSEVAP)*(((3.*SSQG)**0.5)**3.))/(3.*AK2*VOL))*
     &       ((BS-BG)/(BS*BG))
          TSKCALC2 = ((QENV*(((3.*SSQG)**0.5)**3.))/(3.*CD1*VOL*BS))+
     &        ((TFACMP*CD2)/CD1)+((TFACALC*CD3)/CD1)
        ELSE
          TSKCALC1=TC-((QENV*SSQG)/(2.*AK1*VOL))-
     &            ((QENV*(((3.*SSQG)**0.5)**3.))/(3.*AK2*VOL))*
     &            ((BS-BG)/(BS*BG))
          TSKCALC2=(((QENV*(((3.*SSQG)**0.5)**3.))/(3.*KFURCMPRS*VOL))*
     &            ((BLCMP-BS)/(BLCMP*BS)))+TFACMP
        ENDIF
       ENDIF

       TSKCALCAV = (TSKCALC1+TSKCALC2)/2.

       TFADIFF = ABS(TFA-TFACALC)
       TSKDIFF = ABS(TSKIN-TSKCALCAV)

C      CHECK TO SEE IF THE TFA GUESS AND THE CALCULATED GUESS ARE SIMILAR
       IF(TFADIFF.LT.DIFTOL)THEN
C       IF YES, MOVE ON TO CHECK THE TFA GUESS AND CALCULATION
        GO TO 16
       ENDIF
C      IF NO, TRY ANOTHER INITIAL TFA GUESS
       IF(INT(SOLPRO).EQ.1)THEN
C       FIRST SOLUTION PROCEDURE IS TO SET TFA GUESS TO THE CALCULATED TFA
        TFA=TFACALC
       ELSE
        IF(INT(SOLPRO).EQ.2)THEN
C        SECOND SOLUTION PROCEDURE IS TO SET TFA GUESS TO AVERAGE OF PREVIOUS GUESS
C        AND CALCULATED TFA
         TFA=(TFACALC+TFA)/2.
        ELSE
C        FINAL SOLUTION PROCEDURE IS TO INCREASE TFA GUESS INCREMENTALLY TO AVOID
C        LARGE JUMPS PARTICULARLY WHEN DEALING WITH EVAPORATION AT HIGH TEMPERATURES.
         IF((TFA-TFACALC).LT.0.)THEN
          IF(TFADIFF.GT.3.5)THEN
           TFA = TFA+0.5
          ENDIF
          IF((TFADIFF.GT.1.0).AND.(TFADIFF.LT.3.5))THEN
           TFA = TFA+0.05
          ENDIF
          IF((TFADIFF.GT.0.1).AND.(TFADIFF.LT.1.0))THEN
           TFA = TFA+0.05
          ENDIF
          IF((TFADIFF.GT.0.01).AND.(TFADIFF.LT.0.1))THEN
           TFA = TFA+0.005
          ENDIF
          IF((TFADIFF.GT.0.0).AND.(TFADIFF.LT.0.01))THEN
           TFA=TFA+0.0001
          ENDIF
          IF((TFADIFF.GT.0.0).AND.(TFADIFF.LT.0.001))THEN
           TFA=TFA+0.00001
          ENDIF
         ELSE
          IF(TFADIFF.GT.3.5)THEN
           TFA = TFA-0.5
          ENDIF
          IF((TFADIFF.GT.1.0).AND.(TFADIFF.LT.3.5))THEN
           TFA = TFA-0.05
          ENDIF
          IF((TFADIFF.GT.0.1).AND.(TFADIFF.LT.1.0))THEN
           TFA = TFA-0.05
          ENDIF
          IF((TFADIFF.GT.0.01).AND.(TFADIFF.LT.0.1))THEN
           TFA = TFA-0.005
          ENDIF
          IF((TFADIFF.GT.0.001).AND.(TFADIFF.LT.0.01))THEN
           TFA=TFA-0.0001
          ENDIF
          IF((TFADIFF.GT.0.0).AND.(TFADIFF.LT.0.001))THEN
           TFA=TFA-0.00001
          ENDIF
         ENDIF
        ENDIF
       ENDIF
       TSKIN=TSKCALCAV
       SOLCT=SOLCT+1.

       IF(SOLCT.GE.100.)THEN
        IF(INT(SOLPRO).NE.3)THEN
         SOLCT=0.
         SOLPRO=SOLPRO+1.
        ELSE
C        EVEN THE SECOND WAY OF SOLVING FOR BALANCE DOESN'T WORK, INCREASE TOLERANCE
         IF(DIFTOL.LE.0.001)THEN
          DIFTOL=0.01
          SOLCT=0.
          SOLPRO=1.
         ELSE
          SUCCESS=0.
          QGENNET=0.
          GOTO 150
         ENDIF
        ENDIF
       ENDIF
       GO TO 11
       
C      CHECK TO SEE IF THE TSK GUESS AND CALCULATION ARE SIMILAR
16     IF(TSKDIFF.LT.DIFTOL)THEN
C       IF YES, BOTH TFA AND TSK GUESSES ARE SIMILAR TO THE CALCULATED VALUES

        IF(INT(IPT).EQ.1)THEN ! CYLINDER GEOMETRY
         QGENNET = (TC-TSKCALCAV)/((RFLESH**2./(4.*AK1*VOL))+
     &   ((RFLESH**2./(2.*AK2*VOL))*LOG(RSKIN/RFLESH)))
        ENDIF

        IF(INT(IPT).EQ.2)THEN ! SPHERE GEOMETRY
         QGENNET = (TC-TSKCALCAV)/((RFLESH**2./(6.*AK1*VOL))+
     &    ((RFLESH**3./(3.*AK2*VOL))*((RSKIN-RFLESH)/(RFLESH*RSKIN))))
        ENDIF

        IF(INT(IPT).GE.3)THEN ! ELLIPSOID GEOMETRY
         QGENNET = (TC-TSKCALCAV)/((SSQG/(2.*AK1*VOL))+
     &    (((((3.*SSQG)**0.5)**3.)/(3.*AK2*VOL))*
     &    ((BS-BG)/(BG*BS))))
        ENDIF
        GO TO 150
       ELSE
C       IF NO, TRY ANOTHER INITIAL TSKIN GUESS AND START THE LOOP OVER AGAIN.
        IF(NTRY < 20.)THEN         
         TSKIN=TSKCALC1
         GO TO 5
        ELSE
         SUCCESS=0.
         IF(INT(IPT).EQ.1)THEN ! CYLINDER GEOMETRY
          QGENNET = (TC-TSKCALCAV)/((RFLESH**2./(4.*AK1*VOL))+
     &     ((RFLESH**2./(2.*AK2*VOL))*LOG(RSKIN/RFLESH)))
         ENDIF

         IF(INT(IPT).EQ.2)THEN ! SPHERE GEOMETRY
          QGENNET = (TC-TSKCALCAV)/((RFLESH**2./(6.*AK1*VOL))+
     &    ((RFLESH**3./(3.*AK2*VOL))*((RSKIN-RFLESH)/(RFLESH*RSKIN))))
         ENDIF

         IF(INT(IPT).GE.3)THEN ! ELLIPSOID GEOMETRY
          QGENNET = (TC-TSKCALCAV)/((SSQG/(2.*AK1*VOL))+
     &    (((((3*SSQG)**0.5)**3.)/(3.*AK2*VOL))*
     &    ((BS-BG)/(BG*BS))))
         ENDIF         
        ENDIF
       ENDIF
105   CONTINUE
      GO TO 150

C     COMMENT: THIS LOOP IS FOR WHEN THERE IS NO FUR.
120   CONTINUE

      NTRY = NTRY + 1.       
      DO 140, I=1,20
125     CONTINUE
       CALL CONV_ENDO(TS,TA,SHAPE,CONVSK,FLTYPE,FURTST,D,TFA,VEL,ZFUR,
     &  BP,ALT,CONVRES)
       HC=CONVRES(2)
       HD=CONVRES(5)
       HDFREE=CONVRES(6)
       CALL SEVAP_ENDO(BP,TA,RH,VEL,TC,TSKIN,ALT,SKINW,
     & FLYHR,CONVSK,HD,HDFREE,PCTBAREVAP,PCTEYES,ZFUR,FURWET
     &,TFA, CONVAR, SEVAPRES)
       QSEVAP = SEVAPRES(1)

C      THESE QR VARIABLES INCORPORATE THE VARIOUS HR VALUES FOR RADIANT EXCHANGE WITH SKY, GROUND, ETC.
       QR1=CONVSK*(FASKY*4.*EMIS*SIG* 
     &      (((TSKIN+273.15)+(TSKY+273.15))/2.)**3.)
       QR2=CONVSK*(FABUSH*4.*EMIS*SIG*
     &      (((TSKIN+273.15)+(TBUSH+273.15))/2.)**3.)
       QR3=CONVSK*(FAVEG*4.*EMIS*SIG*
     &      (((TSKIN+273.15)+(TVEG+273.15))/2.)**3.)
       QR4=CONVSK*(FAGRD*4.*EMIS*SIG*
     &      (((TSKIN+273.15)+(TLOWER+273.15))/2.)**3.)

       TSKT1= ((4.*AK1*VOL)/(RSKIN**2.)*TC)-QSEVAP+HC*CONVSK*
     &  TA+QSLR
       TSKT2= QR1*TSKY+QR2*TBUSH+QR3*TVEG+QR4*TLOWER
       TSKT3=((4.*AK1*VOL)/(RSKIN**2.))+HC*CONVSK+QR1+QR2+
     &  QR3+QR4
       TSKCALC=(TSKT1+TSKT2)/TSKT3

       QRSKY=QR1*(TSKCALC-TSKY)
       QRBSH=QR2*(TSKCALC-TBUSH)
       QRVEG=QR3*(TSKCALC-TVEG)
       QRGRD=QR4*(TSKCALC-TLOWER)
       QRAD = QRSKY+QRBSH+QRVEG+QRGRD
       QCONV = HC*CONVSK*(TSKCALC-TA)
       QENV = QRAD+QCONV-QSLR
       TSKDIFF = ABS(TSKIN-TSKCALC)

C      CHECK TO SEE IF THE TSK GUESS AND CALCULATION ARE SIMILAR
       IF(TSKDIFF.LT.DIFTOL)THEN
C       IF YES, BOTH TFA AND TSK GUESSES ARE SIMILAR TO THE CALCULATED VALUES
        QGENNET = ((4.*AK1*VOL)/RSKIN**2.)*(TC-TSKCALC)
        GO TO 150
       ELSE
C       IF NO, TRY ANOTHER INITIAL TSKIN GUESS AND START THE LOOP OVER AGAIN.
        TSKIN=TSKCALC
        TSKCALCAV=TSKCALC
        TFA=TSKCALC
        NTRY=NTRY+1.
        IF(INT(NTRY).EQ.101)THEN
         IF(DIFTOL.LE.0.001)THEN
          DIFTOL=0.01
          NTRY=0.
         ELSE
C         CAN'T FIND A SOLUTION, QUIT
          SUCCESS=0.
          QGENNET=0.
         GOTO 150
         ENDIF
        ENDIF
        GO TO 125
       ENDIF
140   CONTINUE

150    CONTINUE
*************************************************************************************************************
C     END CALCULATING TFA AND TSKIN VALUES FOR BARE BODY PARTS
*************************************************************************************************************

      RESULTS = (/TFA,TSKCALCAV,QCONV,QCOND,QGENNET,QSEVAP,QRAD,QSLR,
     & QRSKY,QRBSH,QRVEG,QRGRD,QFSEVAP,NTRY,SUCCESS,KFUR/) 
    
      RETURN
      END