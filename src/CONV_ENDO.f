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

C     SUBROUTINE TO COMPUTE CONVECTIVE HEAT TRANSFER.
C     CALCULATING SUM OF FREE AND FORCED CONVECTION

C     ALL UNITS SI  (M,KG,S,C,K,J,PA)

C     ALT = ALTITUDE
C     ANU = NUSSELT NUMBER
C     BETA = GRASHOF NUMBER TERM (1/AIR TEMP (K))
C     BP = BAROMETRIC PRESSURE
C     CP = SPECIFIC HEAT OF AIR
C     D = CHARACTERISTIC DIMENSION FOR CONVECTION
C     DB = DRY BULB TEMPERATURE (C)
C     DELTAT = TEMPERATURE DIFFERENCE
C     DENSTY = DENSITY OF AIR
C     DIFVPR = DIFFUSIVITY OF WATER VAPOR
C     FLTYPE = FLUID TYPE: 0 = AIR; 1 = FRESH WATER; 2 = SALT WATER
C     FURTST = INPUT WHERE IF <=0 MEANS NO EFFECTIVE FUR
C     GGROUP = GROUP OF GRASHOF VARIABLES
C     GR = GRASHOF NUMBER
C     GRAV = ACCELERATION DUE TO GRAVITY
C     HC = HEAT TRANSFER COEFFICIENT
C     HCCOMB = HEAT TRANSFER COEFFICIENT COMBINING FORCED AND FREE CONVECTION
C     HCFOR = HEAT TRANSFER COEFFICIENT FOR FORCED CONVECTION
C     HCFREE = HEAT TRANSFER COEFFICIENT FOR FREE CONVECTION
C     HD = MASS TRANSFER COEFFICIENT COMBINING FORCED AND FREE
C     HDFORC = MASS TRANSFER COEFFICIENT FOR FORCED CONVECTION
C     HDFREE = MASS TRANSFER COEFFICIENT FOR FREE CONVECTION
C     HTOVPR = WATER VAPOR PRESSURE
C     NGEOM = SHAPE
C      1 = CYLINDER
C      2 = SPHERE
C      3 = PLATE
C      4 = ELLIPSOID
C      5 = TRUNCATED CONE (NOT IMPLEMENTED)
C     NUFORCED = NUSSELT NUMBER FOR FORCED CONVECTION
C     NUFREE = = NUSSELT NUMBER FOR FREE CONVECTION 
C     NUTOTAL = = NUSSELT NUMBER COMBINING FORCED AND FREE CONVECTION 
C     PATMOS = ATMOSPHERIC PRESSURE
C     PI = THE NUMBER PI
C     PR = PRANDTL NUMBER
C     QCONV = HEAT LOSS BY CONVECTION
C     QFORCED = HEAT LOSS BY FORCED CONVECTION
C     QFREE = HEAT LOSS BY FREE CONVECTION
C     RA = RAYLEIGH NUMBER
C     RE = REYNOLD'S NUMBER
C     RESULTS = OUTPUT VECTOR
C     SC = SCHMIDT NUMBER
C     SH = SHERWOOD NUMBER
C     SURFAR = SURFACE AREA (M2)
C     TCOEFF = TEMPERATURE COEFFICIENT OF EXPANSION OF AIR
C     TENV = TEMPERATURE OF ENVIRONMENT (AIR/WATER)
C     TEST = GRASHOF-PRANDTL PRODUCT
C     TFA = CURRENT GUESS OF OBJECT FUR/AIR INTERFACE TEMPERATURE
C     THCOND = THERMAL CONDUCTIVITY OF AIR
C     TS = CURRENT GUESS OF OBJECT SKIN TEMPERATURE
C     VEL = AIR VELOCITY
C     VISDYN = DYNAMIC VISCOSITY OF AIR
C     VISKIN = KINEMATIC VISCOSITY OF AIR
C     XTRA = PART OF AN ERROR CHECK
C     ZFUR = FUR DEPTH

      SUBROUTINE CONV_ENDO(TS,TENV,NGEOM,SURFAR,FLTYPE,FURTST,D,TFA,
     &VEL,ZFUR,BP,ALT,RESULTS) 
     
      IMPLICIT NONE

      DOUBLE PRECISION ALT,ANU,BETA,BP,CP,D,DB,DELTAT,DENSTY,DIFVPR
      DOUBLE PRECISION FLTYPE,FURTST,GGROUP,GR,GRAV,HC,HCCOMB,HCFOR
      DOUBLE PRECISION HCFREE,HD,HDFORC,HDFREE,HTOVPR,NGEOM,NUFORCED
      DOUBLE PRECISION NUFREE,NUTOTAL,PATMOS,PI,PR,QCONV
      DOUBLE PRECISION RA,RE,RESULTS,SC,SH,SURFAR,TCOEFF,TENV
      DOUBLE PRECISION TEST,TFA,THCOND,TS,VEL,VISDYN,VISKIN,XTRA,ZFUR
      
      DIMENSION RESULTS(14)

      PI=ACOS(-1.0D0)
      
      GRAV=9.80665
      CP=1.0057E+3

