function [channels, channels1] = get_channels(SimulationParameters)
    %POC Summary of this function goes here
    %   Detailed explanation goes here
    AliceAnt = qd_arrayant(SimulationParameters.Alice.antenna);
    AliceAnt.center_frequency = SimulationParameters.C_Freq;                 % 5 GHz
    AliceAnt.name= 'Alice';
    [gain_dBiA,pow_maxA]=calc_gain(AliceAnt);            % guadagno antenna normalizzato in dBi e potenza max in main beam direction
    disp(  ['Alice Antenna Gain is:', num2str(gain_dBiA), ' dBi'] );
    
    BobAnt = qd_arrayant(SimulationParameters.Bob.antenna);
    BobAnt.center_frequency = SimulationParameters.C_Freq;
    BobAnt.name= 'Bob';
    [gain_dBiB,pow_maxB]=calc_gain(BobAnt); 
    disp(  ['Bob Antenna Gain is:', num2str(gain_dBiB), ' dBi'] );
    
    
    EveAnt = qd_arrayant(SimulationParameters.Eve.antenna);
    EveAnt.center_frequency = SimulationParameters.C_Freq;
    EveAnt.name= 'Eve';
    [gain_dBiE,pow_maxE]=calc_gain(EveAnt); 
    disp(  ['Eve Antenna Gain is:', num2str(gain_dBiE), ' dBi'] );
    
    s = qd_simulation_parameters;
    s.center_frequency = SimulationParameters.C_Freq;
    layout = qd_layout(s); 
    layout1= qd_layout(s); % layout Alice trasmette, layout1 Bob trasmette
    layout.set_scenario(SimulationParameters.Scenario);
    layout1.set_scenario(SimulationParameters.Scenario);
   
    switch SimulationParameters.scen_layout
    
        case 'Normal'
            disp('Simulation Layout: Alice AP transmits to Bob and Eve that act as normal STAs')
            
            
            rx_positions = [SimulationParameters.Bob.pos,SimulationParameters.Eve.pos];
            layout.tx_array = AliceAnt;
            layout.no_tx = 1;
            layout.tx_position = SimulationParameters.Alice.pos;
            layout.no_rx = 2;
            for irx=1:layout.no_rx
                Track_Rx = qd_track.generate('linear', 1, 0);
                Track_Rx.name = ['track',num2str(irx)];
                Track_Rx.initial_position =  rx_positions(:, irx);
                Track_Rx.no_snapshots = 1;
                Track_Rx.scenario = SimulationParameters.Scenario;
                layout.rx_track(irx) = Track_Rx;
            end
            layout.rx_array(1) = BobAnt;
            layout.rx_array(2) = EveAnt;
            


        case 'Eavesdropping'
            
            disp('Simulation Layout: Alice AP transmits to Bob STA, Eve eavedrops the data')
             
            % % In questo caso la simulazione è molto simile a normal solo
            % % che si deve considerare anche Bob che trasmette, per considerare il canale Bob-Eve
            rx_positions = [SimulationParameters.Bob.pos,SimulationParameters.Eve.pos];
            layout.tx_array = AliceAnt;
            layout.no_tx = 1;
            layout.tx_position = SimulationParameters.Alice.pos;
            layout.no_rx = 2;
            for irx=1:layout.no_rx
                Track_Rx = qd_track.generate('linear', 1, 0);
                Track_Rx.name = ['track',num2str(irx)];
                Track_Rx.initial_position =  rx_positions(:, irx);
                Track_Rx.no_snapshots = 1;
                Track_Rx.scenario = SimulationParameters.Scenario;
                layout.rx_track(irx) = Track_Rx;
            end
            layout.rx_array(1) = BobAnt;
            layout.rx_array(2) = EveAnt;



            %layout1

            layout1.no_tx = 1;
            layout1.no_rx = 2;
            rx_positions1 = [SimulationParameters.Alice.pos,SimulationParameters.Eve.pos];
            layout1.tx_array = BobAnt;
            layout1.tx_position = SimulationParameters.Bob.pos;

            for irx=1:layout1.no_rx
                Track_Rx = qd_track.generate('linear', 1, 0);
                Track_Rx.name = ['track',num2str(irx)];
                Track_Rx.initial_position =  rx_positions1(:, irx);
                Track_Rx.no_snapshots = 1;
                Track_Rx.scenario = SimulationParameters.Scenario;
                layout1.rx_track(irx) = Track_Rx;
            end
            layout1.rx_array(1) = AliceAnt;
            layout1.rx_array(2) = EveAnt;
           
        case 'Jamming'
            
            disp('Simulation Layout: Alice AP transmits to Bob STA, Eve acts as a jammer to one of the two trusted points')
            rx_positions = SimulationParameters.Bob.pos;
            layout.tx_array = AliceAnt;
            layout.no_tx = 1;
            layout.tx_position = SimulationParameters.Alice.pos;
            layout.no_rx = 1;
            for irx=1:layout.no_rx
                Track_Rx = qd_track.generate('linear', 1, 0);
                Track_Rx.name = ['track',num2str(irx)];
                Track_Rx.initial_position =  rx_positions(:, irx);
                Track_Rx.no_snapshots = 1;
                Track_Rx.scenario = SimulationParameters.Scenario;
                layout.rx_track(irx) = Track_Rx;
            end
            layout.rx_array(1) = BobAnt;
            



            %layout1

            layout1.no_tx = 1;
            layout1.no_rx = 2;
            rx_positions1 = [SimulationParameters.Alice.pos,SimulationParameters.Bob.pos];
            layout1.tx_array = EveAnt;
            layout1.tx_position = SimulationParameters.Eve.pos;

            for irx=1:layout1.no_rx
                Track_Rx = qd_track.generate('linear', 1, 0);
                Track_Rx.name = ['track',num2str(irx)];
                Track_Rx.initial_position =  rx_positions1(:, irx);
                Track_Rx.no_snapshots = 1;
                Track_Rx.scenario = SimulationParameters.Scenario;
                layout1.rx_track(irx) = Track_Rx;
            end
            layout1.rx_array(1) = AliceAnt;
            layout1.rx_array(2) = BobAnt;
            
            
    
        case 'Replay'
            
            disp('Simulation Layout: Alice AP transmits to Bob STA, Eve eavedrops the data from one terminal and redirect it to the otherone')
            
     
            rx_positions = [SimulationParameters.Bob.pos,SimulationParameters.Eve.pos];
            layout.tx_array = AliceAnt;
            layout.no_tx = 1;
            layout.tx_position = SimulationParameters.Alice.pos;
            layout.no_rx = 2;
            for irx=1:layout.no_rx
                Track_Rx = qd_track.generate('linear', 1, 0);
                Track_Rx.name = ['track',num2str(irx)];
                Track_Rx.initial_position =  rx_positions(:, irx);
                Track_Rx.no_snapshots = 1;
                Track_Rx.scenario = SimulationParameters.Scenario;
                layout.rx_track(irx) = Track_Rx;
            end
            layout.rx_array(1) = BobAnt;
            layout.rx_array(2) = EveAnt;



            %layout1

            layout1.no_tx = 1;
            layout1.no_rx = 1;
            rx_positions1 = SimulationParameters.Bob.pos;
            layout1.tx_array = EveAnt;
            layout1.tx_position = SimulationParameters.Eve.pos;

            for irx=1:layout1.no_rx
                Track_Rx = qd_track.generate('linear', 1, 0);
                Track_Rx.name = ['track',num2str(irx)];
                Track_Rx.initial_position =  rx_positions1(:, irx);
                Track_Rx.no_snapshots = 1;
                Track_Rx.scenario = SimulationParameters.Scenario;
                layout1.rx_track(irx) = Track_Rx;
            end
            layout1.rx_array(1) = BobAnt;
            
            
    
       
        
        otherwise
            disp('ToDo')
            disp('Not Implemented or Error')
    
    
    end
    
    if SimulationParameters.show_pwmap
        [ map, x_coords, y_coords] = layout.power_map( SimulationParameters.Scenario, SimulationParameters.ScenarioPrec,...
            1, -50, 200, -50, 200, 1.5 );
        P_db = 10*log10(map{1});                                % LOS pathloss in dB

        
        layout.visualize([],[],0);                                   % Show BS and MT positions on the map
        hold on; imagesc( x_coords, y_coords, P_db ); hold off  % Plot the antenna footprint
        axis([-10, 10, -10, 10]);
        caxis( [-80 -40] );                                     % Color range
        colmap = colormap;
        colormap( colmap*0.5 + 0.5 );                           % Adjust colors to be "lighter"
        set(gca,'layer','top')                                  % Show grid on top of the map
        colorbar('south')
        title('Selected Layout Power Map [dB]')

        [ map, x_coords, y_coords] = layout1.power_map( SimulationParameters.Scenario, SimulationParameters.ScenarioPrec,...
            1, -50, 200, -50, 200, 1.5 );
        P_db = 10*log10(map{1});                                % LOS pathloss in dB

        
        layout1.visualize([],[],0);                                   % Show BS and MT positions on the map
        hold on; imagesc( x_coords, y_coords, P_db ); hold off  % Plot the antenna footprint
        axis([-10, 10, -10, 10]);
        caxis( [-80 -40] );                                     % Color range
        colmap = colormap;
        colormap( colmap*0.5 + 0.5 );                           % Adjust colors to be "lighter"
        set(gca,'layer','top')                                  % Show grid on top of the map
        colorbar('south')
        title('Selected Layout Power Map [dB]')

    end
    
    
    % Generating a layout.channel impulse responses
     
    [channels, builder] = layout.get_channels;         %channels canali tra Alice-Bob e Alice-Eve
    if strcmp(SimulationParameters.scen_layout,'Jamming') || strcmp(SimulationParameters.scen_layout,'Replay') || strcmp(SimulationParameters.scen_layout,'Eavesdropping')
        [channels1, builder1] = layout1.get_channels;      %channels1 canali tra Bob-Alice e Bob-Eve
    else
        channels1 = [];
    end
   
    
  end

