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
device.setSourcePulse()
device.setSourcePulse('dPeriod', 1.3)