C     USING ALTITUDE TO COMPUTE BP (SEE DRYAIR LISTING)

      DB=TENV
      IF(DB .LT. -75.)THEN
       DB = -75.
      ENDIF

C     COMPUTING FLUID PROPERTIES:
C     FLTYPE = 0->AIR; 1->FRESH WATER; 2->SALT WATER
      IF (INT(FLTYPE) .EQ. 0) THEN
       CALL DRYAIR(DB,BP,ALT,PATMOS,DENSTY,VISDYN,VISKIN,DIFVPR,
     *  THCOND,HTOVPR,TCOEFF,GGROUP)
      ELSE
       IF(INT(FLTYPE) .EQ. 1)THEN
C       FRESH WATER
        CALL WATER(TENV,BETA,CP,DENSTY,THCOND,VISDYN)
       ELSE
        IF(INT(FLTYPE) .EQ. 2)THEN
         CALL SEAWATER(TENV,CP,DENSTY,THCOND,VISDYN)
        ELSE
C          WRITE(0,*)'FLUID TYPE UNDEFINED: AIR, FRESH, OR SALT WATER?'
        ENDIF
       ENDIF
      ENDIF

C     COMPUTING PRANDTL NUMBER
      PR=CP*VISDYN/THCOND

C     COMPUTING SCHMIDT NUMBER
      IF (INT(FLTYPE) .EQ. 0) THEN
C      AIR
       SC=VISDYN/(DENSTY*DIFVPR)
      ELSE
C      WATER; NO MEANING
       SC=1.0
      ENDIF

C     COMPUTING FREE CONVECTION VARIABLES FOR THE GRASHOF NUMBER
      BETA=1./(TENV+273.15)
      IF(FURTST .LE. 0.00) THEN
C      NO FUR, FREE CONVECTION FROM SKIN TO AIR OR INSIDE OF SHELTER, IF RELEVANT
       DELTAT=TS-TENV
      ELSE
C      FREE CONVECTION IN FUR CONSIDERED NEGLIGIBLE; FREE CONVECTION ONLY OFF FUR SURFACE.
       DELTAT=TFA-TENV
      ENDIF

C     STABILITY CHECK
      IF(DELTAT .LE. 0.0000000E+00)THEN
       DELTAT = DELTAT + 0.00001
      ENDIF
      
      GR=((DENSTY**2.)*BETA*GRAV*(D**3.)*DELTAT)/(VISDYN**2.)
C     CORRECTING IF NEGATIVE DELTAT
      GR = ABS(GR)
C     RAYLEIGH NUMBER
      RA=GR*PR

C     AVOIDING DIVIDE BY ZERO IN FREE VS FORCED TEST
      IF (VEL .LE. 0.00000) THEN
       VEL = 0.01
      ENDIF
      
