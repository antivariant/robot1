function smVrepMotor(block)
setup(block);


%%%%%%%%%
% Setup %
%%%%%%%%%
function setup(block)

    %% Input and Output configuration  

    block.NumInputPorts  = 1;
    block.NumOutputPorts = 0;

    block.InputPort(1).DatatypeID  = 0;  % double
    block.InputPort(1).Complexity  = 'Real';
    block.InputPort(1).Dimensions = 1;

    %% Paramrters
    block.NumDialogPrms     = 3;

    %% Options
    block.SetAccelRunOnTLC(true); % Specify if Accelerator should use TLC or call back to the 

    block.SimStateCompliance = 'DefaultSimState';

    block.NumContStates = 0;

    block.SampleTimes = [0.05 0];

    %% Register Methods

    block.RegBlockMethod('PostPropagationSetup',@DoPostPropSetup);
    block.RegBlockMethod('InitializeConditions',@InitConditions);

    block.RegBlockMethod('Start', @Start);
    block.RegBlockMethod('Outputs', @Outputs);
    block.RegBlockMethod('Update', @Update);
    block.RegBlockMethod('Terminate', @Terminate);

%%%%%%%%%%%%%
% Functions %
%%%%%%%%%%%%%

  %% Diskrete states

function DoPostPropSetup(block)
    block.NumDworks=1;
    block.Dwork(1).Name = 'x0'; 
    block.Dwork(1).Dimensions      = 1;
    block.Dwork(1).DatatypeID      = 0;
    block.Dwork(1).Complexity      = 'Real';
    block.Dwork(1).UsedAsDiscState = true;

function InitConditions(block)
    block.Dwork(1).Data = 0;    

%% Main functions
function Start(block)
    global vrep;
    global clientID;

    addr = char(block.DialogPrm(1).Data);
    port = int16(block.DialogPrm(2).Data);

    vrep=remApi('remoteApi');
    vrep.simxFinish(-1); 
    clientID = vrep.simxStart(addr,port,true,true,5000,5);

    vrep.simxSynchronous(clientID,true);
    vrep.simxStartSimulation(clientID,vrep.simx_opmode_oneshot_wait);

function Outputs(block)
    global vrep;
    global clientID;
    global jointHandle;

    if block.InputPort(1).Data ~= block.Dwork(1).Data 
        jname = char(block.DialogPrm(3).Data);    
        [~, jointHandle] = vrep.simxGetObjectHandle(clientID, jname, vrep.simx_opmode_oneshot_wait);
        vrep.simxSetJointTargetVelocity(clientID, jointHandle,  block.InputPort(1).Data, vrep.simx_opmode_oneshot_wait);  
    end

function Update(block)
    block.Dwork(1).Data = block.InputPort(1).Data;

function Terminate(~)
    global vrep;
    global clientID;

    vrep.simxFinish(clientID);
    %vrep.delete();
