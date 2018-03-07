classdef TcpClientBase < handle
    
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        % {char 1xm} tcp/ip host
        cHost = '192.168.10.40'
        
        % {uint16 1x1} tcpip port network control uses telnet port 23
        u16Port = uint16(23)
        
        % {tcpclient 1x1}
        comm
        
        % {double 1x1}
        dTimeout = 1
        
    end
    
    methods
        
        
        function this = TcpClientBase(varargin) 
            
            
            for k = 1 : 2: length(varargin)
                % this.msg(sprintf('passed in %s', varargin{k}));
                if this.hasProp( varargin{k})
                    % this.msg(sprintf('settting %s', varargin{k}));
                    this.(varargin{k}) = varargin{k + 1};
                end
            end
            
            this.comm = tcpclient(this.cHost, this.u16Port);
            this.clearBytesAvailable();
            
        end
                
    end
    
    methods (Access = protected)
                
        % @param {uint8 1x1} u8Terminator - terminator byte in
        % decimal form, e.g. 10, 13
        % @return {uint8 1xm} stream of bytes retrieved from the 
        % hardware
        
        function u8 = readToTerminator(this, u8Terminator)
            
            lTerminatorReached = false;
            u8Result = [];
            idTic = tic;
            lDebug = false;
            
            while(~lTerminatorReached && ...
                   toc(idTic) < this.dTimeout )
               
                if (this.comm.BytesAvailable > 0)
                    
                    cMsg = [...
                        sprintf('readToTerminator(%d) ', u8Terminator), ...
                        sprintf('reading %u bytesAvailable', this.comm.BytesAvailable), ...
                        '\n' ...
                    ];
                    lDebug && fprintf(cMsg);
                    % Append available bytes to previously read bytes
                    
                    % {uint8 1xm} 
                    u8Val = read(this.comm, this.comm.BytesAvailable);
                    % {uint8 1x?}
                    u8Result = [u8Result u8Val];
                    % search new data for terminator
                    u8Index = find(u8Val == u8Terminator);
                    if ~isempty(u8Index)
                        lTerminatorReached = true;
                    end
                else
                    cMsg = sprintf(...
                        'micronix.MMC103.readToTerminator() no BytesAvailable %1.3f s\n', ...
                        toc(idTic) ...
                    );
                    lDebug && fprintf(cMsg);
                end
            end
            
            u8 = u8Result;
            
        end
        
        
        % Read until the terminator is reached and convert to ASCII if
        % necessary (tcpip and tcpclient transmit and receive binary data).
        % @return {char 1xm} the ASCII result
        
        function c = read(this)
            
            u8Result = this.readToTerminator(uint8(13));
            
            % remove line feed and carriage return terminator
            u8Result = u8Result(1 : end - 2);
            
            % convert to ASCII (char)
            c = char(u8Result);
                    
        end
        
        % Write an ASCII command to  
        % Create the binary command packet as follows:
        % Convert the char command into a list of uint8 (decimal), 
        % concat with the first terminator: 10 (base10) === 'line feed')
        % concat with the second terminator: 13 (base10)=== 'carriage return') 
        % write the command to the tcpclient
        % @param {char 1xm} ASCII command without terminators
        function write(this, cCmd)
            
            lDebug = true;
            lDebug && fprintf('write(%s)\n', cCmd);
            u8Cmd = [uint8(cCmd) 13];
            write(this.comm, u8Cmd);                    
        end

        
        function l = hasProp(this, c)
            
            l = false;
            if ~isempty(findprop(this, c))
                l = true;
            end
            
        end
        
        % Send a command and format the result as a double
        function d = queryDouble(this, cCmd)
            c = this.queryChar(cCmd);
            % strip leading '#' char
            c = c(2:end);
            d = str2double(c);
        end
        
        % Send a command and get the result back as ASCII
        function c = queryChar(this, cCmd)
            this.clearBytesAvailable();
            this.write(cCmd)
            c = this.read();
        end
        
        function clearBytesAvailable(this)
            
            % This doesn't alway work.  I've found that if I overfill the
            % input buffer, call this method, then do a subsequent read,
            % the results come back all with -1.6050e9.  Need to figure
            % this out
            
            lDebug = false;
            lDebug && fprintf('clearBytesAvailable()\n');
            
            while this.comm.BytesAvailable > 0
                cMsg = sprintf(...
                    'clearBytesAvailable() clearing %1.0f bytes\n', ...
                    this.comm.BytesAvailable ...
                );
                lDebug && fprintf(cMsg);
                fread(this.comm, this.comm.BytesAvailable);
            end
            
        end
        
        function msg(this, cMsg)
            fprintf('TcpClientBase.msg(): %s\n', cMsg);
        end
        
    end
    
end

