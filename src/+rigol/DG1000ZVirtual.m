classdef DG1000ZVirtual < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        % Requires port 5555
        
        
    end
    
    properties (Access = private)
        
        % {logical 1x2} true when the hardware is outputting 5V.  One 
        % value for each channel
        lIsOn = [false false]
        
        
        % {timer 1x1} - storage for timers used in the trigger method to
        % update the value of lIsOn of each channel
        t1
        t2
    end
    
    methods
        
        
        function this = DG1000ZVirtual(varargin) 
                        
            for k = 1 : 2: length(varargin)
                this.msg(sprintf('passed in %s', varargin{k}));
                if this.hasProp( varargin{k})
                    this.msg(sprintf('settting %s', varargin{k}));
                    this.(varargin{k}) = varargin{k + 1};
                end
            end
            
        end
        
        function c = idn(this)
            c = 'DG100ZVirtual';
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
                fprintf('rigol.DG1000ZVirtual.trigger5VTTLPulse returning since already outputting 5VTTL\n');
                return
            end
            
            this.lIsOn(u8Ch) = true;
                        
            if (u8Ch == 1)
                this.t1 = timer(...
                    'StartDelay', dSec, ...
                    'TimerFcn', @this.onTimer1 ...
                );
                start(this.t1);
            else
                this.t2 = timer(...
                    'StartDelay', dSec, ...
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
            this.lIsOn(u8Ch) = true;
        end
        
        function turnOff5VTTL(this, u8Ch)
            this.lIsOn(u8Ch) = false;
        end
        
        
    end
    
end

