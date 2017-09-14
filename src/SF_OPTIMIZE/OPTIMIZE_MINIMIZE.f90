MODULE OPTIMIZE_MINIMIZE
  USE CGFIT_ROUTINES
  implicit none
  private

  interface fmin_cg
     module procedure fmin_cg_df,fmin_cg_f
  end interface fmin_cg

  interface fmin_cgplus
     module procedure fmin_cgplus_df,fmin_cgplus_f
  end interface fmin_cgplus

  interface fmin_cgminimize
     module procedure fmin_cgminimize_func,fmin_cgminimize_sub
  end interface fmin_cgminimize

  interface dbrent
     module procedure :: dbrent_wgrad
     module procedure :: dbrent_nograd
  end interface dbrent


  !General-purpose
  ! public :: fmin         !Minimize a function using the downhill simplex algorithm.
  ! public :: fmin_powell  !Minimize a function using modified Powell’s method. This method
  public :: fmin_cg
  public :: fmin_cgplus
  public :: fmin_cgminimize
  ! public :: fmin_bfgs    !Minimize a function using the BFGS algorithm.
  ! public :: fmin_ncg     !Unconstrained minimization of a function using the Newton-CG method.
  ! public :: leastsq      !Minimize the sum of squares of a set of equations. a wrapper around MINPACKs lmdif and lmder algorithms.


  !Global
  ! public :: anneal       !Minimize a function using simulated annealing.
  ! public :: basinhopping ! Find the global minimum of a function using the basin-hopping algorithm ..


  !Scalar function minimizers
  public :: brent         !minimize a given a function of one-variable with a possible bracketing interval without using derivative information
  public :: dbrent        !minimize a given a function of one-variable with a possible bracketing interval  using derivative information
  public :: bracket       !Bracket the minimum of the function.





