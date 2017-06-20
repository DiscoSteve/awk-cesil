/*  cesil.awk - an interpreter for the old CESIL language by Steve Nicklin  */
/*  Copyright (C) 2012  Steve Nicklin		                            */
/*  This program is free software; you can redistribute it and\or modify    */
/*  it under the terms of the GNU General Public License as published by    */
/*  the Free Software Foundation; either version 3 of the License, or       */
/*  (at your option) any later version.                                     */
/*  This program is distributed in the hope that it will be useful,         */
/*  but WITHOUT ANY WARRANTY; without even the implied warranty of          */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           */
/*  GNU General Public License for more details.                            */
/*  You should have received a copy of the GNU General Public License       */
/*  along with this program; if not, write to the Free Software Foundation, */
/*  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA       */
/*                                                                          */
/*  You can contact the author at steve@stevenicklin.com                    */

BEGIN{
   pc=0
   dc=0
   lc=0
   INCODE=1
   for(i=0;i<100;i++) validvalue[i]=""

   if (DEBUG==1) printf("Running in DEBUG mode.\nParsing program ...\n")
}


{
    if ((NF > 0) && (substr($0,1,1) != "*"))
    {
   if (INCODE == 1)
   {
      OPERAND = ""
      INSTRUCTION = ""
      LABEL = ""
      HASALABEL=1

      INPUTLINE=$0
      gsub("\t"," ",INPUTLINE)
      if (substr(INPUTLINE,1,1) == " ") HASALABEL = 0

      if (HASALABEL == 0)
      {
         INSTRUCTION = $1
         opstart = 2
      }
      else
      {
         LABEL = $1   
         INSTRUCTION = $2
         validlabel[LABEL] = LABEL
         labellocation[LABEL] = pc
         labelname[lc] = LABEL
         lc++
         opstart = 3
      }

      if (NF >= opstart)
      {
         /* need to fix spacing retention */
         WORD = $opstart
         gsub("\"","",WORD)
         OPERAND = WORD
         for(word=opstart+1;word<=NF;word++)
         {
            WORD = $word
            gsub("\"","",WORD)
            OPERAND = OPERAND " " WORD
         }
      }

      if (INSTRUCTION == "%")
      {
         INCODE=0
      }
      else
      {
         label[pc] = LABEL
         instruction[pc] = INSTRUCTION
         operand[pc] = OPERAND

         LASTINSTRUCTION = INSTRUCTION
         pc++
      }
      
   }
   else
   {
      data[dc] = $1
      for(word=2;word<=NF;word++)
      {
         data[dc] = data[dc] " " $word
      }
      dc++
   }
    }
    else
    {
   if (DEBUG==1) print "cesil: blank line ignored at " NR 
    }
}

