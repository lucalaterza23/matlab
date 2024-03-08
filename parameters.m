function [SimulationParameters] = parameters()
%PARAMETERS Summary of this function goes here
%   Detailed explanation goes here

% Node Positions
SimulationParameters.Alice.pos = [0;0;1.5];
SimulationParameters.Bob.pos = [5;5;1.5];
SimulationParameters.Eve.pos = [4;5;1.5];



% Node Antennas
SimulationParameters.Alice.antenna = 'half-wave-dipole';
SimulationParameters.Bob.antenna = 'half-wave-dipole';
SimulationParameters.Eve.antenna = 'half-wave-dipole';

% Antenna's Power transmission
SimulationParameters.Alice.txpower = 20;   % dBm 
SimulationParameters.Bob.txpower = 20;
SimulationParameters.Eve.txpower = 20;


% Scenario
SimulationParameters.Scenario = '3GPP_38.901_Indoor_LOS';
SimulationParameters.ScenarioPrec = 'quick';


% Center Frequency
SimulationParameters.C_Freq = 5e9;

% Scenario Layout: Normal, Jamming, Replay, Eavesdropping (Passive)
% Normal: Alice AP <-> Bob e Eve STA
% Eavesdropping: Alice <-> Bob, Alice -> Eve, Bob -> Eve
% Jamming: Alice AP <-> Bob STA , Eve -> Alice e Bob STA
% Replay: Alice <-> Bob, Alice -> Eve -> Bob

SimulationParameters.scen_layout = 'Jamming';


% Show Layout and PowerMAP
SimulationParameters.show_pwmap = true;


% Show Transmission Plot
SimulationParameters.show_transmission = true;



% Waveform Configuration
% An 802.11ax HE transmission is simulated in this example. The HT format
% configuration object, <docid:wlan_ref#buw6fyh wlanHTConfig>, contains the
% format specific configuration of the transmission. The properties of the
% object contain the configuration.

SimulationParameters.cfgHE = wlanHESUConfig;
SimulationParameters.cfgHE.ChannelBandwidth = 'CBW20';  % Channel bandwidth
SimulationParameters.cfgHE.NumSpaceTimeStreams = 1;     % Number of space-time streams
SimulationParameters.cfgHE.NumTransmitAntennas = 1;     % Number of transmit antennas
SimulationParameters.cfgHE.APEPLength = 1e3;            % Payload length in bytes
SimulationParameters.cfgHE.ExtendedRange = false;       % Do not use extended range format
SimulationParameters.cfgHE.Upper106ToneRU = false;      % Do not use upper 106 tone RU
SimulationParameters.cfgHE.PreHESpatialMapping = false; % Spatial mapping of pre-HE fields
SimulationParameters.cfgHE.GuardInterval = 0.8;         % Guard interval duration
SimulationParameters.cfgHE.HELTFType = 4;               % HE-LTF compression mode
SimulationParameters.cfgHE.ChannelCoding = 'LDPC';      % Channel coding
SimulationParameters.cfgHE.MCS = 3;                     % Modulation and coding scheme


% SNR
SimulationParameters.SNR = 0:20;

% Jammer Power
  SimulationParameters.jammer_power = 15;   % Watt

% VERBOSE

SimulationParameters.verbose = false;



end

