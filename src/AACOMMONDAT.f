      MODULE AACOMMONDAT

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

C     DEFINES DYNAMICALLY VARYING ARRAYS AND VECTORS

      IMPLICIT NONE
      
      INTEGER, ALLOCATABLE, PUBLIC :: BEHAV_STAGES(:,:),DAYDOY(:)
      
      DOUBLE PRECISION, ALLOCATABLE, PUBLIC :: ARRHENIUS(:,:),
     & ARRHENIUS2(:,:),DAY(:),FOODLEVELS(:),FOODWATERS(:),L_INSTAR(:)
     & ,MAXSHADES(:),MINSHADES(:),NUTRI_STAGES(:,:),POND_ENV(:,:,:,:)
     & ,RAINFALL2(:),RAINHR(:),PRESHR(:),S_INSTAR(:),TBS(:)
     & ,THERMAL_STAGES(:,:),TRANSIENT(:),WATER_STAGES(:,:)
     & ,WETLANDDEPTHS(:),WETLANDTEMPS(:),XP(:),YP(:),ZD1(:),ZD2(:)
     & ,ZD3(:),ZD4(:),ZD5(:),ZD6(:),ZD7(:),ZP1(:),ZP2(:),ZP3(:),ZP4(:)
     & ,ZP5(:),ZP6(:),ZP7(:),FEC(:),SURV(:),ACT(:),FOR(:),LX(:),MX(:)
     
      END MODULE AACOMMONDAT

