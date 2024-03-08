function stats = perform_transmission_with_jammer(dataIn,norm_channel, jam_channel,SimulationParameters)




    % For each SNR point in the vector |snr| a number of packets are
    % generated, passed through a channel and demodulated to determine the
    % packet error rate.
    
    snr = SimulationParameters.SNR;
    
    % The number of packets tested at each SNR point is controlled by two
    % parameters:
    %
    % # |maxNumPEs| is the maximum number of packet errors simulated at each
    % SNR point. When the number of packet errors reaches this limit, the
    % simulation at this SNR point is complete.
    % # |maxNumPackets| is the maximum number of packets simulated at each SNR
    % point and limits the length of the simulation if the packet error limit
    % is not reached. 
    %
    % The numbers chosen in this example will lead to a very short simulation.
    % For meaningful results we recommend increasing the numbers.
    
    maxNumPEs = 10; % The maximum number of packet errors at an SNR point
    maxNumPackets = 100; % The maximum number of packets at an SNR point
    
    % Set the remaining variables for the simulation.
    
    % Get the baseband sampling rate
    fs = wlanSampleRate(SimulationParameters.cfgHE);

    % Get jammer power
    jammer_power = SimulationParameters.jammer_power;
    jammer_init = barrageJammer('ERP',jammer_power,'SamplesPerFrame',fs);
    jammer_signal = jammer_init();

    % Legitimate Channel Coefficient
    leg_channel = norm_channel(1,1).coeff;
    % Jammer Channel Coefficient ( Jamming on Bob)
    jam_channel = jam_channel(2,1).coeff;
    
    % Get the OFDM info
    ofdmInfo = wlanHEOFDMInfo('HE-Data',SimulationParameters.cfgHE);
    
    % Indices for accessing each field within the time-domain packet
    ind = wlanFieldIndices(SimulationParameters.cfgHE);
    
    % Processing SNR Points
    % For each SNR point a number of packets are tested and the packet error
    % rate calculated.
    %
    % For each packet the following processing steps occur:
    %
    % # A PSDU is created and encoded to create a single packet waveform.
    % # The waveform is passed through a different realization of the TGn
    % channel model.
    % # AWGN is added to the received waveform to create the desired average
    % SNR per active subcarrier after OFDM demodulation.
    % # The packet is detected.
    % # Coarse carrier frequency offset is estimated and corrected.
    % # Fine timing synchronization is established. The L-STF, L-LTF and L-SIG
    % samples are provided for fine timing to allow for packet detection at the
    % start or end of the L-STF.
    % # Fine carrier frequency offset is estimated and corrected.
    % # The HT-LTF is extracted from the synchronized received waveform. The
    % HT-LTF is OFDM demodulated and channel estimation is performed.
    % # The HT Data field is extracted from the synchronized received waveform.
    % The PSDU is recovered using the extracted field and the channel estimate.
    %
    % A |parfor| loop can be used to parallelize processing of the SNR points.
    % To enable the use of parallel computing for increased speed comment out
    % the 'for' statement and uncomment the 'parfor' statement below.
            
    S = numel(snr);
    packetErrorRate = zeros(S,1);
    %parfor i = 1:S % Use 'parfor' to speed up the simulation
    %disp(['Start loop over SNR'])
    for i = 1:S % Use 'for' to debug the simulation
    
    
        % Loop to simulate multiple packets
        numPacketErrors = 0;
        numBitErrors = 0;
        totBits = 0;
        n = 1; % Index of packet transmitted
        %disp(['Start while packet errors and max packs'])
        while numPacketErrors<=maxNumPEs && n<=maxNumPackets
            % Generate a packet waveform
            txPSDU = dataIn;
            tx = wlanWaveformGenerator(txPSDU,SimulationParameters.cfgHE);
            tx = tx.*(10^(SimulationParameters.Alice.txpower/20));
            
            % Add trailing zeros to allow for channel filter delay
            txPad = [tx; zeros(15,SimulationParameters.cfgHE.NumTransmitAntennas)]; 
            
            % Pass the waveform through the Quadriga Channel
            coeff = squeeze(leg_channel);
            rx_time = conv(txPad,coeff,'same');
            
            % Pass the jamming signal to the Channel
            j_coeff = squeeze(jam_channel);
            rx_jam = conv(jammer_signal,j_coeff,'same');
            
            % N.B. In questo caso non utilizzo il multiband combinaer
            % poichè il segnale di jamming è realizzato tramite il Barrage
            % Jammer che modella un segnale di jamming ad ampio spettro
            % come rumore gaussiano bianco.
            

            % Applico rumore
            rx_with_noise = awgn(rx_time, snr(i),'measured');
            n_pw = 10*log10(mean(abs(rx_time).^2)) - snr(i);
            n_pw = 10^(n_pw/10);
            

            mbc = comm.MultibandCombiner( ...
                     InputSampleRate=fs, ...
                     FrequencyOffsets=[0 0], ...
                     OutputSampleRateSource="Auto");
            
            % Dato che suppongo che il freq offset sia [0 0] per cui che il
            % segnale di interferenza insiste su tutto il canale
            % legittimo, posso considerare l'SINR come segue

            sinr(i) = 10*log10(mean(abs(rx_time).^2)) - (  10*log10(mean(abs(rx_jam).^2) + n_pw));
            
            % Aggiungo il jammer
            rx = mbc([rx_with_noise,rx_jam(1:length(rx_with_noise))]);
            
            


            % Packet detect and determine coarse packet offset
            coarsePktOffset = wlanPacketDetect(rx,SimulationParameters.cfgHE.ChannelBandwidth);
            if isempty(coarsePktOffset) % If empty no L-STF detected; packet error
                if SimulationParameters.verbose
                    disp(['empty no L-STF detected; packet error'])
                end
                numPacketErrors = numPacketErrors+1;
                numBitErrors = numBitErrors + length(txPad);
                totBits = totBits + length(txPad);
                n = n+1;
                continue; % Go to next loop iteration
            end
            %disp(['Extract L-STF and perform coarse frequency offset correction'])
            % Extract L-STF and perform coarse frequency offset correction
            lstf = rx(coarsePktOffset+(ind.LSTF(1):ind.LSTF(2)),:);
            coarseFreqOff = wlanCoarseCFOEstimate(lstf,SimulationParameters.cfgHE.ChannelBandwidth);
            rx = frequencyOffset(rx,fs,-coarseFreqOff);
            
            %disp(['Extract the non-HT fields and determine fine packet offset'])
            % Extract the non-HT fields and determine fine packet offset
            nonhtfields = rx(coarsePktOffset+(ind.LSTF(1):ind.LSIG(2)),:);
            finePktOffset = wlanSymbolTimingEstimate(nonhtfields,SimulationParameters.cfgHE.ChannelBandwidth);
            
            %disp(['Determine final packet offset'])
            % Determine final packet offset
            pktOffset = coarsePktOffset+finePktOffset;
    
            % If packet detected outwith the range of expected delays from
            % the channel modeling; packet error
            if pktOffset>50
                if SimulationParameters.verbose
                    disp(['outwith the range of expected delays'])
                end
                numPacketErrors = numPacketErrors+1;
                numBitErrors = numBitErrors + length(txPad);
                totBits = totBits + length(txPad);
                n = n+1;
                
                continue; % Go to next loop iteration
            end
            
            %disp(['Extract L-LTF and perform fine frequency offset correction'])
            % Extract L-LTF and perform fine frequency offset correction
            rxLLTF = rx(pktOffset+(ind.LLTF(1):ind.LLTF(2)),:);
            fineFreqOff = wlanFineCFOEstimate(rxLLTF,SimulationParameters.cfgHE.ChannelBandwidth);
            rx = frequencyOffset(rx,fs,-fineFreqOff);
            
            %disp(['HE-LTF demodulation and channel estimation'])
            % HE-LTF demodulation and channel estimation
            rxHELTF = rx(pktOffset+(ind.HELTF(1):ind.HELTF(2)),:);
            heltfDemod = wlanHEDemodulate(rxHELTF,'HE-LTF',SimulationParameters.cfgHE);
            [chanEst,pilotEst] = wlanHELTFChannelEstimate(heltfDemod,SimulationParameters.cfgHE);
            
            %disp(['Data demodulate'])
            % Data demodulate
            rxData = rx(pktOffset+(ind.HEData(1):ind.HEData(2)),:);
            demodSym = wlanHEDemodulate(rxData,'HE-Data',SimulationParameters.cfgHE);
            
            %disp(['Pilot phase tracking'])
            % Pilot phase tracking
            demodSym = wlanHETrackPilotError(demodSym,chanEst,SimulationParameters.cfgHE,'HE-Data');
            
            %disp(['Estimate noise power in HE fields'])
            % Estimate noise power in HE fields
            nVarEst = wlanHEDataNoiseEstimate(demodSym(ofdmInfo.PilotIndices,:,:),pilotEst,SimulationParameters.cfgHE);
            
            %disp(['Extract data subcarriers'])
            % Extract data subcarriers from demodulated symbols and channel
            % estimate
            demodDataSym = demodSym(ofdmInfo.DataIndices,:,:);
            chanEstData = chanEst(ofdmInfo.DataIndices,:,:);
            
            %disp(['Equalization and STBC combining'])
            % Equalization and STBC combining
            [eqDataSym,csi] = wlanHEEqualize(demodDataSym,chanEstData,nVarEst,SimulationParameters.cfgHE,'HE-Data');
            
            %disp(['Recover data'])
            % Recover data
            rxPSDU = wlanHEDataBitRecover(eqDataSym,nVarEst,csi,SimulationParameters.cfgHE,'LDPCDecodingMethod','norm-min-sum');
    
            % Determine if any bits are in error, i.e. a packet error
            packetError = ~isequal(txPSDU,rxPSDU);
            numPacketErrors = numPacketErrors+packetError;
            n = n+1;
            totBits = totBits + length(txPSDU);
            numBitErrors = sum(xor(txPSDU,rxPSDU));

        end
        %disp(['End of while'])
        
        % Calculate packet error rate (PER) at SNR point
        packetErrorRate(i) = numPacketErrors/(n-1);
        bitErrorRate(i) = numBitErrors/totBits;
        if SimulationParameters.verbose
            disp(['SNR ' num2str(snr(i))...
                  ' completed after '  num2str(n-1) ' packets,'...
                  ' PER: ' num2str(packetErrorRate(i)) ...
                  ' BER: ' num2str(bitErrorRate(i))]);
        end

    end

    % Capacità canale 
    channel_capacity = 20e6 * log2(1 + 10.^(snr/10));
    
    % Plot Packet Error Rate vs SNR Results
    if SimulationParameters.show_transmission
        figure;
        semilogy(snr,packetErrorRate,'-ob');
        grid on;
        xlabel('SNR [dB]');
        ylabel('PER');
        title('802.11ax 20MHz, MCS3, Direct Mapping, 1x1 Quadriga Channel Model 3GPP 38.901 Indoor LOS');
        figure;
        semilogy(snr,bitErrorRate,'-ob');
        grid on;
        xlabel('SNR [dB]');
        ylabel('BER');
        title('802.11ax 20MHz, MCS3, Direct Mapping, 1x1 Quadriga Channel Model 3GPP 38.901 Indoor LOS');

        figure;
        semilogy(snr,channel_capacity,'-ob');
        grid on;
        xlabel('SNR [dB]');
        ylabel('Channel capacity [bits per second]');
        title('802.11ax 20MHz, MCS3, Direct Mapping, 1x1 Quadriga Channel Model 3GPP 38.901 Indoor LOS');
    end
   
    stats.per = packetErrorRate;
    stats.ber = bitErrorRate;
    stats.channcap= channel_capacity;
    stats.txPSDU = txPSDU;
    if exist('rxPSDU','var')
        stats.rxPSDU = rxPSDU;
        stats.rx = rx;
    else
        stats.rxPSDU = [];
        stats.rx = [];
    end
    stats.tx = tx;
    stats.sinr = sinr;
end

