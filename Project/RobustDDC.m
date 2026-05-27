% =========================================================================
% Robuste Datengetriebene Sichere Regelung mittels Dichtefunktionen
% Aufgabenbeispiel 1: Flow System 
% Verwendete Toolbox: CaΣoS (CASOS) auf Basis von CasADi
% =========================================================================

clear; close all; clc;

%% 1. Initialisierung und Systemdefinition
% Definition der Zustandsvariablen als Indeterminierte in CaSoS
x = casos.Indeterminates('x', 2); 

% Wahre Systemparameter (dienen ausschließlich der Generierung realitätsnaher Beobachtungsdaten)
% Die wahre Dynamik ist: f_true = [x2; -x1 + (1/3)*x1^3 - x2], g_true = [0; 1]
% Dem Reglerkonstrukteur ist jedoch nur die Struktur der Basisfunktionen phi und gamma bekannt.
phi = [x(1); x(2); x(1)^2; x(1)*x(2); x(2)^2; x(1)^3;...
       x(1)^2*x(2); x(1)*x(2)^2; x(2)^3]; % 9-dimensionale Basis (Polynome bis Grad 3)
gamma = 1; % Konstanter Eingang
df = length(phi); % Dimension des Driftvektors (9)
dg = length(gamma); % Dimension des Eingangsvektors (1)

%% 2. Datengenerierung (Simulation der Offline-Phase)
rng(42); % Fixierung des Zufallsgenerators zur strikten Reproduzierbarkeit
T = 80; % Anzahl der gesammelten Datenpunkte, exakt wie in der Studie gefordert 
X_data = 4 * rand(2, T) - 2; % Zustände x_s zufällig gesampelt im Intervall [-2, 2]
U_data = 2 * rand(1, T) - 1; % Steuereingänge u_s zufällig gesampelt im Intervall [-1, 1]
W_data = 2 * (2 * rand(2, T) - 1); % Injektion von Offline-Rauschen mit ||w||_inf <= 2

dX_data = zeros(2, T);
for i = 1:T
    xv = X_data(:, i);
    % Generierung der Ableitungen \dot{x}_s unter Einfluss der wahren Dynamik und des Rauschens
    f_val = [xv(2); -xv(1) + (1/3)*xv(1)^3 - xv(2)];
    g_val = [0; 1];
    dX_data(:, i) = f_val + g_val * U_data(:, i) + W_data(:, i);
end

%% 3. Konstruktion der Konsistenzmenge (Alternativ-Theorem Matrizen)
% Das Störungs-Polytop W wird definiert als Menge {w | W_mat * w <= d_w}
W_mat = [eye(2); -eye(2)]; % 4x2 Matrix zur Limitierung aller Zustandsdimensionen
d_w = [2; 2; 2; 2];        % 4x1 Vektor, repräsentiert ||w||_inf <= 2
nw = 4; % Anzahl der definierenden Ungleichungen des Rausch-Polytops

A = zeros(nw * T, 2 * df); % Allokation der Matrix A für die f-Komponenten
B = zeros(nw * T, 2 * dg); % Allokation der Matrix B für die g-Komponenten
xi = zeros(nw * T, 1);     % Allokation des Vektors xi für die Beobachtungen