END{
   if (DEBUG==1)
   {
      print "Program:"
      TAB = "|"
      for(ip=0;ip<pc;ip++)
      {
         PAD = ""
         if (ip < 100) PAD = "0"
         if (ip < 10) PAD = "00"
         print TAB PAD ip TAB label[ip] TAB instruction[ip] TAB operand[ip] TAB
      }
      print "Labels:"
      for(lp=0;lp<lc;lp++)
      {
         LABEL = labelname[lp]
         print LABEL " = " labellocation[LABEL]
      }
      printf("Data:");
      for(dp=0;dp<dc;dp++)
      {
         printf(" %s",data[dp])
      }
      printf("\nRunning program ...\n")
   }

   RUNNING=1
   IP=0
   NEXTIP=0
   DP=0
   ACCUMULATOR=0

   for(;RUNNING==1;)
   {
      IP = NEXTIP

      LABEL = label[IP]
      INSTRUCTION = instruction[IP]
      OPERAND = operand[IP]

      NEXTIP=IP+1
      if (DEBUG==1)
      {
         print TAB IP TAB LABEL TAB INSTRUCTION TAB OPERAND TAB
      }
      if (INSTRUCTION == "STORE")
      {
         validvalue[OPERAND] = OPERAND
         value[OPERAND] = ACCUMULATOR
         if (DEBUG==1)  print ">>> STORE " OPERAND " = " value[OPERAND]

      }   
      if (INSTRUCTION == "LOAD")
      {
         VALUE = OPERAND
         if (validvalue[OPERAND] == OPERAND) VALUE=value[OPERAND]
         ACCUMULATOR = VALUE
         if (DEBUG==1)  print ">>> LOAD ACCUMULATOR = " ACCUMULATOR
         if (VALUE == "")
         {
            printf("error: no value for OPERAND " OPERAND " at line %d\n",IP);
            RUNNING=0;
         }
      }
      if (INSTRUCTION == "IN")
      {
         if (DP == dc)
         {
            printf("error: out of data at line %d\n",IP);
            RUNNING=0;
         }
         else
         {
            ACCUMULATOR = data[DP]
            DP++;
         }
      }
      if (INSTRUCTION == "PRINT")
      {
         printf(OPERAND);
      }

      if (INSTRUCTION == "OUT")
      {
         printf("%s",ACCUMULATOR);
      }

      if (INSTRUCTION == "LINE")
      {
         printf("\n");
      }
      
      if (INSTRUCTION == "ADD")
      {
         VALUE = OPERAND
         if (validvalue[OPERAND] == OPERAND) VALUE= value[OPERAND]
         ACCUMULATOR = ACCUMULATOR + VALUE
         if (DEBUG==1) print ">>> ACCUMULATOR ADD " VALUE " = " ACCUMULATOR
      }

      if (INSTRUCTION == "SUBTRACT")
      {
         VALUE = OPERAND
         if (validvalue[OPERAND] == OPERAND) VALUE= value[OPERAND]
         ACCUMULATOR = ACCUMULATOR - VALUE
         if (DEBUG==1) print ">>> ACCUMULATOR SUBTRACT " VALUE " = " ACCUMULATOR
      }

      if (INSTRUCTION == "MULTIPLY")
      {
         VALUE = OPERAND
         if (validvalue[OPERAND] == OPERAND) VALUE= value[OPERAND]
         ACCUMULATOR = ACCUMULATOR * VALUE
         if (DEBUG==1) print ">>> ACCUMULATOR MULTIPLY " VALUE " = " ACCUMULATOR
      }

      if (INSTRUCTION == "DIVIDE")
      {
         VALUE = OPERAND
         if (validvalue[OPERAND] == OPERAND) VALUE= value[OPERAND]
         if (VALUE == 0)
         {
            printf("error: divide by zero at line %d\n",IP);
            RUNNING=0;
         }
         else
         {
            ACCUMULATOR = int(ACCUMULATOR / VALUE)
         }
         if (DEBUG==1) print ">>> ACCUMULATOR DIVIDE " VALUE " = " ACCUMULATOR
      }

      if (INSTRUCTION == "HALT")
      {
         RUNNING=0;
         if (debug==1) printf("warning: program halted at line %s\n",IP);
      }

      if (INSTRUCTION == "JUMP")
      {
         if (validlabel[OPERAND] == OPERAND)
         {
            NEXTIP = labellocation[OPERAND]
         }
         else
         {
            RUNNING=0;
            printf("error: undefined label %s line %s\n",OPERAND,IP);
         }
      }

      if (INSTRUCTION == "JIZERO")
      {
          if (ACCUMULATOR == 0)
          {
         if (validlabel[OPERAND] == OPERAND)
         {
            NEXTIP = labellocation[OPERAND]
         }
         else
         {
            RUNNING=0;
            printf("error: undefined label %s line %s\n",OPERAND,IP);
         }
          }
      }

      if (INSTRUCTION == "JINEG")
      {
          if (ACCUMULATOR < 0)
          {
         if (validlabel[OPERAND] == OPERAND)
         {
            NEXTIP = labellocation[OPERAND]
         }
         else
         {
            RUNNING=0;
            printf("error: undefined label %s line %s\n",OPERAND,IP);
         }
          }
      }
   }
   if (DEBUG==1) printf("Program finished.\n")

}
