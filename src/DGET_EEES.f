      SUBROUTINE DGET_EEES(N,A,EEES,DEEES,RPAR,IPAR)

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

C     EQUATIONS TO COMPUTE RATES OF CHANGE IN RESERVE, REPRODUCTION BUFFER, 
C     EGG BATCH BUFFER AND STOMACH ENERGY FOR AN INSECT IMAGO

      IMPLICIT NONE
      INTEGER IPAR,N,BREED
      DOUBLE PRECISION A,EEES,DEEES,DE,DER,DEB,DES,E,E_B,E_R,E_S,E_SM
      DOUBLE PRECISION F,F2,K,K_E,KAP,KAP_X,KAP_R,P_A,P_AM,P_C
      DOUBLE PRECISION P_CR,P_J,P_M,P_R,P_X,P_XM,RPAR,V,X
      DIMENSION EEES(N),DEEES(N),IPAR(13),RPAR(16)

      F=RPAR(1)
      K_E=RPAR(2)
      P_J=RPAR(3)
      P_AM=RPAR(4)
      P_M=RPAR(5)
      P_A=RPAR(6)
      KAP=RPAR(7)
      P_XM=RPAR(8)
      X=RPAR(9)
      K=RPAR(10)
      F2=RPAR(11)
      KAP_X=RPAR(12)
      KAP_R=RPAR(13)
      V=RPAR(14)
      E_SM=RPAR(15)
      BREED=IPAR(1)
      A = EEES(1)
      E = EEES(2)   ! J, RESERVES OF THE IMAGO
      E_R = EEES(3) ! J, REPRODUCTION BUFFER
      E_B = EEES(4) ! J, EGG BATCH BUFFER
      E_S = MAX(0.,EEES(5)) ! J, ENERGY OF THE STOMACH
      
      P_C = E * K_E             ! J/TIME, RESERVE MOBILISATION
      P_R = P_C - P_M - P_J     ! J/TIME, ENERGY ALLOCATION FROM RESERVE TO E_R
      P_X = P_XM * ((X / K) / (F2 + X / K)) * V ** (2. / 3.) ! J/TIME, FOOD ENERGY INTAKE RATE
      IF(BREED.EQ.1)THEN
       !P_CR = KAP_R * E_R * K_E ! J/H, DRAIN FROM E_R TO EGGS
       P_CR = KAP_R * P_R! J/H, DRAIN FROM E_R TO EGGS
      ELSE
       P_CR = 0.D+00
      ENDIF
      IF(E_S .LT. P_A)THEN      ! NO ASSIMILATION IF STOMACH TOO EMPTY
       DE = MAX(0., E_S) - P_C           ! J/TIME, CHANGE IN RESERVE
      ELSE
       DE = F * P_AM * V - P_C  ! J/TIME, CHANGE IN RESERVE
      ENDIF      
      DER = MAX(0.0D0, P_R - P_CR) ! J/TIME, CHANGE IN REPROD BUFFER
      DEB = P_CR                ! J/TIME, CHANGE IN EGG BUFFER
      DES = P_X - F * (P_AM / KAP_X) * V! J/TIME, CHANGE IN STOMACH ENERGY

      DEEES(1)=1.0D+00
      DEEES(2)=DE
      DEEES(3)=DER
      DEEES(4)=DEB
      DEEES(5)=DES

      RETURN
      END