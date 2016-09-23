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
%
%
%*******************************************************************************
%  SimSAC Project
%
%  NeoCASS
%  Next generation Conceptual Aero Structural Sizing  
%
%                      Sergio Ricci             <ricci@aero.polimi.it>
%                      Luca Cavagna             <cavagna@aero.polimi.it>
%                      Alessandro De Gaspari    <degaspari@aero.polimi.it>
%                      Luca Riccobene           <riccobene@aero.polimi.it>
%
%  Department of Aerospace Engineering - Politecnico di Milano (DIAPM)
%  Warning: This code is released only to be used by SimSAC partners.
%  Any usage without an explicit authorization may be persecuted.
%
%*******************************************************************************
%
% Structural analysis modulus applied to toboms structural box.
% 
% Called by:    AFaWWE.m
%
% Calls:        
%
% MODIFICATIONS:
%     DATE        VERS    PROGRAMMER       DESCRIPTION
%
%*******************************************************************************
function str = Str_Tbooms(pdcylin, aircraft, geo, loads, str)
% Tail booms structural sizing disabled since it applies the same formulas
% used for the fuselage

%--------------------------------------------------------------------------------------------------
% Initialize structure: str.tbooms
%--------------------------------------------------------------------------------------------------
str.tbooms.tbar_F  = []; % equivalent isotropic thick for shell                          [m] , vector
str.tbooms.tbar_S  = []; % equivalent isotropic thick for frame                          [m] , vector
str.tbooms.tbar_SC = []; % shell thick due to compressive yield strength                 [m] , vector
str.tbooms.tbar_ST = []; % shell thick due to ultimate tensile strength                  [m] , vector
str.tbooms.tbar_SG = []; % shell thick due to minimum gage                               [m] , vector
str.tbooms.tbar_SB = []; % shell thick due to buckling                                   [m] , vector
str.tbooms.tbar_B  = []; % total thickness of the tbooms structure                       [m] , vector
str.tbooms.tbar_Af = []; % Frame area as product of frame spacing and smeared thickness  [m^2], vector                                   
str.tbooms.d       = []; % frame distance                                                [m] , vector
str.tbooms.WI      = []; % ideal tail booms structural weight                            [kg], vector

%--------------------------------------------------------------------------------------------------
% 4 failure criteria to compute equivalent isotropic thickness for shell tS
% and frames tF along fuselage lenght, based on: 1. compressive yield
% strength; 2. ultimate tensile strength; 3. minimum gage; 4. buckling.
%--------------------------------------------------------------------------------------------------
% 1. compressive yield strength
tbar_SC = loads.tbooms.Nxc ./pdcylin.tbooms.fcs;
str.tbooms.tbar_SC = tbar_SC ;

% 2. ultimate tensile strength
tbar_ST = loads.tbooms.Nxc ./pdcylin.tbooms.fts;
str.tbooms.tbar_ST = tbar_ST;

% 3. minimum gage
tbar_SG = geo.tbooms.Kmg* pdcylin.tbooms.tmg .*ones(length(geo.tbooms.x_nodes), 1);
str.tbooms.tbar_SG = tbar_SG;

% 4. determine optimum buckling smeared thickness for skin and frames
switch pdcylin.tbooms.kcon
    
    % FRAMED BEAM
    case {1,2,3,4,5}
        
        tbar = 4/(27^(1/4)).*...
            ( pi*pdcylin.wing.cf/( pdcylin.tbooms.ckf*geo.tbooms.epsilon^3*pdcylin.tbooms.ef*pdcylin.tbooms.es^3 ) ).^(1/8).*...
            ( 2.*geo.tbooms.R.^2.*pdcylin.tbooms.df/pdcylin.tbooms.ds.*loads.tbooms.Nxc.^2 ) .^(1/4);
        tbar_SB = 3/4 .*tbar;
        tbar_FB = 1/4 .*tbar;
        d       = ones(geo.tbooms.lenx,1)*geo.tbooms.R .*sqrt( 6*pdcylin.tbooms.df/pdcylin.tbooms.ds*...
            sqrt((pi*pdcylin.wing.cf*geo.tbooms.epsilon*pdcylin.tbooms.es)/(pdcylin.tbooms.ckf*pdcylin.tbooms.ef)) );
        
        % Determine new section frame spacing
        % greater than optimum value to reduce frame weight since skin is not buckling critical)
        [tbar_S, index] = max( [tbar_SC, tbar_ST, tbar_SG, tbar_SB], [], 2);
        nbc = intersect(find(index ~= 4), find(loads.tbooms.Nxc/max(loads.tbooms.Nxc)>1e-6));
        if ~isempty(nbc)
            for i = 1:length(nbc)
                k = nbc(i);
                
                % Change frame spacing
                d(k) = pdcylin.tbooms.es * geo.tbooms.epsilon * tbar_S(k)^2/loads.tbooms.Nxc(k);
                
                % Change frame smeared tickness
                tbar_FB(k) = (2 * geo.tbooms.R^2) * sqrt( pi * pdcylin.wing.cf * loads.tbooms.Nxc(k)/...
                    (pdcylin.tbooms.ef * pdcylin.tbooms.ckf * d(k)^3));
            end
        end
        str.tbooms.tbar_SB = tbar_SB;
        str.tbooms.tbar_F  = tbar_FB;
        str.tbooms.d       = d;
        str.tbooms.tbar_S  = tbar_S;
        str.tbooms.tbar_Af = str.tbooms.d .* str.tbooms.tbar_F;
        
    % UNFRAMED BEAM
    case {6,7}
        
        tbar_SB = geo.tbooms.R .*(loads.tbooms.Nxc./(geo.tbooms.R*pdcylin.tbooms.es*geo.tbooms.epsilon)).^(1/geo.tbooms.m);

        % Determine maximum skin tickness
        str.tbooms.tbar_S  = max( [tbar_SC, tbar_ST, tbar_SG, tbar_SB], [], 2);
        %
        str.tbooms.tbar_SB = tbar_SB;
        str.tbooms.tbar_F  = zeros(size(tbar_SB));
        str.tbooms.d       = str.tbooms.tbar_F;
        
    otherwise
        error('Unknown tbooms kcon value.');
        
end

%
str.tbooms.tbar_B = str.tbooms.tbar_S + str.tbooms.tbar_F;

% IDEAL TAIL BOOMS STRUCTURAL WEIGHT (single tail boom)
rm_av      = geo.tbooms.R;
tbar_S_av  = meancouple(str.fus.tbar_S);
tbar_F_av  = meancouple(str.fus.tbar_F);

% Weight computed on mid-point of each element (for a single tail boom)
str.tbooms.WI = 2*pi.*rm_av.*(pdcylin.tbooms.ds.*tbar_S_av + pdcylin.tbooms.df.*tbar_F_av).*diff(geo.tbooms.x_nodes_thick);
