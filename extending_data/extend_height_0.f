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


C     Grid dimensions
      integer :: NX, NY
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


      subroutine get_args(ARGSOK, FILE_NAME
     &  , ifstdopt, prefixopt)
      implicit none
      logical, intent(inout) :: ARGSOK
C     This is the name of the data file we will read. 
      !character*(*) FILE_NAME
      !!parameter (FILE_NAME='height.nc')
      !character*400, intent(out) :: FILE_NAME
      character*(*) :: FILE_NAME
      logical, intent(out) :: ifstdopt
      character*(*), intent(out) :: prefixopt

C     !--- Local ---
C     Data file to read in and write over
      character*400 :: FILE_INOUT
C     Number of arguments at command line
      integer :: NARGS
C     Grid dimension command line argument (optional)
      character(500) :: dimarg
      integer :: IM, JM
C     Standard deviation additional command line argument (optional, but required if Prefix specified)
C     n-no, s-yes, extend std dev and write to the output file.
      character :: optstd
C     Prefix to output variable (optional, but requires ifstdev to be specified)
C     In some versions of the HITEent file, the array names are 'hgt_<pft>' and in some there is no 'hgt_' prefix.
      character :: optprefix 
      
C     Get file to read and write from command line
      ARGSOK = .false.
      NARGS = iargc()
      if (NARGS.lt.3) then
         WRITE(*,*) 'Usage: ./extend_height filein IM JM <optional s>'
         write(*,*) '  filein: HITEent netcdf file name, max 400 char'
         write(*,*) '  IM: longitudinal grid cells '
     &     //'(e.g. 144 for 2.5 degrees, 720 for 0.5 degrees)'
         write(*,*) '  JM: latitudinal grid cells '
     &     // '(e.g. 90 for 2 degrees, 360 for 0.5 degrees)'
         write(*,*) '   s: optional to process standard deviations'
         write(*,*) 'Result: Outputs version of HITEent file'
     &    // ' with values extended across coastlines.'
         write(*,*) 'WARNING: Overwrites input file with ext content!'
         RETURN
      endif
      call getarg(1,FILE_INOUT)
      call getarg(2, dimarg)
      IM = NCNVRT(dimarg)
      call getarg(3, dimarg)
      JM = NCNVRT(dimarg)
      write(*,*) 'Input/output file: ',trim(FILE_INOUT)
      write(*,*)  IM, JM

      if (NARGS.gt.3) then
        call getarg(4, optstd)
        if ((optstd.ne.'s').or.(optstd.ne.'n')) then
          write(*,*) "optstd: ",optstd
     &     , "not recognized"
          RETURN
        endif
      endif

      optprefix = ''
      if (NARGS.gt.4) then
        call getarg(5, optprefix)
        write(*,*) "optprefix: ",optprefix
      endif

      ARGSOK=.true.
      FILE_NAME = FILE_INOUT
      NX = IM
      NY = JM
      ifstdopt = optstd.eq.'s'
      prefixopt = trim(optprefix)

      write(*,*) ARGSOK, FILE_NAME, NX, NY, ifstdopt, prefixopt
      end subroutine get_args


C-------------------------------------------------

      subroutine extend_veg(ncid,
     &  prefix)
      implicit none
      include 'netcdf.inc'
C     This will be the netCDF ID for the file and data variable.
      integer, intent(in) :: ncid
      character*(*) :: prefix

      !real*4 data_in(NX, NY, N_COVERTYPES)
      real*4, ALLOCATABLE :: data_in(:, :, :) !dim=(NX, NY, N_COVERTYPES)

      integer varid

C     Loop indexes, and error handling.
      integer x, y, retval, n, iter, s, sx, k

      allocate(data_in(NX, NY, N_COVERTYPES))

      do n=1,N_COVERTYPES
C       Get the varid of the data variable, based on its name.
        write(*,*) trim(prefix)//ent_cover_names(n)
        retval = nf_inq_varid(ncid,  trim(prefix)
     &              //ent_cover_names(n), varid)
        if (retval .ne. nf_noerr) call handle_err(retval)

C       Read the data.
        retval = nf_get_var_real( ncid, varid, data_in(:,:,n) )
        if (retval .ne. nf_noerr) call handle_err(retval)
      enddo

C     Check the data.
      do k=1,N_COVERTYPES-2
      do iter =1, NX
      do x = 1, NX
         do y = 1, NY
           s = mod(iter,2)*2 - 1
           sx = mod(x,2)*2 - 1
           sx = sx*s
            !print *, x, y, data_in(x,y)
            if ( data_in(x,y,k)  < .0001 ) then
              if ( try_n( data_in(:,:,k), x, y, 1, 0) ) cycle
              if ( try_n( data_in(:,:,k), x, y, -sx, 0) ) cycle
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
            if ( data_in(x,y,k)  < .0001 ) then
              if ( try_n( data_in(:,:,k), x, y, 1, 0) ) cycle
              if ( try_n( data_in(:,:,k), x, y, -sx, 0) ) cycle
              if ( try_n( data_in(:,:,k), x, y, 0, s) ) cycle
              if ( try_n( data_in(:,:,k), x, y, 0, -s) ) cycle
            endif
         end do
      end do
      end do

      enddo ! k



      do n=1,N_COVERTYPES
        retval = nf_inq_varid(ncid,  
     &        trim(prefix)//ent_cover_names(n), varid)
        if (retval .ne. nf_noerr) call handle_err(retval)
        
        retval = nf_put_var_real( ncid, varid, data_in(:,:,n) )
        if (retval .ne. nf_noerr) call handle_err(retval)
      enddo


      deallocate(data_in)
      end subroutine extend_veg



      logical function try_n( f, i, j, di, dj)
      implicit none
      real*4 f(NX, NY)
      integer :: i, j, di, dj
      integer x, y

      try_n = .false.

      x = mod(i+di-1 +NX, NX) + 1
      y = mod(j+dj-1 +NY, NY) + 1

      if ( f(x,y) > .0001 ) then
        f(i,j) = f(x,y)
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
      implicit none
      include 'netcdf.inc'

      logical :: ifstdev
      logical :: ARGSOK
C     This is the name of the data file we will read. 
      !character*(*) FILE_NAME
      !!parameter (FILE_NAME='height.nc')
      character*400 :: FILE_NAME
C     User options
      logical :: ifstdopt
      character*400 :: prefixopt
C     Necdf and error flags
      integer :: ncid, retval

      call get_args(ARGSOK, FILE_NAME
     &  ,ifstdopt, prefixopt)

      if (ARGSOK) then
       
C       Open the file. NF_NOWRITE tells netCDF we want read-only access to
C       the file.
        retval = nf_open(trim(FILE_NAME), NF_WRITE, ncid)
        if (retval .ne. nf_noerr) call handle_err(retval)

        write(*,*) 'nf_open retval: ', retval
 
!        call extend_veg("hgt_")
        call extend_veg(ncid, prefixopt)

        write(*,*) 'ifstdev: ', ifstdev
        if (ifstdev) then
          call extend_veg(ncid, "stdev_")
        endif

C       Close the file, freeing all resources.
        retval = nf_close(ncid)
        if (retval .ne. nf_noerr) call handle_err(retval)
        print *,'*** Read  ', trim(FILE_NAME)
        print *,'*** Wrote ', trim(FILE_NAME)

      endif
      end

