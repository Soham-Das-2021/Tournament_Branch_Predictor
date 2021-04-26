module Tournament_predictor(clk,PC,effective_address);

input clk;                     //Clock signal
input [4:0] PC;                //PC given by processor
input [4:0] effective_address; //Calculated effective address to check whether the predicted outcome is correct or not

reg [1:0] level_1_pred;        //1-level 2-bit branch predictor

parameter SNT=0;
parameter WNT=1;
parameter WT=2;
parameter ST=3;

reg History_bit;              //1-bit History Table
reg [1:0] level_2_pred0;      //2-level 2-bit 1st Predictor
reg [1:0] level_2_pred1;      //2-level 2-bit 2nd Predictor

reg [2:0] BTB_tag [0:3];      //Tags stored in Branch History Buffer
reg [4:0] BTB_addr [0:3];     //Target Address stored in Branch History Buffer

reg [1:0] index;              //to index into the BTB and BHT--- some bits of PC provides the index
reg [2:0] tag;                //Apart from the index, the rest of the bits of the PC is the tag
reg hit;                      //If tag matches with that of the BTB
reg [4:0] right;              //to count the number of times the Tournament predictor is correct

reg [4:0] predicted_next_PC;  //next PC predicted by the Branch predictor
//reg [4:0] actual_next_PC;

reg level_1_correct;          //It is '1' if the prediction of 1-level predictor is correct
reg level_2_correct;          //It is '1' if the prediction of the 2-level predictor is correct

reg [1:0] predictor_state;    //State 0---> Use 1-level predictor with high confidence 
                              //State 1---> Use 1-level predictor with low confidence 
                              //State 2---> Use 2-level predictor with low confidence 
                              //State 3---> Use 2-level predictor with high confidence 

initial
begin
    level_1_pred=0; History_bit=0; level_2_pred0=0; level_2_pred1=0;
    level_1_correct=0; level_2_correct=0; predictor_state=0; right=0;
    BTB_addr[0]=9; BTB_tag[0]=3'b011;          //initially some values are stored in the BTB
end

 
always@(posedge clk && PC)
begin
    index=PC[1:0];
    tag=PC[4:2];

//1-Level 2-bit Branch Predictor
    if(tag==BTB_tag[index])
    begin
      hit=1;
      if(level_1_pred==0)
      begin
        predicted_next_PC=PC+4;
        if(predicted_next_PC==effective_address)
        begin
          level_1_correct=1;
          level_1_pred<=0;
          right<=right+1;
        end  
        else
        begin
          level_1_correct=0;
          level_1_pred<=1; 
        end   
      end  
      else if(level_1_pred==1) 
      begin 
        predicted_next_PC=PC+4;
         if(predicted_next_PC==effective_address)
         begin
          level_1_correct=1;
          level_1_pred<=0;
          right<=right+1;
         end  
        else
        begin
          level_1_correct=0;
          level_1_pred<=2; 
        end  
      end  
      else if(level_1_pred==2) 
      begin 
        predicted_next_PC=BTB_addr[index];
         if(predicted_next_PC==effective_address)
         begin
          level_1_correct=1;
          level_1_pred<=3;
          right<=right+1;
         end 
        else
        begin
          level_1_correct=0;
          level_1_pred<=1; 
        end  
      end  
      else if(level_1_pred==3) 
      begin 
        predicted_next_PC=BTB_addr[index];
         if(predicted_next_PC==effective_address)
         begin
          level_1_correct=1;
          level_1_pred<=3;
          right<=right+1;
         end 
        else
        begin
          level_1_correct=0;
          level_1_pred<=2; 
        end  
      end  
    end  

    else
    begin
      hit=0;  
      predicted_next_PC=PC+4;
        if(predicted_next_PC==effective_address)
         right<=right+1;
      else
      begin
          BTB_tag[index]<=tag;
          BTB_addr[index]<=effective_address;
      end 
      
    end  
 

