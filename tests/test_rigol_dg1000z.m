[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));

% Add src
addpath(genpath(fullfile(cDirThis, '..', 'src')));

clear
clc

cHost = '192.168.10.40';
u16Port = 5555;

device = rigol.DG1000Z(...
    'cHost', cHost, ...
    'u16Port', u16Port ...
);

device.idn()

device.configureFor5VTTLPulse(1);

%{
device.setSourcePulse(...
    'dHigh', 0.2, ...
    'dLow', -0.2, ...
    'dPeriod', 0.42, ...
    'dWidth', 0.1 ...
)

device.getBurstModeIdlePosition(uint8(1))
device.getPulsePeriod(uint8(1))
device.getBurstGatePolarity(uint8(1))


device.triggerBurst(uint8(1))
%}