function pi_startup( langDir )
%
% Initialize and launch PI application
%
%#ok<*WNON,*WNOFF>

warning off 

% Define application root directory
root_dir = fileparts(mfilename('fullpath'));

if ~nargin
    langDir = fullfile( root_dir, 'lang' );
end

% Add in path all source directories of application
if ~isdeployed
    addpath(fullfile(root_dir, 'data'))
    addpath(fullfile(root_dir, 'Patch'))
end

warning on

% Launch PI application
uiPiApp( langDir )

