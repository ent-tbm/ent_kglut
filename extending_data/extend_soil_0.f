! @auth @contact James Lui, james.lui@nasa.gov
! @contact Igor Aleinov, Nancy Kiang
! gfortran -cpp -fconvert=big-endian -O0 -fno-range-check -I$NETCDFHOME/include -mcmodel=large -c extend_soil_0.f
! gfortran extend_soil_0.o -L$NETCDFHOME/lib -lnetcdf -lnetcdff -o extend_soil_0
!
! Fill value/missing value is expected to be negative

      module extend_soil_mod
      implicit none

      integer, parameter :: ngm = 6, imt = 5

      integer, parameter :: d2X2H = 1, dHXH = 2, dQXQ = 3

      integer :: nx = 144, ny = 90

      contains

      subroutine extend_soil(FILE_NAME)!, resolution)
      implicit none
      include 'netcdf.inc'

C     This is the name of the data file we will read. 
      character(len=*), intent(in) :: FILE_NAME

      real*4, allocatable ::  data_in(:,:,:,:)
      real*4 checksum

C     This will be the netCDF ID for the file and data variable.
      integer ncid, varid

C     Loop indexes, and error handling.
      integer x, y, retval, n, iter, s, sx, k, l

C     Open the file. NF_NOWRITE tells netCDF we want read-only access to
C     the file.
      retval = nf_open(FILE_NAME, NF_WRITE, ncid)
      if (retval .ne. nf_noerr) call handle_err(retval)

C     Get dimensions of the file
      retval = nf_inq_dimid(ncid, 'lon', varid)
      if (retval .ne. nf_noerr) call handle_err(retval)
      retval = nf_inq_dimlen(ncid, varid, nx)
      
      retval = nf_inq_dimid(ncid, 'lat', varid)
      if (retval .ne. nf_noerr) call handle_err(retval)
      retval = nf_inq_dimlen(ncid, varid, ny)

C     Get the varid of the data variable, based on its name.
      retval = nf_inq_varid(ncid, 'q', varid)
      if (retval .ne. nf_noerr) call handle_err(retval)

      write(*,*) "resolution of selected: ", nx, ny

      allocate(data_in(NX, NY, imt, ngm))

C     Read the data.
      retval = nf_get_var_real( ncid, varid, data_in(:,:,:,:) )
      if (retval .ne. nf_noerr) call handle_err(retval)

C     Check the data.
      do l=1,ngm
      do k=1,imt
      do iter =1, NX
      do x = 1, NX
         do y = 1, NY
           s = mod(iter,2)*2 - 1
           sx = mod(x,2)*2 - 1
           sx = sx*s
            !print *, x, y, data_in(x,y)
            if ( data_in(x,y,k,l)  < 0d0 .or.
     &        data_in(x,y,k,l) .ne. data_in(x,y,k,l) ) then
              if ( try_n( data_in(:,:,k,l), x, y, 1, 0) ) cycle
              if ( try_n( data_in(:,:,k,l), x, y, -sx, 0) ) cycle
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
            if ( data_in(x,y,k,l)  < 0d0 .or.
     &        data_in(x,y,k,l) .ne. data_in(x,y,k,l) ) then
              if ( try_n( data_in(:,:,k,l), x, y, 1, 0) ) cycle
              if ( try_n( data_in(:,:,k,l), x, y, -sx, 0) ) cycle
              if ( try_n( data_in(:,:,k,l), x, y, 0, s) ) cycle
              if ( try_n( data_in(:,:,k,l), x, y, 0, -s) ) cycle
            endif
         end do
      end do
      end do

      enddo ! k
        do x = 1, NX
        do y = 1, NY
          checksum = sum(data_in(x,y,:,l))
          if (checksum .gt. 1.001 .or. checksum .le. .999) then
            write(*,*) 'WARNING: total does not sum to 1'
            write(*,*) 'i, j, layer, sum: ', x, y, l, checksum
          end if
        end do
        end do
      enddo ! l



      retval = nf_inq_varid(ncid,  'q', varid)
      if (retval .ne. nf_noerr) call handle_err(retval)
        
      retval = nf_put_var_real( ncid, varid, data_in(:,:,:,:) )
      if (retval .ne. nf_noerr) call handle_err(retval)
      
C copy to qk as well
      retval = nf_inq_varid(ncid,  'qk', varid)
      if (retval .ne. nf_noerr) call handle_err(retval)
        
      retval = nf_put_var_real( ncid, varid, data_in(:,:,:,:) )
      if (retval .ne. nf_noerr) call handle_err(retval)

C     Close the file, freeing all resources.
      retval = nf_close(ncid)
      if (retval .ne. nf_noerr) call handle_err(retval)

      print *,'*** SUCCESS reading example file ', FILE_NAME, '!'
      end subroutine extend_soil



      logical function try_n( f, i, j, di, dj)
      implicit none
      real*4 f(NX, NY)
      integer :: i, j, di, dj
      integer x, y

      try_n = .false.

      x = mod(i+di-1 +NX, NX) + 1
      y = mod(j+dj-1 +NY, NY) + 1

      if ( f(x,y) .ge. 0d0 ) then
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

      end module extend_soil_mod

      program foo

      use extend_soil_mod
        implicit none

c      call extend_soil
      character(len=128) :: infile
      character(:), allocatable :: trimmedfile, outfile

      write(*,*) "Input name of soil file"
      read(*,*) infile

      trimmedfile = trim(infile)
      if( trimmedfile(len(trimmedfile)-2:) .ne. '.nc') then
        write(*,*) trimmedfile, " is not a netcdf file"
        stop 3
      endif

      outfile = trimmedfile(:len(trimmedfile)-3)//'_ext.nc'
      write(*,*) "Copying to ", outfile
      call system("cp "//trimmedfile//" "//outfile)
       
      call extend_soil(outfile)

      end program foo

