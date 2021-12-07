function AvogaBro()

number = '\nHow many people are in the room?\n';
n = input(number);
season = '\nWhat season it is?\n 1. Spring   2. Summer   3. Fall   4. Winter\n';
weather = input(season);
if weather==1
    R_clothing = 0.1395; % [m^2*K/W]
    T_wall = 10; % [°C]
    T_ambient = 15; % [°C]
    T_out = 8; % [°C]
    fprintf(2,'Spring;   Wall temperature: 10°C, Ambient temperature: 15°C\n\n')
elseif weather==2
    R_clothing = 0.0775;
    T_wall = 15;
    T_ambient = 25;
    T_out = 30;
    fprintf(2,'Summer;   Wall temperature: 15°C, Ambient temperature: 30°C\n\n')
elseif weather==3
    R_clothing = 0.1395;
    T_wall = 10;
    T_ambient = 15;
    T_out = 8;
    fprintf(2,'Fall;   Wall temperature: 10°C, Ambient temperature: 15°C\n\n')
elseif weather==4
    R_clothing = 0.155;
    T_wall = 5;
    T_ambient = 10;
    T_out = 0;
    fprintf(2,'Winter;   Wall temperature: 5°C, Ambient temperature: 10°C\n\n')
else
    error('Error! Please restart the program.\n')
end

moving = '\nHow fast do people move in the room?\n 1. Standing or seated   2. Slightly moving   3. Dancing\n';
movement = input(moving);
if movement==1
    T_skin = 33; % [°C]
    h_conv = 3.1; % [W/m^2*K]
    m_dot = 1.4292e-4; % 7 [L/min]
    m_dot_vapor = 0.1e-04;
    fprintf(2,'Standing;   Skin temperature: 33°C, Heat transfer coef.: 3.1W/m^2*K\n\n')
elseif movement==2
    T_skin = 34;
    h_conv = 8.6;
    m_dot = 1.5*1.4292e-4; % 10.5 [L/min]
    m_dot_vapor = 0.2e-04;
    fprintf(2,'Slightly moving;   Skin temperature: 34°C, Heat transfer coef.: 8.6W/m^2*K\n\n')
elseif movement==3
    T_skin = 35;
    h_conv = 14.8;
    m_dot = 2*1.4292e-4; % 14[L/min]
    m_dot_vapor = 0.3e-04;
    fprintf(2,'Dancing;   Skin temperature: 35°C, Heat transfer coef.: 14.8W/m^2*K\n\n')
else
    error('Error! Please restart the program.\n')
end

cooling = '\nHow fast is the cooling fan running?\n 1. Minimum speed   2. Middle speed  3. Maximum speed\n';
fan = input(cooling);
if fan==1
    v_air = 2;
    fprintf(2,'The air speed from the fan is 2m/s.\n')
elseif fan==2
    v_air = 4;
    fprintf(2,'The air speed from the fan is 4m/s.\n')
elseif fan==3
    v_air = 6;
    fprintf(2,'The air speed from the fan is 6m/s.\n')
else
    error('Error! Please restart the program.\n')
end

h_rad = 4.7; %heat transfer coefficient for radiation for typical indoor condition [W/m^2*K]
A_clothing = 1.8; %Average surface area of clothing [m^2]
Cp_air = 1005; %specific heat of air [J/kg*K]
Cp_person = 3600; %specific heat of person [J/kg*K]
k_air = 0.026; %thermal conductivity of air [W/m*K]
k_person = 0.3; %thermal conductivity of human [W/m*K]
h_fg = 2430*1000; %enthalpy of vaporization of water [J/kg]
T_exhale = 33; %temperature of exhaled air [°C]
T_operative = (T_ambient+T_wall)/2; 
m_person = 60; %mass of person [kg]
rho_air = 1.225; %density of air [kg/m^3]
rho_person = 985; %density of human [kg/m^3]
V_air = 5*5*3-n*(pi/4)*0.3^2*1.7; %volume of air [m^3]

Q_sens = (A_clothing*(T_skin-T_operative))/(R_clothing+(1/(h_conv+h_rad)));
Q_lat = m_dot_vapor*h_fg;
Q_lat_conv = m_dot*Cp_air*(T_exhale-T_ambient);

Q = n*(Q_sens + Q_lat + Q_lat_conv);
Q_area = Q/(A_clothing*n); % [W/m^2]
Q_volume = Q/(n*(pi/4)*(0.3^2)*1.7); % [W/m^3]

dT = Q*(R_clothing+(1/(h_conv+h_rad)))/(A_clothing*n); % [°C]
dT_skin_dt = Q/(m_person*Cp_person); % [°C/s]
dT_ambient_dt = Q/(rho_air*V_air*Cp_air); % [°C/s]

