#!/usr/bin/perl
############################################################
#
#  copyright 2005,2006 Jaromir Mrazek
#   address:     Jaromir Mrazek, NPI Rez, 25068 Rez, Czech Republic
#                mirozbiro @ seznam.cz
#  this program is distributed under the terms 
#     of GNU General Public Licence
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
# 
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
############################################################
use Time::Local;  # for time2sec
use Cwd;   # for current dir

#print `echo -e  "\\033]0;calc.pl\\a\\c"`; # make term title "calc.pl" 
print `echo   "\\033]0;calc.pl\\a\\c"`; # make term title "calc.pl" 
$SIG{INT}=\&catchupsig;

my $cwd = getcwd();  
print "current directory==$cwd\n";
my $FileNameSeen=""; #persistent variable.

########### ps viewers #########"
#`gv`;
#`ggv`;
#`gsview`;
%gvvi= (
 ggv =>  ["ggv  --geometry 600x600 ","ggv: press  Ctrl-w on canvas to exit the viewer\n"],
 gv =>   ["gv ","gv: press  q  on canvas to exit the viewer\n" ],
);
#
#  a bit of overkill..... $xmgrace{xmgrace}....but...
#  not:
#  0-executable
#  1-instruct
#  2-tmp file
#  3-i from si (set s0,s1,s2)
#
#@xmgrace=("xmgrace ","Exit the xmgrace to continue....","/tmp/calc.drawf.xmgrace",
@xmgrace=("xmgrace -free -noask ","Exit the xmgrace to continue....","$cwd/calc.drawf.xmgrace",
 0 );
#
# here I check the string "@target si" in the xmgrace file... last set 
#
my $lastset=`cat $xmgrace[2] | grep -i target | grep -i -e "^@" | sort -r | head -1`; # vyda treba @target S4
chop($lastset);
if ($lastset ne ""){
    #debug# print "<$lastset>" , length($lastset) ,"\n"; 
    $xmgrace[3]=substr( $lastset,  length($lastset)-1, 1 )+1;
    print "xmgrace set starts with #<",$xmgrace[3],">\n";
}




#print "AHOJJ ", $gvvi{ggv}[0],"\n";

# ######################  konstanty
# $offs=32;  # offset to display a result
# $magnl=3;  # go to expon. form when less then 1E-3
# $magnh=5;  # go to expon when more then 9.999E+5
# $precis=8; # number of valid decimal places

# $switchcomma=0; # ==0:Use decimal point(.dec.numbers) and comma(,fields)
# $switchcomma=0; # ==1:Comma(,for decimal numbers) and a semicolon(; for fields)


# $e=2.71828182845904523536;
# $pi=3.141592653589;
# $hbar=6.581E-22;  # MeV.s
# $ec=1.602176E-19;    # Coulomb
# $hbarc=197;       # Mev.fm
# $k = 8.617343E-11;            # MeV/Kelvin 


my $default_Batch="
offs=32
magnl=3
magnh=5
precis=8
switchcomma=0
e=2.71828182845904523536
pi=3.141592653589
hbar=6.581E-22
ec=1.602176E-19
hbarc=197
k = 8.617343E-11
";



@history=qw();
%fieldvar;

###########--------------  common debug switch: 0,1,2
my $debug=0;
# $debug=1;
my  $Warning="";



my $qqq="
1
2
3
4)
";

#    2008 06 20 ------  OPEN TOTALY TTY READ. For all the calc.pl lifetime
#
#



##############################################
# command  prompt
###############################################

sub get_cmdstr{
    my @history=@_;
    my $s="";
    my $pos=0;
    my $buf="";
    my $hispos=$#history+1;

# open(TTY, "+</dev/tty") or die "no tty: $!";
# system "stty  cbreak </dev/tty >/dev/null 2>/dev/null &";

 while(1==1){
 my $arr="";
 my $key = getc(TTY);
 # print "\b\b \b\b";
  if ($debug>1){print ":character=$key   length=",length($key),"  ord=",ord($key) ,"\n"; }

 # esc, [, ABCD are arrows ......................................

  if  ( ord($key)==1){ $arr="j1";print "\b \b"}# jumps Ctrl-A,D,E
  if  ( ord($key)==4){ $arr="de";print "\b \b"}# ctrl-D
  if  ( ord($key)==5){ $arr="j2";print "\b \b"}# ctrl-E, sometimes "xterm"?
  if  ( ord($key)==18){ $arr="j2";print "\b \b"}  # ctrl R as alternative to E
### 21 22   UV
  if  ( ord($key)==21){ $arr="up";print "\b \b"} # U
  if  ( ord($key)==22){ $arr="do";print "\b \b"} # V
  if  ( ord($key)==10){ $arr="en";}#  enter
  #---- variant bksp=8 in icewm
  if  ( ord($key)==8){ $arr="bk";print "\b \b"}
  if  ( ord($key)==127){ $arr="bk";print "\b \b"}
  if  ( ord($key)==11){ $arr="ck";print "\b \b"} # Ctrl-K


#======================================================
  if ( ord($key)==27){    #---esc
      print "\b\b  \b\b";
      $key = getc(TTY);
  if ($debug>1){ print ":character=$key   length=",length($key),"  ord=",ord($key) ,"\n";}

#------------   key 79 at redhat 8.0
    if ( ord($key)==91 ||  ord($key)==79){  #--arrows (and insert..
       print "\b \b";
       $key = getc(TTY);
       print "\b \b";
  if ($debug>1){ print ":character=$key   length=",length($key),"  ord=",ord($key) ,"\n";}
       if ( ord($key)==65){$arr="up";}
       if ( ord($key)==66){$arr="do";}
       if ( ord($key)==67){$arr="ri";}
       if ( ord($key)==68){$arr="le";}
        # delete key
       if ( ord($key)==51){
          print "\b \b";$key = getc(TTY);if ( ord($key)==126){$arr="de";}}
        #insert
       if ( ord($key)==50){   
          print "\b \b";$key = getc(TTY);if ( ord($key)==126){$arr="in";}}
        #home
       if ( ord($key)==72){print "\b \b";$arr="j1";}
       #end 
       if ( ord($key)==70){print "\b \b";$arr="j2";}
       
    } #arr

#----------
    if ( ord($key)==79){  #--home end on kde
       print "\b \b";
       $key = getc(TTY);
       print "\b \b";
  if ($debug>1){ print ":character=$key   length=",length($key),"  ord=",ord($key) ,"\n";}
        #home 
       if ( ord($key)==72){    print "\b \b";$arr="j1";}
        #end 
       if ( ord($key)==70){    print "\b \b";$arr="j2";}
       
    } #homend kde
       
#----------==================================--------
  } #esc 
  else{ print "\b \b"}
 #.............................................................


###################################" PERFORM OPERATIONS on cmdline ######
 #---------------------------------------------
  if ( $arr ne ""  ){
  #  print "arrow $arr\n";
    CASE:{
        if($arr eq "j1"){$pos=0;print "\r$s\r";last CASE}
        if($arr eq "j2"){$pos=length($s);print "\r$s";last CASE}
        if($arr eq "en"){last CASE}
        if($arr eq "le"){
              if ($pos>0){$pos--;print "\r$s\r",substr($s,0,$pos);}
               else{print "\r$s\r";}
            last CASE}
        if($arr eq "ri"){
            $pos++;
	    print "\r$s\r",substr($s,0,$pos);
	    last CASE}
        if($arr eq "up"){
	    if ($buff eq ""){$buff=$s;}
	    print "\r"," "x length($s);
	    if ($hispos>0){$hispos--}
	    $s=$history[$hispos];
            $pos=length($s);
	    print "\r$s";
	    last CASE}
        if($arr eq "do"){
	    print "\r"," "x length($s);
	    if ($hispos<$#history){$hispos++;
	        $s=$history[$hispos];
                }else{$s=$buff;$buff="";
		      if ($hispos<=$#history){$hispos++;}
                }
            $pos=length($s);
	    print "\r$s";
	    last CASE}
        if($arr eq "de"){
            print "\b \b";
            $s=substr($s,0,$pos).substr($s,$pos+1,length($s));
	    print "\r$s \r",substr($s,0,$pos);
	    last CASE}
        if($arr eq "ck"){ # Ctrl-K
            print "\b \b";
            print " "x length($s);$s=substr($s,0,$pos); 
	    print "\r$s \r",substr($s,0,$pos);
	    last CASE}
        if($arr eq "bk"){
            if ($pos>0){
            print "\b \b";
            my $ss=substr($s,0,$pos-1).substr($s,$pos,length($s));
            $s=$ss;
            $pos--;
	    print "\r$s \r",substr($s,0,$pos);
	    last CASE;
	    }
        }
    }
  }else{
    if ($pos==length($s)){
        print $key;
        $s.=$key;
    }else{
	$s=substr($s,0,$pos).$key.substr($s,$pos,length($s));
        #print $key,substr($s,$pos+1,length($s));
        print "\r$s \r",substr($s,0,$pos+1);
    }
      $pos++;
 }
 # print "\b";
 if($arr eq "en"){last;}
 }# while....

# close TTY;
# system "stty  -cbreak   </dev/tty >/dev/tty 2>&1"; 

    if ($debug>1){print "Exit getcmdstr  routine ........\n";}
 return $s;
}#.......... end of routine............





#print "velkyosle";
#print ">",&get_cmdstr,"<\n";
#exit;http://mathomatic.orgserve.de/math/feedback.html





$Helpv="
-----------------------------------------------------------
OUTPUT/INPUT FORMATING
    offs = 32 # offset to display a result
   magnl = 3  # go to exponential form when less then 1E-3
   magnh = 5  # go to exponential when more then 9.999E+5
  precis = 8  # number of displayed decimal places

  switchcomma = 0; # 0:decimal point; 1:decimal comma(+semicolon; for fields)

predefined PHYSICAL CONSTANTS
    e = 2.71828182845904523536  # euler constant
   pi = 3.141592653589          # PI
 hbar = 6.581E-22               # MeV.s   planck constant/2PI
   ec = 1.602E-19               # Coulomb - electron charge
hbarc = 197                     # MeV.fm
    k = 8.617343E-11            # MeV/Kelvin 
-----------------------------------------------------------
";


$Helpfyz="
PHYS    | ------------------------------------------------------------
  conv B| Time <=> red.tr.prob. 
        |     bb2t12(keV, B[eb],\'sigL\')   ... eb   -> partial level lifetime
        |     bw2t12(keV, B[wu],\'sigL\',A) ... w.u. -> partial level lifetime
        |     t122bb(keV, T12,  \'sigL\') ...  partial level lifetime -> eb 
        | Reduced.transition.probabilities. in different units:
        |     b2b( Bvalue,  sigmaL, conversion, A): 
        |       eg. b2b(101,\'E2\',\'FW\',77)
        |       conv: BF BW FB FW WB WF  (uppercase to avoid collision)
        |       A if not supplied, taken from var a. e.g.a=32 (just W.U.)
        |     btw:
        |      B(E2,0->2,A=46)=196e2fm4=20wu.  B(E2 2->0)=1/5(0->2)=4wu
        |      B(E2,0->2,A=44)=0.0314e2b2=34wu.B(E2 2->0)=1/5(0->2)=6.8wu
        |      delta=sqrt(   bw2t12(ene,bm1,\'M1\',a)/ ( bw2t12(ene,be2,\'E2\',a) )  )
        |
        | Neutron tof <=> Energy_n:
        |     tof2e(tof,distance,A), e2tof(E,dist,A)..
        |     neutron tof in ns, dist in meters, A-mother nucleus
        |
        | Reactions:
        |    rerate(flux, sigma, MM, thickness)=reaction rate
        |          flux (particles/s), cross section (barn), 
        |          target: MolarM (usually mass number), thickness(g/cm2)
        |    reratet(flux,sigma, MM, tgt thickness in um, rho_in_g_cm3)
        |    fluxap( beamint (Amp), charge ) Intensity in Amps=> part/s
        |    fluxpa( beamint (part/s), charge )  p/s => Ampers
        |       e.g. fluxap(2e-6, 22)*7*(24:00:00) = #ions/week at 2uA
        |    t2gcm( t, density ) thickness (in cm) => g/cm2
        |    gcm2t( t in g/cm2, density ) => thickness (in cm) 
        |    rho(\'Al\') = density of Al
        |       e.g. t2gcm(0.1, rho(\'al\') )=0.2698 : 1mm Al=0.27g/cm2
        |    react(2,1, 14,6, 1,1 , 15,6,  T1,  angle3) ... 14C(d,p)15C
        |        (A,Z proj, tgt, eject, remn,  TKE,  det.angle)
        |        (A,Z:proj,tgt,eject,remn,TKE,ang, Eexc,amu1,amu2,amu3,amu4)
        |    printreact(9,4,12,6) ... prints many reactions for 9Be+12C
        | Masses:
        |    mex(14,6) = mass excess 14C
        |    amu(2,1)  =  atomic mass of deuteron ( 1amu = 931.49403 )
        |    mex(4,2)+mex(4,2) - mex(8,4)  =  Q reaction 2alpha->8Be (<0)
        |    mex(16,8)+mex(2,1)- mex(18,9) = 7.525 Q react. 16O+d=>18F
        |    mex(12,6)+mex(1,0)-mex(13,6)  =  S1n in  13C
        |    mex(8,3)+mex(1,1)-mex(9,4)    =  S1p in  9Be
";

$Helpf="
-----------------------------------------------------------
      financ: |find final amount 
              |  GETINTER(interest (1%=0.01),#months,init \$, monthly savs, ys)
              |find time in months to save aim
              |  SOLVEINTERM(aim \$, interest (1%=0.01), ini\$, monthly\$,yrly\$)
              |find what must be an interest to save the aim
              |  SOLVEINTERI( aim\$, #months, initialy \$, m\$,y\$ )
              | 
          mat:|  p0,p2,p4(legendre pol.)... usually used as p2(cos(45)) 
        other:|  time2sec(year,month,day,hour,min,sec)   gives #sec from 1970
              |  sec2time(sec) prints date (inversely to time2sec())
              |  sec2timed(sec) prints difference in days etc.
              |
 stat(FIELDS):|  INPUT:  qq=(1,2, 2, 2.1, 1.2) 
              |          qq=(1 2  2  2.1  1.2)
              |          readf(filename,fa,fb,fc)..LOWERCASE filename
              |          readf(filen.ext,a,b)... LOWERCASE filename
              |          readcsvf(filen.ext)... LC filename, just name
              |               line with 'calc.pl.variables' defines variables 
              |               line with 'calc.pl.stop'      defines stop 
              |          batch(filename): only parse commands in a file
              |          fillf(ff,10,0,1)   ... ff, #, start, step
              |  FNC:avg(ff)     avg(val,err)...int,tot err. X2  
              |      median(ff)   
              |      sum(ff)      
              |      sortf(ff,ea,eb) , sortrevf(...) ...sort all by 1st
              |      showf()        ... show all defined fields
              |  OUT:printf(f1,f2)  ... column print
              |      writef(file,a,b)    ... LOWERCASE filename; autoext=calcpl
              |      latexf(a,b,c)  ...    LaTeX table 
              |      drawf(a,b,c)   ...    a is xasis, b and c are sets for yaxis
              |      
              |   example: aa=(5,4,3); bb=aa*2-4; cc=aa/bb; printf(aa,bb,cc)
              |   NO EXPRESSIONS IN ARGUMENTS (NOT e.g. writef(name, a+b) )!!!
-----------------------------------------------------------
";


$Help="
-----------------------------------------------------------
numbers:      |  as usual    0.34   1.2E+6     etc.
              |  hours:minutes         ... transformed directly to minutes
              |  hours:minutes:seconds ... transformed directly to seconds
              |  0xff   0b1001 (hexa,binary)  
operations    |     +,-,*,/,**,^,sqrt
              |     :,:: (conversion to hours:minutes,hms)
              |     0x, 0b display in hexa,bin
              |     &,|,>>,<<   binary operations and,or,shift
              |          -3+5 is operation on the last result!!
              |          BUT (-1)*3+5 is 2 or _-3+5 is 2 (_ stands for blank)
functions:    |  not case sensitive.!! (always autotransformed to uppercase)
              |  sin,cos,tan,asin,acos,atan,exp,ln,log  ... ALWAYS parenthesis()
               ==>>  for help on special functions:   ### helpf() ###
              |
switches:     |    deg(),rad()        ... operates in degrees, radians(default)
              |    \"default operation mode 1\": +<enter>  ,-<enter> 
              |    \"default op. mode 2\": +++number<enter>  (or ***,---,///)
              |    clear \"default op.mode\"        <enter>
              |    xmgraceon() xmgraceoff()
              |
Variables:    |  lowercase ONLY!! NO numbers in the name!!  ### helpv() ###
              |  var=3+3,  var=, =var (to keep the last result),  
              |  (a,b,c)=(10+1,4.4*2.5+1,44/4+2) ... multiple assignement
              |  var (prints the value)
              |  predefined variables:   pi, e, offs ... offset of printout
--------------------------------------------
more help: helpv()  ...  predefined variables
           helpf()  ...  functions and fields
           helpfyz()...  physfunc
           helpm()  ...  mathomatic
           helpcatch() ..catches, hints 
";



$Helpcatch="
--------------------------------------------
Functions: use <enter> as a reference to previous result 
          (eg. sin()<enter> makes sin(previous result)
              15-<enter> makes 15-previous result
              0-<enter>  changes the sign previous result
Problems and catches: 
   *)     -3 is operation, <space>-3 is negative number
   *)    Cannot solve equations: e.g.  =a+3  or   a+1=, but a=3+4 is ok.
   *)    FIELDS - they cannot use numbers in names (f1)
                  files are in lowercase only (characters like _ forbiden)
-------
Mathomatic call included :),   call >mat()<
         ==>> for help:  ### helpm() ###
-----------------------------------------------------------
";
#2do:  ...,  interpolation,...vectors...




$Help_mat="
------------- http://mathomatic.orgserve.de/math/am.htm -------------
clear all        :----  solving eq:
a^2=b^2+c^2
a                         solves for a
derivative b              (deri) makes da/db
simplify                  (simp, simp quick, simp poly)
optimize                  repeating parts moved to buffer..
integrate                 (inte) dumb integration
: ------  
e=f+f^2*pi+e#^2         : e=2.71, pi=3.14, 
sensitivity e           : (sens) tests how var changes...
: ----    elimination, calc, output
f=x+1                 : 4=3+1
f=x^2-5               : 4=3^2-5
elim x                : eliminate x
f                     : quadratic result (sign op.)
calc                  : prints out the results for f (calculate)
#1                    : recall (select) equation f=x+1
x                     : x=f-1
replace f with 4      : the result for x
code 2                : output eq. 2 in  C syntax
list export  [all]    : exports in reasonable format (for tex??)
: ---   extrema
y=(x^3) + (x^2) - x
extrema x                 (extr) finds extremas
calc                       evaluates nonnumeric solutions
: ----   taylor expansion
y=x^3+x^2+x
tayl x
: ---
quit  :--------- can do imaginary, laplace, limits etc.., fact, unfact
----------------------------------------------
";





#----- REAL CODE -----------#----- REAL CODE -----------#----- REAL CODE
#--- REAL CODE --------#----- REAL CODE ---------#----- REAL CODE
#----- REAL CODE -----------#----- REAL CODE -----------#----- REAL CODE



if ($ARGV[0]=~/^\-hm/i){print $Help_mat;exit 0;}
if ($ARGV[0]=~/^\-hf/i){print $Helpf;exit 0;}
if ($ARGV[0]=~/^\-h/i){print $Help;exit 0;}
#print "                ....calc.pl 050315: type help to get short help\n";
#print "                ....calc.pl 060112: type help to get short help\n";
#print "                ....calc.pl 060816: emited type help to get short help\n";
#print "                ....calc.pl 060817: vectors alphaversion type help to get short help\n";
#print "                ....calc.pl 060817: vectors alphaversion, stats. type help to get short help\n";
#print "                ....calc.pl 060828: vectors alphaversion, stats, switchcomma-locale\n";
#print "                ....calc.pl 060921: fields alpha-code, \n";
#print "                ....calc.pl 061107: bugfix release, fields not mentioned \n";
print "                ....calc.pl 110802: new release, fields, xmgrace \n";


if ($ARGV[0]=~/^\-b/i){
    
}



# OPENING TTY
 open(TTY, "+</dev/tty") or die "no tty: $!";
 system "stty  cbreak </dev/tty >/dev/null 2>/dev/null &";


     open IN,"$ENV{HOME}/.calc.pl";
        while (<IN>){ chop($_);push @history,$_;}
     close IN;


$Defoperat="";
$R2dc=1; # radians default
 $XmgON=1;# xmgrace display on default


########################################################
########################################################
###        THE MAIN LOOP
########################################################
########################################################
my $Batch= $default_Batch;      # I put constants HERE
my @Batch=split /\n/, $Batch;
#print "@Batch\n";






while(1==1){

  $Warning="";
 
  if ($#Batch>=0){
      $_=shift(@Batch);
      print;
  }else{
 $_=&get_cmdstr(@history); 
 push @history, $_;
  }
  
  if ($_=~/\($/){
      my $multiinput=$_;
      print "open parenthesis : waiting for input until close parenthesis\n";
      while ($_!~/\)$/){
       $_=&get_cmdstr(@history); 
       $multiinput.=$_." ";
      }
      print "TOTAL INPUT= $multiinput \n";
	  $_= $multiinput;
  }


#### $_="e2tof(0.421,1.22,17)";
 if ($debug>=1){print "input line:$_\n";}
# if ($debug>=2){print "input line:$_\n";}

#####not batch....I put it up:   push @history, $_;
 $xXx=$_;
 if ($DO>0) {print " "x$offs,">$xXx<\n";}

 #-----------------  vyrad nebezpecne prikazy!!!
 #-----------------  vyrad nebezpecne prikazy!!!
 if  ($xXx=~/(?:exec|system|unlink|open|close|delete|\`|sub|char|ord|\$|\\|\@|\{|\}|\[|\])/){$xXx="0";$Warning="..forbiden word or character";}

 $xXx=~s/\s+$//g;  # remove spaces at the end: Important for fields!!
 $xXx=~s/^\s+//g;  # remove spaces at the end: Important for fields!!

 $xXx=~s/\^/\*\*/g;   # change ^ to **

 $xXx=~s/\"/\'/g;   #  remove ", ' # change to '
# $xXx=~s/\'//g;   #  remove ", '


  if ( $switchcomma==1 ){
      $xXx=~s/,/\./g; 
      $xXx=~s/;/,/g; 
  }

#------IMMEDIATELY REPLACE FUNCTIONS with UPPERCASE
#         sqrt,exp,log....  jen sranda, aby se nepouzily jmena fci
#------  !!! ORDER is important !!!!!!
 @functions=qw(
sqrt exp log ln  
atan asin acos
sin cos tan 
p0 p1 p2 p3 p4 
pow
getinter solveinterm solveinteri
bb2t12   bw2t12   t122bb 
reratet rerate fluxap fluxpa rho t2gcm gcm2t  react printreact kinem
mex amu
b2b
rad deg
xmgraceon xmgraceoff
tof2e  e2tof
time2sec sec2timed sec2time
mat  helpcatch helpm helpv helpfyz helpf help  quit
avg median sum  lr
readf readcsvf batch fillf writef printf latexf showf sortrevf sortf drawf drawof);

# I try to extract   $FileNameSeen  as a very first thing
@filefunctions=qw(
readf readcsvf batch writef latexf 
);


my $Ff;
   $FileNameSeen="";  # persistent
 foreach $Ff (@filefunctions){
     if ($xXx=~/(^|[^\w\.])$Ff(\s*\()/){
     # I used this from the previous
#    $xXx=~s/(^|[^\w\.])$Ff(\s*\()/$1."&".$f2.$2/ge; # whatever but not[\w\.] Function=()
     my $Xicht1,$Xicht2;
($Xicht1,$FileNameSeen)=  $xXx=~/(^|[^\w\.])$Ff\s*\(\s*([\w\.\d\+\-]+)/; 
# whatever but not[\w\.] Function=()
# used all -_. etc...     BUT NOT , \s
#print "XICHT-FNSEEN: <$Xicht1>,<$FileNameSeen>\n";
     }# if function is there....
 }
if (length($FileNameSeen)>0){ print "FileNameSeen = <$FileNameSeen>\n";}


########################################
# 1) all to lowercase;
# 2) functions to uppercase
# 3)
#
#
########################################
 if ($debug>=1){print "input line after processin1:$xXx\n";}


## Protection for functions: they are UPPERCASE. 
## from 2011/08   functions MUST have ()  i.e.  deg()  deg are different

 $xXx=~s/([A-Z])/lc($1)/ge;  # Everything uppecase to lowercase! NOW!
                              
 
 if ($debug>=1){print "input line after processin1.5:$xXx\n";}
 
#already defined above  my $Ff;
 foreach $Ff (@functions){ # CHANGE FUNCTIONS TO UPPERCASE
     my $f2=uc($Ff);
#     $xXx=~s/($Ff)/"&".$f2/ge;
#       to avoid interpretation of tmp2 as tm&P2 do 1) ^; 2) \W
#                      added also extensions protect: file.log   =>.&LOG
#     $xXx=~s/^$Ff/"&".$f2/e;        #beginning the line...ok
#     $xXx=~s/(\W)$Ff/$1."&".$f2/ge;
     $xXx=~s/(^|[^\w\.])$Ff(\s*\()/$1."&".$f2.$2/ge; # whatever but not[\w\.] Function=()
 }
  if ($debug>=1) {print "###re-functioned:### $xXx\n";}
 if ($debug>=1){print "input line after processin2:$xXx\n";}





#############   letters as arguments ______ tricky=>make it uppercase! ####
#       if ($xXx=~/RHO/){  # element as argument
#            $nfields=0;
#	    my ($qq)=( $xXx=~/RHO\((\w+)\)/ );
#	    $qq=uc($qq);
#            $xXx=~s/RHO\((\w+)\)/RHO($qq)/g; 
#      }# if xxx=~/


#----------  exponential   aE+-b   ---  change to uppercase...
#         but should be already done ??? obsolete...
 $xXx=~s/(^[\d\.]+)e([\+\-][\d]+)/$1E$2/g;  
 $xXx=~s/([\W][\d\.]+)e([\+\-][\d]+)/$1E$2/g;  



   if ($debug>=1){print "###  beforefield  ###:$xXx\n";}



#--------- field =>   '@' =============############################## vectors
#--------- field =>   '@' =============############################## vectors
#--------- field =>   '@' =============############################## vectors
#                                  INPUT NEW FIELD, add to the list

#__________________ diplay status _______________________
#     foreach (keys %fieldvar){#______ DISPLAY STATUS ______
#	$,=" "; # !!! maters with the line cmd!!!
#        print " "x 10,"field $_ contains (",@{$fieldvar{$_}},")\n";
#	$,=""; # !!! maters with the line cmd!!!
#     }
#          T O   D O    T O   M A K E   I T     R E A S O N A B L E 
# 1st -  treat correctly lowercase and uppercase.
#   initiate fields : basic creation; in-operation creation
# 2nd  swap for $FLDNAME[$index]
# 3rd  run with index 0..max
#################################################################

 #           &display_fields("beforeckf");


#''''''''' field count, check FUNCTIONS ''''''''''''''''''''''''''
 #======== out of field..........READF prepare new fields
  # defp:filename and numbers(1.2e+3)
       if ($xXx=~/READF/){  
	   print "RF:<$xXx>\n";
            $nfields=0;
	    my ($defp)=$xXx=~/READF\(\s*(\w[\w\,\s\.\d\+\-]*)\)/;
#   file.log:  .log was not accepted correctly
#	    my ($defp)=$xXx=~/READF\(\s*(\w.*)\s*\)/;#try again
#	    print "RF: <$defp>\n"; 
	    my $defpu=uc($defp); $xXx=~s/$defp/$defpu/;
	    $defpu=~s/\s+//g;  # clean the spaces before hash key definition!
#	    print "defined befor readf : $xXx ; $defp\n";
	    my @nfld=split/[\,]+/,$defpu;
#	    print "RF2:<@nfld>\n";
  	    foreach (@nfld){ 
 		uc($_);
		if ($nfld[0] eq $_){next;}
              	if (exists $fieldvar{$_}){delete $fieldvar{$_}; }
               $fieldvar{$_}=qw(0);#print "FL=$_, ";
            } # define field
#            $xXx=~s/READF\(\s*(\w[\w\,\s\.\d]*)\)/READF('$1')/; 
            $xXx=~s/READF\(\s*(\w[\w\,\s\.\d\+\-]*)\)/READF('$defpu')/; 
#	    print "substituted: $xXx\n";
      }# if xxx=~/ STAT




       if ($xXx=~/READCSVF/){   #######NEW FUNCTION########READ   CSV#########
# 	    print "beforetuted: $xXx\n";
           $nfields=0;
	    my ($defp)=$xXx=~/READCSVF\(\s*(\w[\w\,\s\.\d\+\-]*)\)/;
	    my $defpu=uc($defp); $xXx=~s/$defp/$defpu/;
	    $defpu=~s/\s+//g;  # clean the spaces before hash key definition!
#	    print "defined befor readf : $xXx ; $defp\n";
	    my @nfld=split/[\,]+/,$defpu;
  	    foreach (@nfld){ 
 		uc($_);
		if ($nfld[0] eq $_){next;}
                #TO JE ZREJME KRAVINA  -BUG-    NO FIELDS HERE
                #TO JE ZREJME KRAVINA  -BUG-    NO FIELDS HERE
                #TO JE ZREJME KRAVINA  -BUG-    NO FIELDS HERE
                #TO JE ZREJME KRAVINA  -BUG-    NO FIELDS HERE
              	if (exists $fieldvar{$_}){delete $fieldvar{$_}; }
               $fieldvar{$_}=qw(0);
               print "FL=$_, ";
            } # define field
#            $xXx=~s/READCSVF\(\s*(\w[\w\,\s\.\d]*)\)/READCSVF('$1')/; 
            $xXx=~s/READCSVF\(\s*(\w[\w\,\s\.\d\+\-]*)\)/READCSVF('$defpu')/; 
	    print "\n\nsubstituted: $xXx\n\n";
      }# if xxx=~/ STAT


       if ($xXx=~/BATCH/){   #######NEW FUNCTION########READ   CSV#########
            $nfields=0;
	    my ($defp)=$xXx=~/BATCH\(\s*(\w[\w\,\s\.\d\+\-]*)\)/;
	    my $defpu=uc($defp); 
	    my $defpu=$defp; 
	    $xXx=~s/$defp/$defpu/;
	    $defpu=~s/\s+//g;  # clean the spaces before hash key definition!
#	    print "defined befor readf : $xXx ; $defp\n";
#	    my @nfld=split/[\,]+/,$defpu;
#  	    foreach (@nfld){ 
# 		uc($_);
#		if ($nfld[0] eq $_){next;}
#              	if (exists $fieldvar{$_}){delete $fieldvar{$_}; }
#               $fieldvar{$_}=qw(0);#print "FL=$_, ";
#            } # define field
#            $xXx=~s/READCSVF\(\s*(\w[\w\,\s\.\d]*)\)/READCSVF('$1')/; 
            $xXx=~s/BATCH\(\s*(\w[\w\,\s\.\d\+\-]*)\)/BATCH('$defpu')/; 
#	    print "substituted: $xXx\n";
      }# if xxx=~/ STAT




       if ($xXx=~/FILLF/){  
            $nfields=0;
	    my ($defp)=$xXx=~/FILLF\(\s*(\w[\w\,\s\.\d\-e\+]*)\)/;
	    my $defpu=$defp; # $xXx=~s/$defp/$defpu/;
	    $defpu=~s/\s+//g;  # clean the spaces before hash key definition!
	    print "defined befor fillf : $defp\n";
	    my @nfld=split/[\,]+/,$defp;
#  	    foreach (@nfld){ 
	    my $a_=$nfld[0];
 		$a_=uc($a_);
	    $defpu=~s/$nfld[0]/'$a_'/;
#		if ($nfld[0] eq $_){next;} # filename
              	if (exists $fieldvar{$a_}){delete $fieldvar{$a_}; }
               $fieldvar{$a_}=qw(0);#print "FL=$_, ";
#            } # define field
#            $xXx=~s/FILLF\(\s*(\w[\w\,\s\.\d\-e\+]*)\)/FILLF('$defpu')/; 
            $xXx=~s/FILLF\(\s*(\w[\w\,\s\.\d\-e\+]*)\)/FILLF($defpu)/; 
	    print "substituted: $xXx\n";
      }# if xxx=~/ STAT

#========================== standalone # of fields ===============
  $nfields=0; #FIND HOW MANY FIELDS ARE IN THE EXPR:determines the context
  foreach $Ff (keys %fieldvar){ #FIND HOW MANY FIELDS ARE IN THE EXPR
     my $myxxx=$xXx; $myxxx=~s/[a-z]+\=//i;
     my $lff=lc($Ff);
     if (  $myxxx=~/[\W\D]$lff[\W\D]/ or
	   $myxxx=~/[\W\D]$lff$/ or
	   $myxxx=~/^$lff[\W\D]/ or 
	   $myxxx=~/^$lff$/ 
     ){ $nfields++;}
#     print "$nfields fields\n";
 }#foreach



#=================== PROTECT FIELD-DEDICATED FUNCTIONS ===============
 
#=================== Prepeare arguments for dedicated functions ======
  if ( $nfields>0){
       $Warning.=" $nfields-flds ";
       # ONE-number Field Functions redefine HERE
       if ($xXx=~/MEDIAN/){  
            $nfields=0;
            $xXx=~s/MEDIAN\(\s*(\w[\w\d]*)\)/MEDIAN('$1')/g; 
      }# if xxx=~/MEDIAN
       if ($xXx=~/SUM/){  
            $nfields=0;
            $xXx=~s/SUM\(\s*(\w[\w\d]*)\)/SUM('$1')/g; 
      }# if xxx=~/ STAT

       if ($xXx=~/AVG/){  # MORE-number Field Functions redef
            $nfields=0;
######            $xXx=~s/AVG\(\s*(\w[\w\d]*)\)/AVG('$1')/g; 
	    my ($defp)=$xXx=~/AVG\(\s*(\w[\w\,\s\.\d]*)\)/;
	    my $defpu=uc($defp); $xXx=~s/$defp/$defpu/;
#	    print "defined befor printf : $defp\n";
            $xXx=~s/AVG\(\s*(\w[\w\,\s\.\d]*)\)/AVG('$defpu')/;
	    if ($defpu eq ""){$xXx="0";$Warning.=" Err ";}
      }# if xxx=~/AVG
       if ($xXx=~/LR/){  
            $nfields=0;# DONT DO OTHER FIELD OPERATIONS
	    my ($defp)=$xXx=~/LR\(\s*(\w[\w\,\s\.\d]*)\)/;
	    my $defpu=uc($defp); $xXx=~s/$defp/$defpu/;
#	    print "defined befor printf : $defp\n";
            $xXx=~s/LR\(\s*(\w[\w\,\s\.\d]*)\)/LR('$defpu')/;
	    if ($defpu eq ""){$xXx="0";$Warning.=" Err ";}
      }# if xxx=~/ STAT

       if ($xXx=~/READF/){  
            $nfields=0;# DONT DO OTHER FIELD OPERATIONS
      }# if xxx=~/ STAT
       if ($xXx=~/READCSVF/){  
            $nfields=0;# DONT DO OTHER FIELD OPERATIONS
      }# if xxx=~/ STAT
       if ($xXx=~/FILLF/){  
            $nfields=0;# DONT DO OTHER FIELD OPERATIONS
      }# if xxx=~/ STAT
       if ($xXx=~/WRITEF/){  
            $nfields=0;# DONT DO OTHER FIELD OPERATIONS
	    my ($defp)=$xXx=~/WRITEF\(\s*([\w\,\s\.\d]+)\)/;
	    my $defpu=uc($defp); $xXx=~s/$defp/$defpu/;
#	    print "defined befor printf : $defp\n";
#            $xXx=~s/WRITEF\(\s*([\w\,\s\.]+)\)/WRITEF('$1')/; 
            $xXx=~s/WRITEF\(\s*([\w\,\s\.]+)\)/WRITEF('$defpu')/; 
	    if ($defpu eq ""){$xXx="0";$Warning.=" Err ";}
      }# if xxx=~/ STAT
       if ($xXx=~/PRINTF/){  
            $nfields=0;# DONT DO OTHER FIELD OPERATIONS
	    my ($defp)=$xXx=~/PRINTF\(\s*(\w[\w\,\s\.\d]*)\)/;
	    my $defpu=uc($defp); $xXx=~s/$defp/$defpu/;
#	    print "defined befor printf : $defp\n";
            $xXx=~s/PRINTF\(\s*(\w[\w\,\s\.\d]*)\)/PRINTF('$defpu')/;
	    if ($defpu eq ""){$xXx="0";$Warning.=" Err ";}
            &display_fields("defp");

      }# if xxx=~/ STAT
       if ($xXx=~/DRAWF/){  
            $nfields=0;# DONT DO OTHER FIELD OPERATIONS
	    my ($defp)=$xXx=~/DRAWF\(\s*(\w[\w\,\s\.\d]*)\)/;
	    my $defpu=uc($defp); $xXx=~s/$defp/$defpu/;
#	    print "defined befor printf : $defp\n";
            $xXx=~s/DRAWF\(\s*(\w[\w\,\s\.\d]*)\)/DRAWF('$defpu')/;
	    if ($defpu eq ""){$xXx="0";$Warning.=" Err ";}
      }# if xxx=~/ STAT
       if ($xXx=~/DRAWOF/){  
            $nfields=0;# DONT DO OTHER FIELD OPERATIONS
	    my ($defp)=$xXx=~/DRAWOF\(\s*(\w[\w\,\s\.\d]*)\)/;
	    my $defpu=uc($defp); $xXx=~s/$defp/$defpu/;
#	    print "defined befor printf : $defp\n";
            $xXx=~s/DRAWOF\(\s*(\w[\w\,\s\.\d]*)\)/DRAWOF('$defpu')/;
	    if ($defpu eq ""){$xXx="0";$Warning.=" Err ";}
      }# if xxx=~/ STAT
       if ($xXx=~/LATEXF/){  
            $nfields=0;# DONT DO OTHER FIELD OPERATIONS
	    my ($defp)=$xXx=~/LATEXF\(\s*([\w\,\s\.\d]+)\)/;
	    my $defpu=uc($defp); $xXx=~s/$defp/$defpu/;
#	    print "defined befor latexf : $defp\n";
            $xXx=~s/LATEXF\(\s*([\w\,\s\.]+)\)/LATEXF('$defpu')/; 
	    if ($defpu eq ""){$xXx="0";$Warning.=" Err ";}
      }# if xxx=~/ STAT
       if ($xXx=~/SORTF/){  
            $nfields=0;# DONT DO OTHER FIELD OPERATIONS
	    my ($defp)=$xXx=~/SORTF\(\s*(\w[\w\,\s\.]*)\)/;
	    my $defpu=uc($defp); $xXx=~s/$defp/$defpu/;
#	    print "defined befor sortf : $defp\n";
            $xXx=~s/SORTF\(\s*([\w\,\s\.]*)\)/SORTF('$defpu')/; 
	    if ($defpu eq ""){$xXx="0";$Warning.=" Err ";}
      }# if xxx=~/ STAT
       if ($xXx=~/SORTREVF/){  
            $nfields=0;# DONT DO OTHER FIELD OPERATIONS
	    my ($defp)=$xXx=~/SORTREVF\(\s*(\w[\w\,\s\.]*)\)/;
	    my $defpu=uc($defp); $xXx=~s/$defp/$defpu/;
#	    print "defined befor sortf : $defp\n";
            $xXx=~s/SORTREVF\(\s*(\w[\w\,\s\.]*)\)/SORTREVF('$defpu')/; 
	    if ($defpu eq ""){$xXx="0";$Warning.=" Err ";}
      }# if xxx=~/ STAT
  }# field present, check stat functions


#            &display_fields("afterckf");


 if ($debug>=1){print "input line after processin2.5=FLD:$xXx\n";}


 if ($debug>=1){print "#####  after fieldfuncions ###:$xXx\n";}








#''''''''''''''''''''' basic field assignement  '''''like ff=(1,2,3,4)
#       ff=(1,2,3,4,5,6,7,8,9)  
#''''''''''''''''''''' basic field assignement  '''''like ff=(1,2,3,4)
#''''''''''''''''''''' basic field assignement  '''''like ff=(1,2,3,4)
 $OUTPUTFIELD="";  $OUTPUTDIM=0;  ## Globals

 if ($xXx=~/\s*[a-z][\w\d]*\s*\=\s*\([\d\,\.\-\sE\+]+\)$/){ #    f = ( 1,2 )
     print "parsing as simple filed input\n";
     $Warning.=" .smpl fld ass. ";
     my ($a,$b)=( $xXx=~/\s*([a-z][\w\d]*)\s*\=\s*\(([\d\,\.\-\sE\+]+)\)/);
     $b=~s/^\s+//;   $b=~s/\s+$//;  
     $b=~s/\,\s+/\,/g; 
     $b=~s/\s+\,/,/g; 
     if ($b!~/\,/){ $b=~s/\s+/\,/g;} #if b doesnot contain any comma, change spaces into commas
     $b=~s/\s+//g; 
     my @b=split/[\,]+/,$b;
     #     if (exists $fieldvar{uc($a)})  { delete $fieldvar{uc($a)};}
     if ($a ne ""){ # variable name
         $a=uc($a); 
	 if (exists $fieldvar{$a}){delete $fieldvar{$a}; }
         $fieldvar{$a}=\@b;
     }
	$,=" "; # !!! maters with the line cmd!!!
        print " "x 10,"field $a contains (",@{$fieldvar{$a}},") smpas\n";
	$,=""; # !!! maters with the line cmd!!!
     $xXx=$#{$fieldvar{$a}}+1; #MANDATORY - beware KEY!
     $nfields=0;
 }# END  if there is a simple field  assignement .... 



 #======---------------  field assign by operation -------------
 #======---------------  field assign by operation -------------
elsif( ($xXx=~/[a-z][\w\d]*\s*\=/ ) and ($nfields>0) ){#  F2F assignement!!!!
     $Warning.=" .fld assign.";
     my ($a)=( $xXx=~/\s*([a-z][\w\d]*)\s*=/) ;
     $OUTPUTFIELD=uc($a);
     $xXx=~s/\s*[a-z][\w\d]*\s*=//i;# remove assignment if there is an =assignment=
     print "       new field <", lc($OUTPUTFIELD),"> defined by opearation\n";
 #     $xXx=$#{$fieldvar{uc($a)}}+1; #MANDATORY beware KEY!
 }# field assign operation
# END ''''''''''''''''''''' basic field assignement  ''''''''''''''
#         now, field or assigned or the key waits, 
#              $fieldvar{ key } ; key is uppercase



  if ($debug>=1) {print "#####  after basicfldassign###:$xXx\n";}




 #&display_fields("afterassign");

#'''''''''''''' something like loop to replace the field name ''''''''
#                               FLD=>access to elements=  @{$fieldvar{$Ff}}
#                               one element :  ${fieldvar{$Ff}}[0].
 if ($nfields>0){
   my $backxxx=$xXx; 
   my $maxlen_=0;my $len_=0; $xXx=" ".$xXx;#add space
  foreach $Ff (keys %fieldvar){ #UPPERCASE,LENGTHMAX
     my $lff=lc($Ff); 
     $xXx=~s/(\b)$lff(\b)/\1$Ff\2/g; # change to upper
     if ($debug>=1) {print "conversion to one element (tesing $Ff):$xXx\n";}
     if ( $xXx=~/$Ff/){
       $len_=$#{$fieldvar{$Ff}}+1; if ($len_>$maxlen_){$maxlen_=$len_;}
     }
  }#all keys ucase, max length
  $OUTPUTDIM=$maxlen_;
 }#end of eval fieldop....................NFIELDS >0    => act
##############################  Fields now uppercased ##############
# &display_fields("afterReplaceName");


#        &process_field_via_map; # should be suppressed.......
#         &display_fields;   # DEBUG

#------------==================#################################### FIELDEND
#------------==================#################################### FIELDEND
#------------==================#################################### FIELDEND













#--------- variables   '$' ============= prepend $ to connect it to PERL
#--------- variables   '$' ============= prepend $ to connect it to PERL
#--------- variables   '$' ============= prepend $ to connect it to PERL
# $xXx=~s/([a-z][a-z\d]*[^_])/\$$1/g;     #            LOWERCASE ONLY

 if ($debug>=1){print "input line after processin2.7(var):$xXx\n";}
 
  $xXx=" ".$xXx." "; # dirty trick to avoid the startofthelines
$xXx=~s/([^\w\d])([a-z][a-z\d]*)/$1\$$2/g;
  $xXx=~s/^ //;
  $xXx=~s/ $//;

#if ($xXx=~/^[a-z][a-z\d]*[\W\D]/){$xXx=~s/^([a-z][a-z\d]*[\W\D])/\$$1/g;}

#if ($xXx=~/^[a-z][a-z\d]*$/){  $xXx=~s/^([a-z][a-z\d]*)$/\$$1/g;}

#if ($xXx=~/[\W\D][a-z][a-z\d]*[\W\D]/){$xXx=~s/[\W\D]([a-z][a-z\d]*)[\W\D]/\$$1/g;}
#if ($xXx=~/[\W\D][a-z][a-z\d]*$/){$xXx=~s/([\W\D][a-z][a-z\d]*)$/\$$1/g;}


 if ($debug>=1){print "input line after processin3(var):$xXx\n";}





#-- zkusim hodiny:minuty:vteriny ------ 060808 conversion back   ok
 if ($xXx eq ":"){
     my $h=int($Res/60); my $m=$Res % 60; 
     $xXx=sprintf("%02d:%02d",$h,$m); printf("%s%5s\n"," "x($offs-1),$xXx);
 }
 if ($xXx eq "::"){
     my $h=int($Res/3600); my $m=$Res % 3600; 
     my $m2=$m/60; my $s=$m % 60;
     $xXx=sprintf("%02d:%02d:%02d",$h,$m2,$s); printf("%s%8s\n"," "x($offs-1),$xXx);
 }

# convert ( display as )to HEXA hexa 
  if ($xXx eq "0x"){  
      if ($Res>4294967296){print "too high number\n";}
      $xXx=$Res;      my $w= sprintf("%s0x%x\n"," "x($offs-1),$Res); print $w; #cannot do >ffff ffff
  }


# convert ( display as )to DEC hexa 
#  if ($xXx eq "0d"){  
#      $xXx=$Res;      my $w= sprintf("%s0d%16i\n"," "x($offs-1),$Res); print $w; #cannot do more
#  }



# convert ( display as )to BINARY binary
  if ($xXx eq "0b"){  
      $xXx=$Res;       my $w1=sprintf("%s0b "," "x($offs-1));
      print $w1;       # print spaces and 0b     #### process 4 digits by 4 digits
      my $w=sprintf("%b",$Res);
      my $w2="";
      my $indx=length($w)-4; if ($indx<0){$indx=0;}
      my $ww=4;
      while (1==1){
       if ($indx<0){ $ww=$ww+$indx; $indx=0;  }
       $w2=" ".substr($w,$indx, $ww).$w2;
#       print $w2," M\n";
       if ($indx==0){ last;}
	$indx-=4;
      }
      print $w2,"\n";
  }





#-- zkusim hodiny:minuty:vteriny ------ 050505    ok
 $xXx=~s/(\d+)(\:)(\d+)(\:)(\d+)/($1*3600+$3*60+$5)/ge;
 $xXx=~s/(\d+)(\:)(\d+)/($1*60+$3)/ge;



 if ($debug>=1){print "input line after processin4:$xXx\n";}
#&display_fields("beforeFieldProc");
 &process_field; # FIELD PROCESS !!!!!!!!
# &display_fields("afterFieldProc");


 if ($debug>=1){print "input line after processin5+res:$xXx; $Res\n";}




 if ($DO>0){  print " "x$offs,">$xXx<\n";}



#============== DEFAULT OPERATION==== and COMMANDS =====
 if ($xXx eq "+"){$Defoperat="+";$xXx="DOD";&dod;}
 if ($xXx eq "-"){$Defoperat="-";$xXx="DOD";&dod;}
 if ($xXx eq "*"){$Defoperat="*";$xXx="DOD";&dod;}

# 3 times means  other default operation
 if ($xXx=~/[\+\-\*\/]{3}/){$Defoperat=$xXx;$xXx="DOD";&dod;}

 if ($xXx=~/^\-/){$Warning.="\t\t...!substaction..";}


#================== COMMANDS==========================
 if ($xXx=~/&XMGRACEON/){$xXx="DOD";
          print "display on  drawf()\n"; $XmgON=1;}
 if ($xXx=~/&XMGRACEOFF/){$xXx="DOD";
          print "no display on drawf()\n"; $XmgON=0;}
 if ($xXx=~/&DEG/){$xXx="DOD";
          print "goniometric in degrees\n"; $R2dc=3.1415926/180;}
 if ($xXx=~/&RAD/){$xXx="DOD";
          print "goniometric in radians\n"; $R2dc=1;}

 if ($xXx=~/&HELPCATCH/){$xXx="DOD";
          print "$Helpcatch";}
 if ($xXx=~/&HELPFYZ/){$xXx="DOD";
          print "$Helpfyz\navailable funcions:  @functions\n";}
 if ($xXx=~/&HELPF/){$xXx="DOD";
          print "$Helpf\navailable funcions:  @functions\n";}
 if ($xXx=~/&HELPM/){$xXx="DOD";
          print "$Help_mat\n\n";}
 if ($xXx=~/&HELPV/){$xXx="DOD";
          print "$Helpv\n\n";}
 if ($xXx=~/&HELP/){$xXx="DOD";
          print "$Help";}
 if ($xXx=~/&MAT/){$xXx="DOD";
          print "type  quit to quit\n";
          system("mathomatic");
#          system("echo Slepice spi.> ");
 }
 if ($xXx=~/&QUIT/){$xXx="DOD";
          close TTY;
          system "stty  -cbreak   </dev/tty >/dev/tty 2>&1"; 
          print "Good bye...\n"; &exit_with_history;}
 if ($xXx=~/&SHOWF/){$xXx="DOD";
          print "_________displaying fields________\n"; &display_fields;}
#         &display_fields;   # DEBUG






 if ($debug>=1){print "input line after processin6(if # only)+res:$xXx, $Res\n";}

#============== CO KDYZ JENOM CISLO



 if ($xXx ne "DOD"){  ###############  skip if DOD ######
#============== change LINE mark -,=   and reset
 if (($Line=~/\-\-/)and($xXx eq "")){
   $Linemark="="; $Res="0";
   #  fix  comment '#' 
   if ($xXx=~/^#/){
        $Linemark="-";
   }
 }elsif(($Line=~/\=\=/)and($xXx eq "")){ # .........save .calc.pl
     &exit_with_history;
 }else{
   $Linemark="-"
 }# if ------ line ------ ===========


 if ($debug>=1){print "input line after processin7(if # only)+res:$xXx, $Res\n";}



 #------ if begins with =, placed at the end // assign to variable via =
 if ($xXx=~/^\=/){
    $xXx=substr($xXx,1,length($xXx)-1)."=";
 }



# OPERATION ON LAST NUMBER:
#===================== pokud koncime znakem .. znamena to operaci na minulem
#===================== ending with +-/* etc ==> operation on the last result
 if ($xXx=~/[\+\-\*\/\=\&\|]$/){
   if ((substr($xXx,length($xXx)-1,1) eq "-")and(substr($Res,0,1) eq "-")){
       $xXx=substr($xXx,0,length($xXx)-1)."+";
       $Res=substr($Res,1,length($Res)-1);
   }
   $xXx=$xXx."$Res";
}#====END======= ending by oper.
 elsif ($xXx=~/^\s*[\+\-\*\/\=\|]/ or $xXx=~/^\s*\&[\d\s]/){#===== beginning by operator
   $xXx="($Res)".$xXx;  # eg. (-45)**2
 }




# if ($debug>=1){print "input line after processin7.5(if # only)+res:$xXx, $Res\n";}



#=========  NO ARGUMENT - TRANSLATE TO THE LAST RESULT= ARGUMENT
#=========  pokud je jenom tohle, ber argument z vysledku
 if ($xXx eq "&SQRT()"){   $xXx="&SQRT($Res)"; }
 if ($xXx eq "&EXP()"){    $xXx="&EXP($Res)"; }
 if ($xXx eq "&LN()"){     $xXx="&LN($Res)"; }
 if ($xXx eq "&LOG()"){    $xXx="&LOG($Res)"; }
 if ($xXx eq "&SIN()"){    $xXx="&SIN($Res)"; }
 if ($xXx eq "&COS()"){    $xXx="&COS($Res)"; }
 if ($xXx eq "&TAN()"){    $xXx="&TAN($Res)";}
 if ($xXx eq "&ATAN()"){   $xXx="&ATAN($Res)"; }
 if ($xXx eq "&ASIN()"){   $xXx="&ASIN($Res)"; }
 if ($xXx eq "&ACOS()"){   $xXx="&ACOS($Res)"; }

 if ($xXx eq "&P0()"){  $xXx="&P0($Res)"; }
 if ($xXx eq "&P2()"){  $xXx="&P2($Res)"; }
 if ($xXx eq "&P4()"){  $xXx="&P4($Res)"; }

 if ($xXx eq "&POW()"){  $xXx="&POW($Res)"; }

#-------  financial
 if ($xXx eq "&GETINTER()"){  $xXx="&GETINTER($Res)"; }
 if ($xXx eq "&SOLVEINTERM()"){  $xXx="&SOLVEINTERM($Res)"; }
 if ($xXx eq "&SOLVEINTERI()"){  $xXx="&SOLVEINTERI($Res)"; }


#------- conversions
 if ($xXx eq "&BB2T12()"){  $xXx="&BB2T12($Res)"; }
 if ($xXx eq "&BW2T12()"){  $xXx="&BW2T12($Res)"; }
 if ($xXx eq "&T122BB()"){  $xXx="&T122BB($Res)"; }
 if ($xXx eq "&B2B()"){  $xXx="&B2B($Res)"; }

 if ($xXx eq "&TOF2E()"){  $xXx="&TOF2E($Res)"; }
 if ($xXx eq "&E2TOF()"){  $xXx="&E2TOF($Res)"; }

 if ($xXx eq "&TIME2SEC()"){  $xXx="&TIME2SEC($Res)"; }
 if ($xXx eq "&SEC2TIME()"){  $xXx="&SEC2TIME($Res)"; }
 if ($xXx eq "&SEC2TIMED()"){  $xXx="&SEC2TIMED($Res)"; }


#NO SENSE  if ($xXx eq "&BATCH()"){  $xXx="&BATCH($Res)"; }
#-- nonsense
# if ($xXx eq "&AVG"){  $xXx="&AVG($Res)"; }
# if ($xXx eq "&MEDIAN"){  $xXx="&MEDIAN($Res)"; }
# if ($xXx eq "&SUM"){  $xXx="&SUM($Res)"; }

#print $xXx,"\n";
# if ($xXx eq "sqrt"){   $xXx="sqrt($Res)"; }



 #====================  clear default operation
 if (($Defoperat ne "")and($xXx eq "")){
   print "default operation cleared\n";
   $Defoperat="";
 }
 
#==================   make default operation!!!
 #==================   make default operation!!!
 # print "x=$xXx   res=$Res  dop=$Defoperat \n";
 if (($Defoperat ne "")and($xXx ne "")){
     if (length($Defoperat)>1){ 
         # if trityp (+++2 or ///1.5  or ***8) DO (currline) opnum' 
	 my $Defoperatqqq=substr($Defoperat,2,length($Defoperat)-2);
	 $xXx="($xXx)$Defoperatqqq";
     }else{
    $xXx="$Res$Defoperat($xXx)";  #this makes:  res op (currline) e.g. 2+1
     } # DOD as length==1 (is it 1?)
 }
# print "x=$xXx   res=$Res  dop=$Defoperat \n";
#==== dobre - operace na minulem ok



if ($debug>=1){print "input line after processin7.5+res:$xXx, $Res\n";}




$Line="";
#========================= eval if not CRLF
 if (length($xXx)<=0) {
   while (length($Line)<=$offs){      $Line.=$Linemark;   }
 }else{ ################   EVAL !!!!!!!###############
        ################   EVAL !!!!!!!###############
        ################   EVAL !!!!!!!###############
     my $att=0;
    if ($xXx=~/[\D]0+[1-9]+\./ or $xXx=~/^0+[1-9]+\./ ) 
#          { $att=1; $Warning.="WARNING:bug due to perl EVAL may appear!!\n";}
            { $att=1; $Warning.="WARNING:bug 001.234 !!";}

#     &display_fields("EVAl");
#print "\nEVALEVALEVALEVALEVALEVALEVALEVALEVALEVALEVALEVALEVALEVAL\n";
#print "$xXx\n";
    $Res=eval($xXx) if ( ($xXx ne "")&&($xXx!~/^#/) ); 
     if ($att==1 and $Res!~/\./){ $Warning.=" YES!!!";}
#print "EVALEVALEVALEVALEVALEVALEVALEVALEVALEVALEVALEVALEVALEVAL\n";

#     &display_fields("EVAl");

#   @res=eval($xXx) if ($xXx ne ""); # Why?
        ################   EVAL !!!!!!!###############
        ################   EVAL !!!!!!!###############
 }

 if ($debug>=1){print "input line after processin8(displ)+res:$xXx; $Res\n";}

#  &display($Res);#<<<<<========================  DISPLAY THE RESULT
  &display2($Res);#<<<<<========================  DISPLAY THE RESULT

 if ($debug>=1){print "input line after processin9(displ)+res:$xXx, $Res\n";}


 }###### skip if DOD ########

}##########################################WHILE






sub EXP{my $a=shift;$a=eval($a);return exp($a);}
sub SQRT{my $a=shift;$a=eval($a);return sqrt($a);}
###sub SQRT{my $a=shift;$a=eval($a);return ;}

sub LOG{my $a=shift;$a=eval($a);return log($a)/log(10);}
sub LN{my $a=shift;$a=eval($a);return log($a);}


sub SIN{my $a=shift;$a=$R2dc*eval($a);return sin($a);}
#sub COS{my $a=shift;$a=$R2dc*eval($a);return sqrt(1-sin($a)*sin($a));}
sub COS{my $a=shift;$a=$R2dc*eval($a);return cos($a);}
sub TAN{my $a=shift;$a=$R2dc*eval($a);  my $sig;
	if (cos($a)<0){$sig=-1;}else{$sig=1;}
    return $sig*sin($a)/sqrt(1-sin($a)*sin($a));
}

sub ATAN{my $a=shift;$a=eval($a);return atan2($a,1)/$R2dc;}
sub ASIN{my $a=shift;$a=eval($a);return atan2($a, sqrt(1 - $a * $a))/$R2dc;}
sub ACOS{my $a=shift;$a=eval($a);return  atan2( sqrt(1-$a*$a), $a)/$R2dc;}
#--- legendovy polynomy
sub P0{my $a=shift;return  1;}
sub P2{my $a=shift;$a=eval($a);return  0.5*(3*$a*$a-1);}
sub P4{my $a=shift;$a=eval($a);return  1/8*(35*$a*$a*$a*$a-30*$a*$a+3);}

sub POW{
  my ($a,$b)=@_; 
  $a=eval($a);
  $b=eval($b);
  return $a**$b;
}

# ----- conversions
#?#####--- nerekurzivni funkce ######## NONRECURSIVE FUNCTIONS ##########
sub T122BB{
  my ($E,$t12,$sL)=@_;
  $sL=~s/\$//g; $sL=uc($sL);
  print "($E,$t12,$sL)\n";
  my $C,$L;  ($L)=($sL=~/(\d)$/); 
 SWITCH:{
   if($sL eq "E1"){$C=4.4E-9;  last SWITCH;}
   if($sL eq "E2"){$C=5.63E+1; last SWITCH;}
   if($sL eq "E3"){$C=1.21E+12;last SWITCH;}
   if($sL eq "M1"){$C=3.96E-5; last SWITCH;}
   if($sL eq "M2"){$C=5.12E+5; last SWITCH;}
   if($sL eq "M3"){$C=1.09E+16;last SWITCH;}
 }
 $E=eval($E);   $t12=eval($t12);
  print "input: energy in kev,  halflife in sec,  multipolarity\n";
  print "C=$C   E=$E keV   L=$L    T12=$t12 s  ->  e2b^$L\n";
  return $C/(  $E**(2*$L+1) * $t12  );
}


sub T122BW{
  my ($E,$t12,$sL,$A)=@_;
   $sL=~s/\$//g; $sL=uc($sL);
  my $C,$L;  ($L)=($sL=~/(\d)$/); 
 SWITCH:{
   if($sL eq "E1"){$C=4.4E-9;  last SWITCH;}
   if($sL eq "E2"){$C=5.63E+1; last SWITCH;}
   if($sL eq "E3"){$C=1.21E+12;last SWITCH;}
   if($sL eq "M1"){$C=3.96E-5; last SWITCH;}
   if($sL eq "M2"){$C=5.12E+5; last SWITCH;}
   if($sL eq "M3"){$C=1.09E+16;last SWITCH;}
 }
 $E=eval($E);   $t12=eval($t12);
  print "input: energy in kev; halflife in sec;  multipol.; A-nucl\n";
  print "C=$C   E=$E keV   L=$L    T12=$t12 s  ->  e2b^$L\n";
  my $B=$C/(  $E**(2*$L+1) * $t12  );
  $B=B2B($B,$sL,'BW',$A); # intermediate conversion  
  return $B;
}


sub BB2T12{
  my ($E,$B,$sL)=@_;
   $sL=~s/\$//g; $sL=uc($sL);
  my $C,$L;  ($L)=($sL=~/(\d)$/); 
 SWITCH:{
   if($sL eq "E1"){$C=4.4E-9;  last SWITCH;}
   if($sL eq "E2"){$C=5.63E+1; last SWITCH;}
   if($sL eq "E3"){$C=1.21E+12;last SWITCH;}
   if($sL eq "M1"){$C=3.96E-5; last SWITCH;}
   if($sL eq "M2"){$C=5.12E+5; last SWITCH;}
   if($sL eq "M3"){$C=1.09E+16;last SWITCH;}
 }
 $E=eval($E);   $B=eval($B);
  print "input: energy in kev; value of B in e.b^N;  multipolarity  \n";
  print "C=$C   E=$E keV   L=$L    B=$B eb^$L  -> sec\n";
  return $C/(  $E**(2*$L+1) * $B  );
}

sub BW2T12{
  my ($E,$B,$sL,$A)=@_;
   $sL=~s/\$//g; $sL=uc($sL);
  $B=B2B($B,$sL,'WB',$A); # intermediate conversion
  my $C,$L;  ($L)=($sL=~/(\d)$/); 
  my $oval;
 SWITCH:{
   if($sL eq "E1"){$C=4.4E-9;  last SWITCH;}
   if($sL eq "E2"){$C=5.63E+1; last SWITCH;}
   if($sL eq "E3"){$C=1.21E+12;last SWITCH;}
   if($sL eq "M1"){$C=3.96E-5; last SWITCH;}
   if($sL eq "M2"){$C=5.12E+5; last SWITCH;}
   if($sL eq "M3"){$C=1.09E+16;last SWITCH;}
 }
 $E=eval($E);   $B=eval($B);
  print "input B2T: energy in kev; value of B in w.u.; multipol.; A-nucl  \n";
  $oval= $C/(  $E**(2*$L+1) * $B  );
  print "C=$C   E=$E keV   L=$L    B=$B eb^$L  -> $oval sec\n";
  return $oval;
}


sub B2B{
  my ($B,$sL,$ctyp)=@_; 
   $ctyp=~s/\$//g; $ctyp=uc($ctyp);
   $sL=~s/\$//g; $sL=uc($sL);
  my $AA=@_[3] || eval($a) || 0;
  my $L,$sig;  ($L)=($sL=~/(\d)$/); ($sig)=($sL=~/^(\D)/); 
  my $out, $wu1,$ct2; ($ct2)=($ctyp=~/(.)$/); 
  $B=eval($B);
  $AA=eval($AA);
  print " input B2B: B-value;  multipol.(e.g.E2); conver.(e.g.BW,FW..); A-nucl\n";
  print " B=$B sigL=$sL   sig=$sig  L=$L  A=$AA convtyp=$ctyp ";
#---------------  final UNIT
  if ($sig eq "E"  and  $ct2 eq "B"){$out="e^2 b^$L";}
  if ($sig eq "E"  and  $ct2 eq "F"){$out="e^2 fm^".(2*$L);}
  if ($sig eq "E"  and  $ct2 eq "W"){$out="wu";}
  if ($sig eq "M"  and  $ct2 eq "B"){$out="muN^2 b^".($L-1);}
  if ($sig eq "M"  and  $ct2 eq "F"){$out="e^2 fm^".(2*$L-2);}
  if ($sig eq "M"  and  $ct2 eq "W"){$out="wu";}
#---------------  1wu in e2bL, muN2bL-1
 SWITCH:{
   if($sL eq "E1"){$wu1=6.45E-4*$AA**(2/3); last SWITCH;}
   if($sL eq "E2"){$wu1=5.94E-6*$AA**(4/3); last SWITCH;}
   if($sL eq "E3"){$wu1=6.0E-8*$AA**(2);    last SWITCH;}
   if($sL eq "M1"){$wu1=1.79;              last SWITCH;}
   if($sL eq "M2"){$wu1=1.66E-2*$AA**(2/3); last SWITCH;}
   if($sL eq "M3"){$wu1=1.66E-4*$AA**(4/3); last SWITCH;}
 }

 SWITCH1:{
   if($sig eq "E" and $ctyp eq "BF"){$B=$B*10**(2*$L);last SWITCH1;}
   if($sig eq "E" and $ctyp eq "FB"){$B=$B/10**(2*$L);last SWITCH1;}
   if($sig eq "E" and $ctyp eq "FW"){$B=$B/10**(2*$L)/$wu1;last SWITCH1;}
   if($sig eq "E" and $ctyp eq "WF"){$B=$B*10**(2*$L)*$wu1;last SWITCH1;}

   if($ctyp eq "BW"){$B=$B/$wu1;last SWITCH1;}
   if($ctyp eq "WB"){$B=$B*$wu1;last SWITCH1;}

   if($sig eq "M" and $ctyp eq "BF"){$B=$B*10**(2*$L-2);last SWITCH1;}
   if($sig eq "M" and $ctyp eq "FB"){$B=$B/10**(2*$L-2);last SWITCH1;}
   if($sig eq "M" and $ctyp eq "FW"){$B=$B/10**(2*$L-2)/$wu1;last SWITCH1;}
   if($sig eq "M" and $ctyp eq "WF"){$B=$B*10**(2*$L-2)*$wu1;last SWITCH1;}
 }
  print "  ->$B  $out\n";
  return $B;
}

sub BATCH{
    my $OUD=shift;
    $Batch="";# change default batch in this moment
	$OUD=~s/\$//;   $OUD= lc($OUD);  $OUD=~s/\s+//g;
	print "in batch (1 file==$OUD ; @_     (OUD) )\n";
	print "IN BATCH (2 file==$FileNameSeen ; @_)\n";
#	print "IN BATCH (3 file==$FileNameSeen ; @_)\n";
#	print "IN BATCH (4 file==$FileNameSeen ; @_)\n";
#	print "IN BATCH (5 file==$FileNameSeen ; @_)\n";
#    	open IN,$OUD;
    	open IN,$FileNameSeen;
	while(<IN>){
            $_=~s/^\s+//;
	    $_=~s/^#.*$//;  #clear any comment
	    $Batch.=$_ if ( $_=~/\S/ );
	}
	close IN;
    print "\n====BATCH FILE CONTAINS=====\n$Batch============================\n";
    @Batch=split /\n/, $Batch;
}


sub TOF2E{
    my ($t, $l ,$A)=@_;
    $t=eval($t);
    $l=eval($l);
    $A=eval($A);
    print "  t=$t ns, dist=$l m, mother A=$A;    result in MeV\n";
    my $vc=$l/ $t/1e-9/1e+8/3;  # (v/c) time in ns; c=3e+8
    my $m=939.565330;
    my $gamma=1/sqrt((1-($vc)**2));
    my $pc=$gamma*$m*$vc;
    my $E=sqrt($pc**2 + $m**2) - $m;
#    print "Neutron energy            = $E\n";
    $E=$E*($A/($A-1));  #  recoil correction... Eexc=En*Amother/(Amother-1)
 return $E;
}
sub E2TOF{
    my ($E, $l ,$A)=@_;
    $E=eval($E);
    $l=eval($l);
    $A=eval($A);
    print "  E=$E MeV, dist=$l m, mother A=$A;   result in ns\n";
    $E=$E/($A/($A-1)); # En = less then Eexc because of recoil
    my $m=939.565330;
    my $pc=sqrt( ($E+$m)**2  -  $m**2);
    my $vc=sqrt(   ($pc/$m)**2 / (($pc/$m)**2 + 1)    );
    my $t=$l/$vc/3e+8 * 1e+9;
    return $t;
}






sub SEC2TIME{
    my($t)=@_;
    my ($y,$mo,$d,$h,$mi,$s);
    $t=eval($t);
    ($s,$mi,$h,$d,$mo,$y)=localtime($t);
    $y=$y+1900;
    $mo=$mo+1;
    print "    date(dmy)=$d.$mo.$y   time=$h:$mi:$s  \n";   
    return $t;
}
sub SEC2TIMED{
    my($t)=@_;
    my ($y,$mo,$d,$h,$mi,$s);
    my $iy=($t/3600.0/24/365);
    my $id=($t-int($iy)*3600*24*365)/24/3600;
    my $ih=($t-int($iy)*365*24*3600-int($id)*24*3600)/3600;
   my $im=($t-int($iy)*365*24*3600-int($id)*24*3600-int($ih)*3600)/60;
    print $iy," year(s) \n";
    print int($iy)," year(s)  ",int($id)," day(s) ",
int($ih)," hours ",$im," minutes\n";
#    $t=eval($t);
#    ($s,$mi,$h,$d,$mo,$y)=localtime($t);
#    $y=$y+1900 - 1970;
#    $mo=$mo+1 -1;
#    $d=$d+
#    $h=$h-1;
#    print "    date(dmy)=$d.$mo.$y   time=$h:$mi:$s  \n";   
    return $t;
}

sub TIME2SEC{
    my ($y,$mo,$d,$h,$mi,$s)=@_;
    my $t;
    $y=eval($y);
    $mo=eval($mo);
    $d=eval($d);
    $h=eval($h);
    $mi=eval($mi);
    $s=eval($s);
    if ($y<1960){print "\n\n\nI dont know to work under 1970\n sorry\n\n";}else{
#     print "    date(dmy)=$d.$mo.$y   time=$h:$mi:$s   ==>  $t sec\n";
     $t=timelocal($s, $mi, $h, $d, $mo-1, $y-1900); # year just 2 digs, mon=0-11 in perl
     print "    date(dmy)=$d.$mo.$y   time=$h:$mi:$s   ==>  $t sec\n";
    }
    return $t;
}




 sub GETINTER{
    my ($ur,$months,$start,$momonthly,$moyearly, $quiet)=@_;
    if ($quiet!=111){
    print "interest=",$ur*100,"% yearly   #-months=$months  bias=$start\$  each-month=$momonthly\$  each-year=$moyearly\$\n"; }

    my $n;
    $ur+=1;
    $ur=$ur**(1/12); # monthly interst
    my $tot=$start;
    my $totinv=$tot;

    foreach ($n=1;$n<=$months;$n++){
      $tot=$tot*$ur+$momonthly;
      $totinv+=$momonthly;
      if ($n%12 == 0){$tot+=$moyearly;$totinv+=$moyearly;}
  #     print "$n        $tot\n";
    }
  #  print "$tot        $totinv    \n";
    return $tot;
 }



 sub SOLVEINTERM{
    my ($aim,$ur,$start,$momonthly,$moyearly)=@_;
    print "aim=$aim\$  interest=",$ur*100,"% yearly    bias=$start\$  each-month=$momonthly\$  each-year=$moyearly\$\n";
    my $montlo=0;my $monthi=100*12;  my $mont; my $to;
   my $tolo=&GETINTER($ur,$montlo,$start,$momonthly,$moyearly ,111);
   my $tohi=&GETINTER($ur,$monthi,$start,$momonthly,$moyearly ,111);
   if ($aim<$tolo or $aim>$tohi){
       print " time to save $aim\$ is out of 0-100*12 months ($tolo, $tohi,)\n"; return;
   }
   foreach (1..20){
    $mont=int(($monthi+$montlo)/2);
    $to=&GETINTER($ur,$mont,$start,$momonthly,$moyearly, 111);
    if ($to>$aim){$tohi=$to;$monthi=$mont;}else
    {$tolo=$to;$montlo=$mont;}
   }
   my $dmont=($montlo - $monthi )/2;
   my $mont=$montlo+$dmont;
   print " $mont  +- $dmont months to save for $aim \$\n";
   return $mont;
 }


 #_____________________________solve for interest
 sub SOLVEINTERI{
    my ($aim,$months,$start,$momonthly,$moyearly)=@_;
    print "aim=$aim\$  #-months=$months   bias=$start\$  each-month=$momonthly\$  each-year=$moyearly\$\n";
   my $urlo=0;my $urhi=2;  my $mont; my $to;
   my $tolo=&GETINTER($urlo, $months,$start,$momonthly,$moyearly ,111);
   my $tohi=&GETINTER($urhi, $months,$start,$momonthly,$moyearly ,111);
   if ($aim<$tolo or $aim>$tohi){
       print "out of 0-100% interest\n"; return;
   }
   foreach (1..20){
    $ur=($urhi+$urlo)/2;
    $to=&GETINTER($ur,$months,$start,$momonthly,$moyearly , 111);
    if ($to>$aim){$tohi=$to;$urhi=$ur;}else
    {$tolo=$to;$urlo=$ur;}
    #print "$to\n";
   }
   my $dint=($urlo - $urhi )/2;
   my $int=$urlo+$dint;
    $int*=100;
    $dint*=100;
   printf(" estim. interest to achieve %f\$ is %.3f +- %.3f \%\n",$aim, $int, $dint);
   return $int/100;
 }


sub MEX{
    my $a=shift;
    my $z=shift;
    my $verb=shift or  1;
    my %mex;
$mex{"1:0"}=8.0713171; 	$dmex{"1:0"}=5e-04; 
#$mex{"1:0"}=8.071323; 	$dmex{"1:0"}=2e-06; 
$mex{"1:1"}=7.2889705; 	$dmex{"1:1"}=1.1e-07; 
$mex{"2:1"}=13.13572158; 	$dmex{"2:1"}=3.5e-07; 
$mex{"3:1"}=14.949806; 	$dmex{"3:1"}=2.31e-06; 
$mex{"4:1"}=25.901518; 	$dmex{"4:1"}=0.103286; 
$mex{"5:1"}=32.89244; 	$dmex{"5:1"}=0.1; 
$mex{"3:2"}=14.93121475; 	$dmex{"3:2"}=2.42e-06; 
$mex{"4:2"}=2.42491565; 	$dmex{"4:2"}=6e-08; 
$mex{"5:2"}=11.386233; 	$dmex{"5:2"}=0.05; 
$mex{"6:2"}=17.595106; 	$dmex{"6:2"}=0.000755; 
$mex{"7:2"}=26.101038; 	$dmex{"7:2"}=0.016658; 
$mex{"8:2"}=31.598044; 	$dmex{"8:2"}=0.006868; 
$mex{"9:2"}=40.939429; 	$dmex{"9:2"}=0.029418; 
$mex{"10:2"}=48.809203; 	$dmex{"10:2"}=0.070001; 
$mex{"4:3"}=25.323185; 	$dmex{"4:3"}=0.212132; 
$mex{"5:3"}=11.678886; 	$dmex{"5:3"}=0.05; 
$mex{"6:3"}=14.086793; 	$dmex{"6:3"}=1.5e-05; 
$mex{"7:3"}=14.908141; 	$dmex{"7:3"}=7.9e-05; 
$mex{"8:3"}=20.946844; 	$dmex{"8:3"}=9.5e-05; 
$mex{"9:3"}=24.954264; 	$dmex{"9:3"}=0.001935; 
$mex{"10:3"}=33.050581; 	$dmex{"10:3"}=0.015124; 
$mex{"11:3"}=40.79731; 	$dmex{"11:3"}=0.019295; 
$mex{"6:4"}=18.374947; 	$dmex{"6:4"}=0.005448; 
$mex{"7:4"}=15.770034; 	$dmex{"7:4"}=0.000106; 
$mex{"8:4"}=4.941672; 	$dmex{"8:4"}=3.5e-05; 
$mex{"9:4"}=11.347648; 	$dmex{"9:4"}=0.000398; 
$mex{"10:4"}=12.60667; 	$dmex{"10:4"}=0.000401; 
$mex{"11:4"}=20.174064; 	$dmex{"11:4"}=0.006356; 
$mex{"12:4"}=25.076506; 	$dmex{"12:4"}=0.015005; 
$mex{"13:4"}=33.247823; 	$dmex{"13:4"}=0.07159; 
$mex{"14:4"}=39.954498; 	$dmex{"14:4"}=0.132245; 
$mex{"7:5"}=27.868346; 	$dmex{"7:5"}=0.070712; 
$mex{"8:5"}=22.92149; 	$dmex{"8:5"}=0.001; 
$mex{"9:5"}=12.415681; 	$dmex{"9:5"}=0.000983; 
$mex{"10:5"}=12.050731; 	$dmex{"10:5"}=0.000386; 
$mex{"11:5"}=8.667931; 	$dmex{"11:5"}=0.000418; 
$mex{"12:5"}=13.368899; 	$dmex{"12:5"}=0.0014; 
$mex{"13:5"}=16.562166; 	$dmex{"13:5"}=0.001084; 
$mex{"14:5"}=23.663683; 	$dmex{"14:5"}=0.021213; 
$mex{"15:5"}=28.972278; 	$dmex{"15:5"}=0.022369; 
$mex{"16:5"}=37.081686; 	$dmex{"16:5"}=0.06; 
$mex{"17:5"}=43.770816; 	$dmex{"17:5"}=0.170873; 
$mex{"8:6"}=35.09406; 	$dmex{"8:6"}=0.023068; 
$mex{"9:6"}=28.910491; 	$dmex{"9:6"}=0.002138; 
$mex{"10:6"}=15.698682; 	$dmex{"10:6"}=0.000403; 
$mex{"11:6"}=10.650342; 	$dmex{"11:6"}=0.00095; 
$mex{"12:6"}=00.000000; 	$dmex{"12:6"}=1e-9   ; 
$mex{"13:6"}=3.12501129; 	$dmex{"13:6"}=9.1e-07; 
$mex{"14:6"}=3.01989305; 	$dmex{"14:6"}=3.8e-06; 
$mex{"15:6"}=9.873144; 	$dmex{"15:6"}=0.0008; 
$mex{"16:6"}=13.694129; 	$dmex{"16:6"}=0.003578; 
$mex{"17:6"}=21.038832; 	$dmex{"17:6"}=0.017376; 
$mex{"18:6"}=24.926178; 	$dmex{"18:6"}=0.030006; 
$mex{"19:6"}=32.420666; 	$dmex{"19:6"}=0.098391; 
$mex{"20:6"}=37.55761; 	$dmex{"20:6"}=0.239161; 
$mex{"10:7"}=38.800148; 	$dmex{"10:7"}=0.4; 
$mex{"11:7"}=24.303569; 	$dmex{"11:7"}=0.046156; 
$mex{"12:7"}=17.338082; 	$dmex{"12:7"}=0.001; 
$mex{"13:7"}=5.345481; 	$dmex{"13:7"}=0.00027; 
$mex{"14:7"}=2.86341704; 	$dmex{"14:7"}=5.8e-07; 
$mex{"15:7"}=0.10143805; 	$dmex{"15:7"}=7e-07; 
$mex{"16:7"}=5.683658; 	$dmex{"16:7"}=0.002622; 
$mex{"17:7"}=7.871368; 	$dmex{"17:7"}=0.015013; 
$mex{"18:7"}=13.114466; 	$dmex{"18:7"}=0.01858; 
$mex{"19:7"}=15.862129; 	$dmex{"19:7"}=0.016415; 
$mex{"20:7"}=21.76511; 	$dmex{"20:7"}=0.05559; 
$mex{"21:7"}=25.251164; 	$dmex{"21:7"}=0.095045; 
$mex{"22:7"}=32.038675; 	$dmex{"22:7"}=0.192213; 
$mex{"23:7"}=36.682; 	$dmex{"23:7"}=0.855; 
$mex{"12:8"}=32.047954; 	$dmex{"12:8"}=0.018466; 
$mex{"13:8"}=23.112428; 	$dmex{"13:8"}=0.009526; 
$mex{"14:8"}=8.007356; 	$dmex{"14:8"}=0.000109; 
$mex{"15:8"}=2.855605; 	$dmex{"15:8"}=0.000491; 
$mex{"16:8"}=-4.73700141; 	$dmex{"16:8"}=1.6e-07; 
$mex{"17:8"}=-0.808813; 	$dmex{"17:8"}=0.00011; 
$mex{"18:8"}=-0.781522; 	$dmex{"18:8"}=0.000621; 
$mex{"19:8"}=3.33487; 	$dmex{"19:8"}=0.002825; 
$mex{"20:8"}=3.797462; 	$dmex{"20:8"}=0.001081; 
$mex{"21:8"}=8.062906; 	$dmex{"21:8"}=0.012016; 
$mex{"22:8"}=9.284152; 	$dmex{"22:8"}=0.056924; 
$mex{"23:8"}=14.617; 	$dmex{"23:8"}=0.078; 
$mex{"24:8"}=18.594; 	$dmex{"24:8"}=0.098; 
$mex{"15:9"}=16.775372; 	$dmex{"15:9"}=0.133793; 
$mex{"16:9"}=10.680254; 	$dmex{"16:9"}=0.008321; 
$mex{"17:9"}=1.951701; 	$dmex{"17:9"}=0.000248; 
$mex{"18:9"}=0.873701; 	$dmex{"18:9"}=0.000534; 
$mex{"19:9"}=-1.487386; 	$dmex{"19:9"}=6.9e-05; 
$mex{"20:9"}=-0.017404; 	$dmex{"20:9"}=7.5e-05; 
$mex{"21:9"}=-0.047551; 	$dmex{"21:9"}=0.001801; 
$mex{"22:9"}=2.793378; 	$dmex{"22:9"}=0.012399; 
$mex{"23:9"}=3.329747; 	$dmex{"23:9"}=0.079541; 
$mex{"24:9"}=7.559527; 	$dmex{"24:9"}=0.072282; 
$mex{"25:9"}=11.348; 	$dmex{"25:9"}=0.065; 
$mex{"26:9"}=18.608; 	$dmex{"26:9"}=0.069; 
$mex{"27:9"}=24.69; 	$dmex{"27:9"}=0.169; 
$mex{"16:10"}=23.996462; 	$dmex{"16:10"}=0.02048; 
$mex{"17:10"}=16.460901; 	$dmex{"17:10"}=0.026953; 
$mex{"18:10"}=5.317166; 	$dmex{"18:10"}=0.00028; 
$mex{"19:10"}=1.75144; 	$dmex{"19:10"}=0.000286; 
$mex{"20:10"}=-7.04193131; 	$dmex{"20:10"}=1.79e-06; 
$mex{"21:10"}=-5.731776; 	$dmex{"21:10"}=3.9e-05; 
$mex{"22:10"}=-8.024715; 	$dmex{"22:10"}=1.8e-05; 
$mex{"23:10"}=-5.154045; 	$dmex{"23:10"}=0.000104; 
$mex{"24:10"}=-5.951521; 	$dmex{"24:10"}=0.000392; 
$mex{"25:10"}=-2.108075; 	$dmex{"25:10"}=0.025643; 
$mex{"26:10"}=0.429611; 	$dmex{"26:10"}=0.026774; 
$mex{"27:10"}=7.033; 	$dmex{"27:10"}=0.058; 
$mex{"28:10"}=11.267; 	$dmex{"28:10"}=0.087; 
$mex{"29:10"}=18.357; 	$dmex{"29:10"}=0.095; 
$mex{"30:10"}=23.052; 	$dmex{"30:10"}=0.251; 
$mex{"31:10"}=30.824; 	$dmex{"31:10"}=1.616; 
$mex{"18:11"}=24.189968; 	$dmex{"18:11"}=0.050301; 
$mex{"19:11"}=12.926808; 	$dmex{"19:11"}=0.012; 
$mex{"20:11"}=6.847719; 	$dmex{"20:11"}=0.006662; 
$mex{"21:11"}=-2.184161; 	$dmex{"21:11"}=0.0007; 
$mex{"22:11"}=-5.182436; 	$dmex{"22:11"}=0.000415; 
$mex{"23:11"}=-9.52985358; 	$dmex{"23:11"}=2.73e-06; 
$mex{"24:11"}=-8.418114; 	$dmex{"24:11"}=7.6e-05; 
$mex{"25:11"}=-9.357818; 	$dmex{"25:11"}=0.0012; 
$mex{"26:11"}=-6.862316; 	$dmex{"26:11"}=0.005832; 
$mex{"27:11"}=-5.517436; 	$dmex{"27:11"}=0.003503; 
$mex{"28:11"}=-0.989247; 	$dmex{"28:11"}=0.013041; 
$mex{"29:11"}=2.665004; 	$dmex{"29:11"}=0.013041; 
$mex{"30:11"}=8.36109; 	$dmex{"30:11"}=0.02515; 
$mex{"31:11"}=12.552; 	$dmex{"31:11"}=0.1; 
$mex{"32:11"}=18.834; 	$dmex{"32:11"}=0.113; 
$mex{"33:11"}=23.632; 	$dmex{"33:11"}=0.328; 
$mex{"19:12"}=33.040092; 	$dmex{"19:12"}=0.251503; 
$mex{"20:12"}=17.570348; 	$dmex{"20:12"}=0.027; 
$mex{"21:12"}=10.910506; 	$dmex{"21:12"}=0.016415; 
$mex{"22:12"}=-0.396963; 	$dmex{"22:12"}=0.001342; 
$mex{"23:12"}=-5.473766; 	$dmex{"23:12"}=0.001286; 
$mex{"24:12"}=-13.933567; 	$dmex{"24:12"}=1.3e-05; 
$mex{"25:12"}=-13.192826; 	$dmex{"25:12"}=3.2e-05; 
$mex{"26:12"}=-16.214582; 	$dmex{"26:12"}=2.7e-05; 
$mex{"27:12"}=-14.586651; 	$dmex{"27:12"}=4.9e-05; 
$mex{"28:12"}=-15.018641; 	$dmex{"28:12"}=0.002004; 
$mex{"29:12"}=-10.619032; 	$dmex{"29:12"}=0.013972; 
$mex{"30:12"}=-8.910672; 	$dmex{"30:12"}=0.008383; 
$mex{"31:12"}=-3.21738; 	$dmex{"31:12"}=0.012109; 
$mex{"32:12"}=-0.954781; 	$dmex{"32:12"}=0.017698; 
$mex{"33:12"}=4.89407; 	$dmex{"33:12"}=0.019561; 
$mex{"34:12"}=8.587; 	$dmex{"34:12"}=0.08; 
$mex{"35:12"}=15.638; 	$dmex{"35:12"}=0.183; 
$mex{"36:12"}=20.38; 	$dmex{"36:12"}=0.455; 
$mex{"23:13"}=6.76957; 	$dmex{"23:13"}=0.018648; 
$mex{"24:13"}=-0.056946; 	$dmex{"24:13"}=0.002782; 
$mex{"25:13"}=-8.916172; 	$dmex{"25:13"}=0.000475; 
$mex{"26:13"}=-12.210309; 	$dmex{"26:13"}=6e-05; 
$mex{"27:13"}=-17.196658; 	$dmex{"27:13"}=0.000116; 
$mex{"28:13"}=-16.850441; 	$dmex{"28:13"}=0.000131; 
$mex{"29:13"}=-18.215322; 	$dmex{"29:13"}=0.001206; 
$mex{"30:13"}=-15.872419; 	$dmex{"30:13"}=0.014045; 
$mex{"31:13"}=-14.953628; 	$dmex{"31:13"}=0.020343; 
$mex{"32:13"}=-11.061966; 	$dmex{"32:13"}=0.085949; 
$mex{"33:13"}=-8.529377; 	$dmex{"33:13"}=0.072745; 
$mex{"34:13"}=-3.04; 	$dmex{"34:13"}=0.065; 
$mex{"35:13"}=-0.21; 	$dmex{"35:13"}=0.065; 
$mex{"36:13"}=5.917; 	$dmex{"36:13"}=0.09; 
$mex{"37:13"}=9.83; 	$dmex{"37:13"}=0.116; 
$mex{"38:13"}=16.193; 	$dmex{"38:13"}=0.237; 
$mex{"39:13"}=20.356; 	$dmex{"39:13"}=0.575; 
$mex{"24:14"}=10.754673; 	$dmex{"24:14"}=0.019472; 
$mex{"25:14"}=3.824318; 	$dmex{"25:14"}=0.01; 
$mex{"26:14"}=-7.144632; 	$dmex{"26:14"}=0.003; 
$mex{"27:14"}=-12.384301; 	$dmex{"27:14"}=0.000151; 
$mex{"28:14"}=-21.49279678; 	$dmex{"28:14"}=1.81e-06; 
$mex{"29:14"}=-21.895046; 	$dmex{"29:14"}=2.1e-05; 
$mex{"30:14"}=-24.432928; 	$dmex{"30:14"}=3e-05; 
$mex{"31:14"}=-22.949006; 	$dmex{"31:14"}=3.9e-05; 
$mex{"32:14"}=-24.080907; 	$dmex{"32:14"}=5e-05; 
$mex{"33:14"}=-20.492662; 	$dmex{"33:14"}=0.015791; 
$mex{"34:14"}=-19.95677; 	$dmex{"34:14"}=0.014118; 
$mex{"35:14"}=-14.360307; 	$dmex{"35:14"}=0.038412; 
$mex{"36:14"}=-12.421; 	$dmex{"36:14"}=0.081; 
$mex{"37:14"}=-6.607; 	$dmex{"37:14"}=0.08; 
$mex{"38:14"}=-4.152; 	$dmex{"38:14"}=0.065; 
$mex{"39:14"}=2.291; 	$dmex{"39:14"}=0.084; 
$mex{"40:14"}=5.47; 	$dmex{"40:14"}=0.21; 
$mex{"41:14"}=12.174; 	$dmex{"41:14"}=0.36; 
$mex{"42:14"}=15.159; 	$dmex{"42:14"}=0.58; 
$mex{"27:15"}=-0.71703; 	$dmex{"27:15"}=0.026341; 
$mex{"28:15"}=-7.158753; 	$dmex{"28:15"}=0.00332; 
$mex{"29:15"}=-16.952626; 	$dmex{"29:15"}=0.0006; 
$mex{"30:15"}=-20.200575; 	$dmex{"30:15"}=0.000313; 
$mex{"31:15"}=-24.440885; 	$dmex{"31:15"}=0.000183; 
$mex{"32:15"}=-24.305218; 	$dmex{"32:15"}=0.000187; 
$mex{"33:15"}=-26.337486; 	$dmex{"33:15"}=0.001098; 
$mex{"34:15"}=-24.557669; 	$dmex{"34:15"}=0.005004; 
$mex{"35:15"}=-24.85774; 	$dmex{"35:15"}=0.001867; 
$mex{"36:15"}=-20.250977; 	$dmex{"36:15"}=0.013114; 
$mex{"37:15"}=-18.994145; 	$dmex{"37:15"}=0.037948; 
$mex{"38:15"}=-14.75782; 	$dmex{"38:15"}=0.103385; 
$mex{"39:15"}=-12.873735; 	$dmex{"39:15"}=0.103412; 
$mex{"40:15"}=-8.064; 	$dmex{"40:15"}=0.091; 
$mex{"41:15"}=-5.017; 	$dmex{"41:15"}=0.078; 
$mex{"42:15"}=0.995; 	$dmex{"42:15"}=0.187; 
$mex{"43:15"}=4.813; 	$dmex{"43:15"}=0.344; 
$mex{"44:15"}=9.378; 	$dmex{"44:15"}=0.9; 
$mex{"28:16"}=4.073203; 	$dmex{"28:16"}=0.16; 
$mex{"29:16"}=-3.159582; 	$dmex{"29:16"}=0.05; 
$mex{"30:16"}=-14.062532; 	$dmex{"30:16"}=0.003003; 
$mex{"31:16"}=-19.044648; 	$dmex{"31:16"}=0.001506; 
$mex{"32:16"}=-26.015697; 	$dmex{"32:16"}=0.000138; 
$mex{"33:16"}=-26.585994; 	$dmex{"33:16"}=0.000136; 
$mex{"34:16"}=-29.931788; 	$dmex{"34:16"}=0.000108; 
$mex{"35:16"}=-28.846356; 	$dmex{"35:16"}=0.0001; 
$mex{"36:16"}=-30.664075; 	$dmex{"36:16"}=0.000189; 
$mex{"37:16"}=-26.89636; 	$dmex{"37:16"}=0.000199; 
$mex{"38:16"}=-26.861197; 	$dmex{"38:16"}=0.007172; 
$mex{"39:16"}=-23.162245; 	$dmex{"39:16"}=0.05; 
$mex{"40:16"}=-22.91; 	$dmex{"40:16"}=0.092; 
$mex{"41:16"}=-19.019105; 	$dmex{"41:16"}=0.118272; 
$mex{"42:16"}=-17.677503; 	$dmex{"42:16"}=0.124215; 
$mex{"43:16"}=-12.049; 	$dmex{"43:16"}=0.089; 
$mex{"44:16"}=-9.102; 	$dmex{"44:16"}=0.132; 
$mex{"45:16"}=-3.889; 	$dmex{"45:16"}=0.638; 
$mex{"31:17"}=-7.067165; 	$dmex{"31:17"}=0.05; 
$mex{"32:17"}=-13.329771; 	$dmex{"32:17"}=0.006593; 
$mex{"33:17"}=-21.003432; 	$dmex{"33:17"}=0.000458; 
$mex{"34:17"}=-24.439776; 	$dmex{"34:17"}=0.000179; 
$mex{"35:17"}=-29.01354; 	$dmex{"35:17"}=3.8e-05; 
$mex{"36:17"}=-29.521857; 	$dmex{"36:17"}=7.2e-05; 
$mex{"37:17"}=-31.761532; 	$dmex{"37:17"}=4.7e-05; 
$mex{"38:17"}=-29.798097; 	$dmex{"38:17"}=9.6e-05; 
$mex{"39:17"}=-29.800203; 	$dmex{"39:17"}=0.001732; 
$mex{"40:17"}=-27.55781; 	$dmex{"40:17"}=0.032066; 
$mex{"41:17"}=-27.307189; 	$dmex{"41:17"}=0.068723; 
$mex{"42:17"}=-24.91299; 	$dmex{"42:17"}=0.14376; 
$mex{"43:17"}=-24.14; 	$dmex{"43:17"}=0.101; 
$mex{"44:17"}=-20.231052; 	$dmex{"44:17"}=0.108028; 
$mex{"45:17"}=-18.361; 	$dmex{"45:17"}=0.078; 
$mex{"46:17"}=-13.847; 	$dmex{"46:17"}=0.152; 
$mex{"47:17"}=-8.919; 	$dmex{"47:17"}=1.004; 
$mex{"32:18"}=-2.200204; 	$dmex{"32:18"}=0.00178; 
$mex{"33:18"}=-9.384141; 	$dmex{"33:18"}=0.000443; 
$mex{"34:18"}=-18.377217; 	$dmex{"34:18"}=0.000386; 
$mex{"35:18"}=-23.047411; 	$dmex{"35:18"}=0.000747; 
$mex{"36:18"}=-30.23154; 	$dmex{"36:18"}=2.7e-05; 
$mex{"37:18"}=-30.947659; 	$dmex{"37:18"}=0.000205; 
$mex{"38:18"}=-34.714551; 	$dmex{"38:18"}=0.000337; 
$mex{"39:18"}=-33.242011; 	$dmex{"39:18"}=0.005004; 
$mex{"40:18"}=-35.03989602; 	$dmex{"40:18"}=2.68e-06; 
$mex{"41:18"}=-33.067467; 	$dmex{"41:18"}=0.000332; 
$mex{"42:18"}=-34.422675; 	$dmex{"42:18"}=0.005775; 
$mex{"43:18"}=-32.009808; 	$dmex{"43:18"}=0.00531; 
$mex{"44:18"}=-32.673053; 	$dmex{"44:18"}=0.001595; 
$mex{"45:18"}=-29.770589; 	$dmex{"45:18"}=0.000547; 
$mex{"46:18"}=-29.720127; 	$dmex{"46:18"}=0.040891; 
$mex{"47:18"}=-25.907836; 	$dmex{"47:18"}=0.100083; 
$mex{"35:19"}=-11.1689; 	$dmex{"35:19"}=0.020001; 
$mex{"36:19"}=-17.426171; 	$dmex{"36:19"}=0.007781; 
$mex{"37:19"}=-24.800199; 	$dmex{"37:19"}=9.4e-05; 
$mex{"38:19"}=-28.800691; 	$dmex{"38:19"}=0.000447; 
$mex{"39:19"}=-33.807011; 	$dmex{"39:19"}=0.00019; 
$mex{"40:19"}=-33.535205; 	$dmex{"40:19"}=0.000192; 
$mex{"41:19"}=-35.559074; 	$dmex{"41:19"}=0.000194; 
$mex{"42:19"}=-35.021556; 	$dmex{"42:19"}=0.000221; 
$mex{"43:19"}=-36.593239; 	$dmex{"43:19"}=0.008949; 
$mex{"44:19"}=-35.809606; 	$dmex{"44:19"}=0.035779; 
$mex{"45:19"}=-36.608186; 	$dmex{"45:19"}=0.010256; 
$mex{"46:19"}=-35.418323; 	$dmex{"46:19"}=0.015546; 
$mex{"47:19"}=-35.696272; 	$dmex{"47:19"}=0.007963; 
$mex{"48:19"}=-32.123935; 	$dmex{"48:19"}=0.024106; 
$mex{"49:19"}=-30.319265; 	$dmex{"49:19"}=0.070119; 
$mex{"50:19"}=-25.352141; 	$dmex{"50:19"}=0.278439; 
$mex{"36:20"}=-6.439359; 	$dmex{"36:20"}=0.040001; 
$mex{"37:20"}=-13.16176; 	$dmex{"37:20"}=0.022362; 
$mex{"38:20"}=-22.05922; 	$dmex{"38:20"}=0.004557; 
$mex{"39:20"}=-27.2744; 	$dmex{"39:20"}=0.001862; 
$mex{"40:20"}=-34.846275; 	$dmex{"40:20"}=0.000209; 
$mex{"41:20"}=-35.137759; 	$dmex{"41:20"}=0.000242; 
$mex{"42:20"}=-38.547072; 	$dmex{"42:20"}=0.000249; 
$mex{"43:20"}=-38.408639; 	$dmex{"43:20"}=0.000301; 
$mex{"44:20"}=-41.468479; 	$dmex{"44:20"}=0.000376; 
$mex{"45:20"}=-40.81195; 	$dmex{"45:20"}=0.000412; 
$mex{"46:20"}=-43.135077; 	$dmex{"46:20"}=0.002276; 
$mex{"47:20"}=-42.340123; 	$dmex{"47:20"}=0.002263; 
$mex{"48:20"}=-44.214129; 	$dmex{"48:20"}=0.004082; 
$mex{"49:20"}=-41.289265; 	$dmex{"49:20"}=0.004086; 
$mex{"50:20"}=-39.570832; 	$dmex{"50:20"}=0.009268; 
$mex{"51:20"}=-35.863251; 	$dmex{"51:20"}=0.093793; 
$mex{"52:20"}=-32.509141; 	$dmex{"52:20"}=0.698621; 
$mex{"39:21"}=-14.168021; 	$dmex{"39:21"}=0.024001; 
$mex{"40:21"}=-20.523228; 	$dmex{"40:21"}=0.002836; 
$mex{"41:21"}=-28.642392; 	$dmex{"41:21"}=0.000225; 
$mex{"42:21"}=-32.121239; 	$dmex{"42:21"}=0.00027; 
$mex{"43:21"}=-36.187929; 	$dmex{"43:21"}=0.001874; 
$mex{"44:21"}=-37.816093; 	$dmex{"44:21"}=0.001767; 
$mex{"45:21"}=-41.067792; 	$dmex{"45:21"}=0.000837; 
$mex{"46:21"}=-41.757115; 	$dmex{"46:21"}=0.000844; 
$mex{"47:21"}=-44.332121; 	$dmex{"47:21"}=0.002029; 
$mex{"48:21"}=-44.496101; 	$dmex{"48:21"}=0.0054; 
$mex{"49:21"}=-46.552368; 	$dmex{"49:21"}=0.003997; 
$mex{"50:21"}=-44.536885; 	$dmex{"50:21"}=0.015546; 
$mex{"51:21"}=-43.218184; 	$dmex{"51:21"}=0.020412; 
$mex{"52:21"}=-40.356541; 	$dmex{"52:21"}=0.193271; 
$mex{"54:21"}=-34.218841; 	$dmex{"54:21"}=0.370138; 
$mex{"55:21"}=-29.580571; 	$dmex{"55:21"}=0.735979; 
$mex{"40:22"}=-8.850275; 	$dmex{"40:22"}=0.16; 
$mex{"42:22"}=-25.121552; 	$dmex{"42:22"}=0.005452; 
$mex{"43:22"}=-29.321103; 	$dmex{"43:22"}=0.006903; 
$mex{"44:22"}=-37.548459; 	$dmex{"44:22"}=0.000731; 
$mex{"45:22"}=-39.005737; 	$dmex{"45:22"}=0.00098; 
$mex{"46:22"}=-44.123422; 	$dmex{"46:22"}=0.000833; 
$mex{"47:22"}=-44.932394; 	$dmex{"47:22"}=0.000822; 
$mex{"48:22"}=-48.487727; 	$dmex{"48:22"}=0.000822; 
$mex{"49:22"}=-48.558799; 	$dmex{"49:22"}=0.000822; 
$mex{"50:22"}=-51.426672; 	$dmex{"50:22"}=0.000823; 
$mex{"51:22"}=-49.727849; 	$dmex{"51:22"}=0.000958; 
$mex{"52:22"}=-49.464837; 	$dmex{"52:22"}=0.007119; 
$mex{"53:22"}=-46.828839; 	$dmex{"53:22"}=0.100051; 
$mex{"54:22"}=-45.594395; 	$dmex{"54:22"}=0.124717; 
$mex{"55:22"}=-41.670332; 	$dmex{"55:22"}=0.152102; 
$mex{"56:22"}=-38.936785; 	$dmex{"56:22"}=0.19595; 
$mex{"57:22"}=-33.543903; 	$dmex{"57:22"}=0.455424; 
$mex{"44:23"}=-24.11638; 	$dmex{"44:23"}=0.121094; 
$mex{"45:23"}=-31.879629; 	$dmex{"45:23"}=0.017029; 
$mex{"46:23"}=-37.073013; 	$dmex{"46:23"}=0.001027; 
$mex{"47:23"}=-42.002051; 	$dmex{"47:23"}=0.000836; 
$mex{"48:23"}=-44.475385; 	$dmex{"48:23"}=0.002551; 
$mex{"49:23"}=-47.956943; 	$dmex{"49:23"}=0.001161; 
$mex{"50:23"}=-49.221554; 	$dmex{"50:23"}=0.001005; 
$mex{"51:23"}=-52.201383; 	$dmex{"51:23"}=0.001001; 
$mex{"52:23"}=-51.44131; 	$dmex{"52:23"}=0.001009; 
$mex{"53:23"}=-51.848839; 	$dmex{"53:23"}=0.003193; 
$mex{"54:23"}=-49.890954; 	$dmex{"54:23"}=0.01502; 
$mex{"55:23"}=-49.151491; 	$dmex{"55:23"}=0.100003; 
$mex{"56:23"}=-46.080109; 	$dmex{"56:23"}=0.204259; 
$mex{"57:23"}=-44.188742; 	$dmex{"57:23"}=0.232979; 
$mex{"58:23"}=-40.208743; 	$dmex{"58:23"}=0.24793; 
$mex{"59:23"}=-37.066562; 	$dmex{"59:23"}=0.307377; 
$mex{"60:23"}=-32.577268; 	$dmex{"60:23"}=0.474712; 
$mex{"45:24"}=-18.965218; 	$dmex{"45:24"}=0.503007; 
$mex{"46:24"}=-29.473742; 	$dmex{"46:24"}=0.019995; 
$mex{"47:24"}=-34.558385; 	$dmex{"47:24"}=0.014036; 
$mex{"48:24"}=-42.81918; 	$dmex{"48:24"}=0.007379; 
$mex{"49:24"}=-45.330484; 	$dmex{"49:24"}=0.002417; 
$mex{"50:24"}=-50.259499; 	$dmex{"50:24"}=0.001001; 
$mex{"51:24"}=-51.448807; 	$dmex{"51:24"}=0.001001; 
$mex{"52:24"}=-55.416933; 	$dmex{"52:24"}=0.000779; 
$mex{"53:24"}=-55.284741; 	$dmex{"53:24"}=0.000771; 
$mex{"54:24"}=-56.932545; 	$dmex{"54:24"}=0.000765; 
$mex{"55:24"}=-55.107491; 	$dmex{"55:24"}=0.000788; 
$mex{"56:24"}=-55.281245; 	$dmex{"56:24"}=0.001863; 
$mex{"57:24"}=-52.52414; 	$dmex{"57:24"}=0.001863; 
$mex{"58:24"}=-51.834726; 	$dmex{"58:24"}=0.202917; 
$mex{"59:24"}=-47.89149; 	$dmex{"59:24"}=0.244333; 
$mex{"60:24"}=-46.503876; 	$dmex{"60:24"}=0.213397; 
$mex{"61:24"}=-42.180653; 	$dmex{"61:24"}=0.254607; 
$mex{"62:24"}=-40.414553; 	$dmex{"62:24"}=0.336992; 
$mex{"48:25"}=-29.323431; 	$dmex{"48:25"}=0.111779; 
$mex{"49:25"}=-37.615586; 	$dmex{"49:25"}=0.02401; 
$mex{"50:25"}=-42.626814; 	$dmex{"50:25"}=0.001026; 
$mex{"51:25"}=-48.241341; 	$dmex{"51:25"}=0.000998; 
$mex{"52:25"}=-50.705444; 	$dmex{"52:25"}=0.001961; 
$mex{"53:25"}=-54.687904; 	$dmex{"53:25"}=0.000817; 
$mex{"54:25"}=-55.55537; 	$dmex{"54:25"}=0.001263; 
$mex{"55:25"}=-57.71058; 	$dmex{"55:25"}=0.00068; 
$mex{"56:25"}=-56.90971; 	$dmex{"56:25"}=0.000687; 
$mex{"57:25"}=-57.4868; 	$dmex{"57:25"}=0.00185; 
$mex{"58:25"}=-55.906827; 	$dmex{"58:25"}=0.030008; 
$mex{"59:25"}=-55.479562; 	$dmex{"59:25"}=0.030006; 
$mex{"60:25"}=-53.177832; 	$dmex{"60:25"}=0.08607; 
$mex{"61:25"}=-51.555736; 	$dmex{"61:25"}=0.227914; 
$mex{"62:25"}=-48.038804; 	$dmex{"62:25"}=0.223088; 
$mex{"63:25"}=-46.351151; 	$dmex{"63:25"}=0.258342; 
$mex{"64:25"}=-42.616698; 	$dmex{"64:25"}=0.266746; 
$mex{"65:25"}=-40.672693; 	$dmex{"65:25"}=0.536695; 
$mex{"50:26"}=-34.475541; 	$dmex{"50:26"}=0.060004; 
$mex{"51:26"}=-40.222341; 	$dmex{"51:26"}=0.015016; 
$mex{"52:26"}=-48.331615; 	$dmex{"52:26"}=0.006547; 
$mex{"53:26"}=-50.945323; 	$dmex{"53:26"}=0.001773; 
$mex{"54:26"}=-56.252456; 	$dmex{"54:26"}=0.00069; 
$mex{"55:26"}=-57.479368; 	$dmex{"55:26"}=0.000686; 
$mex{"56:26"}=-60.605352; 	$dmex{"56:26"}=0.000685; 
$mex{"57:26"}=-60.18013; 	$dmex{"57:26"}=0.000686; 
$mex{"58:26"}=-62.153418; 	$dmex{"58:26"}=0.000704; 
$mex{"59:26"}=-60.663114; 	$dmex{"59:26"}=0.000712; 
$mex{"60:26"}=-61.411832; 	$dmex{"60:26"}=0.003464; 
$mex{"61:26"}=-58.921391; 	$dmex{"61:26"}=0.020009; 
$mex{"62:26"}=-58.900749; 	$dmex{"62:26"}=0.014489; 
$mex{"63:26"}=-55.545834; 	$dmex{"63:26"}=0.168133; 
$mex{"64:26"}=-54.770668; 	$dmex{"64:26"}=0.276563; 
$mex{"65:26"}=-50.877951; 	$dmex{"65:26"}=0.243259; 
$mex{"66:26"}=-49.573517; 	$dmex{"66:26"}=0.30264; 
$mex{"67:26"}=-45.692348; 	$dmex{"67:26"}=0.41557; 
$mex{"68:26"}=-43.128173; 	$dmex{"68:26"}=0.698621; 
$mex{"53:27"}=-42.644824; 	$dmex{"53:27"}=0.01801; 
$mex{"54:27"}=-48.009541; 	$dmex{"54:27"}=0.000717; 
$mex{"55:27"}=-54.027557; 	$dmex{"55:27"}=0.00073; 
$mex{"56:27"}=-56.039352; 	$dmex{"56:27"}=0.002114; 
$mex{"57:27"}=-59.344204; 	$dmex{"57:27"}=0.000713; 
$mex{"58:27"}=-59.845868; 	$dmex{"58:27"}=0.00125; 
$mex{"59:27"}=-62.228412; 	$dmex{"59:27"}=0.000624; 
$mex{"60:27"}=-61.649012; 	$dmex{"60:27"}=0.000628; 
$mex{"61:27"}=-62.898422; 	$dmex{"61:27"}=0.000928; 
$mex{"62:27"}=-61.431505; 	$dmex{"62:27"}=0.020009; 
$mex{"63:27"}=-61.840387; 	$dmex{"63:27"}=0.020009; 
$mex{"64:27"}=-59.792686; 	$dmex{"64:27"}=0.020009; 
$mex{"65:27"}=-59.169934; 	$dmex{"65:27"}=0.013146; 
$mex{"66:27"}=-56.111332; 	$dmex{"66:27"}=0.252102; 
$mex{"67:27"}=-55.061049; 	$dmex{"67:27"}=0.318259; 
$mex{"68:27"}=-51.350415; 	$dmex{"68:27"}=0.318259; 
$mex{"69:27"}=-50.002598; 	$dmex{"69:27"}=0.335338; 
$mex{"70:27"}=-45.643206; 	$dmex{"70:27"}=0.838345; 
$mex{"71:27"}=-43.873368; 	$dmex{"71:27"}=0.838345; 
$mex{"54:28"}=-39.210779; 	$dmex{"54:28"}=0.050004; 
$mex{"55:28"}=-45.335579; 	$dmex{"55:28"}=0.011017; 
$mex{"56:28"}=-53.903674; 	$dmex{"56:28"}=0.011072; 
$mex{"57:28"}=-56.081969; 	$dmex{"57:28"}=0.001814; 
$mex{"58:28"}=-60.227694; 	$dmex{"58:28"}=0.000609; 
$mex{"59:28"}=-61.15565; 	$dmex{"59:28"}=0.000608; 
$mex{"60:28"}=-64.472079; 	$dmex{"60:28"}=0.000607; 
$mex{"61:28"}=-64.220892; 	$dmex{"61:28"}=0.000607; 
$mex{"62:28"}=-66.746096; 	$dmex{"62:28"}=0.000597; 
$mex{"63:28"}=-65.512556; 	$dmex{"63:28"}=0.000597; 
$mex{"64:28"}=-67.099277; 	$dmex{"64:28"}=0.00061; 
$mex{"65:28"}=-65.126052; 	$dmex{"65:28"}=0.000623; 
$mex{"66:28"}=-66.006285; 	$dmex{"66:28"}=0.001397; 
$mex{"67:28"}=-63.74268; 	$dmex{"67:28"}=0.002888; 
$mex{"68:28"}=-63.463815; 	$dmex{"68:28"}=0.002981; 
$mex{"69:28"}=-59.978648; 	$dmex{"69:28"}=0.003726; 
$mex{"70:28"}=-59.14987; 	$dmex{"70:28"}=0.3458; 
$mex{"71:28"}=-55.203797; 	$dmex{"71:28"}=0.368036; 
$mex{"72:28"}=-53.940319; 	$dmex{"72:28"}=0.436425; 
$mex{"57:29"}=-47.309576; 	$dmex{"57:29"}=0.015657; 
$mex{"58:29"}=-51.662055; 	$dmex{"58:29"}=0.001563; 
$mex{"59:29"}=-56.357224; 	$dmex{"59:29"}=0.000788; 
$mex{"60:29"}=-58.344099; 	$dmex{"60:29"}=0.001686; 
$mex{"61:29"}=-61.98364; 	$dmex{"61:29"}=0.000978; 
$mex{"62:29"}=-62.797837; 	$dmex{"62:29"}=0.004101; 
$mex{"63:29"}=-65.579531; 	$dmex{"63:29"}=0.000597; 
$mex{"64:29"}=-65.424243; 	$dmex{"64:29"}=0.0006; 
$mex{"65:29"}=-67.263661; 	$dmex{"65:29"}=0.000678; 
$mex{"66:29"}=-66.258274; 	$dmex{"66:29"}=0.000683; 
$mex{"67:29"}=-67.318779; 	$dmex{"67:29"}=0.001211; 
$mex{"68:29"}=-65.567035; 	$dmex{"68:29"}=0.001584; 
$mex{"69:29"}=-65.736213; 	$dmex{"69:29"}=0.001397; 
$mex{"70:29"}=-62.976127; 	$dmex{"70:29"}=0.001584; 
$mex{"71:29"}=-62.711127; 	$dmex{"71:29"}=0.00149; 
$mex{"72:29"}=-59.782999; 	$dmex{"72:29"}=0.001397; 
$mex{"73:29"}=-58.986595; 	$dmex{"73:29"}=0.003912; 
$mex{"74:29"}=-56.006205; 	$dmex{"74:29"}=0.006148; 
$mex{"75:29"}=-54.119802; 	$dmex{"75:29"}=0.978069; 
$mex{"76:29"}=-50.975985; 	$dmex{"76:29"}=0.006707; 
$mex{"58:30"}=-42.297694; 	$dmex{"58:30"}=0.050004; 
$mex{"59:30"}=-47.260499; 	$dmex{"59:30"}=0.037147; 
$mex{"60:30"}=-54.187768; 	$dmex{"60:30"}=0.010556; 
$mex{"61:30"}=-56.34548; 	$dmex{"61:30"}=0.016278; 
$mex{"62:30"}=-61.171431; 	$dmex{"62:30"}=0.010023; 
$mex{"63:30"}=-62.213025; 	$dmex{"63:30"}=0.001583; 
$mex{"64:30"}=-66.003595; 	$dmex{"64:30"}=0.000683; 
$mex{"65:30"}=-65.911599; 	$dmex{"65:30"}=0.000684; 
$mex{"66:30"}=-68.899427; 	$dmex{"66:30"}=0.00092; 
$mex{"67:30"}=-67.880441; 	$dmex{"67:30"}=0.000936; 
$mex{"68:30"}=-70.00722; 	$dmex{"68:30"}=0.000955; 
$mex{"69:30"}=-68.417973; 	$dmex{"69:30"}=0.000969; 
$mex{"70:30"}=-69.564648; 	$dmex{"70:30"}=0.001952; 
$mex{"71:30"}=-67.326897; 	$dmex{"71:30"}=0.010189; 
$mex{"72:30"}=-68.13138; 	$dmex{"72:30"}=0.006086; 
$mex{"73:30"}=-65.410343; 	$dmex{"73:30"}=0.040034; 
$mex{"74:30"}=-65.708883; 	$dmex{"74:30"}=0.047138; 
$mex{"75:30"}=-62.469023; 	$dmex{"75:30"}=0.07063; 
$mex{"76:30"}=-62.13664; 	$dmex{"76:30"}=0.080024; 
$mex{"77:30"}=-58.722344; 	$dmex{"77:30"}=0.120024; 
$mex{"78:30"}=-57.34257; 	$dmex{"78:30"}=0.090033; 
$mex{"80:30"}=-51.844769; 	$dmex{"80:30"}=0.172051; 
$mex{"61:31"}=-47.09048; 	$dmex{"61:31"}=0.052583; 
$mex{"62:31"}=-52.000431; 	$dmex{"62:31"}=0.027865; 
$mex{"63:31"}=-56.547093; 	$dmex{"63:31"}=0.001304; 
$mex{"64:31"}=-58.834328; 	$dmex{"64:31"}=0.00202; 
$mex{"65:31"}=-62.657173; 	$dmex{"65:31"}=0.000833; 
$mex{"66:31"}=-63.724427; 	$dmex{"66:31"}=0.003138; 
$mex{"67:31"}=-66.879683; 	$dmex{"67:31"}=0.001271; 
$mex{"68:31"}=-67.08612; 	$dmex{"68:31"}=0.001534; 
$mex{"69:31"}=-69.327758; 	$dmex{"69:31"}=0.001204; 
$mex{"70:31"}=-68.910089; 	$dmex{"70:31"}=0.001208; 
$mex{"71:31"}=-70.140242; 	$dmex{"71:31"}=0.001018; 
$mex{"72:31"}=-68.58938; 	$dmex{"72:31"}=0.001017; 
$mex{"73:31"}=-69.699335; 	$dmex{"73:31"}=0.001677; 
$mex{"74:31"}=-68.049585; 	$dmex{"74:31"}=0.003726; 
$mex{"75:31"}=-68.46458; 	$dmex{"75:31"}=0.002422; 
$mex{"76:31"}=-66.29664; 	$dmex{"76:31"}=0.001956; 
$mex{"77:31"}=-65.992344; 	$dmex{"77:31"}=0.002422; 
$mex{"78:31"}=-63.70657; 	$dmex{"78:31"}=0.002422; 
$mex{"79:31"}=-62.509526; 	$dmex{"79:31"}=0.09814; 
$mex{"80:31"}=-59.135169; 	$dmex{"80:31"}=0.123295; 
$mex{"81:31"}=-57.983308; 	$dmex{"81:31"}=0.192173; 
$mex{"64:32"}=-54.349881; 	$dmex{"64:32"}=0.031671; 
$mex{"65:32"}=-56.414625; 	$dmex{"65:32"}=0.100002; 
$mex{"66:32"}=-61.624427; 	$dmex{"66:32"}=0.030164; 
$mex{"67:32"}=-62.65781; 	$dmex{"67:32"}=0.004666; 
$mex{"68:32"}=-66.979785; 	$dmex{"68:32"}=0.006227; 
$mex{"69:32"}=-67.100605; 	$dmex{"69:32"}=0.001324; 
$mex{"70:32"}=-70.563111; 	$dmex{"70:32"}=0.001027; 
$mex{"71:32"}=-69.907736; 	$dmex{"71:32"}=0.001025; 
$mex{"72:32"}=-72.585911; 	$dmex{"72:32"}=0.001635; 
$mex{"73:32"}=-71.297534; 	$dmex{"73:32"}=0.001635; 
$mex{"74:32"}=-73.422437; 	$dmex{"74:32"}=0.001635; 
$mex{"75:32"}=-71.856427; 	$dmex{"75:32"}=0.001636; 
$mex{"76:32"}=-73.213046; 	$dmex{"76:32"}=0.001651; 
$mex{"77:32"}=-71.214029; 	$dmex{"77:32"}=0.001699; 
$mex{"78:32"}=-71.862211; 	$dmex{"78:32"}=0.003902; 
$mex{"79:32"}=-69.488526; 	$dmex{"79:32"}=0.089619; 
$mex{"80:32"}=-69.515169; 	$dmex{"80:32"}=0.028312; 
$mex{"81:32"}=-66.303308; 	$dmex{"81:32"}=0.120127; 
$mex{"82:32"}=-65.624008; 	$dmex{"82:32"}=0.244139; 
$mex{"66:33"}=-51.502304; 	$dmex{"66:33"}=0.679991; 
$mex{"67:33"}=-56.64781; 	$dmex{"67:33"}=0.100109; 
$mex{"68:33"}=-58.899233; 	$dmex{"68:33"}=0.043366; 
$mex{"69:33"}=-63.086666; 	$dmex{"69:33"}=0.031216; 
$mex{"70:33"}=-64.343111; 	$dmex{"70:33"}=0.050011; 
$mex{"71:33"}=-67.894336; 	$dmex{"71:33"}=0.004209; 
$mex{"72:33"}=-68.229809; 	$dmex{"72:33"}=0.004398; 
$mex{"73:33"}=-70.956701; 	$dmex{"73:33"}=0.003928; 
$mex{"74:33"}=-70.859967; 	$dmex{"74:33"}=0.002349; 
$mex{"75:33"}=-73.03241; 	$dmex{"75:33"}=0.001818; 
$mex{"76:33"}=-72.289504; 	$dmex{"76:33"}=0.001819; 
$mex{"77:33"}=-73.916577; 	$dmex{"77:33"}=0.002304; 
$mex{"78:33"}=-72.817419; 	$dmex{"78:33"}=0.009934; 
$mex{"79:33"}=-73.636526; 	$dmex{"79:33"}=0.005611; 
$mex{"80:33"}=-72.159286; 	$dmex{"80:33"}=0.023332; 
$mex{"81:33"}=-72.533308; 	$dmex{"81:33"}=0.005527; 
$mex{"82:33"}=-70.324008; 	$dmex{"82:33"}=0.20001; 
$mex{"83:33"}=-69.880657; 	$dmex{"83:33"}=0.22003; 
$mex{"68:34"}=-54.214814; 	$dmex{"68:34"}=0.032602; 
$mex{"69:34"}=-56.301531; 	$dmex{"69:34"}=0.034443; 
$mex{"70:34"}=-62.046216; 	$dmex{"70:34"}=0.061582; 
$mex{"71:34"}=-63.116336; 	$dmex{"71:34"}=0.031587; 
$mex{"72:34"}=-67.894407; 	$dmex{"72:34"}=0.012057; 
$mex{"73:34"}=-68.217642; 	$dmex{"73:34"}=0.010689; 
$mex{"74:34"}=-72.212735; 	$dmex{"74:34"}=0.001676; 
$mex{"75:34"}=-72.169018; 	$dmex{"75:34"}=0.001674; 
$mex{"76:34"}=-75.25205; 	$dmex{"76:34"}=0.001651; 
$mex{"77:34"}=-74.599594; 	$dmex{"77:34"}=0.001652; 
$mex{"78:34"}=-77.026086; 	$dmex{"78:34"}=0.001655; 
$mex{"79:34"}=-75.917602; 	$dmex{"79:34"}=0.001661; 
$mex{"80:34"}=-77.759936; 	$dmex{"80:34"}=0.001989; 
$mex{"81:34"}=-76.389519; 	$dmex{"81:34"}=0.00202; 
$mex{"82:34"}=-77.594008; 	$dmex{"82:34"}=0.00202; 
$mex{"83:34"}=-75.340657; 	$dmex{"83:34"}=0.003616; 
$mex{"84:34"}=-75.951829; 	$dmex{"84:34"}=0.014541; 
$mex{"85:34"}=-72.428267; 	$dmex{"85:34"}=0.029896; 
$mex{"86:34"}=-70.54057; 	$dmex{"86:34"}=0.015557; 
$mex{"87:34"}=-66.581926; 	$dmex{"87:34"}=0.039212; 
$mex{"88:34"}=-63.878135; 	$dmex{"88:34"}=0.049366; 
$mex{"71:35"}=-57.063323; 	$dmex{"71:35"}=0.568211; 
$mex{"72:35"}=-59.015201; 	$dmex{"72:35"}=0.05961; 
$mex{"73:35"}=-63.628936; 	$dmex{"73:35"}=0.05079; 
$mex{"74:35"}=-65.306081; 	$dmex{"74:35"}=0.015093; 
$mex{"75:35"}=-69.139018; 	$dmex{"75:35"}=0.014241; 
$mex{"76:35"}=-70.289169; 	$dmex{"76:35"}=0.009467; 
$mex{"77:35"}=-73.234914; 	$dmex{"77:35"}=0.00326; 
$mex{"78:35"}=-73.452302; 	$dmex{"78:35"}=0.00394; 
$mex{"79:35"}=-76.068514; 	$dmex{"79:35"}=0.002017; 
$mex{"80:35"}=-75.889472; 	$dmex{"80:35"}=0.002013; 
$mex{"81:35"}=-77.974839; 	$dmex{"81:35"}=0.001952; 
$mex{"82:35"}=-77.496465; 	$dmex{"82:35"}=0.00195; 
$mex{"83:35"}=-79.00893; 	$dmex{"83:35"}=0.004221; 
$mex{"84:35"}=-77.799335; 	$dmex{"84:35"}=0.014651; 
$mex{"85:35"}=-78.610267; 	$dmex{"85:35"}=0.0191; 
$mex{"86:35"}=-75.63957; 	$dmex{"86:35"}=0.011; 
$mex{"87:35"}=-73.856926; 	$dmex{"87:35"}=0.01768; 
$mex{"88:35"}=-70.732135; 	$dmex{"88:35"}=0.038419; 
$mex{"89:35"}=-68.57162; 	$dmex{"89:35"}=0.059807; 
$mex{"90:35"}=-64.619846; 	$dmex{"90:35"}=0.077249; 
$mex{"91:35"}=-61.508323; 	$dmex{"91:35"}=0.07256; 
$mex{"92:35"}=-56.580144; 	$dmex{"92:35"}=0.049595; 
$mex{"71:36"}=-46.923323; 	$dmex{"71:36"}=0.652123; 
$mex{"72:36"}=-53.940919; 	$dmex{"72:36"}=0.007993; 
$mex{"73:36"}=-56.551751; 	$dmex{"73:36"}=0.006578; 
$mex{"74:36"}=-62.331509; 	$dmex{"74:36"}=0.00204; 
$mex{"75:36"}=-64.323624; 	$dmex{"75:36"}=0.008104; 
$mex{"76:36"}=-69.014318; 	$dmex{"76:36"}=0.004032; 
$mex{"77:36"}=-70.169443; 	$dmex{"77:36"}=0.001956; 
$mex{"78:36"}=-74.179727; 	$dmex{"78:36"}=0.001075; 
$mex{"79:36"}=-74.442736; 	$dmex{"79:36"}=0.003896; 
$mex{"80:36"}=-77.892492; 	$dmex{"80:36"}=0.00147; 
$mex{"81:36"}=-77.694038; 	$dmex{"81:36"}=0.001987; 
$mex{"82:36"}=-80.589508; 	$dmex{"82:36"}=0.00178; 
$mex{"83:36"}=-79.981709; 	$dmex{"83:36"}=0.002812; 
$mex{"84:36"}=-82.430991; 	$dmex{"84:36"}=0.002805; 
$mex{"85:36"}=-81.480267; 	$dmex{"85:36"}=0.001947; 
$mex{"86:36"}=-83.26557; 	$dmex{"86:36"}=0.000102; 
$mex{"87:36"}=-80.709426; 	$dmex{"87:36"}=0.000267; 
$mex{"88:36"}=-79.692135; 	$dmex{"88:36"}=0.013417; 
$mex{"89:36"}=-76.72662; 	$dmex{"89:36"}=0.051739; 
$mex{"90:36"}=-74.969846; 	$dmex{"90:36"}=0.018505; 
$mex{"91:36"}=-71.310323; 	$dmex{"91:36"}=0.057139; 
$mex{"92:36"}=-68.785048; 	$dmex{"92:36"}=0.011715; 
$mex{"93:36"}=-64.017525; 	$dmex{"93:36"}=0.100287; 
$mex{"74:37"}=-51.91705; 	$dmex{"74:37"}=0.003675; 
$mex{"75:37"}=-57.221677; 	$dmex{"75:37"}=0.007452; 
$mex{"76:37"}=-60.479832; 	$dmex{"76:37"}=0.001863; 
$mex{"77:37"}=-64.824531; 	$dmex{"77:37"}=0.007452; 
$mex{"78:37"}=-66.936228; 	$dmex{"78:37"}=0.007452; 
$mex{"79:37"}=-70.803362; 	$dmex{"79:37"}=0.005988; 
$mex{"80:37"}=-72.172854; 	$dmex{"80:37"}=0.006975; 
$mex{"81:37"}=-75.454821; 	$dmex{"81:37"}=0.005998; 
$mex{"82:37"}=-76.188201; 	$dmex{"82:37"}=0.002758; 
$mex{"83:37"}=-79.074805; 	$dmex{"83:37"}=0.006009; 
$mex{"84:37"}=-79.750025; 	$dmex{"84:37"}=0.002805; 
$mex{"85:37"}=-82.167331; 	$dmex{"85:37"}=1.1e-05; 
$mex{"86:37"}=-82.747017; 	$dmex{"86:37"}=0.000199; 
$mex{"87:37"}=-84.597795; 	$dmex{"87:37"}=1.2e-05; 
$mex{"88:37"}=-82.608998; 	$dmex{"88:37"}=0.00016; 
$mex{"89:37"}=-81.712502; 	$dmex{"89:37"}=0.005462; 
$mex{"90:37"}=-79.361712; 	$dmex{"90:37"}=0.006534; 
$mex{"91:37"}=-77.745323; 	$dmex{"91:37"}=0.008055; 
$mex{"92:37"}=-74.772048; 	$dmex{"92:37"}=0.006102; 
$mex{"93:37"}=-72.617525; 	$dmex{"93:37"}=0.007579; 
$mex{"94:37"}=-68.553352; 	$dmex{"94:37"}=0.008357; 
$mex{"95:37"}=-65.853935; 	$dmex{"95:37"}=0.021112; 
$mex{"96:37"}=-61.224644; 	$dmex{"96:37"}=0.029434; 
$mex{"97:37"}=-58.356314; 	$dmex{"97:37"}=0.030512; 
$mex{"98:37"}=-54.221644; 	$dmex{"98:37"}=0.050247; 
$mex{"99:37"}=-50.87887; 	$dmex{"99:37"}=0.12567; 
$mex{"101:37"}=-43.597231; 	$dmex{"101:37"}=0.166082; 
$mex{"75:38"}=-46.621677; 	$dmex{"75:38"}=0.220126; 
$mex{"76:38"}=-54.243893; 	$dmex{"76:38"}=0.03726; 
$mex{"77:38"}=-57.804063; 	$dmex{"77:38"}=0.009315; 
$mex{"78:38"}=-63.173924; 	$dmex{"78:38"}=0.007452; 
$mex{"79:38"}=-65.476577; 	$dmex{"79:38"}=0.008383; 
$mex{"80:38"}=-70.308223; 	$dmex{"80:38"}=0.006575; 
$mex{"81:38"}=-71.527705; 	$dmex{"81:38"}=0.0062; 
$mex{"82:38"}=-76.008384; 	$dmex{"82:38"}=0.00557; 
$mex{"83:38"}=-76.795439; 	$dmex{"83:38"}=0.010315; 
$mex{"84:38"}=-80.643837; 	$dmex{"84:38"}=0.003202; 
$mex{"85:38"}=-81.102572; 	$dmex{"85:38"}=0.002837; 
$mex{"86:38"}=-84.523576; 	$dmex{"86:38"}=0.001074; 
$mex{"87:38"}=-84.880413; 	$dmex{"87:38"}=0.001073; 
$mex{"88:38"}=-87.92174; 	$dmex{"88:38"}=0.001083; 
$mex{"89:38"}=-86.209141; 	$dmex{"89:38"}=0.001087; 
$mex{"90:38"}=-85.941604; 	$dmex{"90:38"}=0.002887; 
$mex{"91:38"}=-83.645279; 	$dmex{"91:38"}=0.004523; 
$mex{"92:38"}=-82.867702; 	$dmex{"92:38"}=0.003403; 
$mex{"93:38"}=-80.084606; 	$dmex{"93:38"}=0.007531; 
$mex{"94:38"}=-78.84043; 	$dmex{"94:38"}=0.007184; 
$mex{"95:38"}=-75.116826; 	$dmex{"95:38"}=0.007481; 
$mex{"96:38"}=-72.938959; 	$dmex{"96:38"}=0.02738; 
$mex{"97:38"}=-68.788109; 	$dmex{"97:38"}=0.01919; 
$mex{"98:38"}=-66.645662; 	$dmex{"98:38"}=0.026349; 
$mex{"99:38"}=-62.185677; 	$dmex{"99:38"}=0.079999; 
$mex{"100:38"}=-60.219307; 	$dmex{"100:38"}=0.127217; 
$mex{"101:38"}=-55.407231; 	$dmex{"101:38"}=0.124432; 
$mex{"102:38"}=-53.077471; 	$dmex{"102:38"}=0.111172; 
$mex{"79:39"}=-58.356577; 	$dmex{"79:39"}=0.450078; 
$mex{"80:39"}=-61.217786; 	$dmex{"80:39"}=0.176984; 
$mex{"81:39"}=-66.017338; 	$dmex{"81:39"}=0.062155; 
$mex{"82:39"}=-68.192393; 	$dmex{"82:39"}=0.102579; 
$mex{"83:39"}=-72.326557; 	$dmex{"83:39"}=0.044314; 
$mex{"84:39"}=-74.157855; 	$dmex{"84:39"}=0.091379; 
$mex{"85:39"}=-77.842123; 	$dmex{"85:39"}=0.018965; 
$mex{"86:39"}=-79.283576; 	$dmex{"86:39"}=0.014183; 
$mex{"87:39"}=-83.018723; 	$dmex{"87:39"}=0.001557; 
$mex{"88:39"}=-84.29914; 	$dmex{"88:39"}=0.00185; 
$mex{"89:39"}=-87.701749; 	$dmex{"89:39"}=0.002552; 
$mex{"90:39"}=-86.487462; 	$dmex{"90:39"}=0.002552; 
$mex{"91:39"}=-86.345031; 	$dmex{"91:39"}=0.002887; 
$mex{"92:39"}=-84.813327; 	$dmex{"92:39"}=0.009264; 
$mex{"93:39"}=-84.22316; 	$dmex{"93:39"}=0.010632; 
$mex{"94:39"}=-82.348499; 	$dmex{"94:39"}=0.007166; 
$mex{"95:39"}=-81.207068; 	$dmex{"95:39"}=0.007222; 
$mex{"96:39"}=-78.346709; 	$dmex{"96:39"}=0.023442; 
$mex{"97:39"}=-76.257693; 	$dmex{"97:39"}=0.011667; 
$mex{"98:39"}=-72.46742; 	$dmex{"98:39"}=0.024549; 
$mex{"99:39"}=-70.200924; 	$dmex{"99:39"}=0.024391; 
$mex{"100:39"}=-67.294307; 	$dmex{"100:39"}=0.07864; 
$mex{"101:39"}=-64.912231; 	$dmex{"101:39"}=0.095306; 
$mex{"102:39"}=-61.892471; 	$dmex{"102:39"}=0.086367; 
$mex{"80:40"}=-55.517043; 	$dmex{"80:40"}=1.49039; 
$mex{"81:40"}=-58.488484; 	$dmex{"81:40"}=0.16654; 
$mex{"82:40"}=-64.19; 	$dmex{"82:40"}=0.51; 
$mex{"83:40"}=-66.458557; 	$dmex{"83:40"}=0.095858; 
$mex{"85:40"}=-73.149123; 	$dmex{"85:40"}=0.1008; 
$mex{"86:40"}=-77.80435; 	$dmex{"86:40"}=0.030093; 
$mex{"87:40"}=-79.34815; 	$dmex{"87:40"}=0.008343; 
$mex{"88:40"}=-83.623101; 	$dmex{"88:40"}=0.010277; 
$mex{"89:40"}=-84.868884; 	$dmex{"89:40"}=0.003698; 
$mex{"90:40"}=-88.767265; 	$dmex{"90:40"}=0.002368; 
$mex{"91:40"}=-87.890402; 	$dmex{"91:40"}=0.002346; 
$mex{"92:40"}=-88.453882; 	$dmex{"92:40"}=0.002345; 
$mex{"93:40"}=-87.11704; 	$dmex{"93:40"}=0.002341; 
$mex{"94:40"}=-87.266837; 	$dmex{"94:40"}=0.00242; 
$mex{"95:40"}=-85.657766; 	$dmex{"95:40"}=0.002399; 
$mex{"96:40"}=-85.442791; 	$dmex{"96:40"}=0.002788; 
$mex{"97:40"}=-82.946645; 	$dmex{"97:40"}=0.002785; 
$mex{"98:40"}=-81.286925; 	$dmex{"98:40"}=0.019946; 
$mex{"99:40"}=-77.768473; 	$dmex{"99:40"}=0.020033; 
$mex{"100:40"}=-76.604307; 	$dmex{"100:40"}=0.035837; 
$mex{"101:40"}=-73.457231; 	$dmex{"101:40"}=0.031357; 
$mex{"102:40"}=-71.742471; 	$dmex{"102:40"}=0.050589; 
$mex{"103:40"}=-68.372027; 	$dmex{"103:40"}=0.108742; 
$mex{"83:41"}=-58.958557; 	$dmex{"83:41"}=0.314942; 
$mex{"85:41"}=-67.149123; 	$dmex{"85:41"}=0.223966; 
$mex{"86:41"}=-69.82635; 	$dmex{"86:41"}=0.085473; 
$mex{"87:41"}=-74.18315; 	$dmex{"87:41"}=0.060577; 
$mex{"88:41"}=-76.073101; 	$dmex{"88:41"}=0.100527; 
$mex{"89:41"}=-80.650386; 	$dmex{"89:41"}=0.026801; 
$mex{"90:41"}=-82.656265; 	$dmex{"90:41"}=0.004648; 
$mex{"91:41"}=-86.632442; 	$dmex{"91:41"}=0.003776; 
$mex{"92:41"}=-86.448337; 	$dmex{"92:41"}=0.002828; 
$mex{"93:41"}=-87.208278; 	$dmex{"93:41"}=0.002429; 
$mex{"94:41"}=-86.364502; 	$dmex{"94:41"}=0.002429; 
$mex{"95:41"}=-86.781901; 	$dmex{"95:41"}=0.001968; 
$mex{"96:41"}=-85.603696; 	$dmex{"96:41"}=0.00373; 
$mex{"97:41"}=-85.605644; 	$dmex{"97:41"}=0.002552; 
$mex{"98:41"}=-83.528547; 	$dmex{"98:41"}=0.005725; 
$mex{"99:41"}=-82.326954; 	$dmex{"99:41"}=0.013339; 
$mex{"100:41"}=-79.939307; 	$dmex{"100:41"}=0.025677; 
$mex{"101:41"}=-78.942231; 	$dmex{"101:41"}=0.018928; 
$mex{"102:41"}=-76.347471; 	$dmex{"102:41"}=0.040734; 
$mex{"103:41"}=-75.317027; 	$dmex{"103:41"}=0.067822; 
$mex{"104:41"}=-72.223666; 	$dmex{"104:41"}=0.10481; 
$mex{"105:41"}=-70.852653; 	$dmex{"105:41"}=0.099799; 
$mex{"86:42"}=-64.55635; 	$dmex{"86:42"}=0.438413; 
$mex{"87:42"}=-67.694927; 	$dmex{"87:42"}=0.223279; 
$mex{"88:42"}=-72.700088; 	$dmex{"88:42"}=0.020359; 
$mex{"89:42"}=-75.003889; 	$dmex{"89:42"}=0.015475; 
$mex{"90:42"}=-80.167265; 	$dmex{"90:42"}=0.006133; 
$mex{"91:42"}=-82.204165; 	$dmex{"91:42"}=0.011181; 
$mex{"92:42"}=-86.805003; 	$dmex{"92:42"}=0.003804; 
$mex{"93:42"}=-86.803495; 	$dmex{"93:42"}=0.003804; 
$mex{"94:42"}=-88.409708; 	$dmex{"94:42"}=0.001918; 
$mex{"95:42"}=-87.707492; 	$dmex{"95:42"}=0.001916; 
$mex{"96:42"}=-88.790496; 	$dmex{"96:42"}=0.001916; 
$mex{"97:42"}=-87.540442; 	$dmex{"97:42"}=0.001913; 
$mex{"98:42"}=-88.111723; 	$dmex{"98:42"}=0.001913; 
$mex{"99:42"}=-85.96584; 	$dmex{"99:42"}=0.001915; 
$mex{"100:42"}=-86.184307; 	$dmex{"100:42"}=0.005855; 
$mex{"101:42"}=-83.511231; 	$dmex{"101:42"}=0.005856; 
$mex{"102:42"}=-83.557471; 	$dmex{"102:42"}=0.020839; 
$mex{"103:42"}=-80.847027; 	$dmex{"103:42"}=0.060826; 
$mex{"104:42"}=-80.328666; 	$dmex{"104:42"}=0.053713; 
$mex{"105:42"}=-77.337653; 	$dmex{"105:42"}=0.071133; 
$mex{"106:42"}=-76.255078; 	$dmex{"106:42"}=0.017948; 
$mex{"107:42"}=-72.942869; 	$dmex{"107:42"}=0.161627; 
$mex{"89:43"}=-67.49; 	$dmex{"89:43"}=0.21; 
$mex{"90:43"}=-71.206603; 	$dmex{"90:43"}=0.242187; 
$mex{"91:43"}=-75.984165; 	$dmex{"91:43"}=0.200312; 
$mex{"92:43"}=-78.934648; 	$dmex{"92:43"}=0.026004; 
$mex{"93:43"}=-83.602533; 	$dmex{"93:43"}=0.003933; 
$mex{"94:43"}=-84.153961; 	$dmex{"94:43"}=0.004498; 
$mex{"95:43"}=-86.016873; 	$dmex{"95:43"}=0.005417; 
$mex{"96:43"}=-85.817254; 	$dmex{"96:43"}=0.00549; 
$mex{"97:43"}=-87.220108; 	$dmex{"97:43"}=0.004538; 
$mex{"98:43"}=-86.427771; 	$dmex{"98:43"}=0.003817; 
$mex{"99:43"}=-87.323141; 	$dmex{"99:43"}=0.001979; 
$mex{"100:43"}=-86.016224; 	$dmex{"100:43"}=0.002217; 
$mex{"101:43"}=-86.33584; 	$dmex{"101:43"}=0.024084; 
$mex{"102:43"}=-84.565665; 	$dmex{"102:43"}=0.009393; 
$mex{"103:43"}=-84.597027; 	$dmex{"103:43"}=0.009992; 
$mex{"104:43"}=-82.486166; 	$dmex{"104:43"}=0.045663; 
$mex{"105:43"}=-82.287653; 	$dmex{"105:43"}=0.055089; 
$mex{"106:43"}=-79.775078; 	$dmex{"106:43"}=0.013328; 
$mex{"107:43"}=-79.102869; 	$dmex{"107:43"}=0.150077; 
$mex{"108:43"}=-75.952879; 	$dmex{"108:43"}=0.126467; 
$mex{"109:43"}=-74.535668; 	$dmex{"109:43"}=0.096272; 
$mex{"110:43"}=-70.960763; 	$dmex{"110:43"}=0.07655; 
$mex{"111:43"}=-69.216683; 	$dmex{"111:43"}=0.108698; 
$mex{"112:43"}=-65.999617; 	$dmex{"112:43"}=0.124158; 
$mex{"91:44"}=-68.58; 	$dmex{"91:44"}=0.5; 
$mex{"93:44"}=-77.265533; 	$dmex{"93:44"}=0.085091; 
$mex{"94:44"}=-82.567898; 	$dmex{"94:44"}=0.012733; 
$mex{"95:44"}=-83.449819; 	$dmex{"95:44"}=0.011874; 
$mex{"96:44"}=-86.072062; 	$dmex{"96:44"}=0.007882; 
$mex{"97:44"}=-86.112242; 	$dmex{"97:44"}=0.00835; 
$mex{"98:44"}=-88.224469; 	$dmex{"98:44"}=0.006271; 
$mex{"99:44"}=-87.616977; 	$dmex{"99:44"}=0.002011; 
$mex{"100:44"}=-89.218984; 	$dmex{"100:44"}=0.002011; 
$mex{"101:44"}=-87.94972; 	$dmex{"101:44"}=0.002014; 
$mex{"102:44"}=-89.098043; 	$dmex{"102:44"}=0.002014; 
$mex{"103:44"}=-87.258775; 	$dmex{"103:44"}=0.002018; 
$mex{"104:44"}=-88.088872; 	$dmex{"104:44"}=0.003137; 
$mex{"105:44"}=-85.927653; 	$dmex{"105:44"}=0.003138; 
$mex{"106:44"}=-86.322078; 	$dmex{"106:44"}=0.007525; 
$mex{"107:44"}=-83.922869; 	$dmex{"107:44"}=0.123686; 
$mex{"108:44"}=-83.672879; 	$dmex{"108:44"}=0.116163; 
$mex{"109:44"}=-80.850668; 	$dmex{"109:44"}=0.066093; 
$mex{"110:44"}=-79.981763; 	$dmex{"110:44"}=0.053244; 
$mex{"111:44"}=-76.665683; 	$dmex{"111:44"}=0.073588; 
$mex{"112:44"}=-75.483617; 	$dmex{"112:44"}=0.073588; 
$mex{"113:44"}=-72.202714; 	$dmex{"113:44"}=0.069997; 
$mex{"115:44"}=-66.428402; 	$dmex{"115:44"}=0.128715; 
$mex{"95:45"}=-78.339819; 	$dmex{"95:45"}=0.150469; 
$mex{"96:45"}=-79.679409; 	$dmex{"96:45"}=0.012733; 
$mex{"97:45"}=-82.589242; 	$dmex{"97:45"}=0.036328; 
$mex{"98:45"}=-83.174815; 	$dmex{"98:45"}=0.011804; 
$mex{"99:45"}=-85.574394; 	$dmex{"99:45"}=0.007137; 
$mex{"100:45"}=-85.584225; 	$dmex{"100:45"}=0.018198; 
$mex{"101:45"}=-87.408021; 	$dmex{"101:45"}=0.01723; 
$mex{"102:45"}=-86.775004; 	$dmex{"102:45"}=0.004941; 
$mex{"103:45"}=-88.022185; 	$dmex{"103:45"}=0.002806; 
$mex{"104:45"}=-86.949825; 	$dmex{"104:45"}=0.002807; 
$mex{"105:45"}=-87.845641; 	$dmex{"105:45"}=0.004027; 
$mex{"106:45"}=-86.361478; 	$dmex{"106:45"}=0.007522; 
$mex{"107:45"}=-86.863285; 	$dmex{"107:45"}=0.011929; 
$mex{"108:45"}=-85.019304; 	$dmex{"108:45"}=0.105056; 
$mex{"109:45"}=-85.010668; 	$dmex{"109:45"}=0.011968; 
$mex{"110:45"}=-82.775901; 	$dmex{"110:45"}=0.050445; 
$mex{"111:45"}=-82.357192; 	$dmex{"111:45"}=0.029613; 
$mex{"112:45"}=-79.741327; 	$dmex{"112:45"}=0.051609; 
$mex{"113:45"}=-78.682714; 	$dmex{"113:45"}=0.048986; 
$mex{"114:45"}=-75.631725; 	$dmex{"114:45"}=0.112711; 
$mex{"115:45"}=-74.208402; 	$dmex{"115:45"}=0.08104; 
$mex{"116:45"}=-70.735792; 	$dmex{"116:45"}=0.137861; 
$mex{"96:46"}=-76.229409; 	$dmex{"96:46"}=0.150539; 
$mex{"97:46"}=-77.799242; 	$dmex{"97:46"}=0.302192; 
$mex{"98:46"}=-81.299957; 	$dmex{"98:46"}=0.021497; 
$mex{"99:46"}=-82.187735; 	$dmex{"99:46"}=0.01518; 
$mex{"100:46"}=-85.226218; 	$dmex{"100:46"}=0.011256; 
$mex{"101:46"}=-85.428021; 	$dmex{"101:46"}=0.017688; 
$mex{"102:46"}=-87.925075; 	$dmex{"102:46"}=0.002988; 
$mex{"103:46"}=-87.47911; 	$dmex{"103:46"}=0.002902; 
$mex{"104:46"}=-89.390045; 	$dmex{"104:46"}=0.004133; 
$mex{"105:46"}=-88.412828; 	$dmex{"105:46"}=0.004073; 
$mex{"106:46"}=-89.902478; 	$dmex{"106:46"}=0.004073; 
$mex{"107:46"}=-88.367594; 	$dmex{"107:46"}=0.004083; 
$mex{"108:46"}=-89.524304; 	$dmex{"108:46"}=0.003442; 
$mex{"109:46"}=-87.606591; 	$dmex{"109:46"}=0.00344; 
$mex{"110:46"}=-88.349175; 	$dmex{"110:46"}=0.010873; 
$mex{"111:46"}=-86.004158; 	$dmex{"111:46"}=0.01088; 
$mex{"112:46"}=-86.336399; 	$dmex{"112:46"}=0.017947; 
$mex{"113:46"}=-83.692028; 	$dmex{"113:46"}=0.035792; 
$mex{"114:46"}=-83.496665; 	$dmex{"114:46"}=0.023634; 
$mex{"115:46"}=-80.403; 	$dmex{"115:46"}=0.060988; 
$mex{"116:46"}=-79.960691; 	$dmex{"116:46"}=0.055568; 
$mex{"117:46"}=-76.530301; 	$dmex{"117:46"}=0.059455; 
$mex{"118:46"}=-75.465639; 	$dmex{"118:46"}=0.209931; 
$mex{"120:46"}=-70.149064; 	$dmex{"120:46"}=0.123908; 
$mex{"97:47"}=-70.819242; 	$dmex{"97:47"}=0.321589; 
$mex{"98:47"}=-73.060614; 	$dmex{"98:47"}=0.066976; 
$mex{"99:47"}=-76.757735; 	$dmex{"99:47"}=0.150766; 
$mex{"100:47"}=-78.148384; 	$dmex{"100:47"}=0.077126; 
$mex{"101:47"}=-81.224197; 	$dmex{"101:47"}=0.104408; 
$mex{"102:47"}=-82.264893; 	$dmex{"102:47"}=0.027945; 
$mex{"103:47"}=-84.791366; 	$dmex{"103:47"}=0.016682; 
$mex{"104:47"}=-85.111392; 	$dmex{"104:47"}=0.005751; 
$mex{"105:47"}=-87.067992; 	$dmex{"105:47"}=0.010982; 
$mex{"106:47"}=-86.93734; 	$dmex{"106:47"}=0.004913; 
$mex{"107:47"}=-88.401743; 	$dmex{"107:47"}=0.004271; 
$mex{"108:47"}=-87.601836; 	$dmex{"108:47"}=0.004274; 
$mex{"109:47"}=-88.722669; 	$dmex{"109:47"}=0.0029; 
$mex{"110:47"}=-87.460552; 	$dmex{"110:47"}=0.002899; 
$mex{"111:47"}=-88.220719; 	$dmex{"111:47"}=0.003015; 
$mex{"112:47"}=-86.624458; 	$dmex{"112:47"}=0.016884; 
$mex{"113:47"}=-87.032672; 	$dmex{"113:47"}=0.016613; 
$mex{"114:47"}=-84.948803; 	$dmex{"114:47"}=0.024824; 
$mex{"115:47"}=-84.987; 	$dmex{"115:47"}=0.034922; 
$mex{"116:47"}=-82.567691; 	$dmex{"116:47"}=0.046773; 
$mex{"117:47"}=-82.265301; 	$dmex{"117:47"}=0.050109; 
$mex{"118:47"}=-79.565639; 	$dmex{"118:47"}=0.063806; 
$mex{"119:47"}=-78.557492; 	$dmex{"119:47"}=0.089775; 
$mex{"120:47"}=-75.649064; 	$dmex{"120:47"}=0.073165; 
$mex{"121:47"}=-74.661064; 	$dmex{"121:47"}=0.14681; 
$mex{"98:48"}=-67.630614; 	$dmex{"98:48"}=0.078012; 
$mex{"100:48"}=-74.249829; 	$dmex{"100:48"}=0.095269; 
$mex{"101:48"}=-75.74766; 	$dmex{"101:48"}=0.150936; 
$mex{"102:48"}=-79.677893; 	$dmex{"102:48"}=0.029067; 
$mex{"103:48"}=-80.649453; 	$dmex{"103:48"}=0.01537; 
$mex{"104:48"}=-83.974674; 	$dmex{"104:48"}=0.009466; 
$mex{"105:48"}=-84.330103; 	$dmex{"105:48"}=0.011549; 
$mex{"106:48"}=-87.132499; 	$dmex{"106:48"}=0.005931; 
$mex{"107:48"}=-86.984841; 	$dmex{"107:48"}=0.005773; 
$mex{"108:48"}=-89.252325; 	$dmex{"108:48"}=0.005566; 
$mex{"109:48"}=-88.508424; 	$dmex{"109:48"}=0.003896; 
$mex{"110:48"}=-90.35299; 	$dmex{"110:48"}=0.002665; 
$mex{"111:48"}=-89.257519; 	$dmex{"111:48"}=0.002662; 
$mex{"112:48"}=-90.580518; 	$dmex{"112:48"}=0.002659; 
$mex{"113:48"}=-89.049279; 	$dmex{"113:48"}=0.002673; 
$mex{"114:48"}=-90.020941; 	$dmex{"114:48"}=0.002674; 
$mex{"115:48"}=-88.090485; 	$dmex{"115:48"}=0.002724; 
$mex{"116:48"}=-88.719392; 	$dmex{"116:48"}=0.00315; 
$mex{"117:48"}=-86.425301; 	$dmex{"117:48"}=0.003305; 
$mex{"118:48"}=-86.708557; 	$dmex{"118:48"}=0.020247; 
$mex{"119:48"}=-83.907492; 	$dmex{"119:48"}=0.080371; 
$mex{"120:48"}=-83.974064; 	$dmex{"120:48"}=0.018793; 
$mex{"121:48"}=-81.061064; 	$dmex{"121:48"}=0.084576; 
$mex{"122:48"}=-80.73032; 	$dmex{"122:48"}=0.043023; 
$mex{"123:48"}=-77.311209; 	$dmex{"123:48"}=0.040876; 
$mex{"124:48"}=-76.710752; 	$dmex{"124:48"}=0.062641; 
$mex{"125:48"}=-73.358534; 	$dmex{"125:48"}=0.068893; 
$mex{"126:48"}=-72.327416; 	$dmex{"126:48"}=0.054143; 
$mex{"127:48"}=-68.5171; 	$dmex{"127:48"}=0.074386; 
$mex{"128:48"}=-67.288998; 	$dmex{"128:48"}=0.294042; 
$mex{"130:48"}=-61.569949; 	$dmex{"130:48"}=0.282769; 
$mex{"100:49"}=-64.169829; 	$dmex{"100:49"}=0.24895; 
$mex{"102:49"}=-70.709488; 	$dmex{"102:49"}=0.111699; 
$mex{"103:49"}=-74.599453; 	$dmex{"103:49"}=0.025224; 
$mex{"104:49"}=-76.106627; 	$dmex{"104:49"}=0.084733; 
$mex{"105:49"}=-79.481085; 	$dmex{"105:49"}=0.017348; 
$mex{"106:49"}=-80.606451; 	$dmex{"106:49"}=0.012333; 
$mex{"107:49"}=-83.559577; 	$dmex{"107:49"}=0.011391; 
$mex{"108:49"}=-84.115603; 	$dmex{"108:49"}=0.009749; 
$mex{"109:49"}=-86.488746; 	$dmex{"109:49"}=0.005828; 
$mex{"110:49"}=-86.47499; 	$dmex{"110:49"}=0.01185; 
$mex{"111:49"}=-88.395728; 	$dmex{"111:49"}=0.004828; 
$mex{"112:49"}=-87.996067; 	$dmex{"112:49"}=0.005126; 
$mex{"113:49"}=-89.36962; 	$dmex{"113:49"}=0.003212; 
$mex{"114:49"}=-88.572155; 	$dmex{"114:49"}=0.003205; 
$mex{"115:49"}=-89.536616; 	$dmex{"115:49"}=0.004463; 
$mex{"116:49"}=-88.250019; 	$dmex{"116:49"}=0.004468; 
$mex{"117:49"}=-88.945042; 	$dmex{"117:49"}=0.005668; 
$mex{"118:49"}=-87.230346; 	$dmex{"118:49"}=0.00825; 
$mex{"119:49"}=-87.704492; 	$dmex{"119:49"}=0.007713; 
$mex{"120:49"}=-85.735073; 	$dmex{"120:49"}=0.040078; 
$mex{"121:49"}=-85.841064; 	$dmex{"121:49"}=0.027444; 
$mex{"122:49"}=-83.577359; 	$dmex{"122:49"}=0.050074; 
$mex{"123:49"}=-83.426209; 	$dmex{"123:49"}=0.024121; 
$mex{"124:49"}=-80.876752; 	$dmex{"124:49"}=0.04902; 
$mex{"125:49"}=-80.480534; 	$dmex{"125:49"}=0.030038; 
$mex{"126:49"}=-77.813416; 	$dmex{"126:49"}=0.040441; 
$mex{"127:49"}=-76.9851; 	$dmex{"127:49"}=0.039552; 
$mex{"128:49"}=-74.358998; 	$dmex{"128:49"}=0.048589; 
$mex{"129:49"}=-72.938793; 	$dmex{"129:49"}=0.043103; 
$mex{"130:49"}=-69.889949; 	$dmex{"130:49"}=0.039474; 
$mex{"131:49"}=-68.137141; 	$dmex{"131:49"}=0.027993; 
$mex{"132:49"}=-62.419171; 	$dmex{"132:49"}=0.061532; 
$mex{"100:50"}=-56.779829; 	$dmex{"100:50"}=0.705391; 
$mex{"102:50"}=-64.929488; 	$dmex{"102:50"}=0.13182; 
$mex{"104:50"}=-71.591627; 	$dmex{"104:50"}=0.103825; 
$mex{"105:50"}=-73.262528; 	$dmex{"105:50"}=0.080586; 
$mex{"106:50"}=-77.425204; 	$dmex{"106:50"}=0.050288; 
$mex{"107:50"}=-78.576801; 	$dmex{"107:50"}=0.083434; 
$mex{"108:50"}=-82.040983; 	$dmex{"108:50"}=0.019854; 
$mex{"109:50"}=-82.639154; 	$dmex{"109:50"}=0.009967; 
$mex{"110:50"}=-85.843888; 	$dmex{"110:50"}=0.013777; 
$mex{"111:50"}=-85.944797; 	$dmex{"111:50"}=0.006836; 
$mex{"112:50"}=-88.661269; 	$dmex{"112:50"}=0.004283; 
$mex{"113:50"}=-88.333039; 	$dmex{"113:50"}=0.004017; 
$mex{"114:50"}=-90.560901; 	$dmex{"114:50"}=0.003172; 
$mex{"115:50"}=-90.035978; 	$dmex{"115:50"}=0.002944; 
$mex{"116:50"}=-91.528107; 	$dmex{"116:50"}=0.002943; 
$mex{"117:50"}=-90.39995; 	$dmex{"117:50"}=0.002922; 
$mex{"118:50"}=-91.65606; 	$dmex{"118:50"}=0.002888; 
$mex{"119:50"}=-90.068363; 	$dmex{"119:50"}=0.002873; 
$mex{"120:50"}=-91.105073; 	$dmex{"120:50"}=0.002504; 
$mex{"121:50"}=-89.204076; 	$dmex{"121:50"}=0.002495; 
$mex{"122:50"}=-89.94595; 	$dmex{"122:50"}=0.002716; 
$mex{"123:50"}=-87.820474; 	$dmex{"123:50"}=0.002706; 
$mex{"124:50"}=-88.236752; 	$dmex{"124:50"}=0.001394; 
$mex{"125:50"}=-85.898534; 	$dmex{"125:50"}=0.001501; 
$mex{"126:50"}=-86.020416; 	$dmex{"126:50"}=0.010698; 
$mex{"127:50"}=-83.4991; 	$dmex{"127:50"}=0.024563; 
$mex{"128:50"}=-83.334598; 	$dmex{"128:50"}=0.027219; 
$mex{"129:50"}=-80.593793; 	$dmex{"129:50"}=0.028876; 
$mex{"130:50"}=-80.138949; 	$dmex{"130:50"}=0.010685; 
$mex{"131:50"}=-77.314218; 	$dmex{"131:50"}=0.021178; 
$mex{"132:50"}=-76.554171; 	$dmex{"132:50"}=0.013644; 
$mex{"133:50"}=-70.952598; 	$dmex{"133:50"}=0.035662; 
$mex{"134:50"}=-66.795791; 	$dmex{"134:50"}=0.099945; 
$mex{"105:51"}=-63.820056; 	$dmex{"105:51"}=0.104903; 
$mex{"109:51"}=-76.259154; 	$dmex{"109:51"}=0.018851; 
$mex{"111:51"}=-80.888145; 	$dmex{"111:51"}=0.027945; 
$mex{"112:51"}=-81.600729; 	$dmex{"112:51"}=0.017829; 
$mex{"113:51"}=-84.419744; 	$dmex{"113:51"}=0.017586; 
$mex{"114:51"}=-84.515383; 	$dmex{"114:51"}=0.027945; 
$mex{"115:51"}=-87.003403; 	$dmex{"115:51"}=0.016025; 
$mex{"116:51"}=-86.821176; 	$dmex{"116:51"}=0.00584; 
$mex{"117:51"}=-88.64475; 	$dmex{"117:51"}=0.009413; 
$mex{"118:51"}=-87.99942; 	$dmex{"118:51"}=0.004146; 
$mex{"119:51"}=-89.477443; 	$dmex{"119:51"}=0.0082; 
$mex{"120:51"}=-88.424465; 	$dmex{"120:51"}=0.007566; 
$mex{"121:51"}=-89.595111; 	$dmex{"121:51"}=0.002198; 
$mex{"122:51"}=-88.330175; 	$dmex{"122:51"}=0.002197; 
$mex{"123:51"}=-89.224113; 	$dmex{"123:51"}=0.002071; 
$mex{"124:51"}=-87.620291; 	$dmex{"124:51"}=0.00207; 
$mex{"125:51"}=-88.255501; 	$dmex{"125:51"}=0.002584; 
$mex{"126:51"}=-86.398416; 	$dmex{"126:51"}=0.03185; 
$mex{"127:51"}=-86.7001; 	$dmex{"127:51"}=0.005228; 
$mex{"128:51"}=-84.608531; 	$dmex{"128:51"}=0.025061; 
$mex{"129:51"}=-84.627681; 	$dmex{"129:51"}=0.021285; 
$mex{"130:51"}=-82.291605; 	$dmex{"130:51"}=0.017089; 
$mex{"131:51"}=-81.987983; 	$dmex{"131:51"}=0.020617; 
$mex{"132:51"}=-79.673573; 	$dmex{"132:51"}=0.014373; 
$mex{"133:51"}=-78.942598; 	$dmex{"133:51"}=0.025431; 
$mex{"134:51"}=-74.165791; 	$dmex{"134:51"}=0.043463; 
$mex{"135:51"}=-69.707636; 	$dmex{"135:51"}=0.102731; 
$mex{"106:52"}=-58.214429; 	$dmex{"106:52"}=0.132152; 
$mex{"108:52"}=-65.721935; 	$dmex{"108:52"}=0.103908; 
$mex{"109:52"}=-67.612012; 	$dmex{"109:52"}=0.063199; 
$mex{"110:52"}=-72.27712; 	$dmex{"110:52"}=0.052642; 
$mex{"111:52"}=-73.484917; 	$dmex{"111:52"}=0.071343; 
$mex{"112:52"}=-77.301267; 	$dmex{"112:52"}=0.170277; 
$mex{"113:52"}=-78.34703; 	$dmex{"113:52"}=0.027945; 
$mex{"114:52"}=-81.88857; 	$dmex{"114:52"}=0.027945; 
$mex{"115:52"}=-82.062759; 	$dmex{"115:52"}=0.027945; 
$mex{"116:52"}=-85.268962; 	$dmex{"116:52"}=0.027945; 
$mex{"117:52"}=-85.096897; 	$dmex{"117:52"}=0.013412; 
$mex{"118:52"}=-87.721044; 	$dmex{"118:52"}=0.01477; 
$mex{"119:52"}=-87.184443; 	$dmex{"119:52"}=0.008441; 
$mex{"120:52"}=-89.404587; 	$dmex{"120:52"}=0.009696; 
$mex{"121:52"}=-88.551151; 	$dmex{"121:52"}=0.02593; 
$mex{"122:52"}=-90.314028; 	$dmex{"122:52"}=0.00149; 
$mex{"123:52"}=-89.171894; 	$dmex{"123:52"}=0.001483; 
$mex{"124:52"}=-90.524548; 	$dmex{"124:52"}=0.001475; 
$mex{"125:52"}=-89.022201; 	$dmex{"125:52"}=0.001475; 
$mex{"126:52"}=-90.064575; 	$dmex{"126:52"}=0.001477; 
$mex{"127:52"}=-88.2811; 	$dmex{"127:52"}=0.001528; 
$mex{"128:52"}=-88.992091; 	$dmex{"128:52"}=0.00175; 
$mex{"129:52"}=-87.003181; 	$dmex{"129:52"}=0.001751; 
$mex{"130:52"}=-87.35141; 	$dmex{"130:52"}=0.001926; 
$mex{"131:52"}=-85.209473; 	$dmex{"131:52"}=0.001927; 
$mex{"132:52"}=-85.182183; 	$dmex{"132:52"}=0.006924; 
$mex{"133:52"}=-82.944598; 	$dmex{"133:52"}=0.024449; 
$mex{"134:52"}=-82.55949; 	$dmex{"134:52"}=0.010663; 
$mex{"135:52"}=-77.827636; 	$dmex{"135:52"}=0.089742; 
$mex{"136:52"}=-74.42521; 	$dmex{"136:52"}=0.045231; 
$mex{"137:52"}=-69.561221; 	$dmex{"137:52"}=0.122466; 
$mex{"109:53"}=-57.613447; 	$dmex{"109:53"}=0.103925; 
$mex{"113:53"}=-71.128339; 	$dmex{"113:53"}=0.053435; 
$mex{"115:53"}=-76.337797; 	$dmex{"115:53"}=0.028876; 
$mex{"116:53"}=-77.49226; 	$dmex{"116:53"}=0.096592; 
$mex{"117:53"}=-80.434508; 	$dmex{"117:53"}=0.027945; 
$mex{"118:53"}=-80.971048; 	$dmex{"118:53"}=0.01976; 
$mex{"119:53"}=-83.76553; 	$dmex{"119:53"}=0.027945; 
$mex{"120:53"}=-83.789587; 	$dmex{"120:53"}=0.017861; 
$mex{"121:53"}=-86.28726; 	$dmex{"121:53"}=0.010361; 
$mex{"122:53"}=-86.080028; 	$dmex{"122:53"}=0.005217; 
$mex{"123:53"}=-87.943313; 	$dmex{"123:53"}=0.003734; 
$mex{"124:53"}=-87.364961; 	$dmex{"124:53"}=0.002373; 
$mex{"125:53"}=-88.836431; 	$dmex{"125:53"}=0.001477; 
$mex{"126:53"}=-87.910536; 	$dmex{"126:53"}=0.003744; 
$mex{"127:53"}=-88.983125; 	$dmex{"127:53"}=0.003532; 
$mex{"128:53"}=-87.737939; 	$dmex{"128:53"}=0.003532; 
$mex{"129:53"}=-88.503367; 	$dmex{"129:53"}=0.003163; 
$mex{"130:53"}=-86.932379; 	$dmex{"130:53"}=0.003163; 
$mex{"131:53"}=-87.444363; 	$dmex{"131:53"}=0.001135; 
$mex{"132:53"}=-85.699888; 	$dmex{"132:53"}=0.005797; 
$mex{"133:53"}=-85.886598; 	$dmex{"133:53"}=0.004665; 
$mex{"134:53"}=-84.07249; 	$dmex{"134:53"}=0.008044; 
$mex{"135:53"}=-83.789636; 	$dmex{"135:53"}=0.00732; 
$mex{"136:53"}=-79.499294; 	$dmex{"136:53"}=0.049698; 
$mex{"137:53"}=-76.50282; 	$dmex{"137:53"}=0.027741; 
$mex{"138:53"}=-72.33089; 	$dmex{"138:53"}=0.082351; 
$mex{"139:53"}=-68.837893; 	$dmex{"139:53"}=0.031074; 
$mex{"110:54"}=-51.904646; 	$dmex{"110:54"}=0.132883; 
$mex{"112:54"}=-59.966685; 	$dmex{"112:54"}=0.104097; 
$mex{"113:54"}=-62.092297; 	$dmex{"113:54"}=0.080586; 
$mex{"114:54"}=-67.085913; 	$dmex{"114:54"}=0.011178; 
$mex{"115:54"}=-68.656771; 	$dmex{"115:54"}=0.012109; 
$mex{"116:54"}=-73.046747; 	$dmex{"116:54"}=0.013041; 
$mex{"117:54"}=-74.185361; 	$dmex{"117:54"}=0.010378; 
$mex{"118:54"}=-78.079081; 	$dmex{"118:54"}=0.010378; 
$mex{"119:54"}=-78.794437; 	$dmex{"119:54"}=0.010378; 
$mex{"120:54"}=-82.172448; 	$dmex{"120:54"}=0.011817; 
$mex{"121:54"}=-82.472775; 	$dmex{"121:54"}=0.011111; 
$mex{"122:54"}=-85.355002; 	$dmex{"122:54"}=0.011111; 
$mex{"123:54"}=-85.248552; 	$dmex{"123:54"}=0.009537; 
$mex{"124:54"}=-87.660103; 	$dmex{"124:54"}=0.001827; 
$mex{"125:54"}=-87.192064; 	$dmex{"125:54"}=0.001869; 
$mex{"126:54"}=-89.168536; 	$dmex{"126:54"}=0.006246; 
$mex{"127:54"}=-88.320793; 	$dmex{"127:54"}=0.004013; 
$mex{"128:54"}=-89.860039; 	$dmex{"128:54"}=0.001428; 
$mex{"129:54"}=-88.697386; 	$dmex{"129:54"}=0.000739; 
$mex{"130:54"}=-89.881713; 	$dmex{"130:54"}=0.00075; 
$mex{"131:54"}=-88.415211; 	$dmex{"131:54"}=0.00096; 
$mex{"132:54"}=-89.28048; 	$dmex{"132:54"}=0.000972; 
$mex{"133:54"}=-87.643598; 	$dmex{"133:54"}=0.0024; 
$mex{"134:54"}=-88.12449; 	$dmex{"134:54"}=0.00084; 
$mex{"135:54"}=-86.417033; 	$dmex{"135:54"}=0.004532; 
$mex{"136:54"}=-86.425137; 	$dmex{"136:54"}=0.007041; 
$mex{"137:54"}=-82.37935; 	$dmex{"137:54"}=0.007042; 
$mex{"138:54"}=-80.15089; 	$dmex{"138:54"}=0.043378; 
$mex{"139:54"}=-75.643893; 	$dmex{"139:54"}=0.020894; 
$mex{"140:54"}=-72.990992; 	$dmex{"140:54"}=0.060558; 
$mex{"141:54"}=-68.326902; 	$dmex{"141:54"}=0.090613; 
$mex{"142:54"}=-65.475096; 	$dmex{"142:54"}=0.10056; 
$mex{"113:55"}=-51.704182; 	$dmex{"113:55"}=0.104129; 
$mex{"116:55"}=-62.49; 	$dmex{"116:55"}=0.35; 
$mex{"117:55"}=-66.442814; 	$dmex{"117:55"}=0.06241; 
$mex{"118:55"}=-68.409391; 	$dmex{"118:55"}=0.012753; 
$mex{"119:55"}=-72.305075; 	$dmex{"119:55"}=0.01394; 
$mex{"120:55"}=-73.888663; 	$dmex{"120:55"}=0.00997; 
$mex{"121:55"}=-77.100495; 	$dmex{"121:55"}=0.013817; 
$mex{"122:55"}=-78.139833; 	$dmex{"122:55"}=0.031953; 
$mex{"123:55"}=-81.043671; 	$dmex{"123:55"}=0.012109; 
$mex{"124:55"}=-81.731335; 	$dmex{"124:55"}=0.008304; 
$mex{"125:55"}=-84.087575; 	$dmex{"125:55"}=0.007744; 
$mex{"126:55"}=-84.34494; 	$dmex{"126:55"}=0.012109; 
$mex{"127:55"}=-86.24002; 	$dmex{"127:55"}=0.005575; 
$mex{"128:55"}=-85.931378; 	$dmex{"128:55"}=0.005497; 
$mex{"129:55"}=-87.500424; 	$dmex{"129:55"}=0.004603; 
$mex{"130:55"}=-86.900424; 	$dmex{"130:55"}=0.008366; 
$mex{"131:55"}=-88.059787; 	$dmex{"131:55"}=0.005017; 
$mex{"132:55"}=-87.155926; 	$dmex{"132:55"}=0.0019; 
$mex{"133:55"}=-88.070958; 	$dmex{"133:55"}=2.2e-05; 
$mex{"134:55"}=-86.891181; 	$dmex{"134:55"}=2.6e-05; 
$mex{"135:55"}=-87.581853; 	$dmex{"135:55"}=0.001; 
$mex{"136:55"}=-86.338711; 	$dmex{"136:55"}=0.001902; 
$mex{"137:55"}=-86.545599; 	$dmex{"137:55"}=0.000455; 
$mex{"138:55"}=-82.887407; 	$dmex{"138:55"}=0.00916; 
$mex{"139:55"}=-80.700915; 	$dmex{"139:55"}=0.003152; 
$mex{"140:55"}=-77.050992; 	$dmex{"140:55"}=0.008203; 
$mex{"141:55"}=-74.476902; 	$dmex{"141:55"}=0.010525; 
$mex{"142:55"}=-70.515096; 	$dmex{"142:55"}=0.0106; 
$mex{"143:55"}=-67.67141; 	$dmex{"143:55"}=0.023686; 
$mex{"144:55"}=-63.269947; 	$dmex{"144:55"}=0.026252; 
$mex{"145:55"}=-60.056986; 	$dmex{"145:55"}=0.010842; 
$mex{"146:55"}=-55.620044; 	$dmex{"146:55"}=0.071271; 
$mex{"147:55"}=-52.019275; 	$dmex{"147:55"}=0.053056; 
$mex{"148:55"}=-47.302986; 	$dmex{"148:55"}=0.575724; 
$mex{"114:56"}=-45.945564; 	$dmex{"114:56"}=0.1392; 
$mex{"119:56"}=-64.59011; 	$dmex{"119:56"}=0.200269; 
$mex{"120:56"}=-68.888663; 	$dmex{"120:56"}=0.300166; 
$mex{"121:56"}=-70.742779; 	$dmex{"121:56"}=0.141851; 
$mex{"122:56"}=-74.608944; 	$dmex{"122:56"}=0.027945; 
$mex{"123:56"}=-75.654978; 	$dmex{"123:56"}=0.012109; 
$mex{"124:56"}=-79.0898; 	$dmex{"124:56"}=0.012497; 
$mex{"125:56"}=-79.66797; 	$dmex{"125:56"}=0.011111; 
$mex{"126:56"}=-82.669928; 	$dmex{"126:56"}=0.012497; 
$mex{"127:56"}=-82.815595; 	$dmex{"127:56"}=0.011488; 
$mex{"128:56"}=-85.401514; 	$dmex{"128:56"}=0.010095; 
$mex{"129:56"}=-85.064555; 	$dmex{"129:56"}=0.010951; 
$mex{"130:56"}=-87.261603; 	$dmex{"130:56"}=0.00279; 
$mex{"131:56"}=-86.68379; 	$dmex{"131:56"}=0.002803; 
$mex{"132:56"}=-88.434841; 	$dmex{"132:56"}=0.001057; 
$mex{"133:56"}=-87.553459; 	$dmex{"133:56"}=0.000995; 
$mex{"134:56"}=-88.949868; 	$dmex{"134:56"}=0.000399; 
$mex{"135:56"}=-87.850512; 	$dmex{"135:56"}=0.000412; 
$mex{"136:56"}=-88.886935; 	$dmex{"136:56"}=0.000414; 
$mex{"137:56"}=-87.721227; 	$dmex{"137:56"}=0.000421; 
$mex{"138:56"}=-88.261631; 	$dmex{"138:56"}=0.000423; 
$mex{"139:56"}=-84.913745; 	$dmex{"139:56"}=0.000424; 
$mex{"140:56"}=-83.271368; 	$dmex{"140:56"}=0.007959; 
$mex{"141:56"}=-79.725632; 	$dmex{"141:56"}=0.008108; 
$mex{"142:56"}=-77.823147; 	$dmex{"142:56"}=0.006181; 
$mex{"143:56"}=-73.935736; 	$dmex{"143:56"}=0.013248; 
$mex{"144:56"}=-71.768956; 	$dmex{"144:56"}=0.013349; 
$mex{"145:56"}=-67.414986; 	$dmex{"145:56"}=0.070835; 
$mex{"146:56"}=-65.00005; 	$dmex{"146:56"}=0.072302; 
$mex{"147:56"}=-61.49; 	$dmex{"147:56"}=0.09; 
$mex{"148:56"}=-58.013403; 	$dmex{"148:56"}=0.084181; 
$mex{"124:57"}=-70.25861; 	$dmex{"124:57"}=0.056669; 
$mex{"125:57"}=-73.759389; 	$dmex{"125:57"}=0.025946; 
$mex{"126:57"}=-74.973468; 	$dmex{"126:57"}=0.090508; 
$mex{"127:57"}=-77.895769; 	$dmex{"127:57"}=0.025946; 
$mex{"128:57"}=-78.631901; 	$dmex{"128:57"}=0.054448; 
$mex{"129:57"}=-81.32612; 	$dmex{"129:57"}=0.02092; 
$mex{"130:57"}=-81.628008; 	$dmex{"130:57"}=0.025946; 
$mex{"131:57"}=-83.769256; 	$dmex{"131:57"}=0.027945; 
$mex{"132:57"}=-83.740245; 	$dmex{"132:57"}=0.039164; 
$mex{"133:57"}=-85.494383; 	$dmex{"133:57"}=0.027945; 
$mex{"134:57"}=-85.21865; 	$dmex{"134:57"}=0.01993; 
$mex{"135:57"}=-86.650512; 	$dmex{"135:57"}=0.010008; 
$mex{"136:57"}=-86.036945; 	$dmex{"136:57"}=0.052914; 
$mex{"137:57"}=-87.100653; 	$dmex{"137:57"}=0.013404; 
$mex{"138:57"}=-86.524681; 	$dmex{"138:57"}=0.003528; 
$mex{"139:57"}=-87.231371; 	$dmex{"139:57"}=0.002415; 
$mex{"140:57"}=-84.321031; 	$dmex{"140:57"}=0.002415; 
$mex{"141:57"}=-82.938221; 	$dmex{"141:57"}=0.004577; 
$mex{"142:57"}=-80.034775; 	$dmex{"142:57"}=0.005663; 
$mex{"143:57"}=-78.187073; 	$dmex{"143:57"}=0.015425; 
$mex{"144:57"}=-74.892447; 	$dmex{"144:57"}=0.048815; 
$mex{"145:57"}=-72.986839; 	$dmex{"145:57"}=0.090123; 
$mex{"146:57"}=-69.122947; 	$dmex{"146:57"}=0.071388; 
$mex{"147:57"}=-66.848403; 	$dmex{"147:57"}=0.048072; 
$mex{"148:57"}=-63.128403; 	$dmex{"148:57"}=0.059045; 
$mex{"126:58"}=-70.820558; 	$dmex{"126:58"}=0.027945; 
$mex{"127:58"}=-71.975611; 	$dmex{"127:58"}=0.057753; 
$mex{"128:58"}=-75.533918; 	$dmex{"128:58"}=0.027945; 
$mex{"129:58"}=-76.287496; 	$dmex{"129:58"}=0.027945; 
$mex{"130:58"}=-79.422905; 	$dmex{"130:58"}=0.027945; 
$mex{"131:58"}=-79.715394; 	$dmex{"131:58"}=0.033534; 
$mex{"132:58"}=-82.474025; 	$dmex{"132:58"}=0.020574; 
$mex{"133:58"}=-82.423228; 	$dmex{"133:58"}=0.016354; 
$mex{"134:58"}=-84.835983; 	$dmex{"134:58"}=0.020387; 
$mex{"135:58"}=-84.62493; 	$dmex{"135:58"}=0.011043; 
$mex{"136:58"}=-86.468332; 	$dmex{"136:58"}=0.013308; 
$mex{"137:58"}=-85.878553; 	$dmex{"137:58"}=0.013308; 
$mex{"138:58"}=-87.568521; 	$dmex{"138:58"}=0.010156; 
$mex{"139:58"}=-86.952496; 	$dmex{"139:58"}=0.007347; 
$mex{"140:58"}=-88.083278; 	$dmex{"140:58"}=0.002462; 
$mex{"141:58"}=-85.440105; 	$dmex{"141:58"}=0.002462; 
$mex{"142:58"}=-84.538479; 	$dmex{"142:58"}=0.002993; 
$mex{"143:58"}=-81.611999; 	$dmex{"143:58"}=0.002993; 
$mex{"144:58"}=-80.436989; 	$dmex{"144:58"}=0.003444; 
$mex{"145:58"}=-77.096839; 	$dmex{"145:58"}=0.041498; 
$mex{"146:58"}=-75.675496; 	$dmex{"146:58"}=0.066442; 
$mex{"147:58"}=-72.028748; 	$dmex{"147:58"}=0.030523; 
$mex{"148:58"}=-70.390756; 	$dmex{"148:58"}=0.029425; 
$mex{"149:58"}=-66.69508; 	$dmex{"149:58"}=0.096908; 
$mex{"150:58"}=-64.823663; 	$dmex{"150:58"}=0.047814; 
$mex{"151:58"}=-61.500777; 	$dmex{"151:58"}=0.102629; 
$mex{"128:59"}=-66.330757; 	$dmex{"128:59"}=0.029808; 
$mex{"129:59"}=-69.773559; 	$dmex{"129:59"}=0.029808; 
$mex{"130:59"}=-71.175457; 	$dmex{"130:59"}=0.064273; 
$mex{"131:59"}=-74.278264; 	$dmex{"131:59"}=0.052164; 
$mex{"132:59"}=-75.213484; 	$dmex{"132:59"}=0.056821; 
$mex{"133:59"}=-77.937607; 	$dmex{"133:59"}=0.012497; 
$mex{"134:59"}=-78.514011; 	$dmex{"134:59"}=0.03547; 
$mex{"135:59"}=-80.935888; 	$dmex{"135:59"}=0.011817; 
$mex{"136:59"}=-81.327241; 	$dmex{"136:59"}=0.012258; 
$mex{"137:59"}=-83.177333; 	$dmex{"137:59"}=0.011787; 
$mex{"138:59"}=-83.131521; 	$dmex{"138:59"}=0.014253; 
$mex{"139:59"}=-84.823335; 	$dmex{"139:59"}=0.007916; 
$mex{"140:59"}=-84.695278; 	$dmex{"140:59"}=0.006485; 
$mex{"141:59"}=-86.020892; 	$dmex{"141:59"}=0.002468; 
$mex{"142:59"}=-83.792724; 	$dmex{"142:59"}=0.002468; 
$mex{"143:59"}=-83.073499; 	$dmex{"143:59"}=0.002633; 
$mex{"144:59"}=-80.755645; 	$dmex{"144:59"}=0.003342; 
$mex{"145:59"}=-79.631839; 	$dmex{"145:59"}=0.007446; 
$mex{"146:59"}=-76.713808; 	$dmex{"146:59"}=0.061711; 
$mex{"147:59"}=-75.454748; 	$dmex{"147:59"}=0.023057; 
$mex{"148:59"}=-72.530756; 	$dmex{"148:59"}=0.025881; 
$mex{"149:59"}=-71.05655; 	$dmex{"149:59"}=0.082122; 
$mex{"150:59"}=-68.303663; 	$dmex{"150:59"}=0.026194; 
$mex{"151:59"}=-66.770777; 	$dmex{"151:59"}=0.023079; 
$mex{"152:59"}=-63.808061; 	$dmex{"152:59"}=0.122497; 
$mex{"153:59"}=-61.628663; 	$dmex{"153:59"}=0.103673; 
$mex{"154:59"}=-58.201466; 	$dmex{"154:59"}=0.151651; 
$mex{"130:60"}=-66.596233; 	$dmex{"130:60"}=0.027945; 
$mex{"131:60"}=-67.768984; 	$dmex{"131:60"}=0.027945; 
$mex{"132:60"}=-71.425808; 	$dmex{"132:60"}=0.024205; 
$mex{"133:60"}=-72.332373; 	$dmex{"133:60"}=0.046575; 
$mex{"134:60"}=-75.646459; 	$dmex{"134:60"}=0.011817; 
$mex{"135:60"}=-76.213758; 	$dmex{"135:60"}=0.019296; 
$mex{"136:60"}=-79.199314; 	$dmex{"136:60"}=0.011817; 
$mex{"137:60"}=-79.580199; 	$dmex{"137:60"}=0.011482; 
$mex{"138:60"}=-82.018083; 	$dmex{"138:60"}=0.011817; 
$mex{"139:60"}=-81.991697; 	$dmex{"139:60"}=0.025845; 
$mex{"140:60"}=-84.25177; 	$dmex{"140:60"}=0.027945; 
$mex{"141:60"}=-84.197879; 	$dmex{"141:60"}=0.003739; 
$mex{"142:60"}=-85.955195; 	$dmex{"142:60"}=0.002328; 
$mex{"143:60"}=-84.007448; 	$dmex{"143:60"}=0.002328; 
$mex{"144:60"}=-83.753165; 	$dmex{"144:60"}=0.002328; 
$mex{"145:60"}=-81.437134; 	$dmex{"145:60"}=0.002334; 
$mex{"146:60"}=-80.93105; 	$dmex{"146:60"}=0.002334; 
$mex{"147:60"}=-78.151936; 	$dmex{"147:60"}=0.002335; 
$mex{"148:60"}=-77.413404; 	$dmex{"148:60"}=0.002837; 
$mex{"149:60"}=-74.380875; 	$dmex{"149:60"}=0.002838; 
$mex{"150:60"}=-73.689663; 	$dmex{"150:60"}=0.003184; 
$mex{"151:60"}=-70.952896; 	$dmex{"151:60"}=0.003186; 
$mex{"152:60"}=-70.158061; 	$dmex{"152:60"}=0.024609; 
$mex{"153:60"}=-67.348663; 	$dmex{"153:60"}=0.027352; 
$mex{"154:60"}=-65.691466; 	$dmex{"154:60"}=0.114008; 
$mex{"155:60"}=-62.76; 	$dmex{"155:60"}=0.15; 
$mex{"156:60"}=-60.530237; 	$dmex{"156:60"}=0.202934; 
$mex{"133:61"}=-65.407646; 	$dmex{"133:61"}=0.050301; 
$mex{"134:61"}=-66.738751; 	$dmex{"134:61"}=0.057753; 
$mex{"135:61"}=-69.977556; 	$dmex{"135:61"}=0.058684; 
$mex{"136:61"}=-71.197972; 	$dmex{"136:61"}=0.078062; 
$mex{"137:61"}=-74.072875; 	$dmex{"137:61"}=0.013041; 
$mex{"138:61"}=-74.940294; 	$dmex{"138:61"}=0.027494; 
$mex{"139:61"}=-77.496499; 	$dmex{"139:61"}=0.013481; 
$mex{"140:61"}=-78.20657; 	$dmex{"140:61"}=0.036836; 
$mex{"141:61"}=-80.522949; 	$dmex{"141:61"}=0.013972; 
$mex{"142:61"}=-81.156907; 	$dmex{"142:61"}=0.025061; 
$mex{"143:61"}=-82.965734; 	$dmex{"143:61"}=0.003308; 
$mex{"144:61"}=-81.421106; 	$dmex{"144:61"}=0.00319; 
$mex{"145:61"}=-81.273762; 	$dmex{"145:61"}=0.003137; 
$mex{"146:61"}=-79.45988; 	$dmex{"146:61"}=0.004687; 
$mex{"147:61"}=-79.047936; 	$dmex{"147:61"}=0.002409; 
$mex{"148:61"}=-76.871898; 	$dmex{"148:61"}=0.006083; 
$mex{"149:61"}=-76.071245; 	$dmex{"149:61"}=0.004159; 
$mex{"150:61"}=-73.603339; 	$dmex{"150:61"}=0.020147; 
$mex{"151:61"}=-73.395232; 	$dmex{"151:61"}=0.00534; 
$mex{"152:61"}=-71.262276; 	$dmex{"152:61"}=0.026016; 
$mex{"153:61"}=-70.684663; 	$dmex{"153:61"}=0.011097; 
$mex{"154:61"}=-68.498396; 	$dmex{"154:61"}=0.044794; 
$mex{"155:61"}=-66.973239; 	$dmex{"155:61"}=0.030109; 
$mex{"156:61"}=-64.220237; 	$dmex{"156:61"}=0.034382; 
$mex{"157:61"}=-62.373426; 	$dmex{"157:61"}=0.11193; 
$mex{"158:61"}=-59.092669; 	$dmex{"158:61"}=0.127015; 
$mex{"135:62"}=-62.857216; 	$dmex{"135:62"}=0.154628; 
$mex{"136:62"}=-66.810917; 	$dmex{"136:62"}=0.012497; 
$mex{"137:62"}=-68.025381; 	$dmex{"137:62"}=0.042391; 
$mex{"138:62"}=-71.49779; 	$dmex{"138:62"}=0.011817; 
$mex{"139:62"}=-72.380247; 	$dmex{"139:62"}=0.010884; 
$mex{"140:62"}=-75.455963; 	$dmex{"140:62"}=0.012497; 
$mex{"141:62"}=-75.938662; 	$dmex{"141:62"}=0.008627; 
$mex{"142:62"}=-78.992889; 	$dmex{"142:62"}=0.005675; 
$mex{"143:62"}=-79.523191; 	$dmex{"143:62"}=0.00363; 
$mex{"144:62"}=-81.971958; 	$dmex{"144:62"}=0.002807; 
$mex{"145:62"}=-80.657737; 	$dmex{"145:62"}=0.002814; 
$mex{"146:62"}=-81.00188; 	$dmex{"146:62"}=0.003601; 
$mex{"147:62"}=-79.272075; 	$dmex{"147:62"}=0.002412; 
$mex{"148:62"}=-79.342169; 	$dmex{"148:62"}=0.002417; 
$mex{"149:62"}=-77.141922; 	$dmex{"149:62"}=0.002443; 
$mex{"150:62"}=-77.057339; 	$dmex{"150:62"}=0.002433; 
$mex{"151:62"}=-74.582481; 	$dmex{"151:62"}=0.002433; 
$mex{"152:62"}=-74.768765; 	$dmex{"152:62"}=0.002471; 
$mex{"153:62"}=-72.565846; 	$dmex{"153:62"}=0.002474; 
$mex{"154:62"}=-72.461596; 	$dmex{"154:62"}=0.002548; 
$mex{"155:62"}=-70.197239; 	$dmex{"155:62"}=0.002562; 
$mex{"156:62"}=-69.370326; 	$dmex{"156:62"}=0.009528; 
$mex{"157:62"}=-66.733426; 	$dmex{"157:62"}=0.050282; 
$mex{"158:62"}=-65.212669; 	$dmex{"158:62"}=0.078313; 
$mex{"159:62"}=-62.213301; 	$dmex{"159:62"}=0.100268; 
$mex{"138:63"}=-61.749669; 	$dmex{"138:63"}=0.027945; 
$mex{"139:63"}=-65.39807; 	$dmex{"139:63"}=0.013151; 
$mex{"140:63"}=-66.985963; 	$dmex{"140:63"}=0.051538; 
$mex{"141:63"}=-69.926584; 	$dmex{"141:63"}=0.012641; 
$mex{"142:63"}=-71.319889; 	$dmex{"142:63"}=0.030532; 
$mex{"143:63"}=-74.242392; 	$dmex{"143:63"}=0.010986; 
$mex{"144:63"}=-75.621643; 	$dmex{"144:63"}=0.010827; 
$mex{"145:63"}=-77.998429; 	$dmex{"145:63"}=0.003843; 
$mex{"146:63"}=-77.122285; 	$dmex{"146:63"}=0.006233; 
$mex{"147:63"}=-77.550499; 	$dmex{"147:63"}=0.003228; 
$mex{"148:63"}=-76.302498; 	$dmex{"148:63"}=0.010208; 
$mex{"149:63"}=-76.44656; 	$dmex{"149:63"}=0.004348; 
$mex{"150:63"}=-74.797274; 	$dmex{"150:63"}=0.006497; 
$mex{"151:63"}=-74.659094; 	$dmex{"151:63"}=0.002455; 
$mex{"152:63"}=-72.894497; 	$dmex{"152:63"}=0.002455; 
$mex{"153:63"}=-73.373467; 	$dmex{"153:63"}=0.002457; 
$mex{"154:63"}=-71.744378; 	$dmex{"154:63"}=0.002462; 
$mex{"155:63"}=-71.824466; 	$dmex{"155:63"}=0.00249; 
$mex{"156:63"}=-70.092829; 	$dmex{"156:63"}=0.005812; 
$mex{"157:63"}=-69.467426; 	$dmex{"157:63"}=0.005319; 
$mex{"158:63"}=-67.211669; 	$dmex{"158:63"}=0.076863; 
$mex{"159:63"}=-66.053301; 	$dmex{"159:63"}=0.007321; 
$mex{"140:64"}=-61.782272; 	$dmex{"140:64"}=0.027945; 
$mex{"141:64"}=-63.224224; 	$dmex{"141:64"}=0.01976; 
$mex{"142:64"}=-66.959515; 	$dmex{"142:64"}=0.027945; 
$mex{"143:64"}=-68.232392; 	$dmex{"143:64"}=0.200301; 
$mex{"144:64"}=-71.759504; 	$dmex{"144:64"}=0.027945; 
$mex{"145:64"}=-72.927362; 	$dmex{"145:64"}=0.018756; 
$mex{"146:64"}=-76.093179; 	$dmex{"146:64"}=0.004707; 
$mex{"147:64"}=-75.363063; 	$dmex{"147:64"}=0.00303; 
$mex{"148:64"}=-76.27583; 	$dmex{"148:64"}=0.002807; 
$mex{"149:64"}=-75.133454; 	$dmex{"149:64"}=0.00395; 
$mex{"150:64"}=-75.768769; 	$dmex{"150:64"}=0.006317; 
$mex{"151:64"}=-74.194911; 	$dmex{"151:64"}=0.003674; 
$mex{"152:64"}=-74.714206; 	$dmex{"152:64"}=0.002513; 
$mex{"153:64"}=-72.889831; 	$dmex{"153:64"}=0.002509; 
$mex{"154:64"}=-73.713221; 	$dmex{"154:64"}=0.002504; 
$mex{"155:64"}=-72.077123; 	$dmex{"155:64"}=0.002504; 
$mex{"156:64"}=-72.542197; 	$dmex{"156:64"}=0.002504; 
$mex{"157:64"}=-70.830678; 	$dmex{"157:64"}=0.002505; 
$mex{"158:64"}=-70.696751; 	$dmex{"158:64"}=0.002505; 
$mex{"159:64"}=-68.568524; 	$dmex{"159:64"}=0.002508; 
$mex{"160:64"}=-67.948626; 	$dmex{"160:64"}=0.002556; 
$mex{"161:64"}=-65.512709; 	$dmex{"161:64"}=0.002745; 
$mex{"162:64"}=-64.28729; 	$dmex{"162:64"}=0.00458; 
$mex{"140:65"}=-50.482272; 	$dmex{"140:65"}=0.800488; 
$mex{"141:65"}=-54.540837; 	$dmex{"141:65"}=0.105259; 
$mex{"143:65"}=-60.4344; 	$dmex{"143:65"}=0.059616; 
$mex{"144:65"}=-62.368181; 	$dmex{"144:65"}=0.027945; 
$mex{"145:65"}=-65.880845; 	$dmex{"145:65"}=0.056821; 
$mex{"146:65"}=-67.76937; 	$dmex{"146:65"}=0.045211; 
$mex{"147:65"}=-70.752013; 	$dmex{"147:65"}=0.011915; 
$mex{"148:65"}=-70.540457; 	$dmex{"148:65"}=0.013907; 
$mex{"149:65"}=-71.495975; 	$dmex{"149:65"}=0.004284; 
$mex{"150:65"}=-71.110545; 	$dmex{"150:65"}=0.007556; 
$mex{"151:65"}=-71.62952; 	$dmex{"151:65"}=0.004582; 
$mex{"152:65"}=-70.724206; 	$dmex{"152:65"}=0.040079; 
$mex{"153:65"}=-71.320222; 	$dmex{"153:65"}=0.004491; 
$mex{"154:65"}=-70.161974; 	$dmex{"154:65"}=0.045367; 
$mex{"155:65"}=-71.254414; 	$dmex{"155:65"}=0.012125; 
$mex{"156:65"}=-70.09752; 	$dmex{"156:65"}=0.004412; 
$mex{"157:65"}=-70.770626; 	$dmex{"157:65"}=0.002521; 
$mex{"158:65"}=-69.477216; 	$dmex{"158:65"}=0.002618; 
$mex{"159:65"}=-69.539048; 	$dmex{"159:65"}=0.002551; 
$mex{"160:65"}=-67.842938; 	$dmex{"160:65"}=0.002555; 
$mex{"161:65"}=-67.468186; 	$dmex{"161:65"}=0.002604; 
$mex{"162:65"}=-65.681287; 	$dmex{"162:65"}=0.036452; 
$mex{"163:65"}=-64.601404; 	$dmex{"163:65"}=0.004735; 
$mex{"164:65"}=-62.083294; 	$dmex{"164:65"}=0.100032; 
$mex{"166:65"}=-57.760118; 	$dmex{"166:65"}=0.100033; 
$mex{"144:66"}=-56.584535; 	$dmex{"144:66"}=0.030739; 
$mex{"145:66"}=-58.288238; 	$dmex{"145:66"}=0.045643; 
$mex{"146:66"}=-62.554136; 	$dmex{"146:66"}=0.027112; 
$mex{"147:66"}=-64.187855; 	$dmex{"147:66"}=0.01976; 
$mex{"148:66"}=-67.859496; 	$dmex{"148:66"}=0.010583; 
$mex{"149:66"}=-67.715154; 	$dmex{"149:66"}=0.008764; 
$mex{"150:66"}=-69.316955; 	$dmex{"150:66"}=0.00491; 
$mex{"151:66"}=-68.758601; 	$dmex{"151:66"}=0.00402; 
$mex{"152:66"}=-70.124452; 	$dmex{"152:66"}=0.005181; 
$mex{"153:66"}=-69.149764; 	$dmex{"153:66"}=0.004535; 
$mex{"154:66"}=-70.398165; 	$dmex{"154:66"}=0.007633; 
$mex{"155:66"}=-69.159914; 	$dmex{"155:66"}=0.011976; 
$mex{"156:66"}=-70.529829; 	$dmex{"156:66"}=0.006589; 
$mex{"157:66"}=-69.427886; 	$dmex{"157:66"}=0.006672; 
$mex{"158:66"}=-70.412109; 	$dmex{"158:66"}=0.003397; 
$mex{"159:66"}=-69.173476; 	$dmex{"159:66"}=0.002731; 
$mex{"160:66"}=-69.678064; 	$dmex{"160:66"}=0.002536; 
$mex{"161:66"}=-68.061133; 	$dmex{"161:66"}=0.002535; 
$mex{"162:66"}=-68.186808; 	$dmex{"162:66"}=0.002535; 
$mex{"163:66"}=-66.386498; 	$dmex{"163:66"}=0.002535; 
$mex{"164:66"}=-65.973294; 	$dmex{"164:66"}=0.002534; 
$mex{"165:66"}=-63.617935; 	$dmex{"165:66"}=0.002535; 
$mex{"166:66"}=-62.590118; 	$dmex{"166:66"}=0.002566; 
$mex{"167:66"}=-59.936551; 	$dmex{"167:66"}=0.060271; 
$mex{"168:66"}=-58.564175; 	$dmex{"168:66"}=0.140027; 
$mex{"169:66"}=-55.603099; 	$dmex{"169:66"}=0.300679; 
$mex{"147:67"}=-55.837477; 	$dmex{"147:67"}=0.027945; 
$mex{"148:67"}=-58.01531; 	$dmex{"148:67"}=0.129478; 
$mex{"149:67"}=-61.688403; 	$dmex{"149:67"}=0.018404; 
$mex{"150:67"}=-61.947908; 	$dmex{"150:67"}=0.014182; 
$mex{"151:67"}=-63.632086; 	$dmex{"151:67"}=0.012053; 
$mex{"152:67"}=-63.608266; 	$dmex{"152:67"}=0.013971; 
$mex{"153:67"}=-65.01941; 	$dmex{"153:67"}=0.005554; 
$mex{"154:67"}=-64.644213; 	$dmex{"154:67"}=0.008383; 
$mex{"155:67"}=-66.039673; 	$dmex{"155:67"}=0.01789; 
$mex{"156:67"}=-65.354551; 	$dmex{"156:67"}=0.044712; 
$mex{"157:67"}=-66.82893; 	$dmex{"157:67"}=0.024428; 
$mex{"158:67"}=-66.191026; 	$dmex{"158:67"}=0.027218; 
$mex{"159:67"}=-67.335876; 	$dmex{"159:67"}=0.003829; 
$mex{"160:67"}=-66.388064; 	$dmex{"160:67"}=0.015213; 
$mex{"161:67"}=-67.202843; 	$dmex{"161:67"}=0.003222; 
$mex{"162:67"}=-66.047112; 	$dmex{"162:67"}=0.003921; 
$mex{"163:67"}=-66.383942; 	$dmex{"163:67"}=0.002535; 
$mex{"164:67"}=-64.987069; 	$dmex{"164:67"}=0.002773; 
$mex{"165:67"}=-64.904574; 	$dmex{"165:67"}=0.002525; 
$mex{"166:67"}=-63.076897; 	$dmex{"166:67"}=0.002525; 
$mex{"167:67"}=-62.286551; 	$dmex{"167:67"}=0.005709; 
$mex{"168:67"}=-60.066731; 	$dmex{"168:67"}=0.030105; 
$mex{"169:67"}=-58.803099; 	$dmex{"169:67"}=0.020189; 
$mex{"170:67"}=-56.244606; 	$dmex{"170:67"}=0.050076; 
$mex{"171:67"}=-54.524862; 	$dmex{"171:67"}=0.600006; 
$mex{"149:68"}=-53.741615; 	$dmex{"149:68"}=0.027945; 
$mex{"150:68"}=-57.832887; 	$dmex{"150:68"}=0.017201; 
$mex{"151:68"}=-58.265971; 	$dmex{"151:68"}=0.01647; 
$mex{"152:68"}=-60.500173; 	$dmex{"152:68"}=0.010706; 
$mex{"153:68"}=-60.487968; 	$dmex{"153:68"}=0.008828; 
$mex{"154:68"}=-62.612157; 	$dmex{"154:68"}=0.00547; 
$mex{"155:68"}=-62.215463; 	$dmex{"155:68"}=0.00652; 
$mex{"156:68"}=-64.212821; 	$dmex{"156:68"}=0.024428; 
$mex{"157:68"}=-63.419838; 	$dmex{"157:68"}=0.027945; 
$mex{"158:68"}=-65.303809; 	$dmex{"158:68"}=0.025219; 
$mex{"159:68"}=-64.567376; 	$dmex{"159:68"}=0.004319; 
$mex{"160:68"}=-66.058488; 	$dmex{"160:68"}=0.024428; 
$mex{"161:68"}=-65.20895; 	$dmex{"161:68"}=0.009404; 
$mex{"162:68"}=-66.34262; 	$dmex{"162:68"}=0.003467; 
$mex{"163:68"}=-65.174074; 	$dmex{"163:68"}=0.005243; 
$mex{"164:68"}=-65.949562; 	$dmex{"164:68"}=0.00307; 
$mex{"165:68"}=-64.528312; 	$dmex{"165:68"}=0.003081; 
$mex{"166:68"}=-64.931595; 	$dmex{"166:68"}=0.002514; 
$mex{"167:68"}=-63.296733; 	$dmex{"167:68"}=0.002512; 
$mex{"168:68"}=-62.996731; 	$dmex{"168:68"}=0.002512; 
$mex{"169:68"}=-60.928684; 	$dmex{"169:68"}=0.002516; 
$mex{"170:68"}=-60.114606; 	$dmex{"170:68"}=0.002754; 
$mex{"171:68"}=-57.724862; 	$dmex{"171:68"}=0.002763; 
$mex{"172:68"}=-56.489417; 	$dmex{"172:68"}=0.004618; 
$mex{"151:69"}=-50.781802; 	$dmex{"151:69"}=0.020252; 
$mex{"152:69"}=-51.770574; 	$dmex{"152:69"}=0.073588; 
$mex{"153:69"}=-54.01537; 	$dmex{"153:69"}=0.018461; 
$mex{"154:69"}=-54.429236; 	$dmex{"154:69"}=0.014426; 
$mex{"155:69"}=-56.635339; 	$dmex{"155:69"}=0.013223; 
$mex{"156:69"}=-56.839827; 	$dmex{"156:69"}=0.015744; 
$mex{"157:69"}=-58.709273; 	$dmex{"157:69"}=0.027945; 
$mex{"158:69"}=-58.703194; 	$dmex{"158:69"}=0.025219; 
$mex{"159:69"}=-60.570398; 	$dmex{"159:69"}=0.027945; 
$mex{"160:69"}=-60.302313; 	$dmex{"160:69"}=0.034274; 
$mex{"161:69"}=-61.898708; 	$dmex{"161:69"}=0.027945; 
$mex{"162:69"}=-61.483558; 	$dmex{"162:69"}=0.026277; 
$mex{"163:69"}=-62.735074; 	$dmex{"163:69"}=0.00604; 
$mex{"164:69"}=-61.888462; 	$dmex{"164:69"}=0.027945; 
$mex{"165:69"}=-62.935934; 	$dmex{"165:69"}=0.003319; 
$mex{"166:69"}=-61.893929; 	$dmex{"166:69"}=0.011817; 
$mex{"167:69"}=-62.548311; 	$dmex{"167:69"}=0.002674; 
$mex{"168:69"}=-61.317664; 	$dmex{"168:69"}=0.002897; 
$mex{"169:69"}=-61.279963; 	$dmex{"169:69"}=0.002476; 
$mex{"170:69"}=-59.800614; 	$dmex{"170:69"}=0.002476; 
$mex{"171:69"}=-59.215595; 	$dmex{"171:69"}=0.002584; 
$mex{"172:69"}=-57.37999; 	$dmex{"172:69"}=0.00597; 
$mex{"173:69"}=-56.258878; 	$dmex{"173:69"}=0.005096; 
$mex{"174:69"}=-53.869598; 	$dmex{"174:69"}=0.044785; 
$mex{"175:69"}=-52.315634; 	$dmex{"175:69"}=0.050057; 
$mex{"176:69"}=-49.374133; 	$dmex{"176:69"}=0.100033; 
$mex{"151:70"}=-41.543916; 	$dmex{"151:70"}=0.300493; 
$mex{"152:70"}=-46.305574; 	$dmex{"152:70"}=0.208423; 
$mex{"154:70"}=-49.933735; 	$dmex{"154:70"}=0.017288; 
$mex{"155:70"}=-50.503433; 	$dmex{"155:70"}=0.016625; 
$mex{"156:70"}=-53.26449; 	$dmex{"156:70"}=0.011287; 
$mex{"157:70"}=-53.441815; 	$dmex{"157:70"}=0.010138; 
$mex{"158:70"}=-56.014817; 	$dmex{"158:70"}=0.008203; 
$mex{"159:70"}=-55.842973; 	$dmex{"159:70"}=0.018356; 
$mex{"160:70"}=-58.169617; 	$dmex{"160:70"}=0.016507; 
$mex{"161:70"}=-57.844214; 	$dmex{"161:70"}=0.015993; 
$mex{"162:70"}=-59.831527; 	$dmex{"162:70"}=0.015993; 
$mex{"163:70"}=-59.304213; 	$dmex{"163:70"}=0.015993; 
$mex{"164:70"}=-61.022716; 	$dmex{"164:70"}=0.015993; 
$mex{"165:70"}=-60.287224; 	$dmex{"165:70"}=0.027945; 
$mex{"166:70"}=-61.588481; 	$dmex{"166:70"}=0.008263; 
$mex{"167:70"}=-60.594053; 	$dmex{"167:70"}=0.004628; 
$mex{"168:70"}=-61.574646; 	$dmex{"168:70"}=0.004391; 
$mex{"169:70"}=-60.370311; 	$dmex{"169:70"}=0.004391; 
$mex{"170:70"}=-60.768957; 	$dmex{"170:70"}=0.002449; 
$mex{"171:70"}=-59.312137; 	$dmex{"171:70"}=0.0024; 
$mex{"172:70"}=-59.26028; 	$dmex{"172:70"}=0.002398; 
$mex{"173:70"}=-57.556282; 	$dmex{"173:70"}=0.002388; 
$mex{"174:70"}=-56.949598; 	$dmex{"174:70"}=0.002388; 
$mex{"175:70"}=-54.700634; 	$dmex{"175:70"}=0.002388; 
$mex{"176:70"}=-53.494133; 	$dmex{"176:70"}=0.002571; 
$mex{"177:70"}=-50.989216; 	$dmex{"177:70"}=0.002581; 
$mex{"178:70"}=-49.698297; 	$dmex{"178:70"}=0.010325; 
$mex{"153:71"}=-38.407984; 	$dmex{"153:71"}=0.208658; 
$mex{"155:71"}=-42.554171; 	$dmex{"155:71"}=0.020089; 
$mex{"156:71"}=-43.749923; 	$dmex{"156:71"}=0.073658; 
$mex{"157:71"}=-46.483134; 	$dmex{"157:71"}=0.018682; 
$mex{"158:71"}=-47.214373; 	$dmex{"158:71"}=0.015138; 
$mex{"159:71"}=-49.714975; 	$dmex{"159:71"}=0.037663; 
$mex{"160:71"}=-50.269937; 	$dmex{"160:71"}=0.056821; 
$mex{"161:71"}=-52.562344; 	$dmex{"161:71"}=0.027945; 
$mex{"162:71"}=-52.836866; 	$dmex{"162:71"}=0.075036; 
$mex{"163:71"}=-54.791409; 	$dmex{"163:71"}=0.027945; 
$mex{"164:71"}=-54.64237; 	$dmex{"164:71"}=0.027945; 
$mex{"165:71"}=-56.442273; 	$dmex{"165:71"}=0.02654; 
$mex{"166:71"}=-56.020981; 	$dmex{"166:71"}=0.029808; 
$mex{"167:71"}=-57.501125; 	$dmex{"167:71"}=0.031671; 
$mex{"168:71"}=-57.064151; 	$dmex{"168:71"}=0.04695; 
$mex{"169:71"}=-58.077311; 	$dmex{"169:71"}=0.005318; 
$mex{"170:71"}=-57.310199; 	$dmex{"170:71"}=0.01702; 
$mex{"171:71"}=-57.833542; 	$dmex{"171:71"}=0.002767; 
$mex{"172:71"}=-56.741334; 	$dmex{"172:71"}=0.002978; 
$mex{"173:71"}=-56.885778; 	$dmex{"173:71"}=0.00242; 
$mex{"174:71"}=-55.575279; 	$dmex{"174:71"}=0.002405; 
$mex{"175:71"}=-55.170695; 	$dmex{"175:71"}=0.002187; 
$mex{"176:71"}=-53.387359; 	$dmex{"176:71"}=0.002184; 
$mex{"177:71"}=-52.389034; 	$dmex{"177:71"}=0.002185; 
$mex{"178:71"}=-50.343004; 	$dmex{"178:71"}=0.002889; 
$mex{"179:71"}=-49.06417; 	$dmex{"179:71"}=0.005458; 
$mex{"180:71"}=-46.685398; 	$dmex{"180:71"}=0.070743; 
$mex{"156:72"}=-37.852167; 	$dmex{"156:72"}=0.208458; 
$mex{"158:72"}=-42.104119; 	$dmex{"158:72"}=0.017501; 
$mex{"159:72"}=-42.853503; 	$dmex{"159:72"}=0.016838; 
$mex{"160:72"}=-45.937205; 	$dmex{"160:72"}=0.011583; 
$mex{"161:72"}=-46.318685; 	$dmex{"161:72"}=0.022536; 
$mex{"162:72"}=-49.173105; 	$dmex{"162:72"}=0.009598; 
$mex{"163:72"}=-49.28628; 	$dmex{"163:72"}=0.027945; 
$mex{"164:72"}=-51.821541; 	$dmex{"164:72"}=0.020403; 
$mex{"165:72"}=-51.635507; 	$dmex{"165:72"}=0.027945; 
$mex{"166:72"}=-53.858984; 	$dmex{"166:72"}=0.027945; 
$mex{"167:72"}=-53.467756; 	$dmex{"167:72"}=0.027945; 
$mex{"168:72"}=-55.360552; 	$dmex{"168:72"}=0.027945; 
$mex{"169:72"}=-54.71689; 	$dmex{"169:72"}=0.027945; 
$mex{"170:72"}=-56.253855; 	$dmex{"170:72"}=0.027945; 
$mex{"171:72"}=-55.431345; 	$dmex{"171:72"}=0.028876; 
$mex{"172:72"}=-56.403544; 	$dmex{"172:72"}=0.024428; 
$mex{"173:72"}=-55.411784; 	$dmex{"173:72"}=0.027945; 
$mex{"174:72"}=-55.846626; 	$dmex{"174:72"}=0.002806; 
$mex{"175:72"}=-54.483847; 	$dmex{"175:72"}=0.002825; 
$mex{"176:72"}=-54.577509; 	$dmex{"176:72"}=0.002216; 
$mex{"177:72"}=-52.889623; 	$dmex{"177:72"}=0.002146; 
$mex{"178:72"}=-52.444262; 	$dmex{"178:72"}=0.002144; 
$mex{"179:72"}=-50.471936; 	$dmex{"179:72"}=0.002143; 
$mex{"180:72"}=-49.788398; 	$dmex{"180:72"}=0.002147; 
$mex{"181:72"}=-47.411884; 	$dmex{"181:72"}=0.002148; 
$mex{"182:72"}=-46.058563; 	$dmex{"182:72"}=0.006373; 
$mex{"183:72"}=-43.286117; 	$dmex{"183:72"}=0.030054; 
$mex{"184:72"}=-41.501304; 	$dmex{"184:72"}=0.039708; 
$mex{"157:73"}=-29.628547; 	$dmex{"157:73"}=0.208684; 
$mex{"159:73"}=-34.44835; 	$dmex{"159:73"}=0.020514; 
$mex{"160:73"}=-35.875507; 	$dmex{"160:73"}=0.089025; 
$mex{"161:73"}=-38.78; 	$dmex{"161:73"}=0.05; 
$mex{"162:73"}=-39.782377; 	$dmex{"162:73"}=0.052241; 
$mex{"163:73"}=-42.541078; 	$dmex{"163:73"}=0.038061; 
$mex{"164:73"}=-43.282801; 	$dmex{"164:73"}=0.027945; 
$mex{"165:73"}=-45.855107; 	$dmex{"165:73"}=0.017371; 
$mex{"166:73"}=-46.097776; 	$dmex{"166:73"}=0.027945; 
$mex{"167:73"}=-48.35106; 	$dmex{"167:73"}=0.027945; 
$mex{"168:73"}=-48.393908; 	$dmex{"168:73"}=0.027945; 
$mex{"169:73"}=-50.29043; 	$dmex{"169:73"}=0.027945; 
$mex{"170:73"}=-50.137665; 	$dmex{"170:73"}=0.027945; 
$mex{"171:73"}=-51.720273; 	$dmex{"171:73"}=0.027945; 
$mex{"172:73"}=-51.329977; 	$dmex{"172:73"}=0.027945; 
$mex{"173:73"}=-52.396538; 	$dmex{"173:73"}=0.027945; 
$mex{"174:73"}=-51.740766; 	$dmex{"174:73"}=0.027945; 
$mex{"175:73"}=-52.408647; 	$dmex{"175:73"}=0.027945; 
$mex{"176:73"}=-51.365374; 	$dmex{"176:73"}=0.030739; 
$mex{"177:73"}=-51.723623; 	$dmex{"177:73"}=0.003689; 
$mex{"178:73"}=-50.507262; 	$dmex{"178:73"}=0.015152; 
$mex{"179:73"}=-50.366314; 	$dmex{"179:73"}=0.002173; 
$mex{"180:73"}=-48.936195; 	$dmex{"180:73"}=0.002216; 
$mex{"181:73"}=-48.441634; 	$dmex{"181:73"}=0.001793; 
$mex{"182:73"}=-46.433254; 	$dmex{"182:73"}=0.001794; 
$mex{"183:73"}=-45.296117; 	$dmex{"183:73"}=0.001805; 
$mex{"184:73"}=-42.841304; 	$dmex{"184:73"}=0.026014; 
$mex{"185:73"}=-41.396176; 	$dmex{"185:73"}=0.014171; 
$mex{"186:73"}=-38.608542; 	$dmex{"186:73"}=0.060025; 
$mex{"160:74"}=-29.361804; 	$dmex{"160:74"}=0.208508; 
$mex{"162:74"}=-34.001937; 	$dmex{"162:74"}=0.01771; 
$mex{"163:74"}=-34.909095; 	$dmex{"163:74"}=0.052759; 
$mex{"164:74"}=-38.233747; 	$dmex{"164:74"}=0.011756; 
$mex{"165:74"}=-38.861977; 	$dmex{"165:74"}=0.024976; 
$mex{"166:74"}=-41.891844; 	$dmex{"166:74"}=0.010398; 
$mex{"167:74"}=-42.088612; 	$dmex{"167:74"}=0.019264; 
$mex{"168:74"}=-44.890192; 	$dmex{"168:74"}=0.016283; 
$mex{"169:74"}=-44.917768; 	$dmex{"169:74"}=0.015436; 
$mex{"170:74"}=-47.293364; 	$dmex{"170:74"}=0.015127; 
$mex{"171:74"}=-47.086091; 	$dmex{"171:74"}=0.027945; 
$mex{"172:74"}=-49.097186; 	$dmex{"172:74"}=0.027945; 
$mex{"173:74"}=-48.727383; 	$dmex{"173:74"}=0.027945; 
$mex{"174:74"}=-50.227088; 	$dmex{"174:74"}=0.027945; 
$mex{"175:74"}=-49.632795; 	$dmex{"175:74"}=0.027945; 
$mex{"176:74"}=-50.641603; 	$dmex{"176:74"}=0.027945; 
$mex{"177:74"}=-49.701726; 	$dmex{"177:74"}=0.027945; 
$mex{"178:74"}=-50.415962; 	$dmex{"178:74"}=0.015284; 
$mex{"179:74"}=-49.303561; 	$dmex{"179:74"}=0.015506; 
$mex{"180:74"}=-49.644477; 	$dmex{"180:74"}=0.003931; 
$mex{"181:74"}=-48.253952; 	$dmex{"181:74"}=0.004734; 
$mex{"182:74"}=-48.247518; 	$dmex{"182:74"}=0.000828; 
$mex{"183:74"}=-46.367023; 	$dmex{"183:74"}=0.000824; 
$mex{"184:74"}=-45.707304; 	$dmex{"184:74"}=0.000859; 
$mex{"185:74"}=-43.389676; 	$dmex{"185:74"}=0.000904; 
$mex{"186:74"}=-42.509542; 	$dmex{"186:74"}=0.001749; 
$mex{"187:74"}=-39.904768; 	$dmex{"187:74"}=0.001748; 
$mex{"188:74"}=-38.66715; 	$dmex{"188:74"}=0.003317; 
$mex{"189:74"}=-35.477935; 	$dmex{"189:74"}=0.200172; 
$mex{"190:74"}=-34.296326; 	$dmex{"190:74"}=0.164848; 
$mex{"161:75"}=-20.875601; 	$dmex{"161:75"}=0.208576; 
$mex{"163:75"}=-26.006814; 	$dmex{"163:75"}=0.019947; 
$mex{"165:75"}=-30.656812; 	$dmex{"165:75"}=0.027705; 
$mex{"168:75"}=-35.794885; 	$dmex{"168:75"}=0.030821; 
$mex{"169:75"}=-38.385847; 	$dmex{"169:75"}=0.028102; 
$mex{"170:75"}=-38.917754; 	$dmex{"170:75"}=0.025795; 
$mex{"171:75"}=-41.250281; 	$dmex{"171:75"}=0.027945; 
$mex{"172:75"}=-41.523244; 	$dmex{"172:75"}=0.053979; 
$mex{"173:75"}=-43.553865; 	$dmex{"173:75"}=0.027945; 
$mex{"174:75"}=-43.673097; 	$dmex{"174:75"}=0.027945; 
$mex{"175:75"}=-45.288307; 	$dmex{"175:75"}=0.027945; 
$mex{"176:75"}=-45.062886; 	$dmex{"176:75"}=0.027945; 
$mex{"177:75"}=-46.26917; 	$dmex{"177:75"}=0.027945; 
$mex{"178:75"}=-45.653453; 	$dmex{"178:75"}=0.027945; 
$mex{"179:75"}=-46.586212; 	$dmex{"179:75"}=0.024428; 
$mex{"180:75"}=-45.839673; 	$dmex{"180:75"}=0.021392; 
$mex{"181:75"}=-46.511436; 	$dmex{"181:75"}=0.012579; 
$mex{"182:75"}=-45.447518; 	$dmex{"182:75"}=0.101984; 
$mex{"183:75"}=-45.811023; 	$dmex{"183:75"}=0.008042; 
$mex{"184:75"}=-44.226631; 	$dmex{"184:75"}=0.004332; 
$mex{"185:75"}=-43.822152; 	$dmex{"185:75"}=0.001193; 
$mex{"186:75"}=-41.930192; 	$dmex{"186:75"}=0.001202; 
$mex{"187:75"}=-41.215714; 	$dmex{"187:75"}=0.001409; 
$mex{"188:75"}=-39.01615; 	$dmex{"188:75"}=0.001414; 
$mex{"189:75"}=-37.977935; 	$dmex{"189:75"}=0.008297; 
$mex{"190:75"}=-35.566326; 	$dmex{"190:75"}=0.149248; 
$mex{"191:75"}=-34.348616; 	$dmex{"191:75"}=0.010321; 
$mex{"164:76"}=-20.459661; 	$dmex{"164:76"}=0.208591; 
$mex{"166:76"}=-25.4384; 	$dmex{"166:76"}=0.018236; 
$mex{"167:76"}=-26.502896; 	$dmex{"167:76"}=0.072688; 
$mex{"168:76"}=-29.99068; 	$dmex{"168:76"}=0.012103; 
$mex{"169:76"}=-30.721352; 	$dmex{"169:76"}=0.025197; 
$mex{"170:76"}=-33.92778; 	$dmex{"170:76"}=0.0109; 
$mex{"171:76"}=-34.29312; 	$dmex{"171:76"}=0.018745; 
$mex{"172:76"}=-37.238053; 	$dmex{"172:76"}=0.014586; 
$mex{"173:76"}=-37.438225; 	$dmex{"173:76"}=0.014959; 
$mex{"174:76"}=-39.996301; 	$dmex{"174:76"}=0.011139; 
$mex{"175:76"}=-40.104697; 	$dmex{"175:76"}=0.013515; 
$mex{"176:76"}=-42.09794; 	$dmex{"176:76"}=0.027945; 
$mex{"177:76"}=-41.94953; 	$dmex{"177:76"}=0.015718; 
$mex{"178:76"}=-43.546189; 	$dmex{"178:76"}=0.016436; 
$mex{"179:76"}=-43.020103; 	$dmex{"179:76"}=0.018076; 
$mex{"180:76"}=-44.358859; 	$dmex{"180:76"}=0.020301; 
$mex{"181:76"}=-43.552934; 	$dmex{"181:76"}=0.031671; 
$mex{"182:76"}=-44.609074; 	$dmex{"182:76"}=0.021745; 
$mex{"183:76"}=-43.662754; 	$dmex{"183:76"}=0.049797; 
$mex{"184:76"}=-44.256145; 	$dmex{"184:76"}=0.001304; 
$mex{"185:76"}=-42.809355; 	$dmex{"185:76"}=0.001274; 
$mex{"186:76"}=-42.999479; 	$dmex{"186:76"}=0.00138; 
$mex{"187:76"}=-41.218183; 	$dmex{"187:76"}=0.001409; 
$mex{"188:76"}=-41.136426; 	$dmex{"188:76"}=0.001414; 
$mex{"189:76"}=-38.98538; 	$dmex{"189:76"}=0.001465; 
$mex{"190:76"}=-38.706326; 	$dmex{"190:76"}=0.001472; 
$mex{"191:76"}=-36.393733; 	$dmex{"191:76"}=0.001474; 
$mex{"192:76"}=-35.880506; 	$dmex{"192:76"}=0.002556; 
$mex{"193:76"}=-33.392604; 	$dmex{"193:76"}=0.002561; 
$mex{"194:76"}=-32.432681; 	$dmex{"194:76"}=0.002609; 
$mex{"195:76"}=-29.689824; 	$dmex{"195:76"}=0.500003; 
$mex{"196:76"}=-28.280779; 	$dmex{"196:76"}=0.040121; 
$mex{"167:77"}=-17.078797; 	$dmex{"167:77"}=0.018948; 
$mex{"169:77"}=-22.081119; 	$dmex{"169:77"}=0.026465; 
$mex{"171:77"}=-26.430172; 	$dmex{"171:77"}=0.039519; 
$mex{"173:77"}=-30.271935; 	$dmex{"173:77"}=0.013693; 
$mex{"174:77"}=-30.868738; 	$dmex{"174:77"}=0.027666; 
$mex{"175:77"}=-33.428622; 	$dmex{"175:77"}=0.019757; 
$mex{"176:77"}=-33.861029; 	$dmex{"176:77"}=0.02034; 
$mex{"177:77"}=-36.047421; 	$dmex{"177:77"}=0.01976; 
$mex{"178:77"}=-36.251884; 	$dmex{"178:77"}=0.01976; 
$mex{"179:77"}=-38.077364; 	$dmex{"179:77"}=0.010899; 
$mex{"180:77"}=-37.977526; 	$dmex{"180:77"}=0.021706; 
$mex{"181:77"}=-39.471782; 	$dmex{"181:77"}=0.025627; 
$mex{"182:77"}=-39.051679; 	$dmex{"182:77"}=0.020967; 
$mex{"183:77"}=-40.197266; 	$dmex{"183:77"}=0.025115; 
$mex{"184:77"}=-39.610851; 	$dmex{"184:77"}=0.027945; 
$mex{"185:77"}=-40.335554; 	$dmex{"185:77"}=0.027945; 
$mex{"186:77"}=-39.172952; 	$dmex{"186:77"}=0.016526; 
$mex{"187:77"}=-39.715774; 	$dmex{"187:77"}=0.006163; 
$mex{"188:77"}=-38.328071; 	$dmex{"188:77"}=0.006994; 
$mex{"189:77"}=-38.453064; 	$dmex{"189:77"}=0.012743; 
$mex{"190:77"}=-36.751194; 	$dmex{"190:77"}=0.001715; 
$mex{"191:77"}=-36.706409; 	$dmex{"191:77"}=0.001668; 
$mex{"192:77"}=-34.833207; 	$dmex{"192:77"}=0.001669; 
$mex{"193:77"}=-34.533808; 	$dmex{"193:77"}=0.001672; 
$mex{"194:77"}=-32.529281; 	$dmex{"194:77"}=0.001676; 
$mex{"195:77"}=-31.689824; 	$dmex{"195:77"}=0.001677; 
$mex{"196:77"}=-29.438431; 	$dmex{"196:77"}=0.038421; 
$mex{"197:77"}=-28.267783; 	$dmex{"197:77"}=0.020241; 
$mex{"199:77"}=-24.400873; 	$dmex{"199:77"}=0.041118; 
$mex{"168:78"}=-11.037512; 	$dmex{"168:78"}=0.208792; 
$mex{"170:78"}=-16.305533; 	$dmex{"170:78"}=0.018662; 
$mex{"171:78"}=-17.470596; 	$dmex{"171:78"}=0.088224; 
$mex{"172:78"}=-21.101014; 	$dmex{"172:78"}=0.012778; 
$mex{"173:78"}=-21.94157; 	$dmex{"173:78"}=0.05599; 
$mex{"174:78"}=-25.319155; 	$dmex{"174:78"}=0.011822; 
$mex{"175:78"}=-25.69009; 	$dmex{"175:78"}=0.018885; 
$mex{"176:78"}=-28.927898; 	$dmex{"176:78"}=0.014428; 
$mex{"177:78"}=-29.370489; 	$dmex{"177:78"}=0.014988; 
$mex{"178:78"}=-31.998007; 	$dmex{"178:78"}=0.010823; 
$mex{"179:78"}=-32.263781; 	$dmex{"179:78"}=0.009092; 
$mex{"180:78"}=-34.435958; 	$dmex{"180:78"}=0.010978; 
$mex{"181:78"}=-34.374658; 	$dmex{"181:78"}=0.014863; 
$mex{"182:78"}=-36.169301; 	$dmex{"182:78"}=0.01562; 
$mex{"183:78"}=-35.772441; 	$dmex{"183:78"}=0.015592; 
$mex{"184:78"}=-37.332183; 	$dmex{"184:78"}=0.018126; 
$mex{"185:78"}=-36.683166; 	$dmex{"185:78"}=0.040986; 
$mex{"186:78"}=-37.864474; 	$dmex{"186:78"}=0.021745; 
$mex{"187:78"}=-36.712973; 	$dmex{"187:78"}=0.027945; 
$mex{"188:78"}=-37.82295; 	$dmex{"188:78"}=0.005385; 
$mex{"189:78"}=-36.483186; 	$dmex{"189:78"}=0.011175; 
$mex{"190:78"}=-37.323422; 	$dmex{"190:78"}=0.005705; 
$mex{"191:78"}=-35.69796; 	$dmex{"191:78"}=0.004367; 
$mex{"192:78"}=-36.292864; 	$dmex{"192:78"}=0.00247; 
$mex{"193:78"}=-34.477014; 	$dmex{"193:78"}=0.001681; 
$mex{"194:78"}=-34.763121; 	$dmex{"194:78"}=0.000884; 
$mex{"195:78"}=-32.796847; 	$dmex{"195:78"}=0.000877; 
$mex{"196:78"}=-32.647448; 	$dmex{"196:78"}=0.000868; 
$mex{"197:78"}=-30.422425; 	$dmex{"197:78"}=0.00083; 
$mex{"198:78"}=-29.907673; 	$dmex{"198:78"}=0.003113; 
$mex{"199:78"}=-27.392356; 	$dmex{"199:78"}=0.003153; 
$mex{"200:78"}=-26.602838; 	$dmex{"200:78"}=0.020241; 
$mex{"201:78"}=-23.741111; 	$dmex{"201:78"}=0.050102; 
$mex{"171:79"}=-7.564773; 	$dmex{"171:79"}=0.025644; 
$mex{"173:79"}=-12.819798; 	$dmex{"173:79"}=0.026005; 
$mex{"175:79"}=-17.443057; 	$dmex{"175:79"}=0.042396; 
$mex{"177:79"}=-21.550199; 	$dmex{"177:79"}=0.012869; 
$mex{"178:79"}=-22.326122; 	$dmex{"178:79"}=0.057144; 
$mex{"179:79"}=-24.952104; 	$dmex{"179:79"}=0.016549; 
$mex{"180:79"}=-25.596408; 	$dmex{"180:79"}=0.021009; 
$mex{"181:79"}=-27.871187; 	$dmex{"181:79"}=0.019976; 
$mex{"182:79"}=-28.300768; 	$dmex{"182:79"}=0.02026; 
$mex{"183:79"}=-30.186894; 	$dmex{"183:79"}=0.010492; 
$mex{"184:79"}=-30.31871; 	$dmex{"184:79"}=0.022275; 
$mex{"185:79"}=-31.866958; 	$dmex{"185:79"}=0.026028; 
$mex{"186:79"}=-31.714853; 	$dmex{"186:79"}=0.020967; 
$mex{"187:79"}=-33.005122; 	$dmex{"187:79"}=0.025115; 
$mex{"188:79"}=-32.300802; 	$dmex{"188:79"}=0.020387; 
$mex{"189:79"}=-33.581955; 	$dmex{"189:79"}=0.020081; 
$mex{"190:79"}=-32.881422; 	$dmex{"190:79"}=0.016048; 
$mex{"191:79"}=-33.809297; 	$dmex{"191:79"}=0.037032; 
$mex{"192:79"}=-32.776523; 	$dmex{"192:79"}=0.015812; 
$mex{"193:79"}=-33.394325; 	$dmex{"193:79"}=0.010648; 
$mex{"194:79"}=-32.262062; 	$dmex{"194:79"}=0.010203; 
$mex{"195:79"}=-32.570023; 	$dmex{"195:79"}=0.001329; 
$mex{"196:79"}=-31.140018; 	$dmex{"196:79"}=0.002972; 
$mex{"197:79"}=-31.141091; 	$dmex{"197:79"}=0.000602; 
$mex{"198:79"}=-29.582104; 	$dmex{"198:79"}=0.000596; 
$mex{"199:79"}=-29.095035; 	$dmex{"199:79"}=0.000604; 
$mex{"200:79"}=-27.268884; 	$dmex{"200:79"}=0.049748; 
$mex{"201:79"}=-26.401111; 	$dmex{"201:79"}=0.003193; 
$mex{"202:79"}=-24.399705; 	$dmex{"202:79"}=0.166411; 
$mex{"203:79"}=-23.143394; 	$dmex{"203:79"}=0.003058; 
$mex{"172:80"}=-1.087345; 	$dmex{"172:80"}=0.209154; 
$mex{"174:80"}=-6.647425; 	$dmex{"174:80"}=0.019606; 
$mex{"175:80"}=-7.989172; 	$dmex{"175:80"}=0.101408; 
$mex{"176:80"}=-11.779132; 	$dmex{"176:80"}=0.014176; 
$mex{"177:80"}=-12.780882; 	$dmex{"177:80"}=0.075066; 
$mex{"178:80"}=-16.316846; 	$dmex{"178:80"}=0.012878; 
$mex{"179:80"}=-16.921649; 	$dmex{"179:80"}=0.027308; 
$mex{"180:80"}=-20.244723; 	$dmex{"180:80"}=0.013968; 
$mex{"181:80"}=-20.661178; 	$dmex{"181:80"}=0.015383; 
$mex{"182:80"}=-23.576146; 	$dmex{"182:80"}=0.009715; 
$mex{"183:80"}=-23.799819; 	$dmex{"183:80"}=0.0082; 
$mex{"184:80"}=-26.349123; 	$dmex{"184:80"}=0.010065; 
$mex{"185:80"}=-26.175833; 	$dmex{"185:80"}=0.015536; 
$mex{"186:80"}=-28.539309; 	$dmex{"186:80"}=0.011247; 
$mex{"187:80"}=-28.117858; 	$dmex{"187:80"}=0.013924; 
$mex{"188:80"}=-30.201784; 	$dmex{"188:80"}=0.011532; 
$mex{"189:80"}=-29.630792; 	$dmex{"189:80"}=0.033413; 
$mex{"190:80"}=-31.370436; 	$dmex{"190:80"}=0.015919; 
$mex{"191:80"}=-30.59296; 	$dmex{"191:80"}=0.02259; 
$mex{"192:80"}=-32.011418; 	$dmex{"192:80"}=0.015551; 
$mex{"193:80"}=-31.050961; 	$dmex{"193:80"}=0.015378; 
$mex{"194:80"}=-32.192983; 	$dmex{"194:80"}=0.012535; 
$mex{"195:80"}=-31.000015; 	$dmex{"195:80"}=0.023145; 
$mex{"196:80"}=-31.826683; 	$dmex{"196:80"}=0.002942; 
$mex{"197:80"}=-30.540979; 	$dmex{"197:80"}=0.003203; 
$mex{"198:80"}=-30.954447; 	$dmex{"198:80"}=0.000337; 
$mex{"199:80"}=-29.547053; 	$dmex{"199:80"}=0.000365; 
$mex{"200:80"}=-29.504137; 	$dmex{"200:80"}=0.000379; 
$mex{"201:80"}=-27.663259; 	$dmex{"201:80"}=0.000595; 
$mex{"202:80"}=-27.345859; 	$dmex{"202:80"}=0.000591; 
$mex{"203:80"}=-25.269119; 	$dmex{"203:80"}=0.001689; 
$mex{"204:80"}=-24.690242; 	$dmex{"204:80"}=0.000339; 
$mex{"205:80"}=-22.287497; 	$dmex{"205:80"}=0.003644; 
$mex{"206:80"}=-20.945512; 	$dmex{"206:80"}=0.020446; 
$mex{"207:80"}=-16.218666; 	$dmex{"207:80"}=0.150101; 
$mex{"177:81"}=-3.327962; 	$dmex{"177:81"}=0.024999; 
$mex{"179:81"}=-8.300467; 	$dmex{"179:81"}=0.04318; 
$mex{"181:81"}=-12.801105; 	$dmex{"181:81"}=0.009357; 
$mex{"182:81"}=-13.351007; 	$dmex{"182:81"}=0.07593; 
$mex{"183:81"}=-16.587297; 	$dmex{"183:81"}=0.009749; 
$mex{"184:81"}=-16.885078; 	$dmex{"184:81"}=0.049317; 
$mex{"185:81"}=-19.755772; 	$dmex{"185:81"}=0.05388; 
$mex{"186:81"}=-20.190133; 	$dmex{"186:81"}=0.184436; 
$mex{"187:81"}=-22.443512; 	$dmex{"187:81"}=0.008107; 
$mex{"188:81"}=-22.346744; 	$dmex{"188:81"}=0.032609; 
$mex{"189:81"}=-24.602221; 	$dmex{"189:81"}=0.010891; 
$mex{"190:81"}=-24.333279; 	$dmex{"190:81"}=0.049436; 
$mex{"191:81"}=-26.281028; 	$dmex{"191:81"}=0.007569; 
$mex{"192:81"}=-25.872246; 	$dmex{"192:81"}=0.031671; 
$mex{"193:81"}=-27.318856; 	$dmex{"193:81"}=0.110848; 
$mex{"194:81"}=-26.827027; 	$dmex{"194:81"}=0.135067; 
$mex{"195:81"}=-28.155026; 	$dmex{"195:81"}=0.013796; 
$mex{"196:81"}=-27.496631; 	$dmex{"196:81"}=0.012109; 
$mex{"197:81"}=-28.34116; 	$dmex{"197:81"}=0.016304; 
$mex{"198:81"}=-27.494447; 	$dmex{"198:81"}=0.080001; 
$mex{"199:81"}=-28.059394; 	$dmex{"199:81"}=0.027945; 
$mex{"200:81"}=-27.048096; 	$dmex{"200:81"}=0.005747; 
$mex{"201:81"}=-27.182028; 	$dmex{"201:81"}=0.015054; 
$mex{"202:81"}=-25.983272; 	$dmex{"202:81"}=0.014755; 
$mex{"203:81"}=-25.761192; 	$dmex{"203:81"}=0.001272; 
$mex{"204:81"}=-24.345972; 	$dmex{"204:81"}=0.001251; 
$mex{"205:81"}=-23.820592; 	$dmex{"205:81"}=0.001325; 
$mex{"206:81"}=-22.253094; 	$dmex{"206:81"}=0.00137; 
$mex{"207:81"}=-21.033666; 	$dmex{"207:81"}=0.005497; 
$mex{"208:81"}=-16.749473; 	$dmex{"208:81"}=0.00199; 
$mex{"209:81"}=-13.638048; 	$dmex{"209:81"}=0.007901; 
$mex{"210:81"}=-9.246298; 	$dmex{"210:81"}=0.011638; 
$mex{"178:82"}=3.5678; 	$dmex{"178:82"}=0.02428; 
$mex{"180:82"}=-1.939209; 	$dmex{"180:82"}=0.020888; 
$mex{"181:82"}=-3.144762; 	$dmex{"181:82"}=0.090194; 
$mex{"182:82"}=-6.826135; 	$dmex{"182:82"}=0.014007; 
$mex{"183:82"}=-7.568734; 	$dmex{"183:82"}=0.028191; 
$mex{"184:82"}=-11.045339; 	$dmex{"184:82"}=0.014297; 
$mex{"185:82"}=-11.541263; 	$dmex{"185:82"}=0.016175; 
$mex{"186:82"}=-14.681328; 	$dmex{"186:82"}=0.011298; 
$mex{"187:82"}=-14.979941; 	$dmex{"187:82"}=0.008286; 
$mex{"188:82"}=-17.815439; 	$dmex{"188:82"}=0.010626; 
$mex{"189:82"}=-17.878165; 	$dmex{"189:82"}=0.034465; 
$mex{"190:82"}=-20.416935; 	$dmex{"190:82"}=0.012139; 
$mex{"191:82"}=-20.246022; 	$dmex{"191:82"}=0.039123; 
$mex{"192:82"}=-22.555968; 	$dmex{"192:82"}=0.012612; 
$mex{"193:82"}=-22.19449; 	$dmex{"193:82"}=0.049577; 
$mex{"194:82"}=-24.2076; 	$dmex{"194:82"}=0.017466; 
$mex{"195:82"}=-23.713927; 	$dmex{"195:82"}=0.023367; 
$mex{"196:82"}=-25.360754; 	$dmex{"196:82"}=0.014279; 
$mex{"197:82"}=-24.748749; 	$dmex{"197:82"}=0.00559; 
$mex{"198:82"}=-26.050199; 	$dmex{"198:82"}=0.014578; 
$mex{"199:82"}=-25.227978; 	$dmex{"199:82"}=0.026423; 
$mex{"200:82"}=-26.243283; 	$dmex{"200:82"}=0.010938; 
$mex{"201:82"}=-25.257915; 	$dmex{"201:82"}=0.022355; 
$mex{"202:82"}=-25.9336; 	$dmex{"202:82"}=0.008178; 
$mex{"203:82"}=-24.78657; 	$dmex{"203:82"}=0.006528; 
$mex{"204:82"}=-25.109735; 	$dmex{"204:82"}=0.001244; 
$mex{"205:82"}=-23.770091; 	$dmex{"205:82"}=0.001241; 
$mex{"206:82"}=-23.78544; 	$dmex{"206:82"}=0.00124; 
$mex{"207:82"}=-22.451905; 	$dmex{"207:82"}=0.001243; 
$mex{"208:82"}=-21.748455; 	$dmex{"208:82"}=0.001244; 
$mex{"209:82"}=-17.61444; 	$dmex{"209:82"}=0.001813; 
$mex{"210:82"}=-14.728292; 	$dmex{"210:82"}=0.001527; 
$mex{"211:82"}=-10.49145; 	$dmex{"211:82"}=0.002661; 
$mex{"212:82"}=-7.547389; 	$dmex{"212:82"}=0.002209; 
$mex{"213:82"}=-3.184313; 	$dmex{"213:82"}=0.007796; 
$mex{"214:82"}=-0.181261; 	$dmex{"214:82"}=0.002381; 
$mex{"186:83"}=-3.169291; 	$dmex{"186:83"}=0.076873; 
$mex{"187:83"}=-6.373435; 	$dmex{"187:83"}=0.015354; 
$mex{"188:83"}=-7.204962; 	$dmex{"188:83"}=0.049812; 
$mex{"189:83"}=-10.061055; 	$dmex{"189:83"}=0.053953; 
$mex{"190:83"}=-10.903017; 	$dmex{"190:83"}=0.184504; 
$mex{"191:83"}=-13.240145; 	$dmex{"191:83"}=0.00743; 
$mex{"192:83"}=-13.545828; 	$dmex{"192:83"}=0.03299; 
$mex{"193:83"}=-15.872871; 	$dmex{"193:83"}=0.00962; 
$mex{"194:83"}=-15.990063; 	$dmex{"194:83"}=0.049183; 
$mex{"195:83"}=-18.023722; 	$dmex{"195:83"}=0.005589; 
$mex{"196:83"}=-18.009031; 	$dmex{"196:83"}=0.024428; 
$mex{"197:83"}=-19.687634; 	$dmex{"197:83"}=0.008439; 
$mex{"198:83"}=-19.369486; 	$dmex{"198:83"}=0.027945; 
$mex{"199:83"}=-20.798434; 	$dmex{"199:83"}=0.011847; 
$mex{"200:83"}=-20.37007; 	$dmex{"200:83"}=0.024027; 
$mex{"201:83"}=-21.415944; 	$dmex{"201:83"}=0.01516; 
$mex{"202:83"}=-20.732892; 	$dmex{"202:83"}=0.020387; 
$mex{"203:83"}=-21.539866; 	$dmex{"203:83"}=0.021633; 
$mex{"204:83"}=-20.667303; 	$dmex{"204:83"}=0.025953; 
$mex{"205:83"}=-21.06167; 	$dmex{"205:83"}=0.007179; 
$mex{"206:83"}=-20.027931; 	$dmex{"206:83"}=0.007782; 
$mex{"207:83"}=-20.054433; 	$dmex{"207:83"}=0.002445; 
$mex{"208:83"}=-18.870022; 	$dmex{"208:83"}=0.002355; 
$mex{"209:83"}=-18.258461; 	$dmex{"209:83"}=0.001448; 
$mex{"210:83"}=-14.791778; 	$dmex{"210:83"}=0.001446; 
$mex{"211:83"}=-11.858421; 	$dmex{"211:83"}=0.0055; 
$mex{"212:83"}=-8.117295; 	$dmex{"212:83"}=0.00199; 
$mex{"213:83"}=-5.230649; 	$dmex{"213:83"}=0.005003; 
$mex{"214:83"}=-1.200193; 	$dmex{"214:83"}=0.011229; 
$mex{"215:83"}=1.648537; 	$dmex{"215:83"}=0.014904; 
$mex{"216:83"}=5.873948; 	$dmex{"216:83"}=0.011178; 
$mex{"188:84"}=-0.538359; 	$dmex{"188:84"}=0.019419; 
$mex{"189:84"}=-1.415347; 	$dmex{"189:84"}=0.02206; 
$mex{"190:84"}=-4.563217; 	$dmex{"190:84"}=0.01341; 
$mex{"191:84"}=-5.053834; 	$dmex{"191:84"}=0.011004; 
$mex{"192:84"}=-8.071257; 	$dmex{"192:84"}=0.01191; 
$mex{"193:84"}=-8.359902; 	$dmex{"193:84"}=0.034688; 
$mex{"194:84"}=-11.005037; 	$dmex{"194:84"}=0.012569; 
$mex{"195:84"}=-11.074785; 	$dmex{"195:84"}=0.039279; 
$mex{"196:84"}=-13.474451; 	$dmex{"196:84"}=0.012978; 
$mex{"197:84"}=-13.357968; 	$dmex{"197:84"}=0.049745; 
$mex{"198:84"}=-15.473405; 	$dmex{"198:84"}=0.01744; 
$mex{"199:84"}=-15.214964; 	$dmex{"199:84"}=0.023456; 
$mex{"200:84"}=-16.954491; 	$dmex{"200:84"}=0.014417; 
$mex{"201:84"}=-16.524923; 	$dmex{"201:84"}=0.005848; 
$mex{"202:84"}=-17.924235; 	$dmex{"202:84"}=0.014677; 
$mex{"203:84"}=-17.307062; 	$dmex{"203:84"}=0.025946; 
$mex{"204:84"}=-18.333551; 	$dmex{"204:84"}=0.011023; 
$mex{"205:84"}=-17.508993; 	$dmex{"205:84"}=0.019892; 
$mex{"206:84"}=-18.181739; 	$dmex{"206:84"}=0.008281; 
$mex{"207:84"}=-17.145849; 	$dmex{"207:84"}=0.006638; 
$mex{"208:84"}=-17.469516; 	$dmex{"208:84"}=0.001802; 
$mex{"209:84"}=-16.365944; 	$dmex{"209:84"}=0.001842; 
$mex{"210:84"}=-15.953071; 	$dmex{"210:84"}=0.001242; 
$mex{"211:84"}=-12.432507; 	$dmex{"211:84"}=0.001343; 
$mex{"212:84"}=-10.36942; 	$dmex{"212:84"}=0.001248; 
$mex{"213:84"}=-6.6534; 	$dmex{"213:84"}=0.003092; 
$mex{"214:84"}=-4.469913; 	$dmex{"214:84"}=0.001528; 
$mex{"215:84"}=-0.540277; 	$dmex{"215:84"}=0.002547; 
$mex{"216:84"}=1.783844; 	$dmex{"216:84"}=0.002203; 
$mex{"217:84"}=5.900825; 	$dmex{"217:84"}=0.006646; 
$mex{"218:84"}=8.358331; 	$dmex{"218:84"}=0.002379; 
$mex{"193:85"}=-0.14614; 	$dmex{"193:85"}=0.054286; 
$mex{"194:85"}=-1.187575; 	$dmex{"194:85"}=0.18563; 
$mex{"195:85"}=-3.476244; 	$dmex{"195:85"}=0.009056; 
$mex{"196:85"}=-3.92338; 	$dmex{"196:85"}=0.059903; 
$mex{"197:85"}=-6.344205; 	$dmex{"197:85"}=0.050917; 
$mex{"198:85"}=-6.672103; 	$dmex{"198:85"}=0.049234; 
$mex{"199:85"}=-8.819148; 	$dmex{"199:85"}=0.050311; 
$mex{"200:85"}=-8.987739; 	$dmex{"200:85"}=0.024468; 
$mex{"201:85"}=-10.789496; 	$dmex{"201:85"}=0.008284; 
$mex{"202:85"}=-10.590867; 	$dmex{"202:85"}=0.027978; 
$mex{"203:85"}=-12.163464; 	$dmex{"203:85"}=0.011817; 
$mex{"204:85"}=-11.875313; 	$dmex{"204:85"}=0.023979; 
$mex{"205:85"}=-12.971536; 	$dmex{"205:85"}=0.015062; 
$mex{"206:85"}=-12.419576; 	$dmex{"206:85"}=0.020471; 
$mex{"207:85"}=-13.242582; 	$dmex{"207:85"}=0.021495; 
$mex{"208:85"}=-12.491356; 	$dmex{"208:85"}=0.025863; 
$mex{"209:85"}=-12.879634; 	$dmex{"209:85"}=0.007463; 
$mex{"210:85"}=-11.97183; 	$dmex{"210:85"}=0.007843; 
$mex{"211:85"}=-11.647148; 	$dmex{"211:85"}=0.002771; 
$mex{"212:85"}=-8.62119; 	$dmex{"212:85"}=0.007214; 
$mex{"213:85"}=-6.579472; 	$dmex{"213:85"}=0.004922; 
$mex{"214:85"}=-3.379708; 	$dmex{"214:85"}=0.004325; 
$mex{"215:85"}=-1.255123; 	$dmex{"215:85"}=0.006846; 
$mex{"216:85"}=2.25725; 	$dmex{"216:85"}=0.003647; 
$mex{"217:85"}=4.395555; 	$dmex{"217:85"}=0.004917; 
$mex{"218:85"}=8.098722; 	$dmex{"218:85"}=0.011623; 
$mex{"219:85"}=10.397048; 	$dmex{"219:85"}=0.003883; 
$mex{"220:85"}=14.352164; 	$dmex{"220:85"}=0.051234; 
$mex{"195:86"}=5.065181; 	$dmex{"195:86"}=0.051197; 
$mex{"196:86"}=1.970318; 	$dmex{"196:86"}=0.015042; 
$mex{"197:86"}=1.475814; 	$dmex{"197:86"}=0.060854; 
$mex{"198:86"}=-1.230817; 	$dmex{"198:86"}=0.013091; 
$mex{"199:86"}=-1.518058; 	$dmex{"199:86"}=0.063583; 
$mex{"200:86"}=-4.006076; 	$dmex{"200:86"}=0.013226; 
$mex{"201:86"}=-4.072179; 	$dmex{"201:86"}=0.070531; 
$mex{"202:86"}=-6.275017; 	$dmex{"202:86"}=0.017543; 
$mex{"203:86"}=-6.160261; 	$dmex{"203:86"}=0.023567; 
$mex{"204:86"}=-7.984077; 	$dmex{"204:86"}=0.01454; 
$mex{"205:86"}=-7.713889; 	$dmex{"205:86"}=0.050341; 
$mex{"206:86"}=-9.115503; 	$dmex{"206:86"}=0.014769; 
$mex{"207:86"}=-8.631014; 	$dmex{"207:86"}=0.025998; 
$mex{"208:86"}=-9.647976; 	$dmex{"208:86"}=0.011149; 
$mex{"209:86"}=-8.92861; 	$dmex{"209:86"}=0.019988; 
$mex{"210:86"}=-9.597913; 	$dmex{"210:86"}=0.008558; 
$mex{"211:86"}=-8.755556; 	$dmex{"211:86"}=0.006793; 
$mex{"212:86"}=-8.659606; 	$dmex{"212:86"}=0.003182; 
$mex{"213:86"}=-5.698258; 	$dmex{"213:86"}=0.005678; 
$mex{"214:86"}=-4.319753; 	$dmex{"214:86"}=0.009199; 
$mex{"215:86"}=-1.168574; 	$dmex{"215:86"}=0.007687; 
$mex{"216:86"}=0.255574; 	$dmex{"216:86"}=0.007312; 
$mex{"217:86"}=3.658607; 	$dmex{"217:86"}=0.004226; 
$mex{"218:86"}=5.217537; 	$dmex{"218:86"}=0.002373; 
$mex{"219:86"}=8.830754; 	$dmex{"219:86"}=0.002531; 
$mex{"220:86"}=10.613426; 	$dmex{"220:86"}=0.002203; 
$mex{"221:86"}=14.47242; 	$dmex{"221:86"}=0.005902; 
$mex{"222:86"}=16.373558; 	$dmex{"222:86"}=0.00236; 
$mex{"199:87"}=6.760921; 	$dmex{"199:87"}=0.041814; 
$mex{"200:87"}=6.122235; 	$dmex{"200:87"}=0.078028; 
$mex{"201:87"}=3.596375; 	$dmex{"201:87"}=0.071362; 
$mex{"202:87"}=3.141787; 	$dmex{"202:87"}=0.049491; 
$mex{"203:87"}=0.861303; 	$dmex{"203:87"}=0.015835; 
$mex{"204:87"}=0.608456; 	$dmex{"204:87"}=0.024593; 
$mex{"205:87"}=-1.309717; 	$dmex{"205:87"}=0.007824; 
$mex{"206:87"}=-1.242551; 	$dmex{"206:87"}=0.028196; 
$mex{"207:87"}=-2.841602; 	$dmex{"207:87"}=0.050707; 
$mex{"208:87"}=-2.665206; 	$dmex{"208:87"}=0.046535; 
$mex{"209:87"}=-3.769239; 	$dmex{"209:87"}=0.014625; 
$mex{"210:87"}=-3.34617; 	$dmex{"210:87"}=0.022232; 
$mex{"211:87"}=-4.157682; 	$dmex{"211:87"}=0.021101; 
$mex{"212:87"}=-3.537587; 	$dmex{"212:87"}=0.025803; 
$mex{"213:87"}=-3.549848; 	$dmex{"213:87"}=0.007671; 
$mex{"214:87"}=-0.958372; 	$dmex{"214:87"}=0.008766; 
$mex{"215:87"}=0.318103; 	$dmex{"215:87"}=0.007082; 
$mex{"216:87"}=2.978909; 	$dmex{"216:87"}=0.014196; 
$mex{"217:87"}=4.314635; 	$dmex{"217:87"}=0.006548; 
$mex{"218:87"}=7.059162; 	$dmex{"218:87"}=0.004781; 
$mex{"219:87"}=8.618322; 	$dmex{"219:87"}=0.007084; 
$mex{"220:87"}=11.482904; 	$dmex{"220:87"}=0.004093; 
$mex{"221:87"}=13.278226; 	$dmex{"221:87"}=0.004796; 
$mex{"222:87"}=16.349332; 	$dmex{"222:87"}=0.021223; 
$mex{"223:87"}=18.383833; 	$dmex{"223:87"}=0.002397; 
$mex{"224:87"}=21.65719; 	$dmex{"224:87"}=0.050048; 
$mex{"225:87"}=23.814031; 	$dmex{"225:87"}=0.030148; 
$mex{"226:87"}=27.373099; 	$dmex{"226:87"}=0.100028; 
$mex{"227:87"}=29.654986; 	$dmex{"227:87"}=0.100028; 
$mex{"229:87"}=35.816157; 	$dmex{"229:87"}=0.03726; 
$mex{"202:88"}=9.213115; 	$dmex{"202:88"}=0.062598; 
$mex{"203:88"}=8.636458; 	$dmex{"203:88"}=0.080888; 
$mex{"204:88"}=6.054402; 	$dmex{"204:88"}=0.015373; 
$mex{"205:88"}=5.839136; 	$dmex{"205:88"}=0.086456; 
$mex{"206:88"}=3.565079; 	$dmex{"206:88"}=0.01803; 
$mex{"207:88"}=3.537912; 	$dmex{"207:88"}=0.055276; 
$mex{"208:88"}=1.713894; 	$dmex{"208:88"}=0.015408; 
$mex{"209:88"}=1.854952; 	$dmex{"209:88"}=0.050467; 
$mex{"210:88"}=0.461069; 	$dmex{"210:88"}=0.015195; 
$mex{"211:88"}=0.83647; 	$dmex{"211:88"}=0.026242; 
$mex{"212:88"}=-0.191422; 	$dmex{"212:88"}=0.011273; 
$mex{"213:88"}=0.357656; 	$dmex{"213:88"}=0.020299; 
$mex{"214:88"}=0.100503; 	$dmex{"214:88"}=0.009205; 
$mex{"215:88"}=2.533509; 	$dmex{"215:88"}=0.007594; 
$mex{"216:88"}=3.291002; 	$dmex{"216:88"}=0.00875; 
$mex{"217:88"}=5.887347; 	$dmex{"217:88"}=0.008529; 
$mex{"218:88"}=6.651082; 	$dmex{"218:88"}=0.011186; 
$mex{"219:88"}=9.39419; 	$dmex{"219:88"}=0.008272; 
$mex{"220:88"}=10.272874; 	$dmex{"220:88"}=0.009241; 
$mex{"221:88"}=12.963917; 	$dmex{"221:88"}=0.004656; 
$mex{"222:88"}=14.321283; 	$dmex{"222:88"}=0.004571; 
$mex{"223:88"}=17.234662; 	$dmex{"223:88"}=0.002523; 
$mex{"224:88"}=18.82719; 	$dmex{"224:88"}=0.002203; 
$mex{"225:88"}=21.994031; 	$dmex{"225:88"}=0.002986; 
$mex{"226:88"}=23.669099; 	$dmex{"226:88"}=0.002346; 
$mex{"227:88"}=27.178986; 	$dmex{"227:88"}=0.002362; 
$mex{"228:88"}=28.941792; 	$dmex{"228:88"}=0.002434; 
$mex{"229:88"}=32.562774; 	$dmex{"229:88"}=0.018709; 
$mex{"230:88"}=34.517809; 	$dmex{"230:88"}=0.012109; 
$mex{"206:89"}=13.511303; 	$dmex{"206:89"}=0.070352; 
$mex{"207:89"}=11.131119; 	$dmex{"207:89"}=0.052448; 
$mex{"208:89"}=10.760201; 	$dmex{"208:89"}=0.055721; 
$mex{"209:89"}=8.844409; 	$dmex{"209:89"}=0.050608; 
$mex{"210:89"}=8.789565; 	$dmex{"210:89"}=0.057402; 
$mex{"211:89"}=7.204953; 	$dmex{"211:89"}=0.071212; 
$mex{"212:89"}=7.278529; 	$dmex{"212:89"}=0.068305; 
$mex{"213:89"}=6.15498; 	$dmex{"213:89"}=0.052095; 
$mex{"214:89"}=6.428984; 	$dmex{"214:89"}=0.02249; 
$mex{"215:89"}=6.011514; 	$dmex{"215:89"}=0.021406; 
$mex{"216:89"}=8.122698; 	$dmex{"216:89"}=0.026577; 
$mex{"217:89"}=8.706595; 	$dmex{"217:89"}=0.012753; 
$mex{"218:89"}=10.843944; 	$dmex{"218:89"}=0.050763; 
$mex{"219:89"}=11.569518; 	$dmex{"219:89"}=0.050499; 
$mex{"220:89"}=13.751627; 	$dmex{"220:89"}=0.014889; 
$mex{"221:89"}=14.523155; 	$dmex{"221:89"}=0.050427; 
$mex{"222:89"}=16.621441; 	$dmex{"222:89"}=0.005197; 
$mex{"223:89"}=17.826437; 	$dmex{"223:89"}=0.007154; 
$mex{"224:89"}=20.23472; 	$dmex{"224:89"}=0.004152; 
$mex{"225:89"}=21.63822; 	$dmex{"225:89"}=0.00466; 
$mex{"226:89"}=24.310214; 	$dmex{"226:89"}=0.003333; 
$mex{"227:89"}=25.850941; 	$dmex{"227:89"}=0.002393; 
$mex{"228:89"}=28.895981; 	$dmex{"228:89"}=0.002523; 
$mex{"229:89"}=30.753502; 	$dmex{"229:89"}=0.033276; 
$mex{"230:89"}=33.807809; 	$dmex{"230:89"}=0.300244; 
$mex{"231:89"}=35.917278; 	$dmex{"231:89"}=0.100016; 
$mex{"232:89"}=39.148307; 	$dmex{"232:89"}=0.10002; 
$mex{"209:90"}=16.502052; 	$dmex{"209:90"}=0.099873; 
$mex{"210:90"}=14.042591; 	$dmex{"210:90"}=0.025008; 
$mex{"211:90"}=13.905728; 	$dmex{"211:90"}=0.074534; 
$mex{"212:90"}=12.091061; 	$dmex{"212:90"}=0.018474; 
$mex{"213:90"}=12.118868; 	$dmex{"213:90"}=0.071042; 
$mex{"214:90"}=10.711967; 	$dmex{"214:90"}=0.016817; 
$mex{"215:90"}=10.926733; 	$dmex{"215:90"}=0.026889; 
$mex{"216:90"}=10.304294; 	$dmex{"216:90"}=0.012923; 
$mex{"217:90"}=12.215918; 	$dmex{"217:90"}=0.020789; 
$mex{"218:90"}=12.374432; 	$dmex{"218:90"}=0.012952; 
$mex{"219:90"}=14.472525; 	$dmex{"219:90"}=0.050573; 
$mex{"220:90"}=14.668946; 	$dmex{"220:90"}=0.022171; 
$mex{"221:90"}=16.937984; 	$dmex{"221:90"}=0.009357; 
$mex{"222:90"}=17.202945; 	$dmex{"222:90"}=0.012288; 
$mex{"223:90"}=19.385739; 	$dmex{"223:90"}=0.009225; 
$mex{"224:90"}=19.996285; 	$dmex{"224:90"}=0.010952; 
$mex{"225:90"}=22.310233; 	$dmex{"225:90"}=0.005116; 
$mex{"226:90"}=23.19706; 	$dmex{"226:90"}=0.004707; 
$mex{"227:90"}=25.806176; 	$dmex{"227:90"}=0.002521; 
$mex{"228:90"}=26.772188; 	$dmex{"228:90"}=0.002201; 
$mex{"229:90"}=29.586514; 	$dmex{"229:90"}=0.002821; 
$mex{"230:90"}=30.863976; 	$dmex{"230:90"}=0.001792; 
$mex{"231:90"}=33.817278; 	$dmex{"231:90"}=0.0018; 
$mex{"232:90"}=35.448307; 	$dmex{"232:90"}=0.001991; 
$mex{"233:90"}=38.733238; 	$dmex{"233:90"}=0.001993; 
$mex{"234:90"}=40.614285; 	$dmex{"234:90"}=0.0035; 
$mex{"235:90"}=44.25535; 	$dmex{"235:90"}=0.050036; 
$mex{"212:91"}=21.614516; 	$dmex{"212:91"}=0.074865; 
$mex{"213:91"}=19.663224; 	$dmex{"213:91"}=0.071142; 
$mex{"214:91"}=19.48538; 	$dmex{"214:91"}=0.076125; 
$mex{"215:91"}=17.871519; 	$dmex{"215:91"}=0.087012; 
$mex{"216:91"}=17.800445; 	$dmex{"216:91"}=0.069932; 
$mex{"217:91"}=17.068683; 	$dmex{"217:91"}=0.052288; 
$mex{"218:91"}=18.6689; 	$dmex{"218:91"}=0.024613; 
$mex{"219:91"}=18.521029; 	$dmex{"219:91"}=0.05439; 
$mex{"220:91"}=20.376714; 	$dmex{"220:91"}=0.056624; 
$mex{"221:91"}=20.379211; 	$dmex{"221:91"}=0.051601; 
$mex{"223:91"}=22.320714; 	$dmex{"223:91"}=0.071064; 
$mex{"224:91"}=23.870222; 	$dmex{"224:91"}=0.015546; 
$mex{"225:91"}=24.34057; 	$dmex{"225:91"}=0.071013; 
$mex{"226:91"}=26.033165; 	$dmex{"226:91"}=0.01143; 
$mex{"227:91"}=26.831753; 	$dmex{"227:91"}=0.007462; 
$mex{"228:91"}=28.924171; 	$dmex{"228:91"}=0.0044; 
$mex{"229:91"}=29.897971; 	$dmex{"229:91"}=0.002749; 
$mex{"230:91"}=32.174506; 	$dmex{"230:91"}=0.003277; 
$mex{"231:91"}=33.425722; 	$dmex{"231:91"}=0.002257; 
$mex{"232:91"}=35.947837; 	$dmex{"232:91"}=0.007748; 
$mex{"233:91"}=37.490098; 	$dmex{"233:91"}=0.002161; 
$mex{"234:91"}=40.341197; 	$dmex{"234:91"}=0.004723; 
$mex{"235:91"}=42.330456; 	$dmex{"235:91"}=0.050033; 
$mex{"236:91"}=45.346325; 	$dmex{"236:91"}=0.200008; 
$mex{"237:91"}=47.641875; 	$dmex{"237:91"}=0.100018; 
$mex{"238:91"}=50.768948; 	$dmex{"238:91"}=0.06003; 
$mex{"217:92"}=22.699383; 	$dmex{"217:92"}=0.086873; 
$mex{"218:92"}=21.923337; 	$dmex{"218:92"}=0.030519; 
$mex{"219:92"}=23.212048; 	$dmex{"219:92"}=0.056771; 
$mex{"223:92"}=25.83834; 	$dmex{"223:92"}=0.071117; 
$mex{"224:92"}=25.713685; 	$dmex{"224:92"}=0.025315; 
$mex{"225:92"}=27.377277; 	$dmex{"225:92"}=0.011577; 
$mex{"226:92"}=27.328826; 	$dmex{"226:92"}=0.01304; 
$mex{"227:92"}=29.02197; 	$dmex{"227:92"}=0.016864; 
$mex{"228:92"}=29.224699; 	$dmex{"228:92"}=0.014952; 
$mex{"229:92"}=31.210582; 	$dmex{"229:92"}=0.005958; 
$mex{"230:92"}=31.614706; 	$dmex{"230:92"}=0.004761; 
$mex{"231:92"}=33.807368; 	$dmex{"231:92"}=0.003021; 
$mex{"232:92"}=34.610734; 	$dmex{"232:92"}=0.002203; 
$mex{"233:92"}=36.919958; 	$dmex{"233:92"}=0.002705; 
$mex{"234:92"}=38.146625; 	$dmex{"234:92"}=0.001827; 
$mex{"235:92"}=40.920456; 	$dmex{"235:92"}=0.001823; 
$mex{"236:92"}=42.446325; 	$dmex{"236:92"}=0.001826; 
$mex{"237:92"}=45.391875; 	$dmex{"237:92"}=0.001882; 
$mex{"238:92"}=47.308948; 	$dmex{"238:92"}=0.001904; 
$mex{"239:92"}=50.573883; 	$dmex{"239:92"}=0.001912; 
$mex{"240:92"}=52.715098; 	$dmex{"240:92"}=0.005154; 
$mex{"225:93"}=31.590626; 	$dmex{"225:93"}=0.071851; 
$mex{"227:93"}=32.56204; 	$dmex{"227:93"}=0.072508; 
$mex{"229:93"}=33.779521; 	$dmex{"229:93"}=0.08685; 
$mex{"230:93"}=35.236181; 	$dmex{"230:93"}=0.05129; 
$mex{"231:93"}=35.625068; 	$dmex{"231:93"}=0.050554; 
$mex{"233:93"}=37.949575; 	$dmex{"233:93"}=0.050948; 
$mex{"234:93"}=39.956471; 	$dmex{"234:93"}=0.008519; 
$mex{"235:93"}=41.044669; 	$dmex{"235:93"}=0.001994; 
$mex{"236:93"}=43.379304; 	$dmex{"236:93"}=0.050437; 
$mex{"237:93"}=44.873275; 	$dmex{"237:93"}=0.001833; 
$mex{"238:93"}=47.456272; 	$dmex{"238:93"}=0.001844; 
$mex{"239:93"}=49.312385; 	$dmex{"239:93"}=0.002077; 
$mex{"240:93"}=52.314736; 	$dmex{"240:93"}=0.015139; 
$mex{"241:93"}=54.261791; 	$dmex{"241:93"}=0.070734; 
$mex{"242:93"}=57.41839; 	$dmex{"242:93"}=0.200009; 
$mex{"228:94"}=36.088247; 	$dmex{"228:94"}=0.032485; 
$mex{"229:94"}=37.399683; 	$dmex{"229:94"}=0.051323; 
$mex{"230:94"}=36.933632; 	$dmex{"230:94"}=0.015096; 
$mex{"231:94"}=38.285435; 	$dmex{"231:94"}=0.026432; 
$mex{"232:94"}=38.365534; 	$dmex{"232:94"}=0.018086; 
$mex{"233:94"}=40.051797; 	$dmex{"233:94"}=0.050354; 
$mex{"234:94"}=40.349597; 	$dmex{"234:94"}=0.006967; 
$mex{"235:94"}=42.183684; 	$dmex{"235:94"}=0.02057; 
$mex{"236:94"}=42.902718; 	$dmex{"236:94"}=0.002205; 
$mex{"237:94"}=45.093307; 	$dmex{"237:94"}=0.002236; 
$mex{"238:94"}=46.164745; 	$dmex{"238:94"}=0.001834; 
$mex{"239:94"}=48.589877; 	$dmex{"239:94"}=0.001827; 
$mex{"240:94"}=50.126995; 	$dmex{"240:94"}=0.001825; 
$mex{"241:94"}=52.956791; 	$dmex{"241:94"}=0.001825; 
$mex{"242:94"}=54.71839; 	$dmex{"242:94"}=0.00186; 
$mex{"243:94"}=57.755509; 	$dmex{"243:94"}=0.003188; 
$mex{"244:94"}=59.805555; 	$dmex{"244:94"}=0.005053; 
$mex{"245:94"}=63.106068; 	$dmex{"245:94"}=0.014417; 
$mex{"246:94"}=65.39519; 	$dmex{"246:94"}=0.015255; 
$mex{"237:95"}=46.55; 	$dmex{"237:95"}=0.05; 
$mex{"238:95"}=48.423087; 	$dmex{"238:95"}=0.05072; 
$mex{"239:95"}=49.391985; 	$dmex{"239:95"}=0.002444; 
$mex{"240:95"}=51.511785; 	$dmex{"240:95"}=0.013908; 
$mex{"241:95"}=52.936008; 	$dmex{"241:95"}=0.001829; 
$mex{"242:95"}=55.469685; 	$dmex{"242:95"}=0.001832; 
$mex{"243:95"}=57.176109; 	$dmex{"243:95"}=0.002293; 
$mex{"244:95"}=59.880951; 	$dmex{"244:95"}=0.002081; 
$mex{"245:95"}=61.899746; 	$dmex{"245:95"}=0.003467; 
$mex{"246:95"}=64.99464; 	$dmex{"246:95"}=0.018176; 
$mex{"233:96"}=47.293098; 	$dmex{"233:96"}=0.071652; 
$mex{"234:96"}=46.723592; 	$dmex{"234:96"}=0.018204; 
$mex{"238:96"}=49.395914; 	$dmex{"238:96"}=0.036629; 
$mex{"240:96"}=51.725434; 	$dmex{"240:96"}=0.002285; 
$mex{"241:96"}=53.703425; 	$dmex{"241:96"}=0.00217; 
$mex{"242:96"}=54.805218; 	$dmex{"242:96"}=0.001835; 
$mex{"243:96"}=57.183593; 	$dmex{"243:96"}=0.002083; 
$mex{"244:96"}=58.453651; 	$dmex{"244:96"}=0.001825; 
$mex{"245:96"}=61.004706; 	$dmex{"245:96"}=0.002081; 
$mex{"246:96"}=62.618439; 	$dmex{"246:96"}=0.002061; 
$mex{"247:96"}=65.533901; 	$dmex{"247:96"}=0.004364; 
$mex{"248:96"}=67.392202; 	$dmex{"248:96"}=0.005055; 
$mex{"249:96"}=70.75015; 	$dmex{"249:96"}=0.005061; 
$mex{"250:96"}=72.989038; 	$dmex{"250:96"}=0.011205; 
$mex{"251:96"}=76.647617; 	$dmex{"251:96"}=0.022804; 
$mex{"243:97"}=58.691176; 	$dmex{"243:97"}=0.004745; 
$mex{"244:97"}=60.715501; 	$dmex{"244:97"}=0.014472; 
$mex{"245:97"}=61.815448; 	$dmex{"245:97"}=0.002306; 
$mex{"246:97"}=63.968439; 	$dmex{"246:97"}=0.060035; 
$mex{"247:97"}=65.490624; 	$dmex{"247:97"}=0.005501; 
$mex{"249:97"}=69.849622; 	$dmex{"249:97"}=0.002612; 
$mex{"250:97"}=72.95137; 	$dmex{"250:97"}=0.003968; 
$mex{"251:97"}=75.227617; 	$dmex{"251:97"}=0.010956; 
$mex{"242:98"}=59.337614; 	$dmex{"242:98"}=0.036854; 
$mex{"244:98"}=61.479247; 	$dmex{"244:98"}=0.00292; 
$mex{"245:98"}=63.386875; 	$dmex{"245:98"}=0.002856; 
$mex{"246:98"}=64.091733; 	$dmex{"246:98"}=0.00209; 
$mex{"247:98"}=66.136624; 	$dmex{"247:98"}=0.00814; 
$mex{"248:98"}=67.239766; 	$dmex{"248:98"}=0.005323; 
$mex{"249:98"}=69.725622; 	$dmex{"249:98"}=0.002195; 
$mex{"250:98"}=71.171793; 	$dmex{"250:98"}=0.00207; 
$mex{"251:98"}=74.134617; 	$dmex{"251:98"}=0.004477; 
$mex{"252:98"}=76.033987; 	$dmex{"252:98"}=0.005055; 
$mex{"253:98"}=79.301015; 	$dmex{"253:98"}=0.006174; 
$mex{"254:98"}=81.340767; 	$dmex{"254:98"}=0.012303; 
$mex{"251:99"}=74.512202; 	$dmex{"251:99"}=0.006072; 
$mex{"252:99"}=77.293987; 	$dmex{"252:99"}=0.050255; 
$mex{"253:99"}=79.013697; 	$dmex{"253:99"}=0.002612; 
$mex{"254:99"}=81.991986; 	$dmex{"254:99"}=0.004242; 
$mex{"255:99"}=84.088873; 	$dmex{"255:99"}=0.011038; 
    if ($verb>0){
    print "                   mass excess A=$a Z=$z  mex=",$mex{$a.":".$z}," +- ",$dmex{$a.":".$z}," MeV\n";
    }
return  wantarray()?  ( $mex{$a.":".$z}, $dmex{$a.":".$z} ) :  $mex{$a.":".$z} ;
}



sub AMU{
    my $a=shift;
    my $z=shift;
    my $verb=shift or 1; # wtf is this - ah ano (bez niceho to nema nic)?
 #   printf "verbosity  $verb\n";
    my ($mex,$dmex)=&MEX($a,$z, $verb);
     $amu= ( $mex + $a * 931.49403)/931.49403;
    if ($mex!=0){$damu=  ($dmex/$mex)**2 ;}else {$damu=0;}
#    $damu+= /931.49403
    $damu=sqrt($damu);
    if ($verb>0){
    print "                   AMU  A=$a Z=$z    amu=",$amu," +- ",$damu," MeV\n";
    }
    return $amu;
}



sub KINEM{
    print "Program to evaluate relativistic kinematics for a reaction\n";
    print "----------------------------------------------------------\n";
    print "\n";
    my ($a1,$z1,$a2,$z2,$a,$z3,$a4,$z4, $t1,$ang1,$ang2,$dang);

    printf("(1)Input A and Z of a projectile  (e.g.  2 1):\n",1);
    $inp=<STDIN>; chop $inp;$inp=~s/^\s+//;$inp=~s/\s+$//; ($a1,$z1)=split/\s+/,$inp;
    print "    A1=$a1  Z1=$z1\n";

    printf("(2)Input A and Z of a target (2) (e.g.  12 6):\n",1);
    $inp=<STDIN>; chop $inp;$inp=~s/^\s+//;$inp=~s/\s+$//; ($a2,$z2)=split/\s+/,$inp;
    print "    A2=$a2 Z2=$z2\n";

    printf("(3)Input A and Z of a ejectile (3) (e.g.  1 1):\n",1);
    $inp=<STDIN>; chop $inp; $inp=~s/^\s+//;$inp=~s/\s+$//;($a3,$z3)=split/\s+/,$inp;
    print "    A3=$a3  Z3=$z3\n";

    printf("(4)Input A and Z of a remnant (4) (e.g.  13 6):\n",1);
    $inp=<STDIN>; chop $inp; $inp=~s/^\s+//;$inp=~s/\s+$//;($a4,$z4)=split/\s+/,$inp;
    print "    A4=$a4  Z4=$z4 \n";

    printf("(TKE)Input TKE energy of a projectile in MeV (1) (e.g.  10.0):\n",1);
    $inp=<STDIN>; chop $inp;$inp=~s/^\s+//;$inp=~s/\s+$//; $t1=$inp;
    print "    T1=$t1\n";

    printf("(angle)Input theta angles in degrees - from to step (e.g. 5 45 10):\n",1);
    $inp=<STDIN>; chop $inp;$inp=~s/^\s+//;$inp=~s/\s+$//; ($ang1,$ang2,$dang)=split/\s+/,$inp;
    print "    theta from=$ang1  to=$ang2  step=$dang\n";

#------- normal input ok.
    my ($excr, $amu1, $amu2, $amu3, $amu4)=("","","","","");
    printf("now: Enter==CALCULATE else input:  E_exc(remnant) amu1 amu2 amu3 amu4 :\n",1);
    $inp=<STDIN>; chop $inp;$inp=~s/^\s+//;$inp=~s/\s+$//; 
    if ($inp ne ""){
       ($excr, $amu1, $amu2, $amu3, $amu4)=split/\s+/,$inp;
       print "      excremn=$excr, amu1=$amu1, amu2=$amu2, amu3=$amu3, amu4=$amu4\n";
    }

#------------------------------------------------------------ INPUT DONE
    my ($a , $t3a, $t3b, $n);
    my( @a, @acm,@acmb, @t3a, @t3b, @t4a , @th4, @t4 , @th4b, @t4b , @dtde, @dtdo  , @dtbde, @dtbdo, @kscmslab,@kscmslabb);

    $n=0;
    my ($dtde2,$dtde1,$dtdo2,$dtdo1, $theta3max , $Q, $rho3);
    my ($dtbde2,$dtbde1,$dtbdo2,$dtbdo1);
    for ($a=$ang1;$a<=$ang2;$a+=$dang){
# $t3a,$t3b,$theta,$th3cm, $th3cmb, $theta4,$t4a, $theta4b,$t4b,$convsig, $convsigb, $theta3max, $Q
#dtde
	( $t3a[$n],$t3b[$n],$a[$n],$acm[$n],$acmb[$n], $th4[$n], $t4[$n], $th4b[$n], $t4b[$n])=
   &REACT($a1,$z1, $a2,$z2, $a3,$z3, $a4,$z4,  $t1+0.001,  $a ,$excr, $amu1, $amu2, $amu3, $amu4 );
	$dtde2=$t3a[$n];
	$dtbde2=$t3b[$n];
	( $t3a[$n],$t3b[$n],$a[$n],$acm[$n],$acmb[$n], $th4[$n], $t4[$n], $th4b[$n], $t4b[$n])=
   &REACT($a1,$z1, $a2,$z2, $a3,$z3, $a4,$z4,  $t1-0.001,  $a,$excr, $amu1, $amu2, $amu3, $amu4  );
	$dtde1=$t3a[$n];
	$dtbde1=$t3b[$n];
 #dtdo
 	( $t3a[$n],$t3b[$n],$a[$n],$acm[$n],$acmb[$n], $th4[$n], $t4[$n], $th4b[$n], $t4b[$n])=
  &REACT($a1,$z1, $a2,$z2, $a3,$z3, $a4,$z4,  $t1,  $a+0.001,$excr, $amu1, $amu2, $amu3, $amu4  );
	$dtdo2=$t3a[$n];
	$dtbdo2=$t3b[$n];
	( $t3a[$n],$t3b[$n],$a[$n],$acm[$n],$acmb[$n], $th4[$n], $t4[$n], $th4b[$n], $t4b[$n])=
   &REACT($a1,$z1, $a2,$z2, $a3,$z3, $a4,$z4,  $t1,  $a-0.001,$excr, $amu1, $amu2, $amu3, $amu4  );
	$dtdo1=$t3a[$n];
	$dtbdo1=$t3b[$n];
        
#finalni
	$dtde[$n]=($dtde2-$dtde1)*1000/2; # na MeV but interval is sym.
	$dtdo[$n]=($dtdo2-$dtdo1)*1000/2; # na deg but interval is sym.
	$dtbde[$n]=($dtbde2-$dtbde1)*1000/2; # na MeV but interval is sym.
	$dtbdo[$n]=($dtbdo2-$dtbdo1)*1000/2; # na deg but interval is sym.
#extra dlouhy spis
	( $t3a[$n],$t3b[$n],$a[$n],$acm[$n],$acmb[$n], $th4[$n], $t4[$n], $th4b[$n], $t4b[$n], 
	  $kscmslab[$n], $kscmslabb[$n],  $theta3max , $Q, $rho3  )=
   &REACT($a1,$z1, $a2,$z2, $a3,$z3, $a4,$z4,  $t1,  $a,$excr, $amu1, $amu2, $amu3, $amu4  );

	if ($rho3>1){#two solutions
	printf("%6.2f %6.2f  %8.3f  %8.3f   %6.3f   %6.3f  %6.4f %8.2f  %8.3f\n",
	       $a[$n],$acm[$n],  $t3a[$n], $t3b[$n] , $dtde[$n] , $dtdo[$n] ,$kscmslab[$n], $th4[$n], $t4[$n] );

	}else{#one solution
	printf("%6.2f %6.2f  %8.3f  %8.3f   %6.3f   %6.3f  %6.4f %8.2f  %8.3f\n",
	       $a[$n],$acm[$n],  $t3a[$n], $t3b[$n] , $dtde[$n] , $dtdo[$n] ,$kscmslab[$n], $th4[$n], $t4[$n] );

	}
	$n++;

    }#main for loop angles
    $n=0;
    print "=====================================================================\n";
    print "   A1= $a1 $z1   A2= $a2 $z2 ->  A3= $a3 $z3  A4= $a4 $z4\n";    
    print "   masses input by hand:    amu1= ",&AMU($a1,$z1,0),"  amu2= ",&AMU($a2,$z2,0),"\n";
    print "                       :    amu3= ",&AMU($a3,$z3,0),"  amu4= ",&AMU($a4,$z4,0)," \n";
    print "   T1 = $t1 MeV\n";
    print "   excitation   by hand:    excremn=$excr\n";
    print "   masses input by hand:    amu1= $amu1   amu2= $amu2 \n";
    print "                       :    amu3= $amu3   amu4= $amu4 \n";
    print "   theta from= ($ang1 - $ang2) deg ...  step=$dang  deg\n";
    print "            theta3max = $theta3max\n";
    print "                    Q = $Q MeV\n";
    print "                 rho3 = $rho3 (if >1 :=>2 solutions)\n";

if ($rho3>1+1e-7){#two solutions
    print "================================================================================================================\n";
    print " theta3 thet_CM    T3  dTdE   dTdO   sigC-L  theta4   T4   |  thb_CM   T3b   dTbdE dTbdO  sigC-Lb  theta4b   T4b \n";
    print "-----------------------------------------------------------------------------------------------------------------\n";
    for ($a=$ang1;$a<=$ang2;$a+=$dang){
	printf("%6.2f %6.2f %7.3f %6.3f %6.3f %7.4f %6.2f %7.3f | %6.2f %7.3f %6.3f %6.3f %7.4f %6.2f %7.3f\n",
	       $a[$n],$acm[$n],  $t3a[$n],  $dtde[$n] , $dtdo[$n],$kscmslab[$n], $th4[$n], $t4[$n] ,
                      $acmb[$n], $t3b[$n],  $dtbde[$n] , $dtbdo[$n],$kscmslabb[$n], $th4b[$n], $t4b[$n] );
	$n++;
    }
    print "================================================================================================================\n";
}else{# one olution
    print "============================================================================\n";
    print " theta3 thet_CM    T3     dTdE     dTdO  sigC-L    theta4     T4\n";
    print "----------------------------------------------------------------------------\n";
    for ($a=$ang1;$a<=$ang2;$a+=$dang){
	printf("%6.2f %6.2f  %8.3f   %6.3f   %6.3f  %6.4f %8.2f  %8.3f\n",
	       $a[$n],$acm[$n],  $t3a[$n],  $dtde[$n] , $dtdo[$n],$kscmslab[$n], $th4[$n], $t4[$n]  );
	$n++;
    }
    print "============================================================================\n";
}#================end of 1/2solutions


	return 0;
}







sub REACT{
    my ($a,$z, $a2,$z2, $a3,$z3, $a4,$z4, $t, $theta, $exctgt, $amu1, $amu2, $amu3, $amu4, $Q )=@_;
   if ($Q){}else{$Q=-9999;}
#    print "Q=$Q\n";
    printf("\n------- %f deg--------------------------------------\n", $theta);
    my $rs;
    my ($m1,$dm1)=&AMU($a,$z  ,1  );
    my ($m2,$dm2)=&AMU($a2,$z2 ,1 );
    my ($m3,$dm3)=&AMU($a3,$z3 ,1 );
    my ($m4,$dm4)=&AMU($a4,$z4 ,1 );
    $m1=$m1 * 931.49403;
    $m2=$m2 * 931.49403;
    $m3=$m3 * 931.49403;
    $m4=$m4 * 931.49403; # adding excitation of target later

    printf("   AMUs (nudat): %f %f %f %f\n", $m1,$m2,$m3,$m4 );
    if ($amu1>0){  $m1=$amu1 * 931.49403;  }
    if ($amu2>0){  $m2=$amu2 * 931.49403;  }
    if ($amu3>0){  $m3=$amu3 * 931.49403; ;  }
    if ($amu4>0){  $m4=$amu4 * 931.49403   } # adding excitation of target later
    printf("   AMUs  (hand): %f %f %f %f\n", $m1,$m2,$m3,$m4 );
    my $es=$t + $m1  + $m2;
    my $p1=sqrt(     ($t + $m1)**2  - $m1**2  );
    # theta is defacto theta3.
    my $costh3=cos( $theta * 3.1415926535/180);
    my $sinth3=sin( $theta * 3.1415926535/180);
    my $INVALID=0;


    $m4=$m4 + $exctgt; #adding excitation of target HERE
    if ($Q == -9999){
	$Q=$m1+$m2-$m3-$m4 ; 
    }else{   
 	$exctgt=$m1+$m2-$m3-$m4 -$Q;  print " \n\n Q overriden Q=$Q MeV, exc4 evaluated = $exctgt\n\n";
    }



#nerelativ
#    $m3=$m3 + $exctgt; #adding excitation of scattered particle HERE

#    my $SQne=sqrt( $m1*$m3*$t*$costh3**2 +($m1+$m2)*($m4*$Q+($m4-$m1)*$t)  );
#    my $t3na=(sqrt($m1*$m3*t)*$costh3 + $SQne )**2 /($m1+$m2)**2;
#    my $t3nb=(sqrt($m1*$m3*t)*$costh3 - $SQne )**2 /($m1+$m2)**2;
#    print "Q=$Q ;  T3nerel = $t3na  $t3nb  \n";    
#-->>    print "               Q=$Q , p=$p1;  \n";    
#relativ
    my $a3b= $es**2 - $p1**2 + ($m3**2 - ($m4)**2); 
#--- this is square root  from eq (4)  T3=.......
    my $SQ= $a3b**2 - 4*$m3**2 * ($es**2-$p1**2*$costh3**2) ;
#    print  $a3b," ",$m3," ",$es,"  ",$p1,"  ",$costh3,"\n";
#    print  $a3b**2,"    ", 4*$m3**2 * ($es**2-($p1**2)*($costh3**2) ) ,"\n";
    if ($SQ<0){  
	print "    SQ < 0  : $SQ  : setting to           ##### ZERO ####\n";
	$SQ=0;
	$INVALID=1;
    }
    $SQ=sqrt( $SQ ); # prepare for sqrt   <0
####### 2 SOLUTIONS ########
    my $t3a=($a3b*$es + $p1*$costh3* $SQ)/2/($es**2 - $p1**2*$costh3**2) - $m3;
    my $t3b=($a3b*$es - $p1*$costh3* $SQ)/2/($es**2 - $p1**2*$costh3**2) - $m3;
####### 2 SOLUTIONS ########
 #   print "    kinetic E T3=$t3a ($t3b) \n";


# prepare 2-solution's --- decision......  
    my $E1=$t+$m1; # full energy
    my $V=$p1/( $E1 + $m2 ); # CMS velocity  pc/E->v/c?
    my $ttr=- ($m1+$m2)/$m2 * $Q;
       if ($Q>0){$ttr=0;}
    my $ttrc=-$Q;
       if ($Q>0){$ttrc=0;}
# equation   (21)  p3c CMS
  # !!!!!!!!!!  error in this line - use p3c defined later!!!!!
    my $p3c=$m2*sqrt( ($t-$ttr)*($t-$ttr + 2/$m2*$m3*$m4 )/( 2*$m2*$t + ($m1+$m2)**2)  );
# varianta p3c: (19) and (20)
    my $Es=$t + $m1 +$m2;
    my $Esc=$Es * sqrt( 1-$V**2 );
  #PROB  print "tot E= $Es  totEcms = $Esc   p3c= $p3c\n";
    $p3c=sqrt( ($Esc**2-($m3+$m4)**2)*($Esc**2-($m3-$m4)**2) )/2/$Esc;
  #PROB  print "tot E= $Es  totEcms = $Esc   p3c= $p3c\n";

    my $E3c=sqrt( $p3c**2 + $m3**2 );
    my $rho3=$V/$p3c * $E3c;
#    mam-li  p3c  mam samozrejme i p4c :)
#  ziskam E4c - bude dobre pro theta4
    my $p4c=$p3c;

    my $E4c=sqrt ( $p4c**2 + $m4**2 );
    my $t4a=$t-$t3a+$Q; #rovnice (1) zzEne, nezavisle
    my $t4b=$t-$t3b+$Q; #rovnice (1) zzEne, nezavisle


#======================================================== THETA3
 #ziskej p3 (pozor na <0) klasicky ze znalosti p a t  [p3b]
 my $p3=    ($t3a + $m3)**2  - $m3**2  ;  # sqrt pozdeji...
 my $p3b=   ($t3b + $m3)**2  - $m3**2  ;  # sqrt pozdeji...
    if ($p3<0){ print "    p3 <0:  $p3 : setting to ##### ZERO ####\n";$p3=0.0;}
 $p3=sqrt(  $p3  );
    if ($p3b<0){ print "    p3b <0:  $p3b : setting to ##### ZERO ####\n";$p3b=0.0;}
 $p3b=sqrt(  $p3b  );
#    $p3b=42.85920142;
# ziskej plnou informaci o  theta3cm - i sin i cos =>  theta3cm a  PI-theta3cm
# equation (22) 2nd part
 my $sinth3cm = $p3/$p3c*$sinth3; 
 my $sinth3cmb=$p3b/$p3c*$sinth3; 
 my $costh3cm=  ( $p3* $costh3)/(1/sqrt(1-$V**2));
 my $costh3cmb= ( $p3b*$costh3)/(1/sqrt(1-$V**2));
 $costh3cm= ( $costh3cm -  $V*$E3c )/ $p3c ;
 $costh3cmb=( $costh3cm -  $V*$E3c )/ $p3c ;
    my $tmpr2dc=$R2dc;  $R2dc=1.0; ####  change default transofrmation..........
    my $th3cm =&ASIN(  $sinth3cm )*180/3.1415926;
    my $th3cmb=&ASIN(  $sinth3cmb)*180/3.1415926;
    if ($costh3cm <0){ $th3cm =180-$th3cm;  };
    if ($costh3cmb<0){ $th3cmb=180-$th3cmb;  };
#-====================================================== THETA4
    my $th4cm =  180.0 - $th3cm;
    my $th4cmb=  180.0 - $th3cmb;
    #z eq (22)
    my $cotgth4 = 1/(sqrt(1-$V**2)) *  ( $p4c*cos($th4cm /180 * 3.1415926) + $V*$E4c  ) ;
    my $cotgth4b= 1/(sqrt(1-$V**2)) *  ( $p4c*cos($th4cmb/180 * 3.1415926) + $V*$E4c  ) ;
    my $tmpjmen =( $p4c* sin( $th4cm/180.0 * 3.1415926 ) );
    my $tmpjmenb=( $p4c* sin( $th4cmb/180.0 * 3.1415926 ) );
    if ( $tmpjmen ==0) { 
	print "    p4csin ==0:  $tmpjmen : setting to ##### ZERO ####\n";$cotgth4=1e+7; 
    }else{     $cotgth4= $cotgth4/$tmpjmen; }
    if ( $tmpjmenb==0) { 
	print "    p4csinb ==0:  $tmpjmenb : setting to ##### ZERO ####\n";$cotgth4b=1e+7; 
    }else{     $cotgth4b= $cotgth4b/$tmpjmenb; }
 
   my $theta4= &ATAN( 1/ $cotgth4 )*180/3.1415926;
    if ($theta4<0){ $theta4=180+$theta4;}
   my $theta4b= &ATAN( 1/ $cotgth4b )*180/3.1415926;
    if ($theta4b<0){ $theta4b=180+$theta4b;}


# equation (32)  theta max
#    print "doing sinmax\n";
    my $theta3max=180.0;
    if ($rho3>=1.00000){
     my $sinth3max=sqrt(  (1-$V**2)/($rho3**2-$V**2)  );
     $theta3max=&ASIN( $sinth3max )*180/3.1415926;
    }else{ $theta3max=180.0; $t3b=0.0;}
    $R2dc=$tmpr2dc;#put back translation deg2rad.......................

# equation (30) for conversion sigma cm -> sigma lab (sCMS=K*sLab)
#    my $convsig=($p3c/$p3) * sqrt( 1- (($rho3**2-$V**2)*$sinth3**2)/(1-$V**2)  );
#    print "doing  k sigma  V=$V\n";
#
#   at 0 or 180 == p3c/p3
    my $convsig=  (($rho3**2-$V**2)*$sinth3**2)/(1-$V**2)  ;
    $convsig=1.0 - $convsig;
    if ($convsig>0 && $p3>0){ 
	$convsig=($p3c/$p3)**2 * sqrt(  $convsig );
    }else{$convsig=0.;}

# b-variant
    my $convsigb=  (($rho3**2-$V**2)*$sinth3**2)/(1-$V**2)  ;
    $convsigb=1.0 - $convsigb;
    if ($convsigb>0 && $p3b>0){ 
	$convsigb=($p3c/$p3b)**2 * sqrt(  $convsigb );
    }else{$convsigb=0.;}


#=====================  INVALIDATE ALL ====================
    if ($INVALID==1){
	($th3cm,$th4cm,$theta4,$t3a,$t4a,$th3cmb,$th4cmb,$theta4b,$t3b ,$t4b  )=
	 (   0,   0,     0,      0,    0,   0,     0,      0,       0,    0 );
    }

    printf ("        T1   =%15.5f\n",$t );
#    printf ("        th3MX=%15.5f\n",$theta3max );
    printf ("        th3  =%15.5f    (thetaMAX=%15.5f)\n",$theta,  $theta3max  );
    printf ("        th3cm=%15.5f\n",$th3cm );
    printf ("        th4cm=%15.5f\n",$th4cm );
    printf ("        th4  =%15.5f\n",$theta4 );
    printf ("        T3(a)=%15.5f\n",$t3a);
    printf ("        T4(a)=%15.5f\n",$t4a);
    printf ("        Kscsl=%15.5f (sigma_cms=K*sigma_lab)\n",$convsig );
    printf ("        rho3 =%15.5f (if <=1.0 : 1 solution else 2 solutions for T3)\n",$rho3 );
    if ($rho3>1){
    printf ("     b  th3cm=%15.5f\n",$th3cmb );
    printf ("     b  th4cm=%15.5f\n",$th4cmb );
    printf ("     b  th4  =%15.5f\n",$theta4b );
    printf ("     b  T3(b)=%15.5f\n",$t3b);
    printf ("     b  T4(b)=%15.5f\n",$t4b );
    printf ("     b  Kscsl=%15.5f (sigma_cms=K*sigma_lab)\n",$convsigb );
    }
    printf ("        p1   =%15.5f (projectile impuls)\n",$p1 );
    printf ("        E1   =%15.5f (projectile - total energy)\n",$E1 );
    printf ("        V    =%15.5f (velocity of CMS ... v/c)\n",$V );
    printf ("        ttr  =%15.5f (Treshold in Lab)\n",$ttr );
    printf ("        ttrc =%15.5f (Treshold in CMS == -Q)\n",$ttrc );
    printf ("        Q    =%15.5f (if Q>0 = exoterm)\n",$Q );
    printf ("        ExcTg=%15.5f (input tgt excitation)\n",$exctgt );
    printf ("        p3c  =%15.5f\n",$p3c );
    printf ("        p4c  =%15.5f\n",$p4c );
    printf ("     EtotCMS =%15.5f\n",($p3c**2)/2/$m3+($p4c**2)/2/$m4 );
#    print "total Ek =  ",($p3c**2)/2/$m3+($p4c**2)/2/$m4 , "\n";
    printf ("        p3   =%15.5f     b  p3b  =%15.5f\n",$p3,$p3b );
    printf ("        E3c  =%15.5f\n",$E3c );
    printf ("        E4c  =%15.5f\n",$E4c );

#    my $t4a=($a4*$es + $p1*$costh4* $SQ)/2/($es**2 - $p1**2*$costh4**2) - $m3;
#    my $t4b=($a4*$es + $p1*$costh4* $SQ)/2/($es**2 - $p1**2*$costh4**2) - $m3;
#    print "  $a3b = A3 ;  $t3a = T3A ;   $t3b = T3B \n";
    if ($rho3>1){    print "   resulting TKE   T3=$t3a    and      $t3b \n";}
    else{   print "   resulting TKE  T3=$t3a  \n"; } 
#    print "    kinetic E T4=$t4a ($t4b) \n";
    $rs=$t3a;
#    return $rs;
    return  wantarray()? ( $t3a,$t3b,$theta,$th3cm, $th3cmb, $theta4,$t4a, $theta4b,$t4b, $convsig, $convsigb, $theta3max, $Q, $rho3) : $rs;
    print "           try  http://t2.lanl.gov/data/qtool.html for all possible reactions\n";
}











sub RHO{
    my($el)=@_;    my $i;my $ii;
    $el=~s/\$//g;
#    print "$el\n";
 my @element=qw(n H He 
              Li Be B C N O F Ne   
              Na Mg Al Si P S Cl Ar
              K Ca Sc Ti V Cr Mn Fe Co Ni Cu Zn 
   	          Ga Ge As Se Br Kr
              Rb Sr Y Zr Nb Mo Tc Ru Rh Pd Ag Cd 
		  In Sn Sb Te I Xe
              Cs Ba  La 
                      Ce Pr Nd Pm Sm Eu Gd Tb Dy Ho Er Tm Yb Lu 
	       Hf Ta W Re Os Ir Pt Au Hg 
		Tl Pb Bi Po At Rn
              Fr Ra Ac 
                      Th Pa U Np Pu Am Cm Bk Cf Es Fm Md No Lr 
	       Rf Db Sg Bh Hs Mt Ds 111 112 113 114 115 116 117 118);
# density TILL Am
my @den=qw( 
0   0.00008988 0.0001785  
0.534  1.85  2.34  2.267  0.0012506   0.001429  0.001696  0.0008999
0.971  1.738 2.698 2.3296 1.82  2.067   0.003214 0.0017837 
0.862  1.54  2.989      4.540   6.0     7.15    7.21    7.86   8.9   8.908     8.96    7.14
  5.91  5.32  5.72  4.79  3.12  0.003733
1.63 2.54 4.47 6.51 8.57 10.22 11.5 12.37 12.41 12.02 10.5 8.65
  7.31 7.31 6.68 6.24 4.93 0.005887
1.87 3.59 6.15
     6.77 6.77 7.01 7.3 7.52 5.24 7.9 8.23 8.55 8.8 9.07 9.32 6.9 9.84
13.31 16.65 19.35 21.04 22.6 22.4 21.45 19.32 13.55
  11.85 11.35 9.75 9.3  0.000 0.000
1.87 5.5 10.07
     11.72 15.4 18.95 20.2 19.84 13.67
  	    );
# molar weight
my @MM=qw(1  1.0079 4.0026  
6.941 9.01218 10.811 12.0107 14.0067 15.9994 18.998 20.1797
22.98977 24.305 26.9815 28.0855 30.97376 32.065 35.453 39.948
39.0983 40.078  44.9559  47.867  50.9415 51.996 54.938 55.845  58.933 58.693 63.546   65.409
 69.723 72.64 74.9216 78.96 79.904 83.8
85.4678 87.62 88.906 91.224 92.9064 95.94 98 101.07 102.9055 106.42 107.8682 112.411
 114.818 118.71 121.76 127.6 126.9045 131.293 
132.9055 137.327 139.9055
     140.116 140.9077 144.24 145 150.36 151.964 157.25 158.925 162.5 164.9303 167.259 168.9342 173.04 174.967
178.49 180.9479 183.84 186.207 190.23 192.217 195.078 196.9665 200.59
  204.3833 207.2 208.9804 209 210 222
223 226 227 
     232.0381 231.0359 238.0289 237 244 243
           );
    my $den;
    $el=~s/^(\w)/uc($1)/e;
    if (length($el)>1){$el=~s/^(\w)(\w+)/"$1".lc($2)/e;}
    for (my $i=0;$i<=$#element; $i++){
        if ( $el eq $element[$i] ){ $den=$den[$i];$ii=$i; $mm=$MM[$i];}
    }
    print "                   density of $el = $den g/cm3, Z=$ii, MM=$mm g/mol\n";
    return $den;
}





sub T2GCM{
    my ($a,$den)=@_; $a=eval($a);$den=eval($den);
    if ($den eq ""){    print " thicknes in cm -> g/cm2 : input cm,density RHO   cm*RHO=g/cm2\n";}
    printf("                  thickness=%f mm, dens=%f g/cm3, => %f g/cm2\n",$a*10,$den,$a*$den);
    return $a*$den;
}
sub GCM2T{
    my ($a,$den)=@_; $a=eval($a);$den=eval($den);
    if ($den eq ""){    print "  thickness in g/cm2 -> cm : input g/cm2,density RHO   cm*RHO=g/cm2\n";}
    printf("                  thickness=%f g/cm2, dens=%f g/cm3\n",$a,$den);
    printf("                  => %15.9f mm =>%15.9f cm =>%11.5f um\n",$a/$den*10, $a/$den,$a/$den*10000 );
    return $a/$den;
}

sub RERATE{
#
# 1barn is 1e-28 m2  or  1e-24cm2
# flux is density: #/m2/s
#
# 1/ reaction rate    [1/s]
# 2/ R ~ j     j is flux [#/m2/s]
# 3/ R ~ w     w is area density of target [#nuclei/m2]
# 4/ R ~ sigma   is front size of target nucleus
#    R ~ j * sigma * w
# 5/ R = j * sigma * w * A   ... A=area touched by beam [m2]
#        interesting:
#        w*A      is # of scattering centers
#        sigma*w  is 'reactive part of the area'
#-----------------------------------------------------------
# this is correct for a thin target-one layer of atoms
# what if I have finite target? - approximation of w by m/S
#    we just assume that all the 'layers' are just one!
# flux [#/m2/s] we multiply by area touched and we have cps.
#       j * A =  beam
#-----------------------------------------------------------
# w = [#/m2] =   m/mM   * Na  /S   ( mM...molar weight,
#                                    m...sample weight, 
#                                    Na=6.022142e+23 1/mol)
#                g/(g/mol)*(1/mol) * 1/m2
# 6/ R = j    * sigma * m/mM * Na /S     * A=
#      = beam * sigma /mM * Na *m/S
#                    rho = m/V = m/(S*T) ...   m/S=rho*T
# 7/ R = beam * sigma /mM * Na * rho * T   (T...target thickness)
#-----------------------------------------------------------
# flux means that i just take # of incident particles. the question of 1/m2
#    is solved by A : Area
#
#-----------------------------------------------------------
# N/sec,  Crosssect, Mn target, depths in g/cm2
#  flux is part/m2/s ,   we use cps!
  my ($flux, $sigma, $Mn, $dep)=@_;
#  print "   input: beam p/s,sigma barn,Molarweigth g/mol, depth g/cm2\n";
  if ($dep eq ""){print "reaction rate:INPUT flux(part/s),sigma(barn),MM,thickness(g/cm2)\n";}

  $flux=eval($flux);# evaluate the inside
  $sigma=eval($sigma);# evaluate the inside
  $Mn=eval($Mn);# evaluate the inside
  $dep=eval($dep);# evaluate the inside
#
#          j*A     sigma _in_m2   m/S      Na         / mM
#
#                 sigma in cm2    g/cm2   Na(mol)     g/mol
  my $R=  $flux*  $sigma*1E-24*   $dep*   6.02*1E+23/ $Mn;
  printf("          RR:flux=%.2e p/s, sigma=%.2e barn, \n",$flux,$sigma,$dep,$R);
  printf("                molar weight=%.3f\n",$Mn );
  printf("                T=%.2e g/cm2, RATE=%.3e/s\n",$dep,$R);
  return $R;
}




sub RERATET{
#
# check at 
#http://hyperphysics.phy-astr.gsu.edu/hbase/nuclear/crosec2.html#c1
#
#
 # N/sec,  Crosssect, Mn target, depths in um
  my ($flux, $sigma, $Mn, $dep, $rho)=@_;
#  print "   input: beam p/s,sigma barn,Molarweigth g/mol, depth g/cm2\n";
  if ($dep eq ""){
print "reaction rate:INPUT
 beam(part/s),sigma(barn), MM(g/mol), thickness(um), rho(g/cm3)\n";
}

  $flux=eval($flux);# evaluate the inside
  $sigma=eval($sigma);# evaluate the inside
  $Mn=eval($Mn) *0.001;# evalua this is g/mol => 0.001* to have kg/mol
  $dep=eval($dep) * 0.000001;# evaluate the inside  in um->m
  $rho=eval($rho) * 1000;# evaluate the inside from g/cm3 -> kg/m3
#
#          j       sigma _in_m2   T_in_m    Na          /mM     *rho
#
#          j*A     sigma_in_m2   T_in_m     Na in 1/mol   kg/mol  kg/m3
#
  my $R=  $flux*  $sigma*1E-28*   $dep*   6.022142*1E+23/ $Mn    *$rho;
  printf("          RR:beam=%.2e p/s, sigma=%.2e barn, \n",$flux,$sigma,$dep,$R);
  printf("                rho(target)=%.3f  kg/m3\n",$rho );
  printf("                molar weight=%.3f kg/mol\n",$Mn );
  printf("                T=%.2e m, RATE=%.3e/s\n",$dep,$R);
  return $R;
}





sub FLUXAP{
  my ($flux,$chrg)=@_;
  if ($chrg eq ""){print "beam intensity:current->particles. Input current(A),charge,\n";}
  $flux=eval($flux);# evaluate the inside
  $chrg=eval($chrg);# evaluate the inside
  my $R=  $flux/$chrg/1.602E-19;
  printf("        flux=%.2e euA, Q+=%d =%.2e =>part/s\n",$flux*1000000,$chrg,$R);
  return $R;
}
sub FLUXPA{
  my ($flux,$chrg)=@_;
  if ($chrg eq ""){print "beam intensity:current<-particles. Input p/s,charge\n";}
  $flux=eval($flux);# evaluate the inside
  $chrg=eval($chrg);# evaluate the inside
  my $R=  $flux*$chrg*1.602E-19;
  printf("        flux=%.2e part/s, Q+=%d => %.2e euA\n",$flux,$chrg,$R*1000000);
  return $R;
}


sub PRINTREACT{
    my ($a1,$z1, $a2,$z2)=@_;  $a1=eval($a1);$z1=eval($z1);$a2=eval($a2);$z2=eval($z2);
    my ($na2,$nz2,$na1,$nz1);
    my %trl = (
	n =>   ["1","0"],
	p =>   ["1","1"],
	d =>   ["2","1"],
	t =>   ["3","1"],
	he3 => ["3","2"],
	he4 => ["4","2"],
	mn =>   ["-1","-0"],
	mp =>   ["-1","-1"],
	md =>   ["-2","-1"],
	mt =>   ["-3","-1"],
	mhe3 => ["-3","-2"],
	mhe4 => ["-4","-2"],
    );
    my @Qs;
  my %ele = (
        0 => "n",
        1 => "h",
        2 => "he",
        3 => "li",
        4 => "be",
        5 => "b",
        6 => "c",
        7 => "n",
        8 => "o",
        9 => "f",
        10 => "ne",
        11 => "na",
        12 => "mg",
        13 => "al",
        14 => "si",
        15 => "p",
        16 => "s",
        17 => "cl",
        18 => "ar",
        19 => "k",
        20 => "ca",
        20 => "ca",
        21 => "sc",
        22 => "ti",
        23 => "v",
        24 => "cr",
        25 => "mn",
        26 => "fe",
        27 => "co",
        28 => "ni",
        29 => "cu",
        30 => "zn",
      );
#    my %trl;  $trl{"p"}=\(1,1); $trl{"n"}=(1,0);
    print "        elastic\n";
    $Qr=0;
     push @Qs, $Qr;

#
#       print "   mk->DefineDetectorReaction(itarg,1.0,\"$ele{$z1}$a1\",\"$ele{$z2}$a2\",AMU($a2,$z2),AMU($a1,$z1),AMU($a2,$z2), 0.0, 0.0);\n";
    print " $a1$ele{$z1}+$a2$ele{$z2}->$na1$ele{$nz1}+$na2$ele{$nz2} : Q=$Qr \n";

    foreach (keys %trl){
#	print " $_  ",$trl{$_}[0],";  ",$trl{$_}[1],";    \n";
       $na1=$a1+$trl{$_}[0];       $nz1=$z1+$trl{$_}[1];
     # get back  n2  from known n1
      $na2=$a1+$a2-$na1;      $nz2=$z1+$z2-$nz1;

       if ($nz1>=0 && $nz2>=0 && $na1>0 && $na2>0){
      my $Qr= MEX( $a1,$z1 )+MEX($a2,$z2) - MEX( $na1,$nz1)- MEX($na2,$nz2);
      my $mt=join("", map {$_==$Qr} @Qs);
#      print "match = $mt \n";
      if ( $mt  != 1 ){
      push @Qs, $Qr;
      print " $a1$ele{$z1}+$a2$ele{$z2}->$na1$ele{$nz1}+$na2$ele{$nz2} : Q=$Qr   $a1,$z1 + $a2,$z2   tranfer of($trl{$_}[0],$trl{$_}[1])  ->    $na1,$nz1    $na2,$nz2   \n";
#       print "   mk->DefineDetectorReaction(itarg,1.0,\"$ele{$nz1}$na1\",\"$ele{$nz2}$na2\",AMU($a2,$z2),AMU($na1,$nz1),AMU($na2,$nz2),0.0,0.0);\n";
      }# match  != 1
       }# >=0
    }
    return 0;;
}


##############################################"" STATISTICAL
##############################################"" STATISTICAL
##############################################"" STATISTICAL

sub AVG{
    my $OUD=shift;
#    print "In AVG: oud==$OUD\n";
    $OUD=~s/\$//;   $OUD= uc($OUD);  my $i,$sum=0,$n=0,$av;

    if ($OUD=~/[\,\.]/){ #  TWO Fields
#	print "   one field ONLY\n";return 0;

    my @ff=split/[\s\,]+/,$OUD;
#    print "In AVG: ff===@ff\n";
    my ($Sumex1,$SumXY,$SumX,$SumY,$SumW)=(0,0,0,0);
    my ($a,$b,$n);
     if ($#ff>=0){
    print "In AVG:  ff>0 $OUD\n";

    $n=$#{$fieldvar{$ff[0]}}+1;# $#{$fieldvar{$ff[0]}} can create hash ""
    for (my $j=0;$j<=$#{$fieldvar{$ff[0]}}; $j++){ # 
#     for (my $ii=0;$ii<=$#ff; $ii++){ # different fields
	my $y=$fieldvar{$ff[0]}[$j];
	my $dy=$fieldvar{$ff[1]}[$j];
	my $w=1./$dy/$dy;
#	print "$x $y\n";
        $SumY += $y*$w; 
        $SumW += $w;
#     }
    }# for
    my $avg = $SumY/$SumW;
    my $sigi = sqrt( 1/$SumW );
    # second round
    for (my $j=0;$j<=$#{$fieldvar{$ff[0]}}; $j++){ # 
	my $y=$fieldvar{$ff[0]}[$j];
	my $dy=$fieldvar{$ff[1]}[$j];
	my $w=1./$dy/$dy;
        $Sumex1+=$w*($y-$avg)**2 ; 
    }# for
    my $sige=sqrt( $n*$Sumex1/($n-1)/$SumW );
    my $chi=(($sige/$sigi)**2) *($n-1);
    print "      $avg +- $sige \n           (internal error= +- $sigi, Xi2=$chi)\n";    
     }# $#ff>=0 ... protect against ghost hash
    return $#ff;


	
    }else{  # ONE FIELD => standart

    my @ff=qw();
    $ff[0]="$OUD";
#    print "In AVG ONEFIELD: $OUD\n";

#   foreach (keys %fieldvar){print "key $_ , hash= $fieldvar{$OUD}\n";}
#    print   " AVG: outputfield=$OUD; hash= @{$fieldvar{$OUD}} ff==@ff\n";
     if ($#ff>=0){

    foreach $i ( @{$fieldvar{$OUD}} ){
	$sum+=$i; $n++;
    }# each
    $av= $sum/$n;  $sum=0;
    foreach $i ( @{$fieldvar{$OUD}} ){
	$sum+=($i-$av)**2; 
    }# each
	printf("%s AVG=%f +- %f\n"," "x $offs, $av, sqrt($sum/($n-1)) );
     }# $#ff>=0 ... protect against ghost hash

    return $av;
}#else
}# AVG



sub MEDIAN{
    my $OUD=shift;
    $OUD=~s/\$//;   $OUD= uc($OUD);  my $i,$sum=0,$n=0,$av;
    if ($OUD=~/[\,\.]/){print "   one field ONLY\n";return 0;}
#   foreach (keys %fieldvar){print "key $_ , hash= $fieldvar{$OUD}\n";}
#    print   " AVG: outputfield=$OUD; hash= @{$fieldvar{$OUD}} \n";
    my @a= @{$fieldvar{$OUD}}; 
    @a=sort{$a <=> $b} @a;
#    print "  SORTED = @a\n";
    if ($#a % 2==0){ 
	$av=$a[$#a/2];
    }else{	
        $av= ($a[$#a/2-0.5]+$a[$#a/2+0.5])/2;
    }
#	printf("%s MEDIAN=%f \n"," "x $offs, $av );
    return $av; 
}




sub SUM{
    my $OUD=shift;
    $OUD=~s/\$//;   $OUD= uc($OUD);  my $i,$sum=0,$n=0,$av;
    if ($OUD=~/[\,\.]/){print "   one field ONLY\n";return 0;}
    my @a= @{$fieldvar{$OUD}}; 

      foreach $i ( @{$fieldvar{$OUD}} ){
	$sum+=$i; $n++;
    }# each
    return $sum; 
}



sub LR{
    my $OUD=shift; $OUD=~s/^\s//; $OUD=~s/\s$//;
    $OUD=~s/\$//;   $OUD= uc($OUD); 
#   foreach (keys %fieldvar){print "key $_ , hash= $fieldvar{$OUD}\n";}
    print   " LR : outputfield=$OUD;  \n";
    my @ff=split/[\s\,]+/,$OUD;
    my ($SumXX,$SumXY,$SumX,$SumY)=(0,0,0,0);
    my ($a,$b,$n);
     if ($#ff>=0){

    $n=$#{$fieldvar{$ff[0]}}+1;
    for (my $j=0;$j<=$#{$fieldvar{$ff[0]}}; $j++){ # 
#     for (my $ii=0;$ii<=$#ff; $ii++){ # different fields
	my $x=$fieldvar{$ff[0]}[$j];
	my $y=$fieldvar{$ff[1]}[$j];
#	print "$x $y\n";
   $SumXY += $x*$y; 
   $SumXX += $x*$x; 
   $SumX += $x; 
   $SumY += $y; 
#     }
    }# for
  $a = ($n*$SumXY - $SumX*$SumY)/($n*$SumXX - $SumX*$SumX); 
  $b = ($SumY - $a*$SumX)/$n; 
     }# $#ff>=0 ... protect against ghost hash

    print "  Dumb Linear Regression  y = a*x + b;   b+a*  :\n  a=$a\n  b=$b\n";
    return $#ff;
}# sub







sub FILLF{
    my $OUD=shift;
    my ($n,$from,$step)=@_;
#    if ($OUD=~/^\s/){$OUD=shift;}
    $OUD=~s/\$//;   $OUD= uc($OUD);  $OUD=~s/\s+//g;
#    $OUD=~s/^\s+//; $OUD=~s/\s+$//;
    
#   foreach (keys %fieldvar){print "key $_ , hash= $fieldvar{$OUD}\n";}
    print   " FILLF : outputfield=$OUD;  n, from, step = $n, $from, $step \n";
#    my @ff=split/[\s\,]+/,$OUD;
    my $ff=$OUD;
#####    $ff[0]=lc($ff[0]); # FILE lowercase :(
     @fieldvar{$ff}=qw(); # field

    if ($step!=0){#print "reading columns\n";
	 for (my $ii=0;$ii<=$n; $ii++){
	     push @{$fieldvar{$ff}},$from+$ii*$step;
#	     print " @{$fieldvar{$ff}} \n";
         }
     }
	     print "@{$fieldvar{$ff}}\n";
    return $#{$fieldvar{$ff}}; 
}#sub






sub READF{
    my $OUD=shift;
#    if ($OUD=~/^\s/){$OUD=shift;}
    $OUD=~s/\$//;   $OUD= uc($OUD);  $OUD=~s/\s+//g;
#    $OUD=~s/^\s+//; $OUD=~s/\s+$//;
    
#   foreach (keys %fieldvar){print "key $_ , hash= $fieldvar{$OUD}\n";}
    if ($debug>=0) {print   " READF : inputfield=$OUD; hash= @{$fieldvar{$OUD}} \n";}
    my @ff=split/[\s\,]+/,$OUD;
     if ($#ff>=0){

    $ff[0]=lc($ff[0]); # FILE lowercase :(
    if ( -e $ff[0] ){
	$ff[0]=$ff[0];
    }else{
	$ff[0]=$ff[0].".calcpl";
    }
    for (my $ii=1;$ii<=$#ff; $ii++){ @fieldvar{$ff[$ii]}=qw(); }
    print "opening file=$ff[0],  # fields to read=$#ff (@ff[1..$#ff]). value list should follow \n ";
    if ( -e $ff[0] ){
    open IINN,"$ff[0]" ||  print "file $ff[0] doesnot exist !!!!\n";
    }else{
	print " ... File  $ff[0] doesnot exist\n";
    }
    if ($debug>0){print "file opened  #ff= $#ff\n";}
    if ($#ff>=1){ 
	if ($debug>0){print "reading columns (entering while)\n";}
    while (<IINN>){   
	if ($debug>0){print "inside  while\n";}
	if ($debug>0){	print " line=$_ ... \n";}
  	 next if ($_=~/^[\#\;cC\*\/]/); # COMMENT CHARACTERS
	 $_=~s/^[\s]+//;  #remove spaces at begining
#	 $_=~s/^[\W\-]+//; # removes minus!!!
#	 split/[\s,]/
	 my @nums=split/[^\.\-\deE\+]+/,$_;
 	 print "@nums\n";
	 for (my $ii=1;$ii<=$#ff; $ii++){
	     if ($debug>0){print "inc $ff[$ii] by $nums[$ii-1] ";}
	     push @{$fieldvar{$ff[$ii]}},$nums[$ii-1];
			      if ($debug>0){print "$ff[$ii]:$nums[$ii-1]  ";}
         }
			      if ($debug>0){print "\n";}
    }# while IINN
    }#reading columns #ff>1
####    else{print "reading row (NOT DONE)\n"; }
    close IINN;
    print "file closed  (if no values listed - check the filename)\n";
#    print " $ff[1], @{$fieldvar{$ff[1]}} \n";
#    print " $ff[2], @{$fieldvar{$ff[2]}} \n";
 #    for (my $ii=1;$ii<=$#ff; $ii++){
#	     print "$ff[$ii]: @{$fieldvar{$ff[$ii]}}\n";
  #       }

     }# $#ff>=0 ... protect against ghost hash

    return $#ff; 
}









sub WRITEF{
    print "at writef== <@_>\n";

    my $OUD=shift;    $OUD=~s/\$//;  $OUD=~s/^\s+//;  $OUD=~s/\s+$//; $OUD=~s/\s+//;
    my @ffqq=split/[\s\,]+/,$OUD;
#20141218 - i added lowecase writef: to make writef and readf compat.
    my $name= lc($ffqq[0]).".calcpl";

    $OUD= uc($OUD); 
#   foreach (keys %fieldvar){print "key $_ , hash= $fieldvar{$OUD}\n";}
#    print   " WRITEF : outputfield=$OUD;  \n";
    my @ff=split/[\s\,]+/,$OUD;

     if ($#ff>=0){

#    $ff[0]=lc($ff[0]); # FILE lowercase :(
#    my $name=lc($ff[0]).".calcpl";
########BIG PROBLEM WITH FILE LOWERCASE: TRY NORMAL....
#before!    my $name= $ff[0].".calcpl";

#    for (my $ii=1;$ii<=$#ff; $ii++){ @fieldvar{$ff[$ii]}=qw(); }
    print "opening file=<$name>,  # fields to WRITEF=$#ff (@ff[1..$#ff])\n";

    my @ff=split/[\s\,]+/,$OUD;

    open OOUT,">$name";
    for (my $j=0;$j<=$#{$fieldvar{$ff[1]}}; $j++){ 
     for (my $ii=0;$ii<=$#ff-1; $ii++){ 
#	 my $prfstrF="%10".".".$precis."f\t";
	 my $prfstrF="%e\t";
         printf OOUT $prfstrF,$fieldvar{$ff[$ii+1]}[$j]; 
         printf  $prfstrF,$fieldvar{$ff[$ii+1]}[$j]; 
     }
     print OOUT "\n";
    }
    close OOUT;
    
    print "\nfile closed\n";
    print `ls -l $name`;

 #    for (my $ii=1;$ii<=$#ff; $ii++){
#	     print "$ff[$ii]: @{$fieldvar{$ff[$ii]}}\n";
  #       }
          }# $#ff>=0 ... protect against ghost hash

    return $#ff; 
}





sub PRINTF{

   my $OUD=shift; $OUD=~s/^\s//; $OUD=~s/\s$//;
    $OUD=~s/\$//;   $OUD= uc($OUD); 
#   foreach (keys %fieldvar){print "key $_ , hash= $fieldvar{$OUD}\n";}
    print   " PRINTF : outputfield=$OUD;  \n";
    my @ff=split/[\s\,]+/,$OUD;

     if ($#ff>=0){
    for (my $j=0;$j<=$#{$fieldvar{$ff[0]}}; $j++){# $#{$fieldvar{$ff[0]}} can create hash ""
####	print "$j - allfieldvar in printf\n";
     for (my $ii=0;$ii<=$#ff; $ii++){ 
	 my $Q=&display_precision_game($fieldvar{$ff[$ii]}[$j]);
	 $Q=~s/\n/\t/g; $Q=~s/^\s+/ /; $Q=~s/\s+$/ /;  	 print $Q;
	 my $prfstrF="%10".".".$precis."e\t";
        printf($prfstrF,$fieldvar{$ff[$ii]}[$j]); 
     }
     print "\n";
    }
     }# $#ff>=0 ... protect against ghost hash

#&display_fields("C");print "<",keys %fieldvar,">\n";
#??    &BIGBADABUM( $fieldvar{$ff[0]}, $fieldvar{$ff[1]} );
    return $#ff; 
}








#######################
#   original  drawf that uses postscript.
#
sub DRAWOF{
    my $OUD=shift; $OUD=~s/^\s//; $OUD=~s/\s$//;
    $OUD=~s/\$//;   $OUD= uc($OUD); 
# foreach (keys %fieldvar){print "key $_ , hash= $fieldvar{$OUD}\n";}
    my @ff=split/[\s\,]+/,$OUD;
     if ($#ff>=0){

    print   " DRAWFORIG : outputfield=$OUD;  fields = $#ff\n";    
    if ($#ff==1){&BIGBADABUM( $fieldvar{$ff[0]}, $fieldvar{$ff[1]} );}
    if ($#ff==2){&BIGBADABUM( $fieldvar{$ff[0]}, $fieldvar{$ff[1]}, $fieldvar{$ff[2]} );}
    if ($#ff==3){&BIGBADABUM( $fieldvar{$ff[0]}, $fieldvar{$ff[1]}, $fieldvar{$ff[2]}, $fieldvar{$ff[3]} );}
#    print "KUKU\n";
#   &BIGBADABUM( $fieldvar{$ff[0]}, $fieldvar{$ff[1]} );
     }# $#ff>=0 ... protect against ghost hash

 return $#ff; 
}









#######################################################
#   plot data using xmgrace
#
sub DRAWF{
    print "at drawf== <@_>\n";
    my @origparam=@_;
    my $OUD=shift; $OUD=~s/^\s//; $OUD=~s/\s$//; $OUD=~s/\$//;   
    my @ffqq=split/[\s\,]+/,$OUD;

    $OUD= uc($OUD); 
# foreach (keys %fieldvar){print "key $_ , hash= $fieldvar{$OUD}\n";}
    my @ff=split/[\s\,]+/,$OUD;
    print   " DRAWF : outputfield=$OUD;  fields = $#ff\n";    
############### arange and print out the fields 
     if ($#ff>=0){


    my $xaxislabel=$ff[0];  # x
    my $leg0=$ff[1];        # legend
    my $xydytype;
    if ($#ff==1){ $xydytype="\@type xy";}    
    if ($#ff>=2){ $xydytype="\@type xydy";}
    my $si=$xmgrace[3]; # 0,1,...   @s0 legend;   @target s0
    $xmgrace[3]++;

$aaa="#MY GUESS OF PARAMETERS 2
\@page size 600, 450
\@timestamp on
\@    subtitle \"fields <@origparam>\"
\@    legend 0.2, 0.8
\@    xaxis  label \"x axis: $xaxislabel\"
\@    yaxis  label \"y axis \"
\@    s0 symbol 2
\@    s0 line linestyle 0
\@    s1 symbol 3
\@    s1 line linestyle 0
\@    s2 symbol 4
\@    s2 line linestyle 0
\@    s3 symbol 5
\@    s3 line linestyle 0
\@    s4 symbol 6
\@    s4 line linestyle 0
####\@type xydy
\@    s$si legend  \"$leg0\"
\@    target s$si
$xydytype
";
#
# good to make check if 's0' is already there (put si+1)
#

#    my $grfile="/tmp/calc.drawf.xmgrace";
    my $grfile=$xmgrace[2]; # FILE
### NEW GRAPH
    print "opening ad appending xmgrace file <$grfile>\n";
open OUT,">>$grfile"; 
print OUT $aaa;
print OUT 
close OUT;
#APPEND DATA

##
#  to append the data to the existing headers: I use a function WRITEF
#  - unfortunately it appends .calcpl
# THEN I concat the two files...
#
#    my $wrfile="/tmp/calc.writef.xmgrace"; #POZOR .calcpl
    my $wrfile="$cwd/calc.writef.xmgrace"; #POZOR .calcpl
    # x,y,dy,  y2,dy2,  y3,dy3      :     3 nebo 5 nebo 7 ...
    # po trojicich x,y,dy
    #&
    #              x,y2,dy2
    WRITEF( "$wrfile,@origparam" );
##    print `ls -ltrh`;
    `cat $wrfile.calcpl >> $grfile`;

############### run xmgrace 1st ##############################
    if ($XmgON==1){
    print "xmgrace tests    ... $xmgrace[0] $grfile ... exit xmgrace to continue.... \n";
    my $gv=`$xmgrace[0] $grfile`;my $outg=$?;
    }

#    print "result of the comand == $outg\n";
######    `rm $grfile`;
    print "konec XMGRACE\n";#############################


#
#    if ($#ff==1){&BIGBADABUM( $fieldvar{$ff[0]}, $fieldvar{$ff[1]} );}
#    if ($#ff==2){&BIGBADABUM( $fieldvar{$ff[0]}, $fieldvar{$ff[1]}, $fieldvar{$ff[2]} );}
#    if ($#ff==3){&BIGBADABUM( $fieldvar{$ff[0]}, $fieldvar{$ff[1]}, $fieldvar{$ff[2]}, $fieldvar{$ff[3]} );}
###    print "KUKU\n";
###   &BIGBADABUM( $fieldvar{$ff[0]}, $fieldvar{$ff[1]} ); 
    }# $#ff>=0 ... protect against ghost hash
    else{ # we can run xmgrace if no fields.....

     ############### run xmgrace 2nd ##############################
#    if ($XmgON==1){
	print "setting xmgraceON() from now...\n";
	$XmgON=1 ;
    my $grfile=$xmgrace[2]; # FILE
    print "xmgrace tests    ... $xmgrace[0] $grfile ... exit xmgrace to continue.... \n";
    my $gv=`$xmgrace[0] $grfile`;my $outg=$?;
#    }#xmgron

    }# else
 return $#ff; 
}



#
# READCSV HERE
#

sub READCSVF{
    my $OUD=shift;
#    if ($OUD=~/^\s/){$OUD=shift;}
    $OUD=~s/\$//;    $OUD=~s/\s+//g;
    $OUD= uc($OUD); 
#    $OUD=~s/^\s+//; $OUD=~s/\s+$//;
    print   " READCSVF : outputfield=$OUD; hash= @{$fieldvar{$OUD}} \n";
#   foreach (keys %fieldvar){print "key $_ , hash= $fieldvar{$OUD}\n";}
    if ($debug>0) {print   " READCSVF : outputfield=$OUD; hash= @{$fieldvar{$OUD}} \n";}
    my @ff=split/[\s\,]+/,$OUD;
     if ($#ff>=0){
    $ff[0]=lc($ff[0]); # FILE lowercase :(
    $ff[0]=$FileNameSeen;  # RISK!!!!!!!!!1
    for (my $ii=1;$ii<=$#ff; $ii++){ @fieldvar{$ff[$ii]}=qw(); }
    print "opening file=$ff[0]\n";
   
    ## test the presence of "calc.pl.variables"    and  "calc.pl.stop"
    my $ioi=0;my $ioi2=0; $ioi3=999999; #maximum lines (crazy)
    open IINN,"$ff[0]"; 
    while (<IINN>){$
		       ioi++;
		   if (/calc\.pl\.variables/){
		       $ioi2=$ioi;print " MARKER calc.pl.variables found at line $ioi\n";
#		       last;
		   }
		   if (/calc\.pl\.stop/){
		       $ioi3=$ioi;print " MARKER calc.pl.stop found at line $ioi\n";
#		       last;
		   }
    } 
    close IINN;

    ## really open and parse
    open IINN,"$ff[0]" ||  print "file $ff[0] doesnot exist !!!!\n";
    if ($debug>0){print "file opened  #ff= $#ff\n";}
######inserted thing from test CSV readout###############

my $fline;$ioi=0;
   while($ioi<$ioi2) {$fline=<IINN>;chop($fline);$ioi++;}
    $fline=~s/calc\.pl\.variables//; #  no variable like this (complete mess)
#impossible to use due to connection to fields-values
####################################
#     #remove spaces.....	   #
#     $fline=~s/\s//g;		   #
# # remove multiple ,		   #
#     $fline=~s/\,\,\,\,\,\,/\,/g; #
#     $fline=~s/\,\,\,\,\,/\,/g;   #
#     $fline=~s/\,\,\,\,/\,/g;	   #
#     $fline=~s/\,\,\,/\,/g;	   #
#     $fline=~s/\,\,/\,/g;	   #
#     $fline=~s/\,\,/\,/g;	   #
#     $fline=~s/\,\,/\,/g;	   #
#     #remove all ,  @ start	   #
#     $fline=~s/^\,//g;		   #
####################################

my @names=split/,/,$fline;
#
#  prepare variables: UPPERCASE, remove \"\" (from gnumeric...)
#
    foreach (@names){ $_=uc($_); $_=~s/\"//g;}
    print "VARIABLES:\n@names\n\n";
    foreach (@names){
	if ($_=~/^[\w\d]+/){
	print "VARIABLE <$_>:\n";
	print "@{$fieldvar{  $_  }} \n";
	@{$fieldvar{  $_  }}=qw();  # THIS MAY BE ALLRIGHT TO ZERO IT
	print "@{$fieldvar{  $_  }} \n";
	}else{
	print "VARIABLE <$_>:  BAD\n";
	}
    }# DELETE ALL VARIABLES

my $row=1;
while ($line=<IINN>){
    $ioi++;
    last if($ioi>=$ioi3);###  WHEN YOU SEE THE LINE WITH "calc.pl.stop" - END IMMEDIATELY
    print $row++,".";
    chop($line);
my    @vals=split/,/,$line;
#    print "@vals";
################################################################3
#    for (my $i=0;$i<=$#names;$i++){
#            # 1st PASS==CLEARALL PREVIOUS VALUES
#	    if ($i==0){ @{$fieldvar{  $names[$i]  }}=qw();}	
#    }
#################################################################3
    for (my $i=0;$i<=$#names;$i++){
#	print "  $names[$i]==$vals[$i]  ";
	if ( (length($names[$i])>0)&&($names[$i]=~/^[\w\d]+/)){ # NOT empty <>
	    print "$names[$i]==$vals[$i] ";
	    push @{$fieldvar{  $names[$i]  }}, $vals[$i];
	}else{
#	    print $vals[$i],"X";
	}
    }
    print "\n";
}

#close IINN;


    if ($#ff>=1){ 
	if ($debug>0){print "reading columns (entering while)\n";}
    while (<IINN>){   
	if ($debug>0){print "inside  while\n";}
	if ($debug>0){	print " line=$_ ... \n";}
  	 next if ($_=~/^[\#\;cC\*\/]/); # COMMENT CHARACTERS
	 $_=~s/^[\s]+//;  #remove spaces at begining
#	 $_=~s/^[\W\-]+//; # removes minus!!!
#	 split/[\s,]/
	 my @nums=split/[^\.\-\deE\+]+/,$_;
 	 print "@nums\n";
	 for (my $ii=1;$ii<=$#ff; $ii++){
	     if ($debug>0){print "inc $ff[$ii] by $nums[$ii-1] ";}
	     push @{$fieldvar{$ff[$ii]}},$nums[$ii-1];
			      if ($debug>0){print "$ff[$ii]:$nums[$ii-1]  ";}
         }
			      if ($debug>0){print "\n";}
    }# while IINN
    }#reading columns #ff>1
####    else{print "reading row (NOT DONE)\n"; }
    close IINN;
    print "file closed  (if no values listed - check the filename)\n";
#    print " $ff[1], @{$fieldvar{$ff[1]}} \n";
#    print " $ff[2], @{$fieldvar{$ff[2]}} \n";
 #    for (my $ii=1;$ii<=$#ff; $ii++){
#	     print "$ff[$ii]: @{$fieldvar{$ff[$ii]}}\n";
  #       }    
 }# $#ff>=0 ... protect against ghost hash

    return $#ff; 
}







#@x=qw(-5 2 3 4 0.005);
#@y1=qw(111 2.1 34 410 5.123);
#@y2=qw(1 2 3 4 5);
#@y3=qw(8 7 8 9 100000);
#&BIGBADABUM(\@x,\@y1,\@y2,\@y3);


sub LATEXF{
    my $OUD=shift;
    $OUD=~s/\$//; $OUD=~s/\s+//;  $OUD= uc($OUD); 
#   foreach (keys %fieldvar){print "key $_ , hash= $fieldvar{$OUD}\n";}
#    print   " LATEXF : outputfield=$OUD; hash= @{$fieldvar{$OUD}} \n";
    print   " LATEXF : set precis=2  if you want \n";
    my @ff=split/[\s\,]+/,$OUD;    my $tab;
     if ($#ff>=0){

    $PrintRes1=sprintf("\\documentclass[12pt]{article}
\\pagestyle{empty}
\\begin{document}
\\begin{table}[!ht]
\\centering{\\begin{tabular}{*{%d}{|c}|}
\\hline \n", $#ff+1 );
    

     for (my $ii=0;$ii<=$#ff; $ii++){ 
	 if ( $ii==$#ff){$tab="  \\\\  \\hline\n"}else{$tab=" & ";}
            $PrintRes1.=sprintf("%s%s","$ff[$ii]\t",$tab);
     }
#print "\\hline\n";
    for (my $j=0;$j<=$#{$fieldvar{$ff[0]}}; $j++){ 
     for (my $ii=0;$ii<=$#ff; $ii++){ 
#         my $prfstrF;
#	 if ($precis>0){ $prfstrF="%10".".".$precis."f  ";}
#                    else{$prfstrF="%f  ";}
	 if ( $ii==$#ff){$tab="  \\\\  \\hline"}else{$tab=" & ";}
#         printf($prfstrF.$tab,$fieldvar{$ff[$ii]}[$j]); 
	 my $Q=&display_precision_game($fieldvar{$ff[$ii]}[$j]);
	 $Q=~s/\n/\t/g; $Q=~s/^\s+/ /;  $Q=~s/\s+$/ /;
	 $PrintRes1.=sprintf("%s%s", $Q,$tab);
     }
     $PrintRes1.=sprintf("%s", "\n");
    }
     $PrintRes1.=sprintf("%s", "\\end{tabular}
\\caption{..................... \\label{label} }
}
\\end{table}
\\end{document}
\n");   
  }# $#ff>=0 ... protect against ghost hash
    print $PrintRes1;
    open OUT,">calc.latexf.tex";
    print OUT $PrintRes1;
    close OUT;
    print "....latexing\n";
    print `latex calc.latexf.tex`;
    print "....converting to png\n";
    print `convert    -density 300x300   calc.latexf.dvi      -trim  -alpha extract    -negate calc.latexf.png`;
    print "....gqviewing\n";
    `gqview calc.latexf.png`;
    print "done\n";
#latex exco15.tex
#convert    -density 300x300   exco15.dvi      -trim  -alpha extract    -negate exco15.png ; gqview exco15.png

    return $#ff; 
}





sub SORTF{
    my $OUD=shift;  my $k;
    $OUD=~s/\$//;   $OUD= uc($OUD); 
#   foreach (keys %fieldvar){print "key $_ , hash= $fieldvar{$OUD}\n";}
#    print   " SORTF : outputfield=$OUD; hash= @{$fieldvar{$OUD}} \n";
    print   " SORTF : outputfield=$OUD;  \n";
    my @ff=split/[\s\,]+/,$OUD;
        if ($#ff>=0){


    for (my $j=0;$j<=$#{$fieldvar{$ff[0]}}; $j++){ # this goes to maxn
    for (my $k=$j;$k<=$#{$fieldvar{$ff[0]}}; $k++){ # this goes to maxn
	if  ($fieldvar{$ff[0]}[$j] > $fieldvar{$ff[0]}[$k]){

     for (my $ii=0;$ii<=$#ff; $ii++){ 
	 ( $fieldvar{$ff[$ii]}[$j], $fieldvar{$ff[$ii]}[$k] )= 
         ( $fieldvar{$ff[$ii]}[$k], $fieldvar{$ff[$ii]}[$j] );
     }

	}#if
   }}#for for    
 }# $#ff>=0 ... protect against ghost hash

    return $#ff; 
}

sub SORTREVF{
    my $OUD=shift;  my $k;
    $OUD=~s/\$//;   $OUD= uc($OUD); 
#   foreach (keys %fieldvar){print "key $_ , hash= $fieldvar{$OUD}\n";}
    print   " SORTREVF : outputfield=$OUD;  \n";
    my @ff=split/[\s\,]+/,$OUD;
        if ($#ff>=0){


    for (my $j=0;$j<=$#{$fieldvar{$ff[0]}}; $j++){ # this goes to maxn
    for (my $k=$j;$k<=$#{$fieldvar{$ff[0]}}; $k++){ # this goes to maxn
	if  ($fieldvar{$ff[0]}[$j] < $fieldvar{$ff[0]}[$k]){

     for (my $ii=0;$ii<=$#ff; $ii++){ 
	 ( $fieldvar{$ff[$ii]}[$j], $fieldvar{$ff[$ii]}[$k] )= 
         ( $fieldvar{$ff[$ii]}[$k], $fieldvar{$ff[$ii]}[$j] );
     }

	}#if
   }}#for for 
    }# $#ff>=0 ... protect against ghost hash

    return $#ff; 
}






############################################# END OF FUNCTIONS
############################################# END OF FUNCTIONS
############################################# END OF FUNCTIONS
############################################# END OF FUNCTIONS
############################################# END OF FUNCTIONS







###############################################
#      E N D       O F     C O D E
##############################################






########################################################
########################################################
#
# It is much better when it is structured
#          SO - lets start with procedures HERE
#
########################################################
########################################################


 sub dod{ 
print "default operation defined: $Defoperat (-x is operation!, not a negative number)\n";}


################################################# DISPLAY
################################################# DISPLAY
################################################# DISPLAY


sub display2{  # uses display_precision_game useful for the others
 my $NUM;
 # GETS Res, (nowar)
 if ($Line=~/[=\-]/){
   if ($Linemark eq "="){ 
       $Res=0; $Line.=" AC"; 
       # I hope that here is CLEAR: remove xmgrace
       if ( (-e $xmgrace[2])){
          print "removing $xmgrace[2] \n";
	  `rm $xmgrace[2]`;
	  $xmgrace[3]=0;#reset set_i
       }
   }  # IN CASE OF ==== line ... ZERO xxx
   printf("%s\n",$Line);
 }else{ #---- ok, line is not "---------" neither "=============="
  $NUM=&display_precision_game(@_); printf $NUM;
 }
}#SUB


sub display{
    my $Res=shift;
    my $nowar=shift || 0; # if 1==> no warning
#======================  find decimal point.
 $sres=sprintf("%f",$Res);
 $len=length($sres);
 $ppos=index($sres,'.');

# print "$sres .. $len .. $ppos ,,";
 $spa="";
# while (length($spa)<$offs+$len) {$spa.=" ";}
#-----------=========-------   add spaces
 while (length($spa)+$ppos<$offs) {$spa.=" ";}

#--==============----------- print result//////////////

#  dostri == string after the result = Warning string (DO, substract, ...)
#  spa (see above) is just space to put before
 if ($Defoperat ne ""){$dostri="\t\t..DO";}else{$dostri="";}
 if  ($nowar!=1){ $dostri.=$Warning;}



#-------  if line IS ---------- OR ============ only
 if ($Line=~/[=\-]/){
   if ($Linemark eq "="){ $Res=0; $Line.=" AC"; }  # IN CASE OF ==== line ... ZERO xxx
   printf("%s\n",$Line);


 }else{ #---- ok, line is not "---------" neither "=============="

     #_________ play with precision ____ PREPARE DISPLAY FORMAT
         $prfstrE="%s%.".$precis."e %s\n";
         $prfstrF="%s%.".$precis."f %s\n";
#       print "E=$prfstrE\n";       print "F=$prfstrF\n";
     #______________  go to the exponential format ______
#     $magnl=3; $magnh=5; # DEFINED in the begining......
     my $magnlx="1E-".$magnl; my $magnhx="9.999E+".$magnh;
     if (abs($Res)<$magnlx ||  abs($Res)>$magnhx){ 
	 #   play with alignment ..... dec .6 = offs-1
#       printf("%s%.6e %s\n"," "x ($offs-1), $Res,$dostri); # !!! TO REDO 5->variable
       printf($prfstrE," "x ($offs-1), $Res,$dostri); # DISPLAY EXPON
     }else{
#       printf("%s%.8f %s\n",$spa,$Res,$dostri);
       printf($prfstrF,$spa,$Res,$dostri); #DISPLAY FLOAT
     }
   if ($debug>0){print "debug defoperat,DO: $Defoperat,   $DO,\n";}
 }

}# end of DISPLAY ##############################################




sub display_precision_game{
    my $NUM="";

    my $Res=shift;
    my $nowar=shift || 0; # if 1==> no warning
#======================  find decimal point.
 $sres=sprintf("%f",$Res);
 $len=length($sres);
 $ppos=index($sres,'.');

# print "$sres .. $len .. $ppos ,,";
 $spa="";
# while (length($spa)<$offs+$len) {$spa.=" ";}
#-----------=========-------   add spaces
 while (length($spa)+$ppos<$offs) {$spa.=" ";}
     #_________ play with precision ____ PREPARE DISPLAY FORMAT
         $prfstrE="%s%.".$precis."e %s\n";
         $prfstrF="%s%.".$precis."f %s\n";
#       print "E=$prfstrE\n";       print "F=$prfstrF\n";
     #______________  go to the exponential format ______
#     $magnl=3; $magnh=5; # DEFINED in the begining......
     my $magnlx="1E-".$magnl; my $magnhx="9.999E+".$magnh;
     if (abs($Res)<$magnlx ||  abs($Res)>$magnhx){ 
	 #   play with alignment ..... dec .6 = offs-1
#       printf("%s%.6e %s\n"," "x ($offs-1), $Res,$dostri); # !!! TO REDO 5->variable
       $NUM=sprintf($prfstrE," "x ($offs-1), $Res,$dostri); # DISPLAY EXPON
     }else{
#       printf("%s%.8f %s\n",$spa,$Res,$dostri);
        $NUM=sprintf($prfstrF,$spa,$Res,$dostri); #DISPLAY FLOAT
     }    
    return $NUM;
}










sub display_fields{
#__________________ diplay status _______________________
 print "\ndisplay_fields....",shift,"\n";
 my $ii=0;
     foreach (sort keys %fieldvar){#______ DISPLAY STATUS ______
	 $ii++;
	$,=" "; # !!! maters with the line cmd!!!
#        print " "x 10,"field $_ contains (",@{$fieldvar{$_}},")\n";
	 print "$ii ";
        printf("%-10s\t",$_ );
	print " (",@{$fieldvar{$_}},")\n";
	$,=""; # !!! maters with the line cmd!!!
     }
}# display fields DEBUG  routine







sub process_field_via_map{
 #___________________ PROCESS 1 field-VARIABLE ______ via MAP ______
     if ($nfields>1){ print "  $ff.. sorry, I cannot handle  $nfields fields in one expression\n";}

 if ($nfields==1){
 #print "  $ff..  I can handle  $nfields fields in one expression\n";
  if ($OUTPUTFIELD ne ""){ # remove assignment if there is an =assignment=
     $xXx=~s/[a-z]+=//i;
  }
 foreach $Ff (keys %fieldvar){
     if ($xXx=~/$Ff\s*=\s*\([\d\,\.\-\sE]+\)$/i ){  ## contains  assignment 
#	 $Warning.=" fld-asgn ";
	 $xXx=$#{$fieldvar{$Ff}}+1;#MANDATORY beware KEY!
     }elsif($nfields>1){ # too many for now
     }elsif($xXx=~/$Ff/i){ # contains operation
       $Warning.=" = #elms ";
       $xXx=~s/($Ff)/\$\_/gi;   #---prepare for map with $_
       # here was a problem... must redo it...
       @res=map {eval($xXx)} @{$fieldvar{$Ff}};
    #   print "source:",@{$fieldvar{$Ff}},"  expres: $xXx result=@res\n";

#============= DISPLAY ================
       print " "x 10,"(@res)\n"; my $rror;
       my @tmp=qw();
       foreach $rror (@res){
	   my $Warning1=$Warning; $Warning="";
	   &display($rror);
	   $Warning=$Warning1;
	   push @tmp,$rror;
       }
           if ($OUTPUTFIELD ne ""){
#	       if (exists $fieldvar{$OUTPUTFIELD})
#                    { delete $fieldvar{$OUTPUTFIELD};}
             $fieldvar{$OUTPUTFIELD}=\@tmp;
           }
   	   print($spa."-------\n");
           $xXx=$#res+1;
     }# elsif contains operation_______________
#  print " changed fields ... $xXx";
     }# for keys %
 }# if nfields==1
}#end process field via map==================





######################"" key procedure to process the field
#   it must recognize &COS(COS)
#   \b == word boundary
#
sub process_field{
    my ($Ff,$i_elem,$sds_);
 if ($nfields>0){
  my $backxXx=$xXx; 
  foreach $Ff (keys %fieldvar){ #====> replace with reference to element
#     $xXx=~s/(\b)$Ff(\b)/\1\$\{\$fieldvar\{$Ff\}\}[\$i_elem]\2/g;
#
##    cos=(1,2,3)
##    cos(cos) ==>>   &COS( replacement )
#
     $xXx=~s/([^&])(\b)$Ff(\b)/\1\2\$\{\$fieldvar\{$Ff\}\}[\$i_elem]\3/g;
     if ($debug>=1){print "    making    one element:$xXx\n";}
 }# all keys conv to element

 my @tmp=qw(); 
                 # to say display, that the last result was something
  $Linemark="";  $Line="";
 for ($i_elem=0; $i_elem<$OUTPUTDIM;$i_elem++){# go through it
              #  $xXx='${$fieldvar{F}}[$i_elem] + ${$fieldvar{D}}[$i_elem]'; 
   $sds_=eval($xXx);
   $tmp[$i_elem]=$sds_; #print "outfield=$OUTPUTFIELD ..temp=@tmp\n\n";
#   print "i=$i_elem ....$xXx....$sds_\n";

 if ($debug>=1){print "input line after processin4.1(pfdisp):$xXx\n";}
   &display($sds_, 1); # each field element, 1== no warning!
 if ($debug>=1){print "input line after processin4.2(pfdisp):$xXx\n";}
 }# EVAL for
 #================= Bring to assigned field
           if ($OUTPUTFIELD ne ""){
       #    print "HEY! outfield=$OUTPUTFIELD ..temp=@tmp\n";
             $fieldvar{$OUTPUTFIELD}=\@tmp;
           }
   	   print($spa."-------\n");
           $xXx=$OUTPUTDIM;
           # $xXx= $backxXx;
 }#end of eval fieldop....................NFIELDS >0    => act

}


sub exit_with_history{
    my $q=shift @_ || 1; # 1==exit 
     open OUT,">$ENV{HOME}/.calc.pl" || die ".calc.pl not opened..";
     my $hicount=0;
     foreach (@history) {$hicount++;
              if ($_=~/\S/ and ($#history-$hicount)<50){print OUT "$_\n";}}
     close OUT;
     close TTY;
     system "stty  -cbreak   </dev/tty >/dev/tty 2>&1"; 
    if ($q==1){  # normal exit  :  if -1 => usin die afterwards...
     print "exiting, history written...\n";
     print `echo -e  "\\033]0;Terminal\\a\\c"`; # make term title "calc.pl" 
     exit 0;
    }
}


sub catchupsig{ my $sig=shift; 
 print `echo -e  "\\033]0;xterm\\a\\c"`; # make term title "calc.pl" 
 &exit_with_history(-1);
 die "quiting via SIG:$sig...\n";
}# End correctly with C-c

























#@x=qw(-5 2 3 4 0.005);
#@y1=qw(111 2.1 34 410 5.123);
#@y2=qw(1 2 3 4 5);
#@y3=qw(8 7 8 9 100000);
#&BIGBADABUM(\@x,\@y1,\@y2,\@y3);




#########################################################
#########################################################
#
#   REALLY BIG BIG BADA BUM  ---   postscript generator
#    (good name for a comprehension to the function)
#
#
#########################################################
#########################################################

sub BIGBADABUM{
    my @qqq=@_;
    my (@x,@y1,@y2,@y3);
    @x=@{$qqq[0]};
    @y1=@{$qqq[1]};
    if ($#qqq>=1){@y2=@{$qqq[2]};}else{@y2=qw();}
    if ($#qqq>=2){@y3=@{$qqq[3]};}else{@y3=qw();}
#    print "@x\n @y1\n @y2 \n@y3\n";

################################" physical EPS
my ($x0,$y0,$x1,$y1, $dx)=(150,150,450,450,40); # basic EPS dimensions
my $rr=0.1;  # frame a bit bigger

############################## workout the arrays
    my $e;
my $xmin=$x[0];  my $xmax=$x[0];
my $ymin=$y1[0]; my $ymax=$y1[0];
foreach $e (@x){   if ($e<$xmin){$xmin=$e;} if ($e>$xmax){$xmax=$e;}   }
foreach $e (@y1){  if ($e<$ymin){$ymin=$e;} if ($e>$ymax){$ymax=$e;}   }
foreach $e (@y2){  if ($e<$ymin){$ymin=$e;} if ($e>$ymax){$ymax=$e;}   }
foreach $e (@y3){  if ($e<$ymin){$ymin=$e;} if ($e>$ymax){$ymax=$e;}   }

print "    minmax  x, y($xmin,$xmax,$ymin,$ymax)\n";
my $xmin1=$xmin-$rr*($xmax-$xmin);my $xmax1=$xmax+$rr*($xmax-$xmin);
my $ymin1=$ymin-$rr*($ymax-$ymin);my $ymax1=$ymax+$rr*($ymax-$ymin);
print "    minmax  x, y($xmin1,$xmax1,$ymin1,$ymax1)\n";
 $Ax= ($x1-$x0)/($xmax1-$xmin1);  $Bx= +$x0-$xmin1*$Ax;
 $Ay= ($y1-$y0)/($ymax1-$ymin1);  $By= +$y0-$ymin1*$Ay;

my $msx=($xmax1-$xmin1)*0.015;  # MARKER SIZE x
my $msy=($ymax1-$ymin1)*0.015;  # MARKER SIZE y

################################################################
##                     S T A R T                            ####

my $a=Pscr->new; 
$a->setpal("pc");
$a->sfont(11,"arial");

# outer - white FRAME
$a->sp(0); $a->ro($x0-$dx,$y0-$dx,  $x1+$dx, $y1+$dx); 
$a->sp(1);
#$a->sfont($fnt,5);
# FRAME
#$a->mo($x0,$y0);$a->dr($x1,$y0);$a->mo($x0,$y0);$a->dr($x0,$y1);
$a->ro($x0,$y0,  $x1, $y1); 
#$a->mo($x0,$y0);$a->dr($x1,$y0);$a->mo($x0,$y0);$a->dr($x0,$y1);

if ($ymin<0 and $ymax>0){$a->mo(&transfxy($xmin,0));$a->dr(&transfxy($xmax,0));}
if ($xmin<0 and $xmax>0){$a->mo(&transfxy(0,$ymin));$a->dr(&transfxy(0,$ymax));}


  &ticky($a,$xmin1,$ymin,$msx ,$msy, $ymin );
  &ticky($a,$xmin1,$ymax,$msx ,$msy, $ymax );
  &tickx($a,$xmin,$ymin1,$msx ,$msy, $xmin );
  &tickx($a,$xmax,$ymin1,$msx ,$msy, $xmax );

######################################### PLOT 10blu,13red,11gree
  if( ( ($#y1!=$#x) && ($#y1>=0))||( ($#y1!=$#x) && ($#y1>=0))||( ($#y1!=$#x) && ($#y1>=0)) ){
      print "#################################################\n";
      print "# different number of parameters in fields - check\n";
      print "#################################################\n";
  }else{
for ($i=0; $i<=$#x; $i++){
#  &tickx($x[$i],$ymin ,$msx ,$msy, $x[$i] ); 
  if ($#y1==$#x){  &cross1($a, $x[$i], $y1[$i],$msx ,$msy , 11);}
  if ($#y2==$#x){  &cross2($a, $x[$i], $y2[$i],$msx ,$msy , 10);} 
  if ($#y3==$#x){  &cross3($a, $x[$i], $y3[$i],$msx ,$msy , 13);}
#  print "$#y1 $#y2 $#y3  $a, $x[$i], $y1[$i]      $msx ,$msy  \n"; 
# &cross1($a, $x[$i], $y1[$i],$msx ,$msy , 2);
}#for

my $grfile="graph_calcpl.eps";
my $aaa=$a->tops;open OUT,">$grfile"; print OUT $aaa;close OUT;
    my $GGVV="";
    my $gv=`$gvvi{gv}[0] -v`; if ($? >=0 ) {$GGVV="gv";}else{
	my $ggv=`$gvvi{ggv}[0] --help`;
	if ($? >=0 ) {$GGVV="gv";}
    }

#    print `$gvvi{ggv}[0] --help`," - ggv result ot=$?  \n";
#    print `$gvvi{gv}[0] -v`," - gv result ot=$? \n";

    print "$gvvi{$GGVV}[1]";
`$gvvi{$GGVV}[0] $grfile`;
#`ggv --geometry 600x600  $grfile`;
    if ( -t $grfile ){`rm $grfile`;}

  }#if npar ok

$a->DESTROY();

##############################################################
#       graph ............     related  subroutines 
##############################################################
sub transfxy{
    my($k,$l)=@_;
    my($e,$t)= ($Ax*$k+$Bx,  $Ay*$l+$By);
#    print "($e,$t)\n";
    return ($e,$t);
}
sub tickx{
    my($a,$k,$l,$di,$dii, $txt)=@_;
    $a->mo( &transfxy($k,$l+$dii) ); $a->dr(&transfxy($k,$l-$dii) );
    my($z,$e)= &transfxy($k-$di,$l-$dii);
    $a->mo( $z, $e - 2*$a->wilet() );
    my $ss=sprintf("%.2e",$txt);
    $a->la( $ss );
    $a->sp(1);return 0;}
sub ticky{
    my($a,$k,$l,$di,$dii, $txt)=@_;
    $a->mo( &transfxy($k-$di,$l) );  $a->dr( &transfxy($k+$di,$l) ); 
    my($z,$e)= &transfxy($k-$di,$l-$dii);
    my $ss=sprintf("%.2e",$txt);
    $a->mo( $z - (length($ss)+1)*$a->wilet() , $e  );
    $a->la( $ss );
    $a->sp(1);return 0;}
sub cross1{
    my($a,$k,$l,$di,$dii,$s)=@_;$a->sp($s);
    $a->mo( &transfxy($k-$di,$l-$dii) ); $a->dr( &transfxy($k+$di,$l+$dii) );
    $a->mo( &transfxy($k+$di,$l-$dii) ); $a->dr( &transfxy($k-$di,$l+$dii) );   
    $a->sp(1);return 0;
}
sub cross2{
    my($a,$k,$l,$di,$dii,$s)=@_;$a->sp($s);
    $a->mo( &transfxy($k,$l-$dii) ); $a->dr( &transfxy($k,$l+$dii) );
    $a->mo( &transfxy($k-$di,$l) ); $a->dr( &transfxy($k+$di,$l) );   
    $a->sp(1);return 0;
}
sub cross3{
    my($a,$k,$l,$di,$dii,$s)=@_;$a->sp($s);
    $a->mo( &transfxy($k-$di,$l-$dii/2) );$a->dr( &transfxy($k,$l+$dii) );
    $a->dr( &transfxy($k+$di,$l-$dii/2) );$a->dr( &transfxy($k-$di,$l-$dii/2) ); 
   $a->sp(1); return 0;
}

#########################################################
#########################################################
#
# P S C R 
#
#########################################################
#########################################################


package Pscr;

my @Needs=();  #  global variable
my $ch3;  my $PSend;  my $PSini;

#########################################################
######## NEW, clear, unit, wilet, hilet,adj_bb, getbbox, setbbox
#########################################################

sub new{
    &PSCRinitialize;
 my($proto)=shift; my($class)= ref($proto) || $proto;
 my($self)={};
 bless($self,$class);  # allowed inheritance in future
 $self->clear;
 return $self;
}

sub DESTROY{}

sub clear{
  my $self=shift;
  $self->{LIST}=[];    # included objects
  $self->{TEXT}='12 1 sf '; # Hlavni napln
  $self->{SN}='s';      # stroke, newpath
  $self->{PSX}=0;$self->{PSY}=0;      # current cursor
  $self->{BBOX}=[-1,-1,-1,-1];
  $self->{WILET}=6;  $self->{HILET}=12;
  $self->{PAL}='pc';
  $self->{UNIT}='';
}


sub unit{my  $self=shift;$self->{UNIT}=shift;}
sub wilet{my  $self=shift;return $self->{WILET}}
sub hilet{my  $self=shift;return $self->{HILET}}
sub adj_bb{
 my $self=shift;  my($x,$y)=@_;
 $x=0 if ($x<0); $y=0 if ($y<0);
 if (${$self->{BBOX}}[0]==-1){ @{$self->{BBOX}}=($x,$y,$x,$y); }
 if ($x<${$self->{BBOX}}[0]){ ${$self->{BBOX}}[0]=$x }
 if ($y<${$self->{BBOX}}[1]){ ${$self->{BBOX}}[1]=$y }
 if ($x>${$self->{BBOX}}[2]){ ${$self->{BBOX}}[2]=$x }
 if ($y>${$self->{BBOX}}[3]){ ${$self->{BBOX}}[3]=$y }
}

sub getbbox{
 my $self=shift;
 my(@bb)= @{$self->{BBOX}} ;
 if ( $self->{UNIT} eq 'mm' ){ foreach (@bb) {$_=$_/2.8346}};
 return @bb;
}
sub setbbox{
 my $self=shift;my @e=@_;
 if ( $self->{UNIT} eq 'mm' ){ foreach (@e) {$_=$_*2.8346}};
 $self->{BBOX}=[@e];
}
#########################################################
######################## mo dr dr_cr  ra ro  la
##########  tri
#  arc (x,y,diam/2,startang(deg) ,endang(deg) )
#########################################################
sub mo{                 ###########
 my $self=shift;
 if ($self->{SN} eq 's') {$self->{SN}='n';$self->{TEXT}.='n '}
 my(@xy)=@_; if ( $self->{UNIT} eq 'mm' ){ foreach (@xy) {$_=$_*2.8346}};
 $self->{TEXT}.=sprintf(" %.2f %.2f m\n",@xy);
 ($self->{PSX},$self->{PSY})=(@xy); $self->adj_bb(@xy);
}
sub dr{                 ###########
 my $self=shift;
 if ($self->{SN} eq 's') {$self->{SN} ='n';$self->{TEXT}.="n 0 0 m\n"}
  my(@xy)=@_;  if ( $self->{UNIT} eq 'mm' ){ foreach (@xy) {$_=$_*2.8346}};
 $self->{TEXT}.=sprintf(" %.2f %.2f l\n",@xy);
 ($self->{PSX},$self->{PSY})=@xy;
 $self->adj_bb(@xy);
}
sub dr_cr{                 ###########
 my $self=shift;
  my(@xy)=@_;
 my(@qw)=($self->{PSX},$self->{PSY});
 if ( $self->{UNIT} eq 'mm' ){ foreach (@qw){$_=$_/2.8346};}
 my $rrot=atan2(  $xy[1]-$qw[1], $xy[0]-$qw[0]   );
 my $rmax=sqrt(  ($xy[0]-$qw[0])**2+ ($xy[1]-$qw[1])**2 );
 print "(@qw)  (@xy)  $rrot   $rmax\n";
 my $r=0;
 my $dr=1; if ( $self->{UNIT} eq 'mm' ){ $dr=$dr*2.8346};
 while ($r<$rmax){
   $self->mo($r*cos($rrot)+$qw[0] , $r*sin($rrot)+$qw[1] );
   $r=$r+$dr;
   $self->dr($r*cos($rrot)+$qw[0] , $r*sin($rrot)+$qw[1]  );
   $r=$r+$dr;
 }
}
sub ra{                 ###########  filled rect.
 my $self=shift;
 if ($self->{SN}  eq 's') {$self->{SN} ='n';$self->{TEXT}.="n\n"}
 my(@xy)=@_;  if ( $self->{UNIT} eq 'mm' ){ foreach (@xy) {$_=$_*2.8346}};
 $self->{TEXT}.=sprintf(" %.2f %.2f %.2f %.2f b\n",@xy);
 $self->adj_bb(@xy[0..1]); $self->adj_bb(@xy[2..3]);
}
sub ro{                 ###########  outline rect.
 my $self=shift;
# if ($self->{SN}  eq 's') {$self->{SN} ='n';$self->{TEXT}.="n\n"}
 if ($self->{SN} eq 'n') {$self->{SN}='s';$self->{TEXT}.="s\n"}
 my(@xy)=@_;  if ( $self->{UNIT} eq 'mm' ){ foreach (@xy) {$_=$_*2.8346}};
 $self->{TEXT}.=sprintf(" %.2f %.2f %.2f %.2f ob\n",@xy);
 $self->adj_bb(@xy[0..1]); $self->adj_bb(@xy[2..3]);
}



sub la{
 my $self=shift;
# if ($self->{SN}  eq 's') {$self->{SN} ='n';$self->{TEXT}.="n 0 0 m\n"}
 my($txt)=@_;  
#19.2.2003 - zavorky nahradit 
 $txt=~s/\(/\\(/g;
 $txt=~s/\)/\\\)/g;
 @txt=split /\n/,$txt;
 if ($#txt>0) {
    foreach (@txt){$self->{TEXT}.="($_) show\n";

# 31.5.2002 presunto dopredu adjbb kvuli spatnemu bb
      $self->adj_bb($self->{PSX},$self->{PSY});
      $self->adj_bb($self->{PSX}+$self->{WILET}*length($_),
                    $self->{PSY}+$self->{HILET});

      $self->mo($self->{PSX},$self->{PSY}-=$self->{HILET});
#  $self->{PSY}-=$self->{HILET};$self->mo($self->{PSX},$self->{PSY});
                  }
 } else {
 #------------ 22.11.2002 - lepsi bounding box pro pismena=>0.5!!??!!
     $self->{TEXT}.="($txt) show\n";
     $self->adj_bb($self->{PSX}+0.8*$self->{WILET}*length($txt),
                                $self->{PSY}+$self->{HILET});
 }
}

#########################################################
######################## lwid sfont setpal sp setrgb
#########################################################

sub lwid{
   my $self=shift;
   if ($self->{SN}  eq 'n') {$self->{TEXT}.="s n\n"}
   $self->{TEXT}.="$_[0] setlinewidth\n";
}
sub sfont{
 my $self=shift;
 my($size,$type)=@_;
 my($stype)=1;
 if ($type=~/^times/i){
     $stype=1;
 }elsif($type=~/^arial/i){
     $stype=5;
 }elsif($type=~/^courier/i){
     $stype=9;
 }
 if ($type=~/bold/i){
     $stype+=1;
 }
 if($type=~/italic/i){
     $stype+=2;
 }
 $type=$stype;
 $self->{TEXT}.="$size $type sf\n";
 $self->{HILET}=$size; $self->{WILET}=$size/2;
}

sub setpal{
my $self=shift;
$self->{PAL}=shift;
$self->{PAL}='pc' if (0==map/$self->{PAL}/,('rain','earth','month','pc') );
}

sub getpal{ my $self=shift;return $self->{PAL};}

sub sp{ my $self=shift; my($x)=@_;$x--;
if ($self->{SN}  eq 's') {$self->{SN}='n';$self->{TEXT}.=" n ";}
if ($self->{SN}  eq 'n') {$self->{SN}='n';$self->{TEXT}.=" s n ";}
#                    $self->{TEXT}.=" $self->{PSX} $self->{PSY} m %ahoj\n"
#                    }
$self->{TEXT}.=" @{$PCApc->[$x]} rgb\n" if ($self->{PAL} eq 'pc');
#$self->{TEXT}.=" @{$PCArain->[$x]} rgb\n" if ($self->{PAL} eq 'rain');
#$self->{TEXT}.=" @{$PCAearth->[$x]} rgb\n" if ($self->{PAL} eq 'earth');
#$self->{TEXT}.=" @{$PCAmonth->[$x]} rgb\n" if ($self->{PAL} eq 'month');
}
sub setrgb{ my $self=shift;
if ($self->{SN}  eq 's') {$self->{SN} ='n';$self->{TEXT}.=" n "}
if ($self->{SN}  eq 'n') {$self->{SN}='n';$self->{TEXT}.=" s n ";}
$self->{TEXT}.="@_ setrgbcolor\n";}



#########################################################
######################## compile_objs  PRN   TOPS
#########################################################
sub compile_objs{my $self=shift;$self->{TEXT}=$self->prn;$self->{LIST}=[];}

sub prn{
  my $self=shift;
  my $outstring=$self->{TEXT};
if ($outstring=~/$ch3(\d*)$ch3/){
    print "CH3";
    $outstring=~s/$ch3(\d*)$ch3/${$self->{LIST}}[$1]->prn/eg;
   }
  return $outstring;
}

sub tops{
  my $self=shift;
  #########  8.3.2002 pridan integer. GSV 4 chce integer BBox
     foreach (@{$self->{BBOX}} ){$_=int($_)}
     my $boubox=join' ',@{$self->{BBOX}};
 my $outstring="%!PS-Adobe-2.0 EPSF-1.2\n%%BoundingBox:$boubox\n";
 $outstring.=$PSini.$self->prn.$PSend;
  return $outstring;
}

#########################################################################
sub PSCRinitialize{

$PCApc=[
 [0.00,0.00,0.00],[0.00,0.00,0.53],[0.00,0.53,0.00],[0.00,0.53,0.53],
 [0.53,0.00,0.00],[0.53,0.00,0.53],[0.47,0.33,0.00],[0.53,0.53,0.53],
 [0.33,0.33,0.33],[0.33,0.33,1.00],[0.33,1.00,0.33],[0.33,1.00,1.00],
 [1.00,0.33,0.33],[1.00,0.33,1.00],[1.00,1.00,0.33],[1.00,1.00,1.00] ];


$ch3=pack("C",3);$PSend=" s\nshowpage\n";

$PSini=<<EOFINI;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    definitions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/bdef { bind readonly def } bind readonly def
 /inch {72  mul} bind def
 /cm   {72 2.54 div mul} bind def
 /mm   {72 25.4 div mul} bind def
%%%%%%%%%%%%%   x0 y0   %%%%%%%%%%%%%%
/m {moveto} bdef /l {lineto} bdef /n {newpath} bdef /s {stroke} bdef
/rgb {setrgbcolor} bdef
/tr {translate} bdef /sc {scale} bdef
/gr {grestore} bdef  /gs {gsave} bdef
%%%%%%%%%%%%%   x0 y0 width height  %%%%%%%%%%%%%%
/b {
  newpath
  /y1 exch def  /x1 exch def  /y0 exch def  /x0 exch def
  x0 y0  moveto  x1 y0 lineto  x1 y1 lineto  x0 y1 lineto
  closepath  fill
 } bdef
%%%%%%%%%%%%%   x0 y0 width height  %%%%%%%%%%%%%%

/tri {
  newpath
  /y2 exch def  /x2 exch def /y1 exch def  /x1 exch def  /y0 exch def  /x0 exch$
  x0 y0  moveto  x1 y1 lineto  x2 y2 lineto  x0 y0 lineto
  closepath  fill
 } bdef
         
/ob {
  newpath
  /y1 exch def  /x1 exch def  /y0 exch def  /x0 exch def
  x0 y0  moveto  x1 y0 lineto  x1 y1 lineto  x0 y1 lineto
  closepath  stroke
 } bdef
%%%%%%%%%%%%    size  type  sfont %%%%%%%%%%%%%%%%%%
/sf{
  /fnt    exch def
  /fntsiz exch def
 fnt 1 eq {/Times-Roman findfont} if
 fnt 2 eq {/Times-Roman-Bold findfont} if
 fnt 3 eq {/Times-Roman-Italic findfont} if
 fnt 4 eq {/Times-Roman-Bold-Italic findfont} if
 fnt 5 eq {/Arial findfont} if
 fnt 6 eq {/Arial-Bold findfont} if
 fnt 7 eq {/Arial-Italic findfont} if
 fnt 8 eq {/Arial-Bold-Italic findfont} if
 fnt 9 eq {/Courier-New findfont} if
 fnt 10 eq {/Courier-New-Bold findfont} if
 fnt 11 eq {/Courier-New-Italic findfont} if
 fnt 12 eq {/Courier-New-Bold-Italic findfont} if
 fntsiz scalefont
 setfont
} bdef
%%%%%%%%%%% x y angle (text)  text %%%%%%%%%%%%%%
/text{
  /ttt exch def  /r0 exch def  /y0 exch def  /x0 exch def
 gsave
  x0 y0  translate  r0 rotate  0 0 moveto  ttt show
 grestore
} bdef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% run
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EOFINI
}


}#BIGBADABUM

#########################################################
#########################################################
#
#   REALLY BIG BIG BADA BUM  ---   postscript generator
#
#########################################################
#########################################################










##########################################################
##########################################################
#
# 061004 - bug in cos theta  for theta > 90 deg
# 061005 - bug in tan > 180 deg
#          bug in hash definition, now - deleted first
# 061026 - terminal name removed even when Ctrl-c via $SIG{INT}
# 061103 - numbers in field's names, BUG "eval 01.12" found
#          most of lowercase internal vars renamed
#          better readf, writef, "_"  possible
#          bug with not always lowercase [A-Z]
# 061107 - released without fields mentioned
# 061109 - bug in plain text sent to functions => now in ''
# 061208 - fillf n,from,step,   linear regresion(dumb) lr
# 070313 - binary - 4 by 4  (hexa works)
# 070319 - beggining, ending by &,|   ; whitespaces possible
# 070404 - avg - improved, 2 fields possible
# 070405 - react - help line
# 070425 - + added to the characters for field assignement (fillf)
# 070524 - +- added -""- to readf function :/ ;   tm&P2.txt problem in func...
# 070912 - time2sec   sec2time:   not less then 1960
# 070913 - chceck gv, ggv - if they exist
##########################################################
##########################################################
