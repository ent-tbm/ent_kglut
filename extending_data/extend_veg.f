!Author:  Igor Aleinov, Nancy Kiang

      module extend_veg_mod
      implicit none

      integer, parameter :: N_COVERTYPES = 18

      character(len=13), parameter :: ent_cover_names(N_COVERTYPES) = (/
     &     "ever_br_early",
     &     "ever_br_late ",
     &     "ever_nd_early",
     &     "ever_nd_late ",
     &     "cold_br_early",
     &     "cold_br_late ",
     &     "drought_br   ",
     &     "decid_nd     ",
     &     "cold_shrub   ",
     &     "arid_shrub   ",
     &     "c3_grass_per ",
     &     "c4_grass     ",
     &     "c3_grass_ann ",
     &     "c3_grass_arct",
     &     "crops_herb   ",
     &     "crops_woody  ",
     &     "bare_bright  ",
     &     "bare_dark    "
     &     /)

      integer NX, NY
      !parameter (NX = 144, NY = 90) 

      contains

      integer FUNCTION NCNVRT(ARG)
      implicit none
      CHARACTER*500 :: ARG
      integer :: I
      I=0
 10   I=I+1
      IF(ARG(I:I).EQ.' ') GO TO 10
      IF(ARG(I:I).EQ.'-'.OR.ARG(I:I).EQ.'+') I=I+1
      NCNVRT=-999
 20   IF(ARG(I:I).LT.'0'.OR.ARG(I:I).GT.'9') RETURN
      I=I+1
      IF(ARG(I:I).NE.' ') GO TO 20
      READ(ARG,*) NCNVRT
      IF(NCNVRT.LT.0) NCNVRT=-1
      !RETURN
      END function NCNVRT

      subroutine extend_veg
      implicit none
      include 'netcdf.inc'

C     This is the name of the data file we will read. 
      !character*(*) FILE_NAME
      !parameter (FILE_NAME='veg.nc')
      character*400 :: FILE_NAME

      !real*4 data_in(NX, NY, N_COVERTYPES)
      real*4, ALLOCATABLE :: data_in(:, :, :) !dim=(NX, NY, N_COVERTYPES)

C     This will be the netCDF ID for the file and data variable.
      integer ncid, varid

C     Loop indexes, and error handling.
      integer x, y, retval, n, iter, s, sx

C     Number of arguments at command line
      integer :: NARGS
      character(500) :: dimarg

C     Get file to read and write from command line
      NARGS = iargc()
      if (NARGS.lt.3) then
         WRITE(*,*) 'Usage: extend_veg filein IM JM'
         write(*,*) '  filein: VEG netcdf file name, max 400 char'
         write(*,*) '  IM: longitudinal grid cells '
     &     //'(e.g. 144 for 2.5 degrees, 720 for 0.5 degrees)'
         write(*,*) '  JM: latitudinal grid cells '
     &     // '(e.g. 90 for 2 degrees, 360 for 0.5 degrees)'
         write(*,*) 'Result: Outputs version of VEG file'
     &    // ' with values extended across coastlines.'
         write(*,*) 'WARNING: Overwrites input file with ext content!'
         RETURN
      endif
      call getarg(1,FILE_NAME)
      call getarg(2, dimarg)
      NX = NCNVRT(dimarg)
      call getarg(3, dimarg)
      NY = NCNVRT(dimarg)
      write(*,*) 'Inputs: ',trim(FILE_NAME)
      write(*,*)  NX, NY

      allocate(data_in(NX, NY, N_COVERTYPES))

C     Open the file. NF_NOWRITE tells netCDF we want read-only access to
C     the file.
      retval = nf_open(FILE_NAME, NF_WRITE, ncid)
      if (retval .ne. nf_noerr) call handle_err(retval)

      do n=1,N_COVERTYPES
C       Get the varid of the data variable, based on its name.
        retval = nf_inq_varid(ncid,  ent_cover_names(n), varid)
        if (retval .ne. nf_noerr) call handle_err(retval)

C       Read the data.
        retval = nf_get_var_real( ncid, varid, data_in(:,:,n) )
        if (retval .ne. nf_noerr) call handle_err(retval)
      enddo

C     Check the data.
      do iter =1, NX
      do x = 1, NX
         do y = 1, NY
           s = mod(iter,2)*2 - 1
           sx = mod(x,2)*2 - 1
           sx = sx*s
            !print *, x, y, data_in(x,y)
            if ( sum( data_in(x,y,:) ) < .999 ) then
              if ( try_n( data_in, x, y, 1, 0) ) cycle
              if ( try_n( data_in, x, y, -sx, 0) ) cycle
              !if ( try_n( data_in, x, y, 0, s) ) cycle
              !if ( try_n( data_in, x, y, 0, -s) ) cycle
            endif
         end do
      end do
      end do

! repeat with S-N mixing
      do iter =1, NX
      do x = 1, NX
         do y = 1, NY
           s = mod(iter,2)*2 - 1
           sx = mod(x,2)*2 - 1
           sx = sx*s
            !print *, x, y, data_in(x,y)
            if ( sum( data_in(x,y,:) ) < .999 ) then
              if ( try_n( data_in, x, y, 1, 0) ) cycle
              if ( try_n( data_in, x, y, -sx, 0) ) cycle
              if ( try_n( data_in, x, y, 0, s) ) cycle
              if ( try_n( data_in, x, y, 0, -s) ) cycle
            endif
         end do
      end do
      end do



      do n=1,N_COVERTYPES
        retval = nf_inq_varid(ncid,  ent_cover_names(n), varid)
        if (retval .ne. nf_noerr) call handle_err(retval)
        
        retval = nf_put_var_real( ncid, varid, data_in(:,:,n) )
        if (retval .ne. nf_noerr) call handle_err(retval)
      enddo

C     Close the file, freeing all resources.
      retval = nf_close(ncid)
      if (retval .ne. nf_noerr) call handle_err(retval)

      print *,'*** Read  ', trim(FILE_NAME)
      print *,'*** Wrote ', trim(FILE_NAME)

      deallocate(data_in)
      end subroutine extend_veg



      logical function try_n( f, i, j, di, dj)
      implicit none
      real*4 f(NX, NY, N_COVERTYPES)
      integer :: i, j, di, dj
      integer x, y

      try_n = .false.

      x = mod(i+di-1 +NX, NX) + 1
      y = mod(j+dj-1 +NY, NY) + 1

      if ( sum( f(x,y,:) ) > .999 ) then
        f(i,j,:) = f(x,y,:)
        try_n = .true.
      endif

      end function try_n

      subroutine handle_err(errcode)
      implicit none
      include 'netcdf.inc'
      integer errcode

      print *, 'Error: ', nf_strerror(errcode)
      stop 2

      end subroutine handle_err

      end module extend_veg_mod

      program foo

      use extend_veg_mod

      call extend_veg

      end

