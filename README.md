# matlab-rigol-dg1000z
Matlab Communication Class for Rigol DG1000Z Series Function/Arbitrary Waveform Generator


## Temrminator

- Decimal 10, Hex x0A “new line / line feed”
- See [Preparing ASCII data packets with MATLAB fwrite(serial), write(tcpclient), fwrite(tcpip), fprintf(tcpip)](https://github.com/cnanders/matlab-ascii-comm-notes)

## Firmware

- Make sure to upgrade firmware.  The original firmware on the development hardware was 1.04 and this version did not support an important setting for pulse waveforms in burst mode.  Google something like “Rigol DG1000Z Firmware” fore more information.   At the time of writing (2018.03.07), the latest firmware is 1.12


