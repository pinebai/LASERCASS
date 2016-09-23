%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) 2008 - 2011 
% 
% Sergio Ricci (sergio.ricci@polimi.it)
%
% Politecnico di Milano, Dipartimento di Ingegneria Aerospaziale
% Via La Masa 34, 20156 Milano - ITALY
% 
% This file is part of NeoCASS Software (www.neocass.org)
%
% NeoCASS is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public
% License as published by the Free Software Foundation;
% either version 2, or (at your option) any later version.
%
% NeoCASS is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied
% warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
% PURPOSE.  See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public
% License along with NeoCASS; see the file GNU GENERAL 
% PUBLIC LICENSE.TXT.  If not, write to the Free Software 
% Foundation, 59 Temple Place -Suite 330, Boston, MA
% 02111-1307, USA.
%
%**************************************************************************
%  SimSAC Project
%
%  NeoCASS
%  Next generation Conceptual Aero Structural Sizing
%
%                      Sergio Ricci         <ricci@aero.polimi.it>
%                      Luca Cavagna         <cavagna@aero.polimi.it>
%                      Luca Riccobene       <riccobene@aero.polimi.it>
%
%  Department of Aerospace Engineering - Politecnico di Milano (DIAPM)
%  Warning: This code is released only to be used by SimSAC partners.
%  Any usage without an explicit authorization may be persecuted.
%
%**************************************************************************
%
% MODIFICATIONS:
%     DATE        VERS    PROGRAMMER       DESCRIPTION
%     090303      2.1     L.Riccobene      Creation
%
%**************************************************************************
%
% function        m = assign_field_value(s, c_name, c_value)
%
%
%   DESCRIPTION:  Assign 'c_value' in 'c_name' field of struct 's', if exist.
%
%
%         INPUT: NAME           TYPE       DESCRIPTION
%
%                  s            struct     input struct
%
%                c_name         string     field name
%
%                c_value                   value to substitute
%
%        OUTPUT: NAME           TYPE       DESCRIPTION
%
%                 m             struct     updated struct
%
%
% !Remark: if treating a struct array nested within 's' will assign value
% only to the first element; attention must be paid with repeated field names:
% each of them will assume the same c_value.
%
%    REFERENCES:
%
% See also extract_field_value, mergestruct2, fix_struct, find_imagORNaN
%
%**************************************************************************
function m = assign_field_value(s, c_name, c_value)

fn = fieldnames(s);

for n = 1:length(fn),

    % Sub structure
    subs = s.(fn{n});
    
    % Check if struct array
    dim = numel(subs);
    
    if isstruct(subs)
        
        % Recurse
        if dim == 1
            s(dim).(fn{n}) = assign_field_value(subs, c_name, c_value);
        else
            for k = 1:dim,
                s.(fn{n})(k) = assign_field_value(subs(k), c_name, c_value);
            end
        end
        
    else

        % If 'c_name' matches field name, overwrite old value with 'c_value'
        if strcmpi(fn{n}, c_name)
            s(1).(fn{n}) = c_value;
        end

    end

end

m = s;