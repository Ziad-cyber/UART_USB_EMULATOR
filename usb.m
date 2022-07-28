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
payload=reshape(data_binary,(data_json(2,1).parameters.payload)*8,[]);
%answer=input('UART or USB')
%if answer=='USB'
    %H=comm.CRCGenerator('Polynomial',[1100000000000101],'InitialConditions',ones(1,15));
    %step(H,payload)
    address=transpose(fliplr(double(data_json(2,1).parameters.dest_address)-48));
    sync=transpose((double(data_json(2,1).parameters.sync_pattern)-48));
    [rows,no_packets]=size(payload);
    pid_pos = de2bi(rem(1:(no_packets),2^((data_json(2,1).parameters.pid)/2)),4)';
    pid_neg=not(pid_pos);
    pid=[pid_pos;pid_neg];
    sync_tot=repmat(sync,1,no_packets);
    addr_tot=repmat(address,1,no_packets);
    eop=zeros(2,10);
    usb_packet=[sync_tot;pid;addr_tot;payload];
    matrix=[];
    temp=[];
    no_element=[];
    for x=1:no_packets
        y=usb_packet(:,x);
        j=1;
        counter=0;
        [q,w]=size(y);

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
        temp;
        [m,n]=size(temp);
        temp2=[]; %nrzi+bit
        value=1;
        for z=1:m              %  [0,1,0,0,1,0,1,1] -->[
            if temp(z,1)==0
                value=not(value);
                temp2(z,1)=value;
            else
                temp2(z,1)=value;
            end
        end
        no_element(1,x)=m;
        matrix=[matrix;temp2];
    end
    no_element;
    matrix;
    packet1=matrix(1:no_element(1,1));
    packet2=matrix(1:no_element(1,2));

    
    [r,c]=size(matrix);
    efficiency=(rows*no_packets)/(r*c)
    transmission=r*c*data_json(2,1).parameters.bit_duration
    overhead=1-efficiency
    
    
    
    
