classdef DG1000Z < rigol.TcpClientBase
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        % Requires port 5555
    end
    
    methods
        
        
        function this = DG1000Z(varargin) 
            
            this@rigol.TcpClientBase(varargin{:});
            
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
        
        % Create a single 5 Volt TTL pulse of specified duration in
        % seconds
        % @param {double 1x1} dSec - pulse duration in seconds
        function c = trigger5VTTL(this, dSec)
            
            
        end
        
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
            this.write(strjoin({cCmd1, cCmd2, cCmd3, cCmd4}, ';'));
            
            
            % this.setSourceVoltageLow(p.Results.u8Ch, p.Results.dLow);
            % this.setSourceVoltageHigh(p.Results.u8Ch, p.Results.dHigh);

        end
        
        function setSourceVoltageLow(this, u8Ch, dVal)
            
            this.write(cCmd);            
        end
        
        function setSourceVoltageHigh(this, u8Ch, dVal)
            cCmd = sprintf(':SOUR%d:VOLT:LEV:IMM:HIGH %1.3e', u8Ch, dVal);
            this.write(cCmd);  
        end
        
        
        function l = isOpen(this)
            
            
        end
        

    end
    
end

