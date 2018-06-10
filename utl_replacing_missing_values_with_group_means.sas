Replacing Missing Values with group means

  Two Solutions (all mothods gave the same result in WPS and SAS)

      1. proc stdize
      2. Data step
      3. proc sql


github (copy/paste .sas file not readme)
https://github.com/rogerjdeangelis/utl_replacing_missing_values_with_group_means

sas forum
https://communities.sas.com/t5/Base-SAS-Programming/replacing-Missing-Values/m-p/468821

Novinosrin  profile (SQL solution)
https://communities.sas.com/t5/user/viewprofilepage/user-id/138205


INPUT
=====

WORK.HAVE total obs=21

                 AGE_
 ID    GENDER    GROUP    SALARY

  1    Young       M         1
  2    Medium      F        55
  3    Old         M        27
  4    Young       F        33
  5    Medium      M        17
  6    Old         F         4
  7    Young       M        38
  8    Medium      F         .
  9    Old         M        83
 10    Young       F        53
 11    Medium      M         .
 12    Old         F        38
 13    Young       M        87
 14    Medium      F        15
 15    Old         M        83
 16    Young       F         .
 17    Medium      M        55
 18    Old         F        39
 19    Young       M        88
 20    Medium      F        33
 21    Old         M        14


* TO EXPLAIN THE METHOD I SORT BY GENDER AGE_GROUP

proc sort data=have out=havSrt;
by gender Age_group descending salary;
run;quit;


WORK.HAVSRT total obs=21

                          AGE_
 ID    GENDER    GROUP    SALARY

  2    Medium      F        55
 20    Medium      F        33
 14    Medium      F        15  Substitute mean of group
  8    Medium      F         .  34.33 = (55 + 33 + 15)/3 = 103/3 =34.33

 17    Medium      M        55
  5    Medium      M        17
 11    Medium      M         .  36 = (55 + 17)/2


PROCESS
=======

1. proc stdize

   proc sort data=have out=havSrt;
      by gender age_group;
   run;quit;

   proc stdize data=havSrt reponly method=mean out=want;
      by gender age_group;   * class statement does not work;
   var salary;
   run;

   * sort to griginal order?;

2. Data step

   proc sort data=have out=havSrt noequals;
      by gender age_group descending salary;
   run;quit;

   data want;
     retain tot cnt 0; * I like to declare even though not necessary;
     set havSrt;
     by gender age_group;
     if salary ne . then do;
       cnt=cnt+1;
       tot=tot+salary;
     end;
     else salary=tot/cnt;
     if last.age_group then do;
       tot=0;
       cnt=0;
     end;
     drop tot cnt;
   run;quit;

   * sort to griginal order?;

3._Proc_sql;_

   proc sql;
      create
         table want as
     select
          id
         ,gender
         ,age_group     * salary=. fills only missing cells;
         ,sum(salary,mean(salary)*(salary=.)) as salary
     from
         have
     group
         by gender, Age_group
     order
         by id
   ;quit;

    * no sort to original order needed;

OUTPUT
======

  3._Proc_sql;

   40 obs WORK.WANT total obs=21

                    AGE_
    ID    GENDER    GROUP     SALARY

     1    Young       M       1.0000
     2    Medium      F      55.0000
     3    Old         M      27.0000
     4    Young       F      33.0000
     5    Medium      M      17.0000
     6    Old         F       4.0000
     7    Young       M      38.0000

     8    Medium      F      34.3333  *est

     9    Old         M      83.0000
    10    Young       F      53.0000

    11    Medium      M      36.0000  *est

    12    Old         F      38.0000
    13    Young       M      87.0000
    14    Medium      F      15.0000
    15    Old         M      83.0000

    16    Young       F      43.0000  *est

    17    Medium      M      55.0000
    18    Old         F      39.0000
    19    Young       M      88.0000
    20    Medium      F      33.0000
    21    Old         M      14.0000

*                _              _       _
 _ __ ___   __ _| | _____    __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \  / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/ | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|  \__,_|\__,_|\__\__,_|

;

data have;
retain id gender age_group salary;
input id age_group $ gender $ salary;
cards4;
 1 M Young 01
 2 F Medium 55
 3 M Old 27
 4 F Young 33
 5 M Medium 17
 6 F Old 04
 7 M Young 38
 8 F Medium .
 9 M Old 83
10 F Young 53
11 M Medium .
12 F Old 38
13 M Young 87
14 F Medium 15
15 M Old 83
16 F Young .
17 M Medium 55
18 F Old 39
19 M Young 88
20 F Medium 33
21 M Old 14
;;;;
run;quit;

*                               _       _   _
__      ___ __  ___   ___  ___ | |_   _| |_(_) ___  _ __  ___
\ \ /\ / / '_ \/ __| / __|/ _ \| | | | | __| |/ _ \| '_ \/ __|
 \ V  V /| |_) \__ \ \__ \ (_) | | |_| | |_| | (_) | | | \__ \
  \_/\_/ | .__/|___/ |___/\___/|_|\__,_|\__|_|\___/|_| |_|___/
         |_|
;

%utl_submit_wps64('
libname wrk sas7bdat "%sysfunc(pathname(work))";
   proc sort data=wrk.have out=havSrt;
      by gender age_group;
   run;quit;

   proc stdize data=havSrt reponly method=mean out=want;
      by gender age_group;   * class statement does not work;
   var salary;
   run;quit;

   proc print;
   run;quit;
');

%utl_submit_wps64('
libname wrk sas7bdat "%sysfunc(pathname(work))";
   proc sort data=wrk.have out=havSrt noequals;
      by gender age_group descending salary;
   run;quit;
   data want;
     retain tot cnt 0;
     set havSrt;
     by gender age_group;
     if salary ne . then do;
       cnt=cnt+1;
       tot=tot+salary;
     end;
     else salary=tot/cnt;
     if last.age_group then do;
       tot=0;
       cnt=0;
     end;
     drop tot cnt;
   run;quit;
   proc print;
   run;quit;
');


%utl_submit_wps64('
libname wrk sas7bdat "%sysfunc(pathname(work))";
   proc sql;
     select
          id
         ,gender
         ,age_group
         ,sum(salary,mean(salary)*(salary=.)) as salary
     from
         wrk.have
     group
         by gender, Age_group
     order
         by id
   ;quit;
');