contains





  !+-------------------------------------------------------------------+
  !PURPOSE  : 
  ! Given a function f, and given a bracketing triplet of abscissas
  ! ax, bx, cx (such that bx is between ax and cx, and f(bx) is less
  ! than both f(ax) and f(cx)), this routine isolates the minimum to a
  ! fractional precision of about tol using Brent’s method. The abscissa
  ! of the minimum is returned as xmin, and the minimum function value
  ! is returned as brent, the returned function value.
  ! Parameters: Maximum allowed number of iterations; golden ratio;
  ! and a small number that protects against trying to achieve
  ! fractional accuracy for a minimum that happens to be exactly zero.
  !+-------------------------------------------------------------------+
  subroutine brent(func,xmin,brack,tol,niter)
    interface
       function func(x)
         real(8) :: x
         real(8) :: func
       end function func
    end interface
    real(8),intent(inout)         :: xmin
    real(8),dimension(:),optional :: brack
    real(8),optional              :: tol
    integer,optional              :: niter
    real(8)                       :: tol_
    integer                       :: niter_
    integer                       :: iter
    real(8)                       :: ax,xx,bx,fa,fx,fb,fret
    !
    tol_=1d-9;if(present(tol))tol_=tol
    Niter_=200;if(present(Niter))Niter_=Niter
    !
    if(present(brack))then
       select case(size(brack))
       case(1)
          stop "Brent error: calling brent with size(brack)==1. None or two points are necessary."
       case(2)
          ax = brack(1)
          xx = brack(2)
          call bracket(ax,xx,bx,fa,fx,fb,func)
       case (3)
          ax = brack(1)
          xx = brack(2)
          bx = brack(3)
       end select
    else
       ax=0d0
       xx=1d0
       call bracket(ax,xx,bx,fa,fx,fb,func)
    endif
    fret=brent_optimize(ax,xx,bx,func,tol_,niter_,xmin)
  end subroutine brent
  !

  !
  function brent_optimize(ax,bx,cx,func,tol,itmax,xmin)
    real(8), intent(in)  :: ax,bx,cx,tol
    real(8), intent(out) :: xmin
    real(8)              :: brent_optimize
    integer              :: itmax
    real(8), parameter   :: cgold=0.3819660d0,zeps=1.0d-3*epsilon(ax)
    integer              :: iter
    real(8)              :: a,b,d,e,etemp,fu,fv,fw,fx,p,q,r,tol1,tol2,u,v,w,x,xm
    interface
       function func(x)
         real(8) :: x
         real(8) :: func
       end function func
    end interface
    a=min(ax,cx)
    b=max(ax,cx)
    v=bx
    w=v
    x=v
    e=0.d0
    fx=func(x)
    fv=fx
    fw=fx
    do iter=1,itmax
       xm=0.5d0*(a+b)
       tol1=tol*abs(x)+zeps
       tol2=2.0*tol1
       if (abs(x-xm) <= (tol2-0.5d0*(b-a))) then
          xmin=x
          brent_optimize=fx
          return
       end if
       if (abs(e) > tol1) then
          r=(x-w)*(fx-fv)
          q=(x-v)*(fx-fw)
          p=(x-v)*q-(x-w)*r
          q=2.d0*(q-r)
          if (q > 0.d0) p=-p
          q=abs(q)
          etemp=e
          e=d
          if (abs(p) >= abs(0.5d0*q*etemp) .or. &
               p <= q*(a-x) .or. p >= q*(b-x)) then
             e=merge(a-x,b-x, x >= xm )
             d=cgold*e
          else
             d=p/q
             u=x+d
             if (u-a < tol2 .or. b-u < tol2) d=sign(tol1,xm-x)
          end if
       else
          e=merge(a-x,b-x, x >= xm )
          d=cgold*e
       end if
       u=merge(x+d,x+sign(tol1,d), abs(d) >= tol1 )
       fu=func(u)
       if (fu <= fx) then
          if (u >= x) then
             a=x
          else
             b=x
          end if
          call shft(v,w,x,u)
          call shft(fv,fw,fx,fu)
       else
          if (u < x) then
             a=u
          else
             b=u
          end if
          if (fu <= fw .or. w == x) then
             v=w
             fv=fw
             w=u
             fw=fu
          else if (fu <= fv .or. v == x .or. v == w) then
             v=u
             fv=fu
          end if
       end if
    end do
    !pause 'brent: exceed maximum iterations'
  contains
    subroutine shft(a,b,c,d)
      real(8), intent(out) :: a
      real(8), intent(inout) :: b,c
      real(8), intent(in) :: d
      a=b
      b=c
      c=d
    end subroutine shft
  end function brent_optimize






  !+-------------------------------------------------------------------+
  !PURPOSE  : 
  !  Given a function f and its derivative function df, and given a
  !  bracketing triplet of abscissas ax, bx, cx [such that bx is between
  !  ax and cx, and f(bx) is less than both f(ax) and f(cx)], this
  !  routine isolates the minimum to a fractional precision of about
  !  tol using a modification of Brent’s method that uses derivatives.
  !  The abscissa of the minimum is returned as xmin, and the minimum
  !  function value is returned as dbrent, the returned function value.
  !+-------------------------------------------------------------------+ 
  subroutine dbrent_wgrad(func,dfunc,xmin,brack,tol,niter)
    interface
       function func(x)
         real(8) :: x
         real(8) :: func
       end function func
       function dfunc(x)
         real(8) :: x
         real(8) :: dfunc
       end function dfunc
    end interface
    real(8),intent(inout)         :: xmin
    real(8),dimension(:),optional :: brack
    real(8),optional              :: tol
    integer,optional              :: niter
    real(8)                       :: tol_
    integer                       :: niter_
    integer                       :: iter
    real(8)                       :: ax,xx,bx,fa,fx,fb,fret
    !
    tol_=1d-9;if(present(tol))tol_=tol
    Niter_=200;if(present(Niter))Niter_=Niter
    !
    if(present(brack))then
       select case(size(brack))
       case(1)
          stop "Brent error: calling brent with size(brack)==1. None or two points are necessary."
       case(2)
          ax = brack(1)
          xx = brack(2)
          call bracket(ax,xx,bx,fa,fx,fb,func)
       case (3)
          ax = brack(1)
          xx = brack(2)
          bx = brack(3)
       end select
    else
       ax=0d0
       xx=1d0
       call bracket(ax,xx,bx,fa,fx,fb,func)
    endif
    fret=dbrent_optimize(ax,xx,bx,func,dfunc,tol_,niter_,xmin)
  end subroutine dbrent_wgrad
  !
  subroutine dbrent_nograd(func,xmin,brack,tol,niter)
    interface
       function func(x)
         real(8) :: x
         real(8) :: func
       end function func
    end interface
    real(8),intent(inout)         :: xmin
    real(8),dimension(:),optional :: brack
    real(8),optional              :: tol
    integer,optional              :: niter
    real(8)                       :: tol_
    integer                       :: niter_
    integer                       :: iter
    real(8)                       :: ax,xx,bx,fa,fx,fb,fret
    !
    tol_=1d-9;if(present(tol))tol_=tol
    Niter_=200;if(present(Niter))Niter_=Niter
    !
    if(present(brack))then
       select case(size(brack))
       case(1)
          stop "Brent error: calling brent with size(brack)==1. None or two points are necessary."
       case(2)
          ax = brack(1)
          xx = brack(2)
          call bracket(ax,xx,bx,fa,fx,fb,func)
       case (3)
          ax = brack(1)
          xx = brack(2)
          bx = brack(3)
       end select
    else
       ax=0d0
       xx=1d0
       call bracket(ax,xx,bx,fa,fx,fb,func)
    endif
    fret=dbrent_optimize(ax,xx,bx,func,dfunc,tol_,niter_,xmin)
  contains
    function dfunc(x)
      real(8) :: x
      real(8) :: dfunc
      call fgradient_func(func,x,dfunc)
    end function dfunc
    !
    subroutine fgradient_func(funcv,x,fjac,epsfcn)
      implicit none
      interface 
         function funcv(x)
           real(8) :: x
           real(8) :: funcv
         end function funcv
      end interface
      integer          ::  n
      real(8),intent(in) ::  x
      real(8)            ::  x_
      real(8)          ::  fvec
      real(8)          ::  fjac
      real(8),optional ::  epsfcn
      real(8)          ::  eps,eps_
      real(8)          ::  epsmch
      real(8)          ::  h,temp
      real(8)          ::  wa1
      real(8)          ::  wa2
      integer          :: i,j,k
      x_ = x
      eps_= 0.d0; if(present(epsfcn))eps_=epsfcn
      epsmch = epsilon(epsmch)
      eps  = sqrt(max(eps_,epsmch))
      !  Evaluate the function
      fvec = funcv(x_)
      temp = x_
      h    = eps*abs(temp)
      if(h==0d0) h = eps
      x_   = temp + h
      wa1  = funcv(x_)
      x_   = temp
      fjac = (wa1 - fvec)/h
    end subroutine fgradient_func
  end subroutine dbrent_nograd



  function dbrent_optimize(ax,bx,cx,func,fjac,tol,itmax,xmin) result(dbrent)
    real(8),intent(in)  :: ax,bx,cx,tol
    real(8),intent(out) :: xmin
    real(8)             :: dbrent
    integer             :: itmax
    real(8), parameter  :: zeps=1.d-3*epsilon(ax)
    integer             :: iter
    real(8)             :: a,b,d,d1,d2,du,dv,dw,dx,e,fu,fv,fw,fx,olde,tol1,tol2
    real(8)             :: u,u1,u2,v,w,x,xm
    logical             :: ok1,ok2
    interface
       function func(x)
         real(8) :: x
         real(8) :: func
       end function func
       function fjac(x)
         real(8) :: x
         real(8) :: fjac
       end function fjac
    end interface
    a=min(ax,cx)
    b=max(ax,cx)
    v=bx
    w=v
    x=v
    e=0.d0
    fx=func(x)
    fv=fx
    fw=fx
    dx=fjac(x)
    dv=dx
    dw=dx
    do iter=1,ITMAX
       xm=0.5d0*(a+b)
       tol1=tol*abs(x)+ZEPS
       tol2=2.0d0*tol1
       if (abs(x-xm) <= (tol2-0.5d0*(b-a))) exit
       if (abs(e) > tol1) then
          d1=2.0d0*(b-a)
          d2=d1
          if (dw /= dx) d1=(w-x)*dx/(dx-dw)
          if (dv /= dx) d2=(v-x)*dx/(dx-dv)
          u1=x+d1
          u2=x+d2
          ok1=((a-u1)*(u1-b) > 0.d0) .and. (dx*d1 <= 0.d0)
          ok2=((a-u2)*(u2-b) > 0.d0) .and. (dx*d2 <= 0.d0)
          olde=e
          e=d
          if (ok1 .or. ok2) then
             if (ok1 .and. ok2) then
                d=merge(d1,d2, abs(d1) < abs(d2))
             else
                d=merge(d1,d2,ok1)
             end if
             if (abs(d) <= abs(0.5d0*olde)) then
                u=x+d
                if (u-a < tol2 .or. b-u < tol2) &
                     d=sign(tol1,xm-x)
             else
                e=merge(a,b, dx >= 0.d0)-x
                d=0.5d0*e
             end if
          else
             e=merge(a,b, dx >= 0.d0)-x
             d=0.5d0*e
          end if
       else
          e=merge(a,b, dx >= 0.d0)-x
          d=0.5d0*e
       end if
       if (abs(d) >= tol1) then
          u=x+d
          fu=func(u)
       else
          u=x+sign(tol1,d)
          fu=func(u)
          if (fu > fx) exit
       end if
       du=fjac(u)
       if (fu <= fx) then
          if (u >= x) then
             a=x
          else
             b=x
          end if
          call mov3(v,fv,dv,w,fw,dw)
          call mov3(w,fw,dw,x,fx,dx)
          call mov3(x,fx,dx,u,fu,du)
       else
          if (u < x) then
             a=u
          else
             b=u
          end if
          if (fu <= fw .or. w == x) then
             call mov3(v,fv,dv,w,fw,dw)
             call mov3(w,fw,dw,u,fu,du)
          else if (fu <= fv .or. v == x .or. v == w) then
             call mov3(v,fv,dv,u,fu,du)
          end if
       end if
    end do
    if (iter > ITMAX) stop 'dbrent: exceeded maximum iterations'
    xmin=x
    dbrent=fx
  contains
    !bl
    subroutine mov3(a,b,c,d,e,f)
      real(8), intent(in) :: d,e,f
      real(8), intent(out) :: a,b,c
      a=d
      b=e
      c=f
    end subroutine mov3
  end function dbrent_optimize




  !+-------------------------------------------------------------------+
  !PURPOSE  : 
  !     Given a function FUNC, and given distinct initial points AX and BX,
  !     this routine searches in the downhill direction (defined by the 
  !     function as evaluated at the initial points) and returns new points
  !     AX, BX, CX which bracket a minimum of the function.  
  !     Also returned are the function values at the three points, 
  !     FA, FB, and FC.
  !+-------------------------------------------------------------------+
  subroutine bracket(ax,bx,cx,fa,fb,fc,func)
    real(8), intent(inout) :: ax,bx
    real(8), intent(out) :: cx,fa,fb,fc
    !...the first parameter is the default ratio by which successive intervals
    !   are magnified; the second is the maximum magnification allowed for a
    !   parabolic-fit step
    real(8), parameter :: gold=1.618034d0,glimit=100.d0,tiny=1.d-20
    real(8) :: fu,q,r,u,ulim
    interface
       function func(x)
         real(8) :: x
         real(8) :: func
       end function func
    end interface
    fa=func(ax)
    fb=func(bx)
    if (fb > fa) then
       call swap(ax,bx)
       call swap(fa,fb)
    end if
    cx=bx+GOLD*(bx-ax)
    fc=func(cx)
    do
       if (fb < fc) RETURN
       r=(bx-ax)*(fb-fc)
       q=(bx-cx)*(fb-fa)
       u=bx-((bx-cx)*q-(bx-ax)*r)/(2.0*sign(max(abs(q-r),TINY),q-r))
       ulim=bx+GLIMIT*(cx-bx)
       if ((bx-u)*(u-cx) > 0.d0) then
          fu=func(u)
          if (fu < fc) then
             ax=bx
             fa=fb
             bx=u
             fb=fu
             RETURN
          else if (fu > fb) then
             cx=u
             fc=fu
             RETURN
          end if
          u=cx+GOLD*(cx-bx)
          fu=func(u)
       else if ((cx-u)*(u-ulim) > 0.d0) then
          fu=func(u)
          if (fu < fc) then
             bx=cx
             cx=u
             u=cx+GOLD*(cx-bx)
             call shft(fb,fc,fu,func(u))
          end if
       else if ((u-ulim)*(ulim-cx) >= 0.d0) then
          u=ulim
          fu=func(u)
       else
          u=cx+GOLD*(cx-bx)
          fu=func(u)
       end if
       call shft(ax,bx,cx,u)
       call shft(fa,fb,fc,fu)
    end do
  contains
    subroutine swap(a,b)
      real(8), intent(inout) :: a,b
      real(8) :: dum
      dum=a
      a=b
      b=dum
    end subroutine swap
    !-------------------
    subroutine shft(a,b,c,d)
      real(8), intent(out) :: a
      real(8), intent(inout) :: b,c
      real(8), intent(in) :: d
      a=b
      b=c
      c=d
    end subroutine shft
  end subroutine bracket





  !+-------------------------------------------------------------------+
  !  PURPOSE  : Minimize the Chi^2 distance using conjugate gradient
  !     Adapted by FRPRM subroutine from NumRec (10.6)
  !     Given a starting point P that is a vector of length N, 
  !     the Fletcher-Reeves-Polak-Ribiere minimisation is performed 
  !     n a functin FUNC,using its gradient as calculated by a 
  !     routine DFUNC. The convergence tolerance on the function 
  !     value is input as FTOL.  
  !     Returned quantities are: 
  !     - P (the location of the minimum), 
  !     - ITER (the number of iterations that were performed), 
  !     - FRET (the minimum value of the function). 
  !     The routine LINMIN is called to perform line minimisations.
  !     Minimisation routines: DFPMIN, D/LINMIN, MNBRAK, D/BRENT and D/F1DIM
  !     come from Numerical Recipes.
  !  NOTE: this routine makes use of abstract interface to communicate 
  !     with routines contained elsewhere. an easier way would be to include
  !     the routines inside each of the two following fmin_cg routines. 
  !+-------------------------------------------------------------------+
  subroutine fmin_cg_df(p,f,df,iter,fret,ftol,itmax,eps,istop,type,iverbose)
    procedure(cgfit_func)                :: f
    procedure(cgfit_fjac)                :: df
    real(8), dimension(:), intent(inout) :: p
    integer, intent(out)                 :: iter
    real(8), intent(out)                 :: fret
    real(8),optional                     :: ftol,eps
    real(8)                              :: ftol_,eps_
    integer, optional                    :: itmax,type,istop
    integer                              :: itmax_,type_,istop_
    integer                              :: its
    real(8)                              :: dgg,fp,gam,gg,err_
    real(8), dimension(size(p))          :: g,h,xi
    logical,optional :: iverbose
    logical           :: iverbose_
    !
    if(associated(func))nullify(func) ; func=>f
    if(associated(fjac))nullify(fjac) ; fjac=>df
    !
    iverbose_=.false.;if(present(iverbose))iverbose_=iverbose
    ftol_=1.d-5
    if(present(ftol))then
       ftol_=ftol
       if(iverbose_)write(*,"(A,ES9.2)")"CG: ftol updated to:",ftol
    endif
    eps_=1.d-4
    if(present(eps))then
       eps_=eps
       if(iverbose_)write(*,"(A,ES9.2)")"CG: eps updated to:",eps
    endif
    itmax_=500
    if(present(itmax))then
       itmax_=itmax
       if(iverbose_)write(*,"(A,I5)")"CG: itmax updated to:",itmax
    endif
    istop_=0
    if(present(istop))then
       istop_=istop
       if(iverbose_)write(*,"(A,I3)")"CG: istop update to:",istop
    endif
    type_=0
    if(present(type))then
       type_=type
       if(iverbose_)write(*,"(A,I3)")"CG: type update to:",type
    endif
    !
    fp=func(p)
    xi=fjac(p)
    g=-xi
    h=g
    xi=h
    do its=1,itmax_
       iter=its
       call dlinmin(p,xi,fret,ftol_)
       select case(istop_)
       case default
          err_ = abs(fret-fp)/(abs(fret)+abs(fp)+eps_)
       case(1)
          err_ = abs(fret-fp)/(abs(fp)+eps_)
       case(2)
          err_ = abs(fret-fp)
       end select
       if( err_ <= ftol_ )return
       fp = fret
       xi = fjac(p)
       gg=dot_product(g,g)
       select case(type_)
       case default             
          dgg=dot_product(xi+g,xi)  !polak-ribiere
       case (1)
          dgg=dot_product(xi,xi)   !fletcher-reeves.
       end select
       if (gg == 0.d0) return
       gam=dgg/gg
       g=-xi
       h=g+gam*h
       xi=h
    end do
    if(iverbose_)write(*,*)"CG: MaxIter",itmax_," exceeded."
    nullify(func)
    nullify(fjac)
    return
  end subroutine fmin_cg_df
  !
  !
  !NUMERICAL EVALUATION OF THE GRADIENT:
  subroutine fmin_cg_f(p,f,iter,fret,ftol,itmax,eps,istop,type,iverbose)
    procedure(cgfit_func)                :: f
    real(8), dimension(:), intent(inout) :: p
    integer, intent(out)                 :: iter
    real(8), intent(out)                 :: fret
    real(8),optional                     :: ftol,eps
    real(8)                              :: ftol_,eps_
    integer, optional                    :: itmax,type,istop
    integer                              :: itmax_,type_,istop_
    integer                              :: its
    real(8)                              :: dgg,fp,gam,gg,err_
    real(8), dimension(size(p))          :: g,h,xi
    logical,optional :: iverbose
    logical           :: iverbose_
    !
    !this is just to ensure that routine needing dfunc allocated
    !and properly definted will continue to work.
    if(associated(func))nullify(func) ; func=>f
    if(associated(fjac))nullify(fjac) ; fjac=>df
    !
    iverbose_=.false.;if(present(iverbose))iverbose_=iverbose
    ftol_=1.d-5
    if(present(ftol))then
       ftol_=ftol
       if(iverbose_)write(*,"(A,ES9.2)")"CG: ftol updated to:",ftol
    endif
    eps_=1.d-4
    if(present(eps))then
       eps_=eps
       if(iverbose_)write(*,"(A,ES9.2)")"CG: eps updated to:",eps
    endif
    itmax_=500
    if(present(itmax))then
       itmax_=itmax
       if(iverbose_)write(*,"(A,I5)")"CG: itmax updated to:",itmax
    endif
    istop_=0
    if(present(istop))then
       istop_=istop
       if(iverbose_)write(*,"(A,I3)")"CG: istop update to:",istop
    endif
    type_=0
    if(present(type))then
       type_=type
       if(iverbose_)write(*,"(A,I3)")"CG: type update to:",type
    endif
    !
    fp=func(p)
    xi=fjac(p)!f_dgradient(func,size(p),p)
    g=-xi
    h=g
    xi=h
    do its=1,itmax_
       iter=its
       call dlinmin(p,xi,fret,ftol_)
       select case(istop_)
       case default
          err_ = abs(fret-fp)/(abs(fret)+abs(fp)+eps_)
       case(1)
          err_ = abs(fret-fp)/(abs(fp)+eps_)
       case(2)
          err_ = abs(fret-fp)
       end select
       if( err_ <= ftol_)return
       fp=fret
       xi = fjac(p)!f_dgradient(func,size(p),p)        
       gg=dot_product(g,g)
       select case(type_)
       case default             
          dgg=dot_product(xi+g,xi)  !polak-ribiere
       case (1)
          dgg=dot_product(xi,xi)   !fletcher-reeves.
       end select
       if (gg == 0.0) return
       gam=dgg/gg
       g=-xi
       h=g+gam*h
       xi=h
    end do
    if(iverbose_)write(*,*)"CG: MaxIter",itmax_," exceeded."
    nullify(func)
    nullify(fjac)
    return
  end subroutine fmin_cg_f
  !
  function df(p) 
    real(8),dimension(:)       :: p
    real(8),dimension(size(p)) :: df
    df=f_jac_1n_func(func,size(p),p)
  end function df






  !+-------------------------------------------------------------------+
  !     PURPOSE  : Minimize the Chi^2 distance using conjugate gradient
  !     Adapted from unkown minimize.f routine.
  !     don't worry it works...
  !+-------------------------------------------------------------------+
  subroutine fmin_cgminimize_func(p,fcn,iter,fret,ftol,itmax,iprint,mode)
    real(8),dimension(:),intent(inout) :: p
    procedure(cgfit_func)              :: fcn
    integer                            :: iter
    real(8)                            :: fret
    real(8),optional                   :: ftol
    real(8)                            :: ftol_
    integer, optional                  :: itmax,mode,iprint
    integer                            :: itmax_,mode_,iprint_
    integer                            :: n
    real(8)                            :: f
    real(8),allocatable,dimension(:)   :: x,g,h,w,xprmt
    real(8)                            :: dfn,deps,hh
    integer                            :: iexit,itn
    if(associated(func))nullify(func) ; func=>fcn
    iprint_=0;if(present(iprint))iprint_=iprint
    ftol_=1.d-5
    if(present(ftol))then
       ftol_=ftol
       if(iprint_>0)write(*,"(A,ES9.2)")"CG-mininize: ftol updated to:",ftol
    endif
    itmax_=1000
    if(present(itmax))then
       itmax_=itmax
       if(iprint_>0)write(*,"(A,I5)")"CG-minimize: itmax updated to:",itmax
    endif
    mode_ =1
    if(present(mode))then
       mode_=mode_
       if(iprint_>0)write(*,"(A,I5)")"CG-minimize: mode updated to:",mode       
    endif
    N=size(p)
    allocate(x(N),g(N),h(N*N),w(100*N),xprmt(N))
    dfn=-0.5d0
    hh = 1.d-5
    iexit=0
    !set initial point
    x=p
    xprmt=abs(p)+1.d-15
    call minimize_(fcn_,n,x,f,g,h,w,&
         dfn,xprmt,hh,ftol_,mode_,itmax_,iprint_,iexit,itn)
    !set output variables
    iter=itn
    fret=f
    p=x
    deallocate(x,g,h,w,xprmt)
  end subroutine fmin_cgminimize_func
  subroutine fcn_(n,x,f)
    integer :: n
    real(8) :: x(n)
    real(8) :: f
    f=func(x)
  end subroutine fcn_
  !
  subroutine fmin_cgminimize_sub(p,fcn,iter,fret,ftol,itmax,iprint,mode)
    real(8),dimension(:),intent(inout) :: p
    interface 
       subroutine fcn(n,x_,f_)
         integer                       :: n
         real(8),dimension(n)          :: x_
         real(8)                       :: f_
       end subroutine fcn
    end interface
    integer                            :: iter
    real(8)                            :: fret
    real(8),optional                   :: ftol
    real(8)                            :: ftol_
    integer, optional                  :: itmax,mode,iprint
    integer                            :: itmax_,mode_,iprint_
    integer                            :: n
    real(8)                            :: f
    real(8),allocatable,dimension(:)   :: x,g,h,w,xprmt
    real(8)                            :: dfn,deps,hh
    integer                            :: iexit,itn
    iprint_=0;if(present(iprint))iprint_=iprint
    ftol_=1.d-5
    if(present(ftol))then
       ftol_=ftol
       if(iprint_>0)write(*,"(A,ES9.2)")"CG-mininize: ftol updated to:",ftol
    endif
    itmax_=1000
    if(present(itmax))then
       itmax_=itmax
       if(iprint_>0)write(*,"(A,I5)")"CG-minimize: itmax updated to:",itmax
    endif
    mode_ =1
    if(present(mode))then
       mode_=mode_
       if(iprint_>0)write(*,"(A,I5)")"CG-minimize: mode updated to:",mode       
    endif
    n=size(p)
    allocate(x(n),g(n),h(n*n),w(100*n),xprmt(n))
    dfn=-0.5d0
    hh = 1.d-5
    iexit=0
    !set initial point
    x=p
    xprmt=abs(p)+1.d-15
    call minimize_(fcn,n,x,f,g,h,w,&
         dfn,xprmt,hh,ftol_,mode_,itmax_,iprint_,iexit,itn)
    !set output variables
    iter=itn
    fret=f
    p=x
    deallocate(x,g,h,w,xprmt)
  end subroutine fmin_cgminimize_sub







  !--------------------------------------------------------------------
  ! Conjugate Gradient methods for solving unconstrained nonlinear
  !  optimization problems, as described in the paper:
  !
  ! Gilbert, J.C. and Nocedal, J. (1992). "Global Convergence Properties 
  ! of Conjugate Gradient Methods", SIAM Journal on Optimization, Vol. 2,
  ! pp. 21-42. 
  !--------------------------------------------------------------------
  subroutine fmin_cgplus_df(p,func,fjac,iter,fret,ftol,itmax,imethod,iverb1,iverb2)
    real(8),dimension(:),intent(inout) :: p
    integer                            :: N,i
    interface 
       function func(a)
         real(8),dimension(:)          ::  a
         real(8)                       ::  func
       end function func
       function fjac(a)
         real(8),dimension(:)          :: a
         real(8),dimension(size(a))    :: fjac
       end function fjac
    end interface
    integer,intent(out)                :: iter
    real(8)                            :: fret
    real(8),optional                   :: ftol
    real(8)                            :: ftol_
    integer, optional                  :: itmax,iverb1,iverb2,imethod
    integer                            :: itmax_
    real(8),allocatable,dimension(:)   :: x,g,d,gold,w
    real(8)                            :: f,eps,tlev
    logical                            :: finish
    integer                            :: iprint(2),iflag,method
    integer                            :: nfun,irest
    iprint(1)= -1;if(present(iverb1))iprint(1)=iverb1
    iprint(2)= 0;if(present(iverb2))iprint(2)=iverb2
    method   = 2;if(present(imethod))method=imethod
    ftol_=1.d-5
    if(present(ftol))then
       ftol_=ftol
       if(iprint(1)>=0)write(*,"(A,ES9.2)")"CG+: ftol updated to:",ftol
    endif
    itmax_=1000
    if(present(itmax))then
       itmax_=itmax
       if(iprint(1)>=0)write(*,"(A,I5)")"CG+: itmax updated to:",itmax
    endif
    n     = size(p)
    finish= .false. 
    irest = 1
    allocate(x(n),g(n),d(n),gold(n),w(n))
    x     = p
    iflag = 0
    fgloop: do
       !calculate the function and gradient values here
       f = func(x)
       g = fjac(x)
       cgloop: do
          !call the CG code
          !iflag= 0 : successful termination
          !       1 : return to evaluate f and g
          !       2 : return with a new iterate, try termination test
          !      -i : error
          call cgfam(n,x,f,g,d,gold,iprint,ftol_,w,iflag,irest,method,finish,iter,nfun)
          if(iflag <= 0 .OR. iter > itmax_) exit fgloop
          if(iflag == 1) cycle fgloop
          if(iflag == 2) then
             ! termination test.  the user may replace it by some other test. however,
             ! the parameter 'finish' must be set to 'true' when the test is satisfied.
             tlev= ftol_*(1.d0 + dabs(f))
             i=0
             iloop: do 
                i=i+1
                if(i > n) then
                   finish = .true. 
                   cycle cgloop
                endif
                if(dabs(g(i)) > tlev) then
                   cycle cgloop
                else
                   cycle iloop
                endif
             enddo iloop
          endif
       enddo cgloop
    enddo fgloop
    p=x
    fret=f
    if(iflag<0)stop "CG+ error: iflag < 0"
    if(iprint(1)>=0.AND.iter>=itmax_)write(0,*)"CG+ exit with iter >= itmax"
  end subroutine fmin_cgplus_df

  subroutine fmin_cgplus_f(p,fcn,iter,fret,ftol,itmax,imethod,iverb1,iverb2)
    real(8),dimension(:),intent(inout) :: p
    integer                            :: N,i
    ! interface 
    !    function fcn(a)
    !      real(8),dimension(:)          ::  a
    !      real(8)                       ::  fcn
    !    end function fcn
    ! end interface
    procedure(cgfit_func)              :: fcn
    integer,intent(out)                :: iter
    real(8)                            :: fret
    real(8),optional                   :: ftol
    real(8)                            :: ftol_
    integer, optional                  :: itmax,iverb1,iverb2,imethod
    integer                            :: itmax_
    real(8),allocatable,dimension(:)   :: x,g,d,gold,w
    real(8)                            :: f,eps,tlev
    logical                            :: finish
    integer                            :: iprint(2),iflag,method
    integer                            :: nfun,irest
    if(associated(func))nullify(func) ; func=>fcn
    if(associated(fjac))nullify(fjac) ; fjac=>dfcn
    iprint(1)= -1;if(present(iverb1))iprint(1)=iverb1
    iprint(2)= 0;if(present(iverb2))iprint(2)=iverb2
    method   = 2;if(present(imethod))method=imethod
    ftol_=1.d-5
    if(present(ftol))then
       ftol_=ftol
       if(iprint(1)>=0)write(*,"(A,ES9.2)")"CG+: ftol updated to:",ftol
    endif
    itmax_=1000
    if(present(itmax))then
       itmax_=itmax
       if(iprint(1)>=0)write(*,"(A,I5)")"CG+: itmax updated to:",itmax
    endif
    n     = size(p)
    finish= .false. 
    irest = 1
    allocate(x(n),g(n),d(n),gold(n),w(n))
    x     = p
    iflag = 0
    fgloop: do
       !calculate the function and gradient values here
       f = func(x)
       g = fjac(x)
       cgloop: do
          !call the CG code
          !iflag= 0 : successful termination
          !       1 : return to evaluate f and g
          !       2 : return with a new iterate, try termination test
          !      -i : error
          call cgfam(n,x,f,g,d,gold,iprint,ftol_,w,iflag,irest,method,finish,iter,nfun)
          if(iflag <= 0 .OR. iter > itmax_) exit fgloop
          if(iflag == 1) cycle fgloop
          if(iflag == 2) then
             ! termination test.  the user may replace it by some other test. however,
             ! the parameter 'finish' must be set to 'true' when the test is satisfied.
             tlev= ftol_*(1.d0 + dabs(f))
             i=0
             iloop: do 
                i=i+1
                if(i > n) then
                   finish = .true. 
                   cycle cgloop
                endif
                if(dabs(g(i)) > tlev) then
                   cycle cgloop
                else
                   cycle iloop
                endif
             enddo iloop
          endif
       enddo cgloop
    enddo fgloop
    p=x
    fret=f
    if(iflag<0)stop "CG+ error: iflag < 0"
    if(iprint(1)>=0.AND.iter>=itmax_)write(0,*)"CG+ exit with iter >= itmax"
    nullify(func)
    nullify(fjac)
    return
  end subroutine fmin_cgplus_f
  !
  function dfcn(p) 
    real(8),dimension(:)       :: p
    real(8),dimension(size(p)) :: dfcn
    dfcn=f_jac_1n_func(func,size(p),p)
  end function dfcn




  !           AUXILIARY JACOBIAN/GRADIENT CALCULATIONS
  !
  !          1 x N Jacobian (df_i/dx_j for i=1;j=1,...,N)
  !-----------------------------------------------------------------------
  subroutine fdjac_1n_func(funcv,x,fjac,epsfcn)
    implicit none
    interface 
       function funcv(x)
         implicit none
         real(8),dimension(:) :: x
         real(8)              :: funcv
       end function funcv
    end interface
    integer          ::  n
    real(8)          ::  x(:)
    real(8)          ::  fvec
    real(8)          ::  fjac(size(x))
    real(8),optional ::  epsfcn
    real(8)          ::  eps,eps_
    real(8)          ::  epsmch
    real(8)          ::  h,temp
    real(8)          ::  wa1
    real(8)          ::  wa2
    integer          :: i,j,k
    n=size(x)
    eps_= 0.d0; if(present(epsfcn))eps_=epsfcn
    epsmch = epsilon(epsmch)
    eps  = sqrt(max(eps_,epsmch))
    !  Evaluate the function
    fvec = funcv(x)
    do j=1,n
       temp = x(j)
       h    = eps*abs(temp)
       if(h==0.d0) h = eps
       x(j) = temp + h
       wa1  = funcv(x)
       x(j) = temp
       fjac(j) = (wa1 - fvec)/h
    enddo
  end subroutine fdjac_1n_func

  subroutine fdjac_1n_sub(funcv,x,fjac,epsfcn)
    implicit none
    interface 
       subroutine funcv(n,x,y)
         implicit none
         integer              :: n
         real(8),dimension(n) :: x
         real(8)              :: y
       end subroutine funcv
    end interface
    integer          ::  n
    real(8)          ::  x(:)
    real(8)          ::  fvec
    real(8)          ::  fjac(size(x))
    real(8),optional ::  epsfcn
    real(8)          ::  eps,eps_
    real(8)          ::  epsmch
    real(8)          ::  h,temp
    real(8)          ::  wa1
    real(8)          ::  wa2
    integer          :: i,j,k
    n=size(x)
    eps_= 0.d0; if(present(epsfcn))eps_=epsfcn
    epsmch = epsilon(epsmch)
    eps  = sqrt(max(eps_,epsmch))
    !  Evaluate the function
    call funcv(n,x,fvec)
    !  Computation of dense approximate jacobian.
    do j=1,n
       temp = x(j)
       h    = eps*abs(temp)
       if(h==0.d0) h = eps
       x(j) = temp + h
       call funcv(n,x,wa1)
       x(j) = temp
       fjac(j) = (wa1-fvec)/h
    enddo
    return
  end subroutine fdjac_1n_sub

  function f_jac_1n_func(funcv,n,x) result(df)
    interface
       function funcv(x)
         implicit none
         real(8),dimension(:) :: x
         real(8)              :: funcv
       end function funcv
    end interface
    integer               :: n
    real(8), dimension(n) :: x
    real(8), dimension(n) :: df
    call fdjac_1n_func(funcv,x,df)
  end function f_jac_1n_func

  function f_jac_1n_sub(funcv,n,x) result(df)
    interface
       subroutine funcv(n,x,y)
         implicit none
         integer               :: n
         real(8), dimension(n) :: x
         real(8)               :: y
       end subroutine funcv
    end interface
    integer               :: n
    real(8), dimension(n) :: x
    real(8), dimension(n) :: df
    call fdjac_1n_sub(funcv,x,df)
  end function f_jac_1n_sub







END MODULE OPTIMIZE_MINIMIZE
