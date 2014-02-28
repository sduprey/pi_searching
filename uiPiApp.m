classdef uiPiApp < handle
    
    properties ( Dependent, Transient )
        Lang
    end
    
    properties ( Access = protected )
        hFig
        hBox
        hBoxHeader
        hLangTitleBox
        hLangTitle
        hSepLangPad
        hSeqTitleBox
        hSeqTitle
        hSepPadRes
        hResTitleBox
        hResTitle
        hBoxCont
        hBoxLang
        hBoxPad
        hSequenceString
        hBoxRes
        hTextBox
        hText
        hPrevNextBox
        hPbPrev
        hPbNext
    end
    
    % Colors
    properties ( Constant, Hidden, Transient )
        bgColor            = [  80   80   80 ] / 255;
        bgS1Color          = [  66  102  155 ] / 255;
        headerBgColor      = [  91  141  214 ] / 255;
        headerFgColor      = [ 255  255  255 ] / 255;
        sepColor           = [ 255  255  255 ] / 255;
        editBgColor        = [ 240  240  240 ] / 255;
        cancelColor        = [ 245   98   60 ] / 255;
        searchColor        = [ 102  155   66 ] / 255;
        disableColor       = [ 100  100  100 ] / 255;
        textColor          = [ 240  240  240 ] / 255;
        textHighlightColor = [ 245   98   60 ] / 255;
    end
    
    % Language data
    properties ( Access = protected, Hidden, Transient )
        langDir
        lang_ = 'fr';
        langMessages
        langIcons
    end
    
    properties ( Access = protected, Hidden, Transient )
        SearchResult
        Data
    end
    
    % Listeners
    properties ( Access = protected, Transient, Hidden )
        Listeners = {};
    end
    
    % Constants
    properties ( Constant, Hidden, Transient )
        NB_DIGITS = 8; % Number of digits before and after string
    end
    
    methods
        
        function this = uiPiApp( langDir )
            
            % Setup internal properties
            this.langDir = langDir;
            
            % Load PI decimals
            this.loadData();
            
            % Load language data
            this.loadLanguages();
            
            % Create figure
            this.hFig = figure( ...
                'toolbar'    , 'none', ... % Do not show toolbar by default. Can be overwritten by input argument.
                'menubar'    , 'none', ... % Do not show menubar by default. Can be overwritten by input argument.
                'NumberTitle', 'off' , ... % Do not number title by default. Can be overwritten by input argument.
                'Units'      , 'pixels', ...
                'Position'   , [100 100 900 430], ...
                'Visible'    , 'off' );
            
            % Create UI components
            this.createUI();
            
            % Set default language
            this.Lang = this.lang_;
            
            % Watch out for the graphics being destroyed
            this.Listeners{end+1,1} = handle.listener( handle( this.hFig ), 'ObjectBeingDestroyed', @this.onContainerBeingDestroyed );
            
            % Move GUI to center of screen
            movegui( this.hFig, 'center' );
            
            % Make GUI visible
            set( this.hFig, 'Visible', 'on' );
            
        end
        
        function delete( this )
            
            if ishandle( this.hFig ) && ~strcmpi( get( this.hFig, 'BeingDeleted' ), 'on' )
                delete( this.hFig );
            end
            
        end
        
    end
    
    methods
        
        function set.Lang( this, value )
            this.lang_ = value;
            
            % Update displayed texts
            set( this.hLangTitle, 'String', sprintf( this.langMessages.( value ).LangBarTitle ) );
            set( this.hSeqTitle , 'String', sprintf( this.langMessages.( value ).SequenceBarTitle ) );
            set( this.hResTitle , 'String', sprintf( this.langMessages.( value ).ResultBarTitle ) );
            
            % Update result display if possible
            if ~isempty( this.SearchResult )
                this.UpdateResults();
            end
            
        end
        function value = get.Lang( this )
            value = this.lang_;
        end
        
    end
    
    methods ( Access = protected )
        
        function createUI( this )
            
            % Main box
            this.hBox = uiextras.VBox( ...
                'Parent'         , this.hFig, ...
                'BackgroundColor', this.bgColor, ...
                'Padding'        , 0, ...
                'Spacing'        , 0 );
            
            % Header
            this.createHeader( this.hBox );
            
            % Content Box
            this.createContent( this.hBox );
            
            % Set dimensions
            set( this.hBox, 'Sizes', [ 50 -1 ] );
            
            
        end
        
        function createHeader( this, parent )
            
            % Create box
            this.hBoxHeader = uiextras.HBox( ...
                'Parent'         , parent, ...
                'BackgroundColor', this.headerBgColor, ...
                'Padding'        , 0, ...
                'Spacing'        , 0 );
            
            % Language title
            this.hLangTitleBox = uiextras.VBox( ...
                'Parent'         , this.hBoxHeader, ...
                'BackgroundColor', this.headerBgColor, ...
                'Padding'        , 15 );
            this.hLangTitle    = uicontrol( ...
                'Parent'         , this.hLangTitleBox, ...
                'Style'          , 'text'    , ...
                'BackgroundColor', this.headerBgColor, ...
                'ForegroundColor', this.headerFgColor, ...
                'String'         , this.langMessages.(this.lang_).LangBarTitle, ...
                'FontWeight'     , 'bold', ...
                'FontSize'       , 12 );
            
            % Separator
            this.hSepLangPad = uicontrol( ...
                'Parent'         , this.hBoxHeader, ...
                'Style'          , 'text', ...
                'BackgroundColor', this.sepColor );
            
            % Sequence title
            this.hSeqTitleBox = uiextras.VBox( ...
                'Parent'         , this.hBoxHeader, ...
                'BackgroundColor', this.headerBgColor, ...
                'Padding'        , 5 );
            this.hSeqTitle = uicontrol( ...
                'Parent'         , this.hSeqTitleBox, ...
                'Style'          , 'text', ...
                'BackgroundColor', this.headerBgColor,...
                'ForegroundColor', this.headerFgColor, ...
                'String'         , this.langMessages.(this.lang_).SequenceBarTitle, ...
                'FontWeight'     , 'bold',...
                'FontSize'       , 12 );
            
            % Separator
            this.hSepPadRes = uicontrol( ...
                'Parent'         , this.hBoxHeader  , ...
                'Style'          , 'checkbox', ...
                'CData'          , Icons.getIcon( 'sep', this.sepColor, this.headerBgColor ), ...
                'BackgroundColor', this.headerBgColor );
            
            % Result title
            this.hResTitleBox = uiextras.VBox( ...
                'Parent'         , this.hBoxHeader, ...
                'BackgroundColor', this.headerBgColor, ...
                'Padding'        , 15 );
            this.hResTitle = uicontrol( ...
                'Parent'         , this.hResTitleBox, ...
                'Style'          , 'text',...
                'BackgroundColor', this.headerBgColor,...
                'ForegroundColor', this.headerFgColor,...
                'String'         , this.langMessages.(this.lang_).ResultBarTitle,...
                'FontWeight'     , 'bold',...
                'FontSize'       , 12 );
            
            % Set dimensions
            set( this.hBoxHeader, 'Sizes', [ 100 3 250 50 -1 ] );
            
        end
        
        function createContent( this, parent )
            
            % Create box
            this.hBoxCont = uiextras.HBox( ...
                'Parent'         , parent, ...
                'BackgroundColor', this.bgColor, ...
                'Padding'        , 0, ...
                'Spacing'        , 0 );
            
            % Language buttons
            this.createLanguageBar( this.hBoxCont );
            
            % Separator
            uicontrol( 'Parent', this.hBoxCont, 'Style', 'text', 'BackgroundColor', this.sepColor );
            
            % Num Pad
            this.createNumPad( this.hBoxCont);
            
            % Separator
            uicontrol( 'Parent', this.hBoxCont, 'Style', 'text', 'BackgroundColor', this.sepColor );
            
            % Result panel
            this.createResultPanel( this.hBoxCont );
            
            % Set dimensions
            set( this.hBoxCont, 'Sizes', [ 100 3 270 3 -1 ] );
            
        end
        
        function createLanguageBar( this, parent )
            
            % Language ids
            langIds = fieldnames( this.langMessages );
            
            % Number of available languages
            langN = numel( langIds );
            
            % Create box
            this.hBoxLang = uiextras.VBox( ...
                'Parent'         , parent, ...
                'BackgroundColor', this.bgColor, ...
                'Padding'        , 20, ...
                'Spacing'        , 30 );
            
            % Create buttons
            for ind = 1:langN
                uicontrol( ...
                    'Parent'         , this.hBoxLang, ...
                    'Style'          , 'checkbox', ...
                    'BackgroundColor', this.bgColor, ...
                    'CData'          , this.langIcons.( langIds{ ind } ), ...
                    'UserData'       , langIds{ ind }, ...
                    'Callback'       , @this.PbLang_Callback );
            end
            
            % Set dimensions
            set( this.hBoxLang, 'Sizes', 50 * ones( langN, 1 ) );
            
        end
        
        function createNumPad( this, parent )
            
            % Create box
            this.hBoxPad = uiextras.VBox( ...
                'Parent'         , parent, ...
                'BackgroundColor', this.bgColor, ...
                'Padding'        , 10, ...
                'Spacing'        , 22 );
            
            % Edit field
            this.hSequenceString = uicontrol( ...
                'Parent'         , this.hBoxPad, ...
                'Style'          ,'edit', ...
                'BackgroundColor', this.editBgColor, ...
                'ForegroundColor', this.bgColor, ...
                'FontSize'       , 13, ...
                'FontWeight'     , 'bold' );
            
            % Numeric pad
            hLine1 = uiextras.HBox( 'Parent', this.hBoxPad, 'BackgroundColor', this.bgColor, 'Padding', 0, 'Spacing', 21 );
            uiextras.Empty( 'Parent', hLine1, 'BackgroundColor', this.bgColor );
            uicontrol( 'Parent', hLine1, 'Style', 'checkbox', 'BackgroundColor', this.bgColor, 'CData', Icons.getIcon( 'num7', this.headerBgColor, this.bgColor ), 'UserData', '7', 'Callback', @this.PbNumPad_Callback );
            uicontrol( 'Parent', hLine1, 'Style', 'checkbox', 'BackgroundColor', this.bgColor, 'CData', Icons.getIcon( 'num8', this.headerBgColor, this.bgColor ), 'UserData', '8', 'Callback', @this.PbNumPad_Callback );
            uicontrol( 'Parent', hLine1, 'Style', 'checkbox', 'BackgroundColor', this.bgColor, 'CData', Icons.getIcon( 'num9', this.headerBgColor, this.bgColor ), 'UserData', '9', 'Callback', @this.PbNumPad_Callback );
            uiextras.Empty( 'Parent', hLine1, 'BackgroundColor', this.bgColor );
            
            hLine2 = uiextras.HBox( 'Parent', this.hBoxPad, 'BackgroundColor', this.bgColor, 'Padding', 0, 'Spacing', 21 );
            uiextras.Empty( 'Parent', hLine2, 'BackgroundColor', this.bgColor );
            uicontrol( 'Parent', hLine2, 'Style', 'checkbox', 'BackgroundColor', this.bgColor, 'CData', Icons.getIcon( 'num4', this.headerBgColor, this.bgColor ), 'UserData', '4', 'Callback', @this.PbNumPad_Callback );
            uicontrol( 'Parent', hLine2, 'Style', 'checkbox', 'BackgroundColor', this.bgColor, 'CData', Icons.getIcon( 'num5', this.headerBgColor, this.bgColor ), 'UserData', '5', 'Callback', @this.PbNumPad_Callback );
            uicontrol( 'Parent', hLine2, 'Style', 'checkbox', 'BackgroundColor', this.bgColor, 'CData', Icons.getIcon( 'num6', this.headerBgColor, this.bgColor ), 'UserData', '6', 'Callback', @this.PbNumPad_Callback );
            uiextras.Empty( 'Parent', hLine2, 'BackgroundColor', this.bgColor );
            
            hLine3 = uiextras.HBox('Parent', this.hBoxPad, 'BackgroundColor', this.bgColor, 'Padding', 0, 'Spacing', 21 );
            uiextras.Empty('Parent', hLine3, 'BackgroundColor',this.bgColor);
            uicontrol( 'Parent', hLine3, 'Style', 'checkbox', 'BackgroundColor', this.bgColor, 'CData', Icons.getIcon( 'num1', this.headerBgColor, this.bgColor ), 'UserData', '1', 'Callback', @this.PbNumPad_Callback );
            uicontrol( 'Parent', hLine3, 'Style', 'checkbox', 'BackgroundColor', this.bgColor, 'CData', Icons.getIcon( 'num2', this.headerBgColor, this.bgColor ), 'UserData', '2', 'Callback', @this.PbNumPad_Callback );
            uicontrol( 'Parent', hLine3, 'Style', 'checkbox', 'BackgroundColor', this.bgColor, 'CData', Icons.getIcon( 'num3', this.headerBgColor, this.bgColor ), 'UserData', '3', 'Callback', @this.PbNumPad_Callback );
            uiextras.Empty('Parent', hLine3, 'BackgroundColor',this.bgColor);
            
            hLine4 = uiextras.HBox('Parent', this.hBoxPad, 'BackgroundColor', this.bgColor, 'Padding', 0, 'Spacing', 21 );
            uiextras.Empty('Parent', hLine4, 'BackgroundColor',this.bgColor);
            uicontrol( 'Parent', hLine4, 'Style', 'checkbox', 'BackgroundColor', this.bgColor, 'CData', Icons.getIcon( 'cancel', this.cancelColor  , this.bgColor ), 'Callback', @this.PbCancel_Callback );
            uicontrol( 'Parent', hLine4, 'Style', 'checkbox', 'BackgroundColor', this.bgColor, 'CData', Icons.getIcon( 'num0'  , this.headerBgColor, this.bgColor ), 'UserData', '0', 'Callback', @this.PbNumPad_Callback );
            uicontrol( 'Parent', hLine4, 'Style', 'checkbox', 'BackgroundColor', this.bgColor, 'CData', Icons.getIcon( 'search', this.searchColor  , this.bgColor ), 'Callback', @this.PbSearch_Callback );
            uiextras.Empty('Parent', hLine4, 'BackgroundColor',this.bgColor);
            
            uiextras.Empty('Parent', this.hBoxPad, 'BackgroundColor',this.bgColor);
            
            % Set dimensions
            set( hLine1      , 'Sizes', [ 0 -1 -1 -1 0 ] );
            set( hLine2      , 'Sizes', [ 0 -1 -1 -1 0 ] );
            set( hLine3      , 'Sizes', [ 0 -1 -1 -1 0 ] );
            set( hLine4      , 'Sizes', [ 0 -1 -1 -1 0 ] );
            set( this.hBoxPad, 'Sizes', [ 40 54 54 54 54 -1 ] );

        end
        
        function createResultPanel( this, parent )
            
            % Create box
            this.hBoxRes = uiextras.VBox( ...
                'Parent'         , parent, ...
                'BackgroundColor', this.bgColor, ...
                'Padding'        , 20, ...
                'Spacing'        , 0 );
            
            % Result text
            this.hTextBox = uiextras.HBox( 'Parent', this.hBoxRes, 'BackgroundColor', this.bgColor, 'Padding', 0, 'Spacing', 0 );
            uiextras.Empty( 'Parent', this.hTextBox, 'BackgroundColor', this.bgColor );
            this.hText = uicontrol('Parent', this.hTextBox, 'Style', 'checkbox', 'BackgroundColor', this.bgColor, 'CData', NaN(1,1,3), 'FontSize', 13, 'FontWeight', 'bold', 'ForegroundColor', this.textColor, 'String', '' );
            uiextras.Empty('Parent', this.hTextBox, 'BackgroundColor', this.bgColor);
            
            set( this.hTextBox, 'Sizes', [-1 400 -1 ] );
            
            % Navigation buttons
            this.hPrevNextBox = uiextras.HBox('Parent', this.hBoxRes, 'BackgroundColor', this.bgColor, 'Padding', 0, 'Spacing', 0 );
            uiextras.Empty('Parent', this.hPrevNextBox, 'BackgroundColor', this.bgColor);
            this.hPbPrev = uicontrol('Parent', this.hPrevNextBox, 'Style', 'checkbox', 'BackgroundColor', this.bgColor, 'CData', Icons.getIcon('prev', this.disableColor, this.bgColor), 'Callback', { @this.NavResult_Callback, -1 } );
            uiextras.Empty('Parent', this.hPrevNextBox, 'BackgroundColor', this.bgColor);
            this.hPbNext = uicontrol('Parent', this.hPrevNextBox, 'Style', 'checkbox', 'BackgroundColor', this.bgColor, 'CData', Icons.getIcon('next', this.headerBgColor, this.bgColor), 'Callback', { @this.NavResult_Callback, 1 } );
            uiextras.Empty('Parent', this.hPrevNextBox, 'BackgroundColor', this.bgColor);
            
            set( this.hPrevNextBox, 'Sizes', [ 60 54 -1 54 60 ] );
            
            % Spacer
            uiextras.Empty('Parent', this.hBoxRes, 'BackgroundColor', this.bgColor);
            
            % Set dimensions
            set( this.hBoxRes, 'Sizes', [ -1 54 25 ] );

        end
        
        function loadLanguages( this )
            
            % List all message files available
            list = dir( fullfile( this.langDir, 'msg_*.txt' ) );
            
            % Find all language ids
            langIds = regexp( {list.name}', 'msg_([a-z]{2}).txt', 'tokens' );
            langIds = cat( 1, langIds{:} );
            langIds = cat( 1, langIds{:} );
            
            % Init messages & icons structures
            langMes = cell2struct( cell( size( langIds ) ), langIds );
            langIco = langMes;
            
            % Load message files & icons
            for ind = 1:numel( langIds )
                
                % Message file
                fid = fopen( fullfile( this.langDir, list( ind ).name ), 'rt' );
                data = textscan( fid, '%s%s', 'Delimiter', '=', 'CommentStyle', '#' );
                
                langMes.( langIds{ ind } ) = cell2struct( data{2}, data{1}, 1 );
                
                % Icon file
                langIco.( langIds{ ind } ) = imread( fullfile( this.langDir, [ 'flag_' langIds{ ind } '.png' ] ) );
                
            end
            
            % Store data
            this.langMessages = langMes;
            this.langIcons    = langIco;
            
        end
        
        function message = getMessage( this, mesId, varargin )
            message = sprintf( this.langMessages.( this.lang_ ).( mesId ), varargin{:} );
        end
        
        function message = formatMessage( this, message )
            
            % Convert HighlightColor from RGB to HEX
            clr = reshape( dec2hex( this.textHighlightColor * 255 )', 1, [] );
            
            % Replace '\n' for new line by corresponding HTML
            % character '<br />'
            message = strrep( message, '\n', '<br />');
            
            % Replace string '<xxx>' by '<font color="red">xxx</font>'
            % To display it in red in JLabel
            message = regexprep( message, '<(.*?)>', [ '<font color="#' clr '">$1</font>' ] );
            
        end
                
        function onContainerBeingDestroyed( this, source, eventData ) %#ok<INUSD>
            %onContainerBeingDestroyed  Callback that fires when the container dies
            delete( this );
        end
        
        function PbLang_Callback( this, obj, ~ )
            
            % Update GUI language
            this.Lang = get( obj, 'UserData' );
            
        end
        
        function PbNumPad_Callback( this, obj, ~ )
            
            str = get( this.hSequenceString, 'String' );
            set( this.hSequenceString, 'String', [ str get( obj, 'UserData' ) ] );
            
        end
        
        function PbCancel_Callback( this, ~, ~ )
            set( this.hSequenceString, 'String', '' );
        end
        
        function PbSearch_Callback( this, ~, ~ )
            
            % Get string entered by user
            str = get( this.hSequenceString, 'String' );
            
            if isempty( str )
                return
            end
            
            set( this.hFig, 'Pointer', 'watch'); drawnow;
            
            % Find positions where string can be found
            [ start_position, end_position ] = this.find_string_position( str );
            
            % Save in a structure information about result
            this.SearchResult = struct( ...
                'str'  , str           , ...
                'start', start_position, ...
                'end'  , end_position  , ...
                'idx'  , 1               ... % Index of result that will be displayed is 1
                );
            
            % Update display of results
            this.UpdateResults();
            
            set( this.hSequenceString, 'String', '' );
            
            set( this.hFig, 'Pointer', 'arrow'); drawnow;
            
        end
        
        function NavResult_Callback( this, ~, ~, move )
            
            this.SearchResult.idx = this.SearchResult.idx + move;
            
            this.UpdateResults();
            
        end
        
        function UpdateResults( this )
            
            % Get results
            result = this.SearchResult;
            
            % Check if some results are found
            if isempty(result) % No result are calculated
                
                % Define result strings
                result_str = '';
                position_label_str = '';
                position_value_str = '';
                
                prev_str = '';
                next_str = '';
                
                search_str = '';
                
                % Define state of button Next and Prev
                is_next = false;
                is_prev = flase;
                
                
            elseif isempty(result.start) % String was not found in PI decimales
                
                % Define result strings
                result_str = this.getMessage('StringDoNotOccurs', result.str );
                position_label_str = '';
                position_value_str = '';
                
                prev_str = '';
                next_str = '';
                
                search_str = '';
                
                % Define state of button Next and Prev
                is_next = false;
                is_prev = false;
                
            else % Results was found
                
                % Define result strings
                result_str = this.getMessage( 'StringOccursNTimes', length(result.start) );
                
                % Position is displayed with a String, each group of 3 digits are
                % separated by a '.'
                position_str = sprintf('% 9u', result.start(result.idx));
                position_str = mat2cell(position_str, 1,[3 3 3]);
                position_str(cellfun(@(x) isempty(deblank(x)), position_str)) = [];
                position_str = [sprintf('%s ', position_str{1:end-1}) position_str{end} ' '];
                
                % Add message according to language around values of position
                position_label_str = this.getMessage( 'PositionLabel', result.idx );
                position_value_str = this.getMessage( 'PositionValue', position_str );
                
                % Digits before and after searched string
                prev_str = this.get_string_at_position( result.start(result.idx) - this.NB_DIGITS, result.start( result.idx ) - 1 );
                next_str = this.get_string_at_position( result.end( result.idx ) + 1, result.end( result.idx ) + this.NB_DIGITS );
                
                % Add message according to language around next and preivous digits
                prev_str = this.getMessage( 'PreviousDigits', prev_str );
                next_str = this.getMessage( 'NextDigits', next_str );
                
                % Reminder of searched string
                search_str = result.str;
                
                % Define state of button Next and Prev
                if result.idx == 1
                    is_prev = false;
                else
                    is_prev = true;
                end
                
                if result.idx == length(result.start)
                    is_next = false;
                else
                    is_next = true;
                end
                
            end
            
            str = sprintf( '<html>%s<br/><br/>%s<br/>%s<br/><br/>%s&nbsp;<font size="7">%s</font>&nbsp;%s</html>', ...
                this.formatMessage( result_str ), ...
                this.formatMessage( position_label_str ), ...
                this.formatMessage( position_value_str ), ...
                prev_str, ...
                this.formatMessage( [ '<' search_str '>' ] ), ...
                next_str );
            
            set( this.hText, 'String', str )
            
            % Update status of buttons Prev and Next
            if is_next
                set( this.hPbNext, 'Enable', 'on', 'CData', Icons.getIcon( 'next', this.headerBgColor, this.bgColor ) );
            else
                set( this.hPbNext, 'Enable', 'inactive', 'CData', Icons.getIcon( 'next', this.disableColor, this.bgColor ) );
            end
            if is_prev
                set( this.hPbPrev, 'Enable', 'on', 'CData', Icons.getIcon( 'prev', this.headerBgColor, this.bgColor ) );
            else
                set( this.hPbPrev, 'Enable', 'inactive', 'CData', Icons.getIcon( 'prev', this.disableColor, this.bgColor ) );
            end

        end
        
        function loadData( this )
            % Load PI decimals
            
            if isempty( this.Data )
                
                % Load MAT-file in my_struct variable
                my_struct = load( 'digits_results' );
                
                % Extract data from results field of my_struct
                this.Data = my_struct.results;
                
            end
            
        end

        function [ start_pos, end_pos,nb ] = find_string_position( this, str2find )
            % Find all occurrences position of str2find (entered by user) in 200 000 000 first decimals of PI
            
            pi_str = this.Data;
            
            % Parameter: number of characters that are saved in each part of pi_str
            PART_LENGTH = length(pi_str{1});
            
            % Find all occurrences of str2find in pi_str
            
            % First look in each part of pi_str separatly
            % -------------------------------------------
            start_pos = arrayfun(@(x) (x-1)*PART_LENGTH+regexp(pi_str{x},str2find), 1:length(pi_str), 'UniformOutput', false);
            start_pos = [start_pos{:}];
            
            % Look in junction of each parts of pi_str
            % ----------------------------------------
            % Define starting and ending point of each part to make join
            relative_start_idx = PART_LENGTH - length(str2find) + 2;
            relative_end_idx = length(str2find) - 1;
            
            if length(pi_str) > 1
                
                % Create a cell array with all junctions of parts of PI decimals
                part_join_str = cellfun(@(x,y) [x(relative_start_idx:end) y(1:relative_end_idx)], pi_str(1:end-1), pi_str(2:end), 'UniformOutput', false);
                
                % Find string occurence in join
                part_join_pos = cellfun(@(x,y) (y-1)*10e6 + (relative_start_idx-1) + regexp(x,str2find), part_join_str, num2cell(1:length(pi_str)-1)', 'UniformOutput', false);
                part_join_pos = [part_join_pos{:}];
                
                % Add finding position in list of all position (use UNIQUE to sort data in ascending order)
                start_pos = unique([start_pos part_join_pos]);
                
            end
            
            % Calculate end position of string
            end_pos = start_pos + length(str2find) - 1;
            
            % Convert data type
            start_pos = int32(start_pos);
            end_pos = int32(end_pos);
            
            nb = int32(length(start_pos));
            
        end
        
        function str = get_string_at_position( this, idx_start, idx_end )
            %
            
            try
                
                pi_str = this.Data;
                
                % Parameter: number of characters that are saved in each part of pi_str
                PART_LENGTH = length(pi_str{1});
                
                idx = double(max(idx_start,1):min(idx_end,PART_LENGTH*length(pi_str)));
                
                if isempty(idx)
                    
                    % In specific case of empty IDx (for first values), return empty string
                    str = '';
                    
                else
                    
                    % Find cell which contains data corresponding to each indexes (first
                    % and last)
                    idx_cell_start = ceil(idx(1)/PART_LENGTH);
                    idx_cell_end = ceil(idx(end)/PART_LENGTH);
                    
                    % In most of cases, it is the same cell that contains all data to
                    % display so idx_cell_start == idx_cell_end
                    if (idx_cell_start == idx_cell_end)
                        
                        idx = idx - (idx_cell_start-1)*PART_LENGTH;
                        str = pi_str{idx_cell_start}(idx(idx > 0 & idx <= PART_LENGTH));
                        
                    else
                        
                        % When string is split between 2 cells, concatenate part from each cells.
                        % Use MAX and MIN to ensure that indexes are not greater than upper
                        % limit or under 1.
                        % UNIQUE is used to avoid index repetition due to MAX/MIN
                        idx1 = idx - (idx_cell_start-1)*PART_LENGTH;
                        idx2 = idx - (idx_cell_end-1)*PART_LENGTH;
                        
                        str = [pi_str{idx_cell_start}(idx1(idx1 > 0 & idx1 <= PART_LENGTH)) ...
                            pi_str{idx_cell_end}(idx1(idx2 > 0 & idx2 <= PART_LENGTH))];
                        
                    end
                    
                end
                
            catch me
                
                save('C:\Temp\error.mat')
                
                rethrow(me)
                
            end
            
        end
        
    end
    
end

