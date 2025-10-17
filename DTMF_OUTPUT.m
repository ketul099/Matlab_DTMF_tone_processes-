% PATEL KETUL S (63302)
clc;                    % Clear command window
clear all;              % Clear workspace (remove all variables)

% ---------------------------
% STEP 1: Load the audio file
% ---------------------------
[y, Fe] = audioread('numero1.wav');  % 'y' = audio data, 'Fe' = sampling frequency

% ----------------------------------------------------------
% STEP 2: Apply band-pass filters for DTMF tone frequencies
% ----------------------------------------------------------
% DTMF (telephone keypad) tones are combinations of 2 frequencies:
% One from low-frequency group (697, 770, 852, 941 Hz)
% One from high-frequency group (1209, 1336, 1477, 1637 Hz)
% 440Hz tone may be used as reference or dial tone (depending on setup)

% Filter centered at 440 Hz (for reference tone)
filtered440 = filter440BandPass(y);
%sound(filtered440, Fe);

% High-pass filter at 650 Hz to remove dial tone and low-frequency noise
x = filter650HighPass(y);

% Band-pass filters for all DTMF frequencies
filtered697  = filter697BandPass(x);
filtered770  = filter770BandPass(x);
filtered852  = filter852BandPass(x);
filtered941  = filter941BandPass(x);
filtered1209 = filter1209BandPass(x);
filtered1336 = filter1336BandPass(x);
filtered1477 = filter1477BandPass(x);
filtered1637 = filter1637BandPass(x);

% -----------------------------------------------------
% STEP 3: Prepare arrays to store power detection values
% -----------------------------------------------------
% Each array will store signal power for its frequency band across time.
% Length reduced by Fe*0.10 (0.1 seconds window).
detect440  = zeros(1, length(y)-Fe*0.10);
detect697  = zeros(1, length(y)-Fe*0.10);
detect770  = zeros(1, length(y)-Fe*0.10);
detect852  = zeros(1, length(y)-Fe*0.10);
detect941  = zeros(1, length(y)-Fe*0.10);
detect1209 = zeros(1, length(y)-Fe*0.10);
detect1336 = zeros(1, length(y)-Fe*0.10);
detect1477 = zeros(1, length(y)-Fe*0.10);
detect1637 = zeros(1, length(y)-Fe*0.10);

% ----------------------------------------------------
% STEP 4: Compute signal power for each frequency band
% ----------------------------------------------------
for k1 = 1:length(y)-Fe*0.10
    % Take a sliding window of 0.10 seconds (Fe*0.10 samples)
    peak440  = filtered440(k1:k1+Fe*0.10);
    peak697  = filtered697(k1:k1+Fe*0.10);
    peak770  = filtered770(k1:k1+Fe*0.10);
    peak852  = filtered852(k1:k1+Fe*0.10);
    peak941  = filtered941(k1:k1+Fe*0.10);
    peak1209 = filtered1209(k1:k1+Fe*0.10);
    peak1336 = filtered1336(k1:k1+Fe*0.10);
    peak1477 = filtered1477(k1:k1+Fe*0.10);
    peak1637 = filtered1637(k1:k1+Fe*0.10);

    % Compute average power for each frequency in this window
    detect440(k1)  = mean(peak440.^2);
    detect697(k1)  = mean(peak697.^2);
    detect770(k1)  = mean(peak770.^2);
    detect852(k1)  = mean(peak852.^2);
    detect941(k1)  = mean(peak941.^2);
    detect1209(k1) = mean(peak1209.^2);
    detect1336(k1) = mean(peak1336.^2);
    detect1477(k1) = mean(peak1477.^2);
    detect1637(k1) = mean(peak1637.^2);
end

% -------------------------------------------------
% STEP 5: Visualize the power of each frequency band
% -------------------------------------------------
figure(1);
hold on;
grid on;

%plot(detect440); % Uncomment if 440Hz reference tone is used
plot(detect697);
plot(detect770);
plot(detect852);
plot(detect941);
plot(detect1209);
plot(detect1336);
plot(detect1477);
plot(detect1637);

% Note: 1336Hz might show false detections due to 3rd harmonic overlap

% ------------------------------------------------
% STEP 6: Set a threshold level ("squelch") for tone detection
% ------------------------------------------------
% This threshold separates real tones from background noise.
% It’s a fraction of the maximum power observed.
ketul = max([detect697 detect770 detect852 detect941 detect1209 detect1336 detect1477 detect1637]) / 6;
plot(ones(1, length(detect697))*ketul); % Draw threshold line
legend('697', '770', '852', '941', '1209', '1336', '1477', '1637', "squelch");

% -----------------------------------------------
% STEP 7: Detect tones above threshold and decode
% -----------------------------------------------
decoder = zeros(1, length(detect440)) - 1; % initialize with -1 (no tone)

for i = 1:length(detect440)
    % Boolean flags for each frequency detection
    is440  = detect440(i)  > ketul;
    is697  = detect697(i)  > ketul;
    is770  = detect770(i)  > ketul;
    is852  = detect852(i)  > ketul;
    is941  = detect941(i)  > ketul;
    is1209 = detect1209(i) > ketul;
    is1336 = detect1336(i) > ketul;
    is1477 = detect1477(i) > ketul;
    is1637 = detect1637(i) > ketul;

    % Optional: 440Hz tone detection (not DTMF key)
    if(is440)
        decoder(i) = 'T';
    end

    % DTMF key mapping (each key = 1 low freq + 1 high freq)
    if(is697)
        if(is1209), decoder(i) = '1'; end
        if(is1336), decoder(i) = '2'; end
        if(is1477), decoder(i) = '3'; end
        if(is1637), decoder(i) = 'A'; end
    end
    if(is770)
        if(is1209), decoder(i) = '4'; end
        if(is1336), decoder(i) = '5'; end
        if(is1477), decoder(i) = '6'; end
        if(is1637), decoder(i) = 'B'; end
    end
    if(is852)
        if(is1209), decoder(i) = '7'; end
        if(is1336), decoder(i) = '8'; end
        if(is1477), decoder(i) = '9'; end
        if(is1637), decoder(i) = 'C'; end
    end
    if(is941)
        if(is1209), decoder(i) = '*'; end
        if(is1336), decoder(i) = '0'; end
        if(is1477), decoder(i) = '#'; end
        if(is1637), decoder(i) = 'D'; end
    end
end

% ------------------------------------------
% STEP 8: Eliminate repeated consecutive tones
% ------------------------------------------
% Only keep one instance per key press (ignore long durations)
last = -1;
decoded = "";
for k = 1:length(detect440)
    if(decoder(k) ~= last)
        if(decoder(k) ~= -1)
            decoded = decoded + char(decoder(k)); % append new detected tone
        end
        last = decoder(k);
    end
end

% ----------------------------------
% STEP 9: Display the decoded digits
% ----------------------------------
disp(decoded)  % Output the detected sequence of DTMF keys
