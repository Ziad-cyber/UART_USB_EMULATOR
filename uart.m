fileName = 'conf.json'; % filename in JSON extension
fid = fopen(fileName); % Opening the file
raw = fread(fid,inf); % Reading the contents
str = char(raw'); % Transformation
fclose(fid); % Closing the file
data_json= jsondecode(str); % Using the jsondecode function to parse JSON from string
%data_char=fileread('inputdata.txt');
%data_ascii=double(data_char);
fileID = fopen('inputdata.txt');
data=fread(fileID);
data_binary=de2bi(data,8);
data_binary7=de2bi(data,7);


%elseif answer=='UART'
    datasize=input('data size : 7 or 8   ');
    parity=input('parity type: even ,odd or none    ','s');
    s1 = 'even';
    s2 = 'odd';
      if datasize == 7
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

            
        elseif datasize == 8
            if parity=='even'
                arr_b=[];
                for v=1:1280
                eb=data_binary(v,1);
                    for b=2:8
                        eb=xor(eb,data_binary(1,b));
                    end
                arr_b(1,v)=eb;
                end
            elseif parity== 'odd'
                    arr_b=[];
                    for v=1:1280
                    ob=data_binary(v,1);
                        for b=2:8
                            ob=not(xor(ob,data_binary(1,b)));
                        end
                    arr_b(1,v)=ob;
                    end
                    
            end 
      end
    stopbit=input('stop bit:one or two    ','s');
    if stopbit == 'one'
        stp=ones(1280,1);
    elseif stopbit == 'two'
        stp=ones(1280,2);
    end
   startbit=zeros(1280,1);
   if datasize==8
        uart_packet=[startbit,data_binary,arr_b',stp]
   elseif datasize==7
        uart_packet=[startbit,data_binary7,arr_b',stp]
   end
   
   subplot(2,1,1);
   pk1=uart_packet(1,:);
   stairs(pk1)
   grid on
   axis([1 12 -2 2])
   title('Byte 1')
   
  % figure 1
   subplot(2,1,2);
   pk2=uart_packet(2,:);
   stairs(pk2)
   grid on
   axis([1 12 -2 2])
   title('Byte 2')
  % figure 2