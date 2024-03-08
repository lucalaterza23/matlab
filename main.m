function out = main()
close all
clear all
clc
%MAIN Summary of this function goes here
%   Detailed explanation goes here
    % ToDo: Inserire nei parametri anche la potenza di trasmissione dei
    % nodi Txs  (fatto)
    % Server è Alice 
    % Tu Client invii dei dati in tcp e otterrai una stringa esadecimale da
    % trasformare in binario
    params = parameters();

    switch params.scen_layout
        case 'Normal'
            channels = get_channels(params);
            for irx=1:2
                 psduLength = getPSDULength(params.cfgHE); % PSDU length in bytes
                 txPSDU = randi([0 1],psduLength*8,1);
                 stats = perform_transmission(txPSDU,channels(irx,1),params);
                 out(irx) = stats;
                 
            end

        case 'Eavesdropping'
            [channels, channels1] = get_channels(params);
            psduLength = getPSDULength(params.cfgHE); % PSDU length in bytes
            txPSDU1 = randi([0 1],psduLength*8,1); % PSDU Trasmessa da Alice
            txPSDU2 = randi([0 1],psduLength*8,1); % PSDU Trasmessa da Bob

            for irx=1:2
                % Trasmissione Alice -> Bob e Eve
                outA2BE(irx) = perform_transmission(txPSDU1,channels(irx,1),params);
                % Trasmissione Bob -> Alice e Eve
                outB2AE(irx) = perform_transmission(txPSDU2,channels1(irx,1),params);
            end


            % Trasmissioni Legittime - N.B. In generale sarebbe corretto
            % considerare anche solo outA2BE(1) anzichè outB2AE(1), poichè
            % il canale tra Alice e Bob è simmetrico.
            out.rx_Bob_from_Alice = outA2BE(1);
            out.rx_Alice_from_Bob = outB2AE(1);
            % Eavesdropping
            out.rx_Eve_from_Alice = outA2BE(2);
            out.rx_Eve_from_Bob = outB2AE(2);


        % Utilizza dentro la funzione perform_transmission_with_jammer la
        % funzionalità Barrage Jammer
        % https://it.mathworks.com/help/radar/ug/barrage-jammer.html
        case 'Jamming'
             [norm_channel, jam_channel] = get_channels(params);
             psduLength = getPSDULength(params.cfgHE); % PSDU length in bytes
             txPSDU = randi([0 1],psduLength*8,1);
             out = perform_transmission_with_jammer(txPSDU,norm_channel, jam_channel,params);
             

        % Utilizza dentro la funzione perform_transmission_with_reply Replay il multiband combiner
        % https://it.mathworks.com/help/comm/ref/comm.multibandcombiner-system-object.html
        case 'Replay'
             [norm_channel, replay_channel] = get_channels(params);

             psduLength = getPSDULength(params.cfgHE); % PSDU length in bytes
             txPSDU = randi([0 1],psduLength*8,1);
             txPSDU_Eve = randi([0 1],psduLength*8,1);
             % Eve Cattura cio che invia Alice
             out_Alice_to_Eve = perform_transmission(txPSDU,norm_channel(2,1),params);
             % ToDo1: aggiungere piccole variazioni nell'input dato da Eve
             % in modo tale da far ricevere a bob cio che il nodo malevolo
             % vuole con xor

             % ToDo2: modificare potenza di trasmissione di Eve
             out = perform_transmission_with_replay(bitxor(txPSDU,txPSDU_Eve),out_Alice_to_Eve,norm_channel,replay_channel,params);
             

    end

        
end
    


