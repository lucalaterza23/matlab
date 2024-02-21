function out = main()
%MAIN Summary of this function goes here
%   Detailed explanation goes here
    params = parameters();
    channels = get_channels(params);
    channels1=get_channels(params);
    
    switch params.scen_layout
        case 'Normal'
            for irx=1:2
                 psduLength = getPSDULength(params.cfgHE); % PSDU length in bytes
                 txPSDU = randi([0 1],psduLength*8,1);
                 stats = perform_transmission(txPSDU,channels(irx,1),params);
                 out(irx) = stats;
                 
            end

        case 'Eavesdropping'
            for irx=1:2
                 psduLength = getPSDULength(params.cfgHE); % PSDU length in bytes
                 txPSDU = randi([0 1],psduLength*8,1);
                 stats = perform_transmission(txPSDU,channels(irx,1),params);
                 stats1= perform_transmission(txPSDU,channels1(irx,1),params);
                 out(irx) = stats;
                 out(irx) = stats1;
            end

        case 'Jamming'
             for irx=1:2
                 psduLength = getPSDULength(params.cfgHE); % PSDU length in bytes
                 txPSDU = randi([0 1],psduLength*8,1);
                 stats = perform_transmission(txPSDU,channels(irx,1),params);
                 stats1= perform_transmission(txPSDU,channels1(irx,1),params);
                 out(irx) = stats;
                 out(irx) = stats1;
             end

        case 'Reply'
             for irx=1:2
                 psduLength = getPSDULength(params.cfgHE); % PSDU length in bytes
                 txPSDU = randi([0 1],psduLength*8,1);
                 stats = perform_transmission(txPSDU,channels(irx,1),params);
                 stats1= perform_transmission(txPSDU,channels1(irx,1),params);
                 out(irx) = stats;
                 out(irx) = stats1;
         end

        
        
    
end

