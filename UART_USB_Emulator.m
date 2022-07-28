% filename in JSON extension
fileName = 'conf.json';
    % filename in JSON extension
fid = fopen(fileName);
    % Reading the contents
raw = fread(fid,inf);
    % Transformation
str = char(raw');
    % Closing the file
fclose(fid);
    % Using the jsondecode function to parse JSON from string
data_json= jsondecode(str);
payload=[];
data1=[];
data2=[];
    %reading the input file
fileID = fopen('inputdata.txt');
data=fread(fileID);
data_binary=de2bi(data,8);
[rb,cb]=size(data_binary);
 extra=mod(rb,data_json(2,1).parameters.payload);
if extra~=0
    data1=data_binary(1:rb-extra,:);
    data2=data_binary(rb-extra+1:rb,:);
    payload=reshape(data1,(data_json(2,1).parameters.payload)*8,[]);
    payload2=reshape(data2,extra*8,1);
else
    payload=reshape(data_binary,(data_json(2,1).parameters.payload)*8,[]);
end

    %transformation into asscii in 7 and 8 bits FOR UART
data_binary8=[];
data_binary7=[];
ru=[]; %no of rows in uart payload
cu=[]; %no of columns in uart payload
    %constructing payload matrix then asking user for type of data transfer

[rows,no_packets]=size(payload); %GETTING SIZE OF PAYLOAD

answer=input('UART or USB: ','s');
t1 = 'UART';
t2 = 'USB';


            %      USB
if strcmp(answer,t2)
    
    a.total_tx_time = 0;    
    a.overhead = 0;
    a.efficiency = 0;
        %reading USB parameters into matrices
    address=transpose(fliplr(double(data_json(2,1).parameters.dest_address)-48));
    sync=transpose((double(data_json(2,1).parameters.sync_pattern)-48));
    pid_pos = de2bi(rem(1:(no_packets),2^((data_json(2,1).parameters.pid)/2)),4)';
    pid_neg=not(pid_pos);
    pid=[pid_pos;pid_neg];
        %repeatin address and sync to number of packets to put together
    sync_tot=repmat(sync,1,no_packets);
    addr_tot=repmat(address,1,no_packets);
    eop=[0;0];
        %conctenate sync and address with the payload matrix 
    usb_packet=[sync_tot;pid;addr_tot;payload];
    matrix=[];%initialization of matrix of final package output
    matrix2=[];%initialization of matrix of final package output FOR EXTRA BYTES
    temp=[];%temporary vector to store each packet at a time
    no_element=[];%array vector to store each packet's element number
    temp3=[];%temporary vector to store each packet at a time FOR EXTRA BYTES
    no_element2=[];%array vector to store each packet's element number FOR EXTRA BYTES
    
        %Bit stuffing
    for x=1:no_packets
        y=usb_packet(:,x);%storing each packet at a time
        j=1;
        counter=0;
        [q,w]=size(y);
            %counting the number of consequtive ones in each packet 
        for i=1:q

            if y(i,1)==1  
                if  counter~=6
                    counter=counter+1;
                     temp(j,1)=y(i,1);
                    if counter==6
                         counter=0;
                         j=j+1;
                         temp(j,1)=0;

                    end
                end
            else  
                counter=0;
                temp(j,1)=y(i,1);

            end 
           j=j+1; 
        end
        [m,n]=size(temp);
        temp2=[]; %nrzi+bit
        value=1; %starting Value of NRZI
        
            %NRZI for each packet that was bit stuffed
        for z=1:m       
            if temp(z,1)==0
                value=not(value);
                temp2(z,1)=value;
            else
                temp2(z,1)=value;
            end
        end
            %Storing the element number of the final packet
        no_element(1,x)=m;
            %Storing the packet
        matrix=[matrix;temp2];
    end
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if extra~=0
        pid_pos2 = de2bi(rem(no_packets+1,2^((data_json(2,1).parameters.pid)/2)),4)';
        pid_neg2=not(pid_pos2);
        pid2=[pid_pos2;pid_neg2];
        usb_packet2=[sync;pid2;address;payload2]
        [rws,clm]=size(payload2);
        for x=1:clm
            y=usb_packet2(:,x);%storing each packet at a time
            j=1;
            counter=0;
            [q,w]=size(y);
                %counting the number of consequtive ones in each packet 
            for i=1:q

                if y(i,1)==1  
                    if  counter~=6
                        counter=counter+1;
                         TEM(j,1)=y(i,1);
                        if counter==6
                             counter=0;
                             j=j+1;
                             TEM(j,1)=0;

                        end
                    end
                else  
                    counter=0;
                    TEM(j,1)=y(i,1);

                end 
               j=j+1; 
            end
            [m,n]=size(TEM);
            temp2=[]; %nrzi+bit
            value=1; %starting Value of NRZI

                %NRZI for each packet that was bit stuffed
            for z=1:m       
                if TEM(z,1)==0
                    value=not(value);
                    temp2(z,1)=value;
                else
                    temp2(z,1)=value;
                end
            end
                %Storing the element number of the final packet
            no_element2(1,x)=m;
                %Storing the packet
            matrix2=[matrix2;temp2];
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    matrix2;
    matrix=[matrix;matrix2];
    matrix=[matrix;eop];
   no_element=[no_element,no_element2];
        %first 2 packets to be ploted
    packet1=matrix(1:no_element(1,1));
    packet2=matrix(1:no_element(1,2));
    
         % figure 1
       subplot(2,1,1);
       stairs(packet1'+2)
       hold on
       stairs(not(packet1'))
       grid on
       axis([1 1051 -2 4])
       title ('packet 1')
         % figure 2
       subplot(2,1,2);
       stairs(packet2'+2)
       hold on
       stairs(not(packet2'))
       grid on
       axis([1 1051 -2 4])
       title ('packet 2')
        % Efficiency, overhead and transmition time for USB
        
    [r,c]=size(matrix);
    usb_efficiency=(rows*no_packets)/(r*c)*100
    usb_overhead=100-usb_efficiency
    usb_transmission=r*c*data_json(2,1).parameters.bit_duration
    
    a.total_tx_time = usb_transmission;
    a.overhead = usb_overhead;
    a.efficiency = usb_efficiency;
       
       %          UART 
elseif strcmp(answer,t1)
    
     s.total_tx_time = 0;
     s.overhead = 0;
     s.efficience = 0;

    % asking for datasize, parity type and stopbits number
     datasize=double(data_json(1,1).parameters.data_bits);
     parity=data_json(1,1).parameters.parity;
     stopbit=double(data_json(1,1).parameters.stop_bits);
     
     s1 = 'even';
     s2 = 'odd';
     s3= 'none';
        %creating parity for data size of 7
      if datasize == 7
            data_binary7=de2bi(data,7);
            [ru,cu]=size(data_binary7);
            if strcmp(parity,s1)
                arr_b=[];
                for v=1:1280
                eb=data_binary7(v,1);
                    for b=2:7
                        eb=xor(eb,data_binary7(1,b));
                    end
                arr_b(1,v)=eb;
                end
            elseif strcmp(parity,s2)
                    arr_b=[];
                    for v=1:1280
                    ob=data_binary7(v,1);
                        for b=2:7
                            ob=not(xor(ob,data_binary7(1,b)));
                        end
                    arr_b(1,v)=ob;
                    end
            end

            %creating parity for data size of 8
        elseif datasize == 8
            data_binary8=de2bi(data,8);
            [ru,cu]=size(data_binary8);
            if strcmp(parity,s1)
                arr_b=[];
                for v=1:1280
                eb=data_binary8(v,1);
                    for b=2:8
                        eb=xor(eb,data_binary8(1,b));
                    end
                arr_b(1,v)=eb;
                end
            elseif strcmp(parity,s2)
                    arr_b=[];
                    for v=1:1280
                    ob=data_binary8(v,1);
                        for b=2:8
                            ob=not(xor(ob,data_binary8(1,b)));
                        end
                    arr_b(1,v)=ob;
                    end
                    
            end 
      else
         f1=msgbox('invalid input') 
      end
            %creating one or two stop bits
    
    if stopbit==1
        stp=ones(1280,1);
    elseif stopbit==2
        stp=ones(1280,2);
    else
        f2=msgbox('invalid input')
    end
            %creating a zero start bit
   startbit=zeros(1280,1);
            %creating UART packets for data size of 8
   if datasize==8
       if strcmp(parity,s3)
            %without parity
         uart_packet=[startbit,data_binary8,stp];
       else
            %with parity
         uart_packet=[startbit,data_binary8,arr_b',stp];
       end
            %creating UART packets for data size of 7
   elseif datasize==7
       if strcmp(parity,s3)
            %without parity
         uart_packet=[startbit,data_binary7,stp]; %%
       else
            %with parity
         uart_packet=[startbit,data_binary7,arr_b',stp];
       end
   end
   %plot first two bytes
      % figure 2
   subplot(2,1,1);
   
   pk1=[uart_packet(1,:) 1];
   stairs(pk1)
   grid on
   axis([1 13 -2 2])
   title('Byte 1')
   
       % figure 2
   subplot(2,1,2);
   pk2=[uart_packet(2,:) 1];
   stairs(pk2)
   grid on
   axis([1 13 -2 2])
   title('Byte 2')
         % Efficincy, overhead and transmition time for UART
    [r,c]=size(uart_packet);
    uart_efficiency=(ru*cu)/(r*c)*100
    uart_overhead=(100-uart_efficiency)
    uart_transmission=r*c*data_json(1,1).parameters.bit_duration
    
    s.total_tx_time = uart_transmission
    s.overhead = uart_overhead
    s.efficience = uart_efficiency;
else
   f=msgbox('invalid input') 
end
    
    
    %Printing in json file
    protocol_name = {'UART';'USB'};
    outputs = {s;a};
    fid=fopen('ELC3030_60.json','w');
    encodedJSON =jsonencode(table(protocol_name,outputs));
    jsonencode(table(protocol_name,outputs))
    fprintf(fid, encodedJSON);
    fclose('all');