VentSize = Q/(v_air*rho_air*Cp_air*(T_ambient+dT-T_out)); % [m^2]
VentSize_length = sqrt(VentSize*10000); % [cm]

fprintf('\n\nThe amount of heat loss by %d people is %5.2f W\n', n, Q)
fprintf('Final temperature difference between skin and ambient air is %8.4f °C\n', dT)
fprintf('The rate of decrease in skin temperature is %8.4f °C/s\n', dT_skin_dt)
fprintf('The rate of increase in ambient temperature is %8.4f °C/s\n', dT_ambient_dt)
fprintf(2,'\nThe minimum ventilator size to keep ambient temperature constant is %4.1f cm by %4.1f cm.\n', VentSize_length,VentSize_length)

%The room size is 5m*5m*3m.
%Humans were modeled in a cylindrical shape with a diameter of 30 cm and a height of 170 cm.
model = createpde('thermal','transient');
gm = importGeometry(model,'model.stl');
model.Geometry = gm;
generateMesh(model);

thermalProperties(model, 'Cell',1,'ThermalConductivity',k_air,'MassDensity',rho_air,'SpecificHeat',Cp_air);
thermalProperties(model, 'Cell',[2:6], 'ThermalConductivity',k_person,'MassDensity',rho_person,'SpecificHeat',Cp_person);

internalHeatSource(model, Q_volume,'Cell',[2:6]);

thermalBC(model,'Face',[1:6],'Temperature',T_wall);
thermalBC(model,'Face',[7:21],'Temperature',T_skin);
thermalBC(model,'Face',[7,9,10,12,13,15,16,18,19,21],'ConvectionCoefficient',h_conv,'AmbientTemperature',T_ambient);
thermalBC(model,'Face',[1:6],'ConvectionCoefficient',h_conv,'AmbientTemperature',T_ambient);
thermalBC(model,'Face',[1:6],'ConvectionCoefficient',h_conv,'AmbientTemperature',T_ambient);

thermalIC(model,T_ambient,'Cell',1);
thermalIC(model,T_skin,'Cell',[2:6]);

t_range = linspace(0,10000,1001);
result = solve(model,t_range);

figure
pdeplot3D(model,'ColorMapData',result.Temperature(:,1),'FaceAlpha',0.5)
%caxis([10 40])
figure
pdeplot3D(model,'ColorMapData',result.Temperature(:,200),'FaceAlpha',0.5)
%caxis([10 40])
figure
pdeplot3D(model,'ColorMapData',result.Temperature(:,400),'FaceAlpha',0.5)
%caxis([10 40])
figure
pdeplot3D(model,'ColorMapData',result.Temperature(:,600),'FaceAlpha',0.5)
%caxis([10 40])
figure
pdeplot3D(model,'ColorMapData',result.Temperature(:,800),'FaceAlpha',0.5)
%caxis([10 40])
figure
pdeplot3D(model,'ColorMapData',result.Temperature(:,1001),'FaceAlpha',0.5)
%caxis([10 40])


model_steady = createpde('thermal');
gm_steady = importGeometry(model_steady,'model.stl');
model_steady.Geometry = gm_steady;
generateMesh(model);

thermalProperties(model_steady, 'Cell',1,'ThermalConductivity',k_air);
thermalProperties(model_steady, 'Cell',[2:6], 'ThermalConductivity',k_person);

thermalBC(model_steady,'Face',[1:6],'Temperature',T_wall);
thermalBC(model_steady,'Face',[7:21],'Temperature',T_skin);
thermalBC(model_steady,'Face',[7,9,10,12,13,15,16,18,19,21],'HeatFlux',Q_area);
thermalBC(model_steady,'Face',[7,9,10,12,13,15,16,18,19,21],'ConvectionCoefficient',h_conv,'AmbientTemperature',T_ambient);
thermalBC(model_steady,'Face',[1:6],'ConvectionCoefficient',h_conv,'AmbientTemperature',T_ambient);
thermalBC(model_steady,'Face',[1:6],'ConvectionCoefficient',h_conv,'AmbientTemperature',T_ambient);

result_steady = solve(model_steady);

[X,Y,Z]=meshgrid(-2500:100:2500, -2500:100:2500, 0:100:3000);
V=interpolateTemperature(result_steady,X,Y,Z);
V=reshape(V,size(X));

figure
colormap jet
contourslice(X,Y,Z,V,[],[],0:200:2000);
set(gca,'FontSize',18)
title('Steady-state Temperature Distribution')
xlabel('x in mm')
ylabel('y in mm')
zlabel('z in mm')
xlim([-2000,2000])
ylim([-2000,2000])
zlim([0,2000])
axis equal
view(40,15)
c=colorbar;
c.Label.String='Temperature [°C]';
