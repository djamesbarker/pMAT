classdef TDTUDP < handle
    %TDTUDP  TDT UDP class.
    %   obj = TDTUDP(TDT_UDP_HOSTNAME, TYPE) connects to RZ specified by
    %   TDT_UDP_HOSTNAME, which can be either the RZ's IP address or
    %   NetBIOS name
    %   TYPE (optional) specifies the data type to expect.  Default is
    %   'int32'.
    %
    %   obj                 reference to TDTUDP object
    %   obj.read            get next packet
    %   obj.write(data)     write data to RZ
    %
    
    properties
        TDT_UDP_HOSTNAME = '10.10.10.123';

        % data type of received packets
        TYPE = 'int32';
        
        % every RZ UDP command starts with this
        MAGIC = '55AA';

        % UDP command constants
        CMD_SEND_DATA        = '00';
        CMD_GET_VERSION      = '01';
        CMD_SET_REMOTE_IP    = '02';
        CMD_FORGET_REMOTE_IP = '03';

        % Important: the RZ UDP interface port is fixed at 22022
        UDP_PORT = 22022;
        
        INPUT_BUFFER_SIZE  = 4096;
        OUTPUT_BUFFER_SIZE = 4096;
        VERBOSE = 0;
        
        USE_TOOLBOX = 0;
        SORTS = 0;
        BITS = 0;
        REORDER = [];
        
        SOCK = [];
        U = [];
        data = [];

    end
    
    methods
        function obj = TDTUDP(TDT_UDP_HOSTNAME, varargin)
            
            % parse varargin
            for i = 1:2:length(varargin)
                eval(['obj.' upper(varargin{i}) '=varargin{i+1};']);
            end
            
            obj.REORDER = zeros(1,32);
            ind = 1;
            for j = 32:-obj.BITS:1
                obj.REORDER(ind:ind+obj.BITS-1) = j-obj.BITS+1:j;
                ind = ind + obj.BITS;
            end

            obj.TDT_UDP_HOSTNAME = TDT_UDP_HOSTNAME;
            % create a UDP socket object, connect the PC to the target UDP interface
            
            xxx = ver;
            for i = 1:numel(xxx)
                if strcmpi(xxx(i).Name, 'Instrument Control Toolbox')
                    obj.USE_TOOLBOX = 1;
                end
            end
            try
                if obj.USE_TOOLBOX
                    obj.U = udp(TDT_UDP_HOSTNAME, ...
                        obj.UDP_PORT, ...
                        'InputBufferSize', obj.INPUT_BUFFER_SIZE, ...
                        'OutputBufferSize', obj.OUTPUT_BUFFER_SIZE);
                else
                    try
                        obj.SOCK = pnet('udpsocket', obj.UDP_PORT);
                        pnet(obj.SOCK, 'setwritetimeout', 1);
                        pnet(obj.SOCK, 'setreadtimeout', 1);
                        pnet(obj.SOCK, 'udpconnect', 'hostname', obj.TDT_UDP_HOSTNAME);
                    catch
                        error('problem creating UDP socket')
                    end
                end
            catch
                error('problem creating UDP socket')
            end
            
            % bind preliminary IP address and port number to the PC
            if obj.USE_TOOLBOX
                fopen(obj.U);
                if ~strcmp(get(obj.U, 'Status'), 'open')
                    error('problem opening UDP socket')
                end
            end
            
            % configure the header. Notice that it includes the header
            % information followed by the command 2 (set remote IP)
            % and hex '00' (no data packets for header).

            % Sends the packet to the UDP interface, setting the remote IP
            % address of the UDP interface to the host PC
            if obj.USE_TOOLBOX
                fwrite(obj.U, hex2dec([obj.MAGIC, obj.CMD_SET_REMOTE_IP, '00']), 'int32');
            else
                pnet(obj.SOCK, 'write', int32(hex2dec([obj.MAGIC, obj.CMD_SET_REMOTE_IP, '00'])));
                pnet(obj.SOCK, 'writepacket', obj.TDT_UDP_HOSTNAME, obj.UDP_PORT);
            end
        end
        
        function delete(obj)
            if obj.USE_TOOLBOX
                fclose(obj.U);
                delete(obj.U);
            else
                %fclose(obj.SOCK);
                %delete(obj.SOCK);
            end
        end

        function obj = read(obj)
            % read a single packet in as uint32
            if obj.USE_TOOLBOX
                A = fread(obj.U, 1, 'uint32');
            else
                % read a single packet in
                len = pnet(obj.SOCK, 'readpacket');
                if len > 0
                    % if packet larger then 1 byte then read maximum of 1000 doubles in network byte order
                    A = pnet(obj.SOCK, 'read', obj.INPUT_BUFFER_SIZE, 'uint32', 'network')';
                end
            end

            if ~exist('A','var')
                obj.data = [];
                return
            end
            
            A = uint32(A);
            
            if ~isempty(A)
                % check that magic number is in first position of packet
                head = A(1);
                if bitshift(head, -16) == hex2dec(obj.MAGIC)
                    num_chan = bitand(head, 2^16-1);
                    if obj.VERBOSE
                        disp(['number of channels ' num2str(num_chan)])
                    end
                    obj = obj.conv(A(2:end));
                end
            end
        end
        
        function obj = write(obj, data)
            hhh = [obj.MAGIC, obj.CMD_SEND_DATA, dec2hex(numel(data),2)];
            header = hex2dec(hhh);
            if isa(data, 'double')
                data = single(data);
            end
            data = typecast(data, 'uint32');
            
            xxx = [header, data];
            if obj.USE_TOOLBOX
                fwrite(obj.U, xxx, 'int32');
            else
                % Write to write buffer
                pnet(obj.SOCK, 'write', int32(xxx));

                % Send buffer as UDP packet
                pnet(obj.SOCK, 'writepacket', obj.TDT_UDP_HOSTNAME, obj.UDP_PORT);
            end
        end
        
        function obj = conv(obj, data)
            if obj.SORTS == 0 || obj.BITS == 0
                obj.data = typecast(data, obj.TYPE);
            else
                % pack it all into one binary string
                bstr = reshape(dec2bin(data, 32)',1,[]);
                
                % put it in order.  read each 32-bit chunk backwards, by
                % bit count
                for i = 1:32:numel(bstr)
                    t = bstr(i:i+31);
                    bstr(i:i+31) = t(obj.REORDER);
                end
                
                % now pull it apart
                s = [];
                sort_ind = 1e10;
                chan_ind = 0;
                
                for i = 1:obj.BITS:numel(bstr)
                    if sort_ind > obj.SORTS
                        sort_ind = 1;
                        chan_ind = chan_ind + 1;
                        %chan_field = ['ch' num2str(chan_ind)];
                        %s.(chan_field) = [];
                    end
                    v = bin2dec(bstr(i:obj.BITS+i-1));
                    %s.(chan_field)(sort_ind) = v;
                    s(chan_ind,sort_ind) = v;
                    
                    sort_ind = sort_ind + 1;
                end

                obj.data = s;

            end
        end
    end
end
   