C     IF A TRUNCATED CONE (5)
C     WE WILL USE THE CYLINDER EQUATIONS (NGEOM=1).

      IF(INT(NGEOM).EQ.5)THEN
       NGEOM = 1
      ENDIF

C     *********************  FREE CONVECTION  ********************

      IF(INT(NGEOM).EQ.1)THEN
C      FREE CONVECTION IN CYLINDER
C      FROM P.334 KREITH (1965): MC ADAM'S 1954 RECOMMENDED COORDINATES
C      BUT CHECK OUT P. 443-445 IN BIRD, STEWART & LIGHTFOOT, 2002
       IF(RA.LT.0.1)THEN
        ANU=0.976*RA**0.0784
       ELSE IF(RA.LT.100.)THEN
        ANU=1.1173*RA**0.1344
       ELSE IF(RA.LT.10000.)THEN
        ANU=0.7455*RA**0.2167
       ELSE
        ANU=0.5168*RA**0.2501
       ENDIF
      ENDIF

C     FREE CONVECTION IN SPHERE OR ELLIPSOID
      IF((INT(NGEOM).EQ.2).OR.(INT(NGEOM).EQ.4))THEN
C      FREE CONVECTION IN SPHERE
C      FROM P.413 BIRD ET AL (1960) TRANSPORT PHENOMENA)
       ANU=2.+0.60* ((GR**.25)*(PR**.333))
       TEST = (GR**.25)*(PR**.333)
       IF (TEST .GT. 200.) THEN
        XTRA = ((TEST - 200.)/TEST)*100.
C       THIS CRITERION RARELY EXCEEDED EVEN FOR LARGE ANIMALS.  WHEN IT
C       IS, IT IS LESS THAT 10% USUALLY.  IT ALSO DECREASES AS CONVERGENCE
C       ON A SOLUTION HAPPENS.
        IF (XTRA .GT. 150.) THEN
C        WRITE(6,*)'(GR**.25)*(PR**.33)',XTRA,'% TOO LARGE ',
C     &   'FOR CORREL.'
        ENDIF
       ENDIF
      ENDIF

      IF(INT(NGEOM).EQ.3)THEN
C      FREE CONVECTION FOR A PLATE (AS USED BY PHILLIPS & HEATH 1992, 
C      GATES EQN. 9.77, ASSUMES TURBULENT FLOW, NOTE PHILLIPS & HEATH 
C      HAD 2/3 EXPONENT NOT 1/3 AS IN GATES)
        ANU = 0.13*(GR*PR)**(1./3.)
      ENDIF
      
      NUFREE = ANU
C     CALCULATING THE HEAT TRANSFER COEFFICIENT, HC  (NU=HC*D/KAIR) FOR FREE CONVECTION
      HC=(ANU*THCOND)/D
      HCFREE = HC
