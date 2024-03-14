
address="127.0.0.1";
portNumber=4000;
% Created Server
server = tcpserver(address,portNumber,"ConnectionChangedFcn",@connectionFcn,'Timeout',10)
%global received_txPSDU;
global readData;

function connectionFcn(src, ~)
%Client is connected
if src.Connected
    disp("Client connected")
    
    
    %Read Write infinitly with connected client
    while true
        
        readData = read(src,src.NumBytesAvailable,'int8');
        disp(readData);
        txPSDU=transpose(readData);
        save('tx_psdu.mat','txPSDU');
        
       
        
        write(src,"bit ricevuti","string")
        %Sleep for 5 millisecond
        java.lang.Thread.sleep(5);
    end

    
end


end


