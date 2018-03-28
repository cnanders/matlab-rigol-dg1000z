classdef DG1000Z < rigol.TcpClientBase
    
    
    properties (Constant)
        
        cSOURCE_TYPE_DC = 'DC';
        cSOURCE_TYPE_PULSE = 'PULSE';
        cSOURCE_TYPE_NONE = 'NONE';
        
    end
    
    properties
        
        % Requires port 5555
        
        dDelay = 0.25;
    end
    
    properties (Access = private)
        
        % {logical 1x2} true when the hardware is outputting 5V.  One 
        % value for each channel
        lIsOn = [false false]
        
        % {logical 1x2} set to true after configureFor5VTTLPulse is called
        % and set to false after turnOn5VTTL is called (which requires 
        % ARB wafeform type.
        lIsConfiguredFor5VTTLPulse = [false false]
        
        lIsConfiguredFor5VDC = [false false]
        
        % {timer 1x1} - storage for timers used in the trigger method to
        % update the value of lIsOn of each channel
        t1
        t2
        
        % {char 1xm} - see cSOURCE_TYPE_* stores the most recently set
        % source type on the Rigol.  Need to alternate between Arb and
        % Pulse.
        cSourceType
    end
    
    methods
        
        
        function this = DG1000Z(varargin) 
            
            this@rigol.TcpClientBase(varargin{:});
            this.cSourceType{1} = this.cSOURCE_TYPE_NONE;
            this.cSourceType{2} = this.cSOURCE_TYPE_NONE;
            
            for k = 1 : 2: length(varargin)
                this.msg(sprintf('passed in %s', varargin{k}));
                if this.hasProp( varargin{k})
                    this.msg(sprintf('settting %s', varargin{k}));
                    this.(varargin{k}) = varargin{k + 1};
                end
            end
            
        end
        
        function c = idn(this)
            c = this.queryChar('*IDN?');
        end
        
        % @return {logical 1x1} - true if outputting 5VTTL or if in the 
        % middle of communication between requesting 5VTTL and knowing 100%
        % that the 
        function l = getIsOn(this, u8Ch)
            l = this.lIsOn(u8Ch);
        end
        
        % Create a single 5 Volt TTL pulse of specified duration in
        % seconds
        % @param {double 1x1} dSec - pulse duration in seconds
        
        function trigger5VTTLPulse(this, u8Ch, dSec)
            
            if this.lIsOn(u8Ch) == true
                fprintf('rigol.DG1000Z.trigger5VTTLPulse returning since already outputting 5VTTL\n');
                return
            end
            
            this.lIsOn(u8Ch) = true;
                        
            switch this.cSourceType{u8Ch}
                case {this.cSOURCE_TYPE_NONE, this.cSOURCE_TYPE_DC}
                    this.configureFor5VTTLPulse(u8Ch)
            end
            
            % set period to 10% longer than dSec
            cCmd = sprintf(':SOUR%d:FUNC:PULS:PER %1.3e', u8Ch, dSec * 1.1);
            this.write(cCmd);
            pause(this.dDelay);
            
            % set width to dSec
            cCmd = sprintf(':SOUR%d:FUNC:PULS:WIDT %1.3e', u8Ch, dSec);
            this.write(cCmd);
            pause(this.dDelay);
            
            % manually trigger the burst
            cCmd = sprintf(':SOUR%d:BURS:TRIG', u8Ch);
            this.write(cCmd);
            
            
            % cannot write sequentially because it is a POS
            %{
            ceCmd = {
                sprintf(':SOUR%d:FUNC:PULS:PER %1.3e', u8Ch, dSec), ...
                sprintf(':SOUR%d:FUNC:PULS:WIDT %1.3e', u8Ch, dSec), ...
                ... % manually trigger the burst
                sprintf(':SOUR%d:BURS:TRIG', p.Results.u8Ch) ...
            };
            this.write(strjoin(ceCmd, ';'));
            %}
            
            
            % There is no way to ask the hardware what it is outputting
            % Use a timer to flip the lIsOn property after dDelay + dSec
            % seconds go by
            
            if (u8Ch == 1)
                this.t1 = timer(...
                    'StartDelay', dSec + this.dDelay, ...
                    'TimerFcn', @this.onTimer1 ...
                );
                start(this.t1);
            else
                this.t2 = timer(...
                    'StartDelay', dSec + this.dDelay, ...
                    'TimerFcn', @this.onTimer2 ...
                );
                start(this.t2);
            end
            
            
        end
        
        function onTimer1(this, src, evt)
            this.lIsOn(1) = false;
        end
        
        function onTimer2(this, src, evt)
            this.lIsOn(2) = false;
        end
        
        function turnOn5VTTL(this, u8Ch)
            
            if this.lIsOn(u8Ch)
                return
            end
            
            % Set output off
            cCmd = sprintf(':OUTP%d OFF', u8Ch);
            this.write(cCmd);
            pause(this.dDelay);
            
            switch this.cSourceType{u8Ch}
                case {this.cSOURCE_TYPE_NONE, this.cSOURCE_TYPE_PULSE}
                    this.configureFor5VDC(u8Ch)
            end
            
            this.lIsOn(u8Ch) = true;
                                    
            % Set output on
            cCmd = sprintf(':OUTP%d ON', u8Ch);
            this.write(cCmd);
            pause(this.dDelay);
            
        end
        
        function turnOff5VTTL(this, u8Ch)
            
            this.lIsOn(u8Ch) = false;
            
            % Set output off
            cCmd = sprintf(':OUTP%d OFF', u8Ch);
            this.write(cCmd);
            pause(this.dDelay);
        end
        
        
        
        function test(this, u8Ch)
            
            
            % Set output on
            cCmd = sprintf(':OUTP%d OFF', u8Ch);
            this.write(cCmd);
            pause(this.dDelay)
            
            cCmd = sprintf(':SOUR%d:APPL:SIN', u8Ch);
            this.write(cCmd);
            pause(this.dDelay)
            
            cCmd = sprintf(':SOUR%d:APPL:PULS', u8Ch);
            this.write(cCmd);
            pause(this.dDelay)
            
            % Set output on
            cCmd = sprintf(':OUTP%d ON', u8Ch);
            this.write(cCmd);
            pause(this.dDelay)
            
        end
        
        function configureFor5VDC(this, u8Ch)

            % Set the waveform of the specified channel to DC with
            % a value of 5V

            
            cCmd = sprintf(':SOUR%d:APPL:DC 1,1,5', u8Ch);
            this.write(cCmd);
            pause(this.dDelay);
            
            this.cSourceType{u8Ch} = this.cSOURCE_TYPE_DC;
                                
        end
        
        
        function configureFor5VTTLPulse(this, u8Ch)
            
            
            % Set output off
            cCmd = sprintf(':OUTP%d OFF', u8Ch);
            this.write(cCmd);
            pause(this.dDelay);
            
            % Set low and high levels of specified channel
            %{
            cCmd = sprintf(':SOUR%d:VOLT:LEV:IMM:LOW %1.3e', u8Ch, 0);
            this.write(cCmd);
            pause(this.dDelay);
            
            cCmd = sprintf(':SOUR%d:VOLT:LEV:IMM:HIGH %1.3e', u8Ch, 5);
            this.write(cCmd);
            pause(this.dDelay);
            %}
            
            % Set offset and amplitude to get 5VTTL
            
            cCmd = sprintf(':SOUR%d:VOLT:OFFS %1.3e', u8Ch, 2.5);
            this.write(cCmd);
            pause(this.dDelay);
            
            cCmd = sprintf(':SOUR%d:VOLT %1.3e', u8Ch, 5);
            this.write(cCmd);
            pause(this.dDelay);
            
            
            
            % Set the waveform of the specified channel to pulse with
            % an amplitude of 5V and an offset of 2.5V
            % Look up the APPLY commands in manual
            % freq, amp, offset, phase
            cCmd = sprintf(':SOUR%d:APPL:PULS 1,5,2.5,0', u8Ch);
            this.write(cCmd);
            pause(this.dDelay);
            
            
            % Turn burst off
            cCmd = sprintf(':SOUR%d:BURS OFF', u8Ch);
            this.write(cCmd);
            pause(this.dDelay);
            
            % Set burt mode to N cycle
            cCmd = sprintf(':SOUR%d:BURS:MODE TRIG', u8Ch);
            this.write(cCmd);
            pause(this.dDelay);
            
            % Set number of cycles to 1
            cCmd = sprintf(':SOUR%d:BURS:NCYC 1', u8Ch);
            this.write(cCmd);
            pause(this.dDelay);
            
            % Tell idle times (when not bursting to use the bottom/ low
            % level of the pulse signal)
            cCmd = sprintf(':SOUR%d:BURS:IDLE BOTTOM', u8Ch);
            this.write(cCmd);
            pause(this.dDelay);
            
            % Set the burst trigger source to "Manual"
            cCmd = sprintf(':SOUR%d:BURS:TRIG:SOUR MAN', u8Ch);
            this.write(cCmd);
            pause(this.dDelay);
            
            % Turn burst on
            cCmd = sprintf(':SOUR%d:BURS ON', u8Ch);
            this.write(cCmd);
            pause(this.dDelay);
            
            % Set output on
            cCmd = sprintf(':OUTP%d ON', u8Ch);
            this.write(cCmd);
            pause(this.dDelay);
                        
            this.cSourceType{u8Ch} = this.cSOURCE_TYPE_PULSE;      
            
            %{
            ceCmd = {...
                ... % Set output off
                sprintf(':OUTP%d OFF', u8Ch), ...
                ... % Set low and high levels of specified channel
            	sprintf(':SOUR%d:VOLT:LEV:IMM:LOW %1.3e', u8Ch, 0), ...
            	sprintf(':SOUR%d:VOLT:LEV:IMM:HIGH %1.3e', u8Ch, 5), ...
                ... % Turn burst off
                sprintf(':SOUR%d:BURS OFF', u8Ch), ...
                ... % Set burt mode to N cycle
                sprintf(':SOUR%d:BURS:MODE TRIG', u8Ch), ...
                ... % Set number of cycles to 1
                sprintf(':SOUR%d:BURS:NCYC 1', u8Ch), ...
                ... % Tell idle times (when not bursting to use the bottom/ low
                ... % level of the pulse signal)
                sprintf(':SOUR%d:BURS:IDLE BOTTOM', u8Ch), ...
                ... % Set the burst trigger source to "Manual"
                sprintf(':SOUR%d:BURS:TRIG:SOUR MAN', u8Ch), ...
                ... % Turn burst on
                sprintf(':SOUR%d:BURS ON', u8Ch), ...
                ... % Set the waveform of the specified channel to pulse
                sprintf(':SOUR%d:APPL:PULS', u8Ch), ...
                ... % Set output on
                sprintf(':OUTP%d ON', u8Ch), ...
            };
            
            this.write(strjoin(ceCmd, ';'));  
          %}
            
        end
        
        
        %{
        % @param {uint8 1x1} u8Ch - channel (1 or 2)
        % @param {double 1x1} dPeriod - period (sec) [67e-9 : 1e6]
        % @param {double 1x1} dHigh - high level (V) [-10: 10]
        % @param {double 1x1} dLow - low level (V) [-10: 10]
        % @param {double 1x1} dWidth - pulse width (sec) [16e-9 : dPeriod]
        % @param {double 1x1} dPhase - start phase (deg) [0 : 360]
        % Minimum period and width are hardware limits
        
        function setSourcePulse(this, varargin)
            
            % Input validation and defaults
            p = inputParser;
            addParameter(p, 'u8Ch', uint8(1), @(x) isscalar(x) && isinteger(x) && (x > 0) && (x <= 2))
            addParameter(p, 'dPeriod', 0.528, @(x) isscalar(x) && isnumeric(x) && (x >= 67e-9) && (x <= 1e6))
            addParameter(p, 'dHigh', 4.5, @(x) isscalar(x) && isnumeric(x) && (x >= -10) && (x <= 10))
            addParameter(p, 'dLow', 0.3, @(x) isscalar(x) && isnumeric(x) && (x >= -10) && (x <= 10))
            addParameter(p, 'dWidth', 0.4, @(x) isscalar(x) && isnumeric(x) && (x >= 16e-9) && (x <= 1e6))
            addParameter(p, 'dPhase', 0, @(x) isscalar(x) && isnumeric(x) && (x >= 0) && (x <= 360))
            parse(p, varargin{:});

            cCmd1 = sprintf(':SOUR%d:FUNC:PULS:PER %1.3e', p.Results.u8Ch, p.Results.dPeriod);
            cCmd2 = sprintf(':SOUR%d:FUNC:PULS:WIDT %1.3e', p.Results.u8Ch, p.Results.dWidth);
            cCmd3 = sprintf(':SOUR%d:VOLT:LEV:IMM:LOW %1.3e', p.Results.u8Ch, p.Results.dLow);
            cCmd4 = sprintf(':SOUR%d:VOLT:LEV:IMM:HIGH %1.3e', p.Results.u8Ch, p.Results.dHigh);
            this.write(strjoin({cCmd3, cCmd4, cCmd1, cCmd2}, ';'));
            
            % Burst mode, single pulse
            
            
            cCmd1 = sprintf(':SOUR%d:BURS:MODE TRIG', p.Results.u8Ch); % N cycle burst mode
            cCmd2 = sprintf(':SOUR%d:BURS:NCYC 1', p.Results.u8Ch); % Set number of cycles to 1
            cCmd3 = sprintf(':SOUR%d:BURS ON', p.Results.u8Ch);
            cCmd4 = sprintf(':SOUR%d:BURS:IDLE BOTTOM', p.Results.u8Ch);
            % Set the burst trigger source to "Manual"
            cCmd5 = sprintf(':SOUR%d:BURS:TRIG:SOUR MAN', p.Results.u8Ch);
            % Manually trigger a burst output immediately on the specified channel.
            cCmd6 = sprintf(':SOUR%d:BURS:TRIG', p.Results.u8Ch);  % Can also do *TRG I think
            
            
            this.write(strjoin({cCmd1, cCmd2, cCmd3, cCmd4, cCmd5, cCmd6}, ';'));
            
        end
        
        
        function c = getBurstModeIdlePosition(this, u8Ch)
            
            cCmd = sprintf(':SOUR%d:BURS:IDLE?', u8Ch);
            c = this.queryChar(cCmd);
            
        end
        
        function d = getPulsePeriod(this, u8Ch)
            
            cCmd = sprintf(':SOUR%d:FUNC:PULS:PER?', u8Ch);
            d = this.queryDouble(cCmd);
        end
        
        function c = getBurstGatePolarity(this, u8Ch)
            cCmd = sprintf(':SOUR%d:BURS:GATE:POL?', u8Ch);
            c = this.queryChar(cCmd);
        end
        
        function triggerBurst(this, u8Ch)
            cCmd = sprintf(':SOUR%d:BURS:TRIG', u8Ch);
            this.write(cCmd);
        end

                
        function setSourceVoltageLow(this, u8Ch, dVal)
            cCmd = sprintf(':SOUR%d:VOLT:LEV:IMM:LOW %1.3e', u8Ch, dVal);
            this.write(cCmd);            
        end
        
        function setSourceVoltageHigh(this, u8Ch, dVal)
            cCmd = sprintf(':SOUR%d:VOLT:LEV:IMM:HIGH %1.3e', u8Ch, dVal);
            this.write(cCmd);  
        end
        
        
        function l = isOpen(this)
            
            
        end
        %}
        

    end
    
end