C     CALCULATING THE SHERWOOD NUMBER FROM THE COLBURN ANALOGY
C     (BIRD, STEWART & LIGHTFOOT, 1960. TRANSPORT PHENOMENA. WILEY.
      SH = ANU * (SC/PR)**.333
C     CALCULATING THE MASS TRANSFER COEFFICIENT FROM THE SHERWOOD NUMBER
      HDFREE=SH*DIFVPR/D

C     IF(ZFUR.LE.0.000001)THEN
CC      NO FUR, HEAT LOSS FROM SKIN
C       QFREE = HC * SURFAR * (TS - TENV)
C     ELSE
CC      FUR/FEATHERS PRESENT, FREE CONVECTION FROM THE SKIN TO THE FUR/AIR INTERFACE
C      QFREE = HC * SURFAR * (TFA - TENV)
C     ENDIF

C     *******************  FORCED CONVECTION  *********************
C     COMPUTING REYNOLDS NUMBER FROM AIR PROPERTIES FROM DRYAIR
      RE = DENSTY*VEL*D/VISDYN

C     COMPUTING NUSSELT NUMBER

C     CYLINDER
      IF(INT(NGEOM).EQ.1)THEN
       IF(RE.LE.4.)THEN
        ANU=.891*RE**.33
       ELSE IF((RE.GT.4.).AND.(RE.LE.40))THEN
        ANU=.821*RE**.385
       ELSE IF((RE.GT.40.).AND.(RE.LE.4000.))THEN
        ANU=.615*RE**.466
       ELSE IF ((RE.GT.4000.).AND.(RE.LE.40000.))THEN
        ANU=.174*RE**.618
       ELSE
C       RE.GT.40000.
        ANU=.0239*RE**.805
       ENDIF
      ENDIF
C     SPHERE OR ELLIPSOID
      IF((INT(NGEOM).EQ.2).OR.(INT(NGEOM).EQ.4))THEN
       ANU=0.37*RE**0.6
      ENDIF
      IF(INT(NGEOM).EQ.3)THEN
C      FORCED CONVECTION FOR A PLATE (AS USED BY PHILLIPS & HEATH 1992, 
C      GATES EQN. 9.49, ASSUMES TURBULENT FLOW)
        ANU = 0.032*RE**0.8
      ENDIF
      NUFORCED = ANU
      
C  **************************************************************************

C     CALCULATING THE HEAT TRANSFER COEFFICIENT, HC  (NU=HC*D/KAIR)
c      HC=(NUFORCED*THCOND)/D
      
C     CALCULATING THE CONVECTIVE HEAT LOSS

CC     DIFFERENT QFORCED DEPENDING ON WHETHER THERE IS FUR OR NOT
C     IF(ZFUR.LE.0.000001)THEN
CC      NO FUR, HEAT LOSS FROM SKIN
C      QFORCED = HC * SURFAR * (TS - TENV)
C     ELSE
CC      FUR/FEATHERS PRESENT, HEAT LOSS FROM FUR/AIR INTERFACE
C      QFORCED= HC * SURFAR * (TFA-TENV)
C     ENDIF

C     USING BIRD, STEWART, & LIGHTFOOT'S MIXED CONVECTION FORMULA (P. 445, TRANSPORT PHENOMENA, 2002)
      NUTOTAL = (NUFREE**3. + NUFORCED**3.)**(1./3.)
      HCCOMB = NUTOTAL*(THCOND/D)

C     DIFFERENT QCONV DEPENDING ON WHETHER THERE IS FUR OR NOT
      IF(ZFUR.LE.0.000001)THEN
C      NO FUR, HEAT LOSS FROM SKIN
       QCONV = HCCOMB * SURFAR * (TS - TENV)
      ELSE
C      FUR/FEATHERS PRESENT, HEAT LOSS FROM FUR/AIR INTERFACE
       QCONV= HCCOMB * SURFAR * (TFA-TENV)
      ENDIF
      
C     CALCULATING THE SHERWOOD NUMBER FROM THE COLBURN ANALOGY
C     (BIRD, STEWART & LIGHTFOOT, 1960. TRANSPORT PHENOMENA. WILEY.
C     NOTE:  THIS IS THE SAME AS HD = (HC*(CP*RHO))*(PR/SC)**(2/3), WHERE CP IS FOR DRY AIR AND RHO IS FOR MOIST AIR.
      SH =NUFORCED * (SC/PR)**.333
C     CALCULATING THE MASS TRANSFER COEFFICIENT FROM THE SHERWOOD NUMBER; FORCED ONLY
      HDFORC=SH*DIFVPR/D
C     COMBINED FORCED & FREE
      HD=HDFORC+HDFREE
      
      RESULTS = (/QCONV,HCCOMB,HCFREE,HCFOR,HD,HDFREE,HDFORC,ANU,
     &RE,GR,PR,RA,SC,BP/) 
      RETURN
      END