//2-Level 2-bit Branch Predictor 
    if(BTB_tag[index]==tag)
    begin
      hit=1;
      if(History_bit==0)
      begin
          if(level_2_pred0==SNT)
          begin
              predicted_next_PC=PC+4;
              if(predicted_next_PC==effective_address)
              begin
               level_2_correct=1;   
               level_2_pred0<=SNT;
                History_bit<=0;
                right<=right+1;
              end  
              else
              begin
               level_2_correct=0;   
               level_2_pred0<=WNT; 
                History_bit<=1;
              end   
          end
          else if(level_2_pred0==WNT)
          begin
              predicted_next_PC=PC+4;
              if(predicted_next_PC==effective_address)
              begin
               level_2_correct=1;   
               level_2_pred0<=SNT;
                History_bit<=0;
                right<=right+1;
              end
              else
              begin
                level_2_correct=0;  
               level_2_pred0<=WT; 
                History_bit<=1;
              end   
          end
          else if(level_2_pred0==WT)
          begin
              predicted_next_PC=BTB_addr[index];
              if(predicted_next_PC==effective_address)
              begin
               level_2_correct=1;   
               level_2_pred0<=ST;
                History_bit<=1;
                right<=right+1;
              end
              else
              begin
               level_2_correct=0;    
               level_2_pred0<=WNT;
                History_bit<=0;
              end   
          end
          else if(level_2_pred0==ST)
          begin
              predicted_next_PC=BTB_addr[index];
              if(predicted_next_PC==effective_address)
              begin
               level_2_correct=1;   
               level_2_pred0<=ST;
                History_bit<=1;
                right<=right+1;
              end  
              else
              begin
               level_2_correct=0;   
               level_2_pred0<=WT;
                History_bit<=0;
              end   
          end
      end
      else
      begin
          if(level_2_pred1==SNT)
           begin
              predicted_next_PC=PC+4;
              if(predicted_next_PC==effective_address)
              begin
               level_2_correct=1;   
               level_2_pred1<=SNT;
                History_bit<=0;
                right<=right+1;
              end  
              else
              begin
               level_2_correct=0;   
               level_2_pred1<=WNT; 
                History_bit<=1;
              end   
          end
          else if(level_2_pred1==WNT)
          begin
              predicted_next_PC=PC+4;
              if(predicted_next_PC==effective_address)
              begin
                level_2_correct=1;   
               level_2_pred1<=SNT;
                History_bit<=0;
                right<=right+1;
              end  
              else
              begin
                level_2_correct=0;  
               level_2_pred1<=WT; 
                History_bit<=1;
              end   
          end
          else if(level_2_pred1==WT)
          begin
              predicted_next_PC=BTB_addr[index];
              if(predicted_next_PC==effective_address)
              begin
                level_2_correct=1;  
               level_2_pred1<=ST;
                History_bit<=1;
                right<=right+1;
              end  
              else
              begin
                level_2_correct=0;   
               level_2_pred1<=WNT; 
                History_bit<=0; 
              end  
          end
          else if(level_2_pred1==ST)
          begin
              predicted_next_PC=BTB_addr[index];
              if(predicted_next_PC==effective_address)
              begin
               level_2_correct=1;   
               level_2_pred1<=ST;
                History_bit<=1;
                right<=right+1;
              end  
              else
              begin
               level_2_correct=0;   
               level_2_pred1<=WT;  
               History_bit<=0;
              end  
          end
      end
    end
    else
    begin
      hit=0;  
      predicted_next_PC=PC+4;
      if(predicted_next_PC==effective_address)
         right<=right+1;
      else
      begin
          BTB_tag[index]<=tag;
          BTB_addr[index]<=effective_address;
      end 
    end  

//State Machine 
    if(predictor_state==0)          //If in STATE 0
    begin
        if((level_1_correct==0 && level_2_correct==0) || (level_1_correct==1 && level_2_correct==0) || (level_1_correct==1 && level_2_correct==1))
           predictor_state<=0;
        else 
           predictor_state<=1;      //Change to STATE 1 only if 1-level predictor is wrong and 2-level predictor is right; else stay in STATE 0
    end  

    else if(predictor_state==1)     //If in STATE 1
    begin
        if(level_1_correct==1 && level_2_correct==0)     //Change to STATE 0 if 1-level predictor is right and 2-level predictor is wrong
           predictor_state<=0;
        else if((level_1_correct==0 && level_2_correct==0) || (level_1_correct==1 && level_2_correct==1))
           predictor_state<=1;                           //Remain in STATE 1 if bot the predictors are right or both are wrong
        else
           predictor_state<=2;                           //Change to STATE 2 if 1-level predictor is wrong and 2-level predictor is right
    end

    else if(predictor_state==2)     //If in STATE 2
    begin
        if(level_1_correct==1 && level_2_correct==0)     //Change to STATE 1 if 1-level predictor is right and 2-level predictor is wrong
           predictor_state<=1;
        else if((level_1_correct==0 && level_2_correct==0) || (level_1_correct==1 && level_2_correct==1))   
           predictor_state<=2;                          //Remain in STATE 1 if bot the predictors are right or both are wrong
        else 
        predictor_state<=3;                             //Change to STATE 3 if 1-level predictor is wrong and 2-level predictor is right
    end

    else if(predictor_state==3)      //If in STATE 3
    begin
        if(level_1_correct==1 && level_2_correct==0)
           predictor_state<=2;                          //Change to STATE 2 only if 1-level predictor is right and 2-level predictor is wrong, else stay in STATE 3
        else  
           predictor_state<=3;                         
    end
end

endmodule