classdef BH32 < handle
    %BH32  TDT BH32 class.
    %   obj = BH32(varargin) controls a BH32 through SynapseAPI
    %   optional argument is the Synapse computer IP address, otherwise
    %   defaults to 'localhost'
    %
    %   obj                      reference to BH32 object
    %   obj.read                 get device state
    %   obj.write(byteA, byteB)  write bytes to BH32
    %
    %   obj.INPUT_STATE is two element array with byte C and D inputs
    %   obj.OUTPUT_STATE is two element array with byte A and B outputs
    
    properties
        SYN = 0;
        SERVER = 'localhost'
        DEVICE = 'BH32(1)';
        INPUT_STATE = [0 0];
        OUTPUT_STATE = [0 0];
    end
    
    methods
        function obj = BH32(varargin)
            
            % if only device name is argument, use localhost
            if numel(varargin) < 1
                obj.SERVER = 'localhost';
            else
                obj.SERVER = varargin{1};
            end
            
            obj.SYN = SynapseAPI(obj.SERVER);
        end
        
        function delete(obj)
            %obj.SYN.close();
        end
        
        function bytes = read(obj)
            bytes = uint32(obj.SYN.getParameterValue(obj.DEVICE, ...
                'AllBits'));
            bytes = fliplr(typecast(bytes, 'uint8'));
            obj.OUTPUT_STATE = bytes(1:2);
            obj.INPUT_STATE = bytes(3:4);
        end
        
        function write(obj, byteA, byteB)
            if ~all([byteA, byteB] == obj.OUTPUT_STATE)
                obj.SYN.setParameterValue(obj.DEVICE, 'OutputMontage', ...
                    bitshift(byteA, 24) + bitshift(byteB, 16));
            end
        end
    end
end