for i = 1:T
    xv = X_data(:, i);
    uv = U_data(:, i);
    % Numerische Evaluierung der Basisfunktionen an den gesampelten Datenpunkten
    phi_val = [xv(1); xv(2); xv(1)^2; xv(1)*xv(2); xv(2)^2; xv(1)^3;...
               xv(1)^2*xv(2); xv(1)*xv(2)^2; xv(2)^3];
    gamma_val = 1;
    
    % Vektorisierung durch das Kronecker-Produkt zur Entkopplung der Systemparameter 
    A((i-1)*nw+1 : i*nw, :) = kron(W_mat, phi_val');
    B((i-1)*nw+1 : i*nw, :) = kron(W_mat, uv * gamma_val');
    xi((i-1)*nw+1 : i*nw, 1) = W_mat * dX_data(:, i);
end

% Zusammensetzung der globalen Matrix N und des Vektors e nach Gleichung (13) aus dem Paper 
% N = in blockdiagonaler Form
N =;
N =; 
% e = [xi - 1 \otimes d_w; d_w]
e =;
num_faces = size(N, 1); % Berechnet die Anzahl der Flächen des Polytops (324 Flächen)

%% 4. Definition der Dichtefunktion und SOS-Variablen
d_rho = 4; d_psi = 4; % Maximaler Polynomgrad für die gesuchten Funktionen
% Definition der symbolischen Polynome in CaSoS, parametrisiert als quadratische Formen ('gram')
rho = casos.PS.sym('rho', monomials(x, 0:d_rho), 'gram');
psi = casos.PS.sym('psi', monomials(x, 0:d_psi), 'gram');

% Definition der sicheren initialen Startmenge k(x) >= 0 (Kreisscheibe)
k_set = 0.25 - x(1)^2 - (x(2) + 3)^2; 

% Definition der unsicheren Menge als Disjunktion, modelliert durch ein algebraisches Produkt 
h1 = 0.16 - (x(1) + 1)^2 - (x(2) + 1)^2;
h2 = 0.16 - (x(1) + 1)^2 - (x(2) - 1)^2;
h_set = -h1 * h2; 

%% 5. Symbolische Divergenzberechnung für das Funktional r(x)
% Der Vektor r(x) fasst die Divergenzen der dynamischen Vektorfelder zusammen
I_phi = kron(eye(2), phi'); % 2 x 18 Matrix für den Drift-Term
I_gamma = kron(eye(2), gamma'); % 2 x 2 Matrix für den Eingangs-Term
r_x = casos.PS.sym('rx', zeros(22,1)); % Initialisierung des 22-dimensionalen symbolischen Vektors

% Berechnung der spaltenweisen Divergenz für die f-Komponenten
for k = 1:(2*df)
    v_f = rho * I_phi(:, k); % Vektorfeld der k-ten Dimension
    div_val = jacobian(v_f(1), x(1)) + jacobian(v_f(2), x(2));
    r_x(k) = div_val;
end

% Berechnung der spaltenweisen Divergenz für die g-Komponenten
for k = 1:(2*dg)
    v_g = psi * I_gamma(:, k); 
    div_val = jacobian(v_g(1), x(1)) + jacobian(v_g(2), x(2));
    r_x(2*df + k) = div_val;
end

% Berechnung des Gradienten von rho für den Online-Rausch-Term w
r_x(2*df + 2*dg + 1) = jacobian(rho, x(1));
r_x(2*df + 2*dg + 2) = jacobian(rho, x(2));

r_x = -r_x; % Vorzeichenanpassung gemäß der Definition der Polytop-Grenzen

%% 6. SOS Multiplikatoren und numerische Schlupfvariablen
% Der Vektor y(x) >= 0 kompensiert algebraisch die Parameterunsicherheit
y = casos.PS.sym('y', monomials(x, 0:2), num_faces); 
% Lokale Multiplikatoren für die Anwendung des generalisierten S-Verfahrens
s1 = casos.PS.sym('s1', monomials(x, 0:2), 'gram');
s2 = casos.PS.sym('s2', monomials(x, 0:2), 'gram');

% Toleranzen (Slackness-Parameter) zur Vermeidung numerischer Singularitäten an den Rändern 
c1 = 3e-5; 
tol1 = 1e-5;
c2 = 8.8 * tol1;

%% 7. Konstruktion der SOS-Nebenbedingungen (Algorithm 1)
% (A.1) y^T * N - r^T = 0 (Gleichheitsbedingung)
eq_A1 = y' * N - r_x'; 

% (A.2) Divergenzbedingung abzüglich der Rausch-Projektion muss positiv sein
g_A2 = -rho * h_set - y' * e - c1;
% (A.3) & (A.4) Konvexe Relaxation der Absolutbetrags-Schranke für psi
g_A3 = -rho * h_set - psi;
g_A4 = -rho * h_set + psi;
% (A.5) rho muss auf der Startmenge (k_set) positiv sein
g_A5 = rho - s1 * k_set;
% (A.6) rho muss auf der unsicheren Menge (h_set) strikt negativ sein
g_A6 = -rho - s2 * h_set - c2;
% (A.7) Der Projektionsvektor y(x) muss komponentenweise nicht-negativ sein
g_A7 = y; 

% Aggregation aller Nebenbedingungen. Gleichungen werden als >= 0 und <= 0 in den Vektor integriert.
g_constraints = [g_A2; g_A3; g_A4; g_A5; g_A6; g_A7; eq_A1'; -eq_A1'];

%% 8. Lösung des Semidefiniten Programms (SDP)
% Übergabe der Variablen und Restriktionen an die CaSoS Struktur
sos_prob = struct('x', [rho; psi; y(:); s1; s2], 'f', 0, 'g', g_constraints);

opts = struct;
opts.error_on_fail = false; % Verhindert Programmabbruch bei marginaler numerischer Infeasibilität
% Definition der Konen gemäß aktualisierter CaSoS Syntax 
% 'lin' spezifiziert lineare Koeffizientenschranken, 'sos' deklariert Sum-of-Squares Polynome
num_y_coeffs = length(y(:));
opts.Kx = struct('lin', num_y_coeffs, 'sos', 4); % rho, psi, s1, s2 als SOS-Kegel

% Berechnung der Dimensionen der Ungleichungs- und Gleichungsrestriktionen
n_ineq = 1 + 1 + 1 + 1 + 1 + num_faces; % Entspricht A.2 bis A.7
n_eq = 2 * length(eq_A1); % Gleichheitsbedingungen eq_A1 werden doppelt abgebildet (>= und <=)
opts.Kc = struct('sos', n_ineq, 'lin', n_eq);

% Initialisierung des Solvers mit Mosek Backend
S = casos.sossol('S', 'mosek', sos_prob, opts);

% Lösung des konvexen Optimierungsproblems
sol = S();

% Ausgabe des Lösungsstatus. Bei Erfolg formt sich das sichere Regelgesetz als u(x) = psi(x) / rho(x)
disp(S.stats.UNIFIED_RETURN_STATUS);