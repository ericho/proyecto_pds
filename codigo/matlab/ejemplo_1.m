% Codigo ejemplo del paper
addpath("/home/erich/src/proyecto_pds/codigo/matlab");

% Por alguna razon que no investigare ahora, solo funciona con el path
% completo.
path_to_file = '/home/erich/src/proyecto_pds/codigo/matlab/toolbox/data_WAV/Systematic_Chord-C-Major_Eight-Instruments.wav';
filename = 'Systematic_Chord-C-Major_Eight-Instruments.wav';
[f_audio, side_info] = wav_to_audio('', '', path_to_file);
shiftFB = estimateTuning(f_audio);

paramPitch.winLenSTMSP = 4410;
paramPitch.shiftFB = shiftFB;
paramPitch.visualize = 1;
[f_pitch, side_info] = ...
    audio_to_pitch_via_FB(f_audio, paramPitch, side_info);

paramCP.applyLogCompr = 0;
paramCP.visualize = 1;
paramCP.inputFeatureRate = side_info.pitch.featureRate;
[f_CP, side_info] = pitch_to_chroma(f_pitch, paramCP, side_info);

paramCLP.applyLogCompr = 1;
paramCLP.factorLogCompr = 100;
paramCLP.visualize = 1;
paramCLP.inputFeatureRate = side_info.pitch.featureRate;
[f_CLP, side_info] = pitch_to_chroma(f_pitch, paramCLP, side_info);

paramCENS.winLenSmooth = 21;
paramCENS.downsampSmooth = 5;
paramCENS.visualize = 1;
paramCENS.inputFeatureRate = side_info.pitch.featureRate;
[f_CENS, side_info] = pitch_to_CENS(f_pitch, paramCENS, side_info);

paramCRP.coeffsToKeep = [55:120];
paramCRP.visualize = 1;
paramCRP.inputFeatureRate = side_info.pitch.featureRate;
[f_CRP, side_info] = pitch_to_CRP(f_pitch, paramCRP, side_info);

paramSmooth.winLenSmooth = 21;
paramSmooth.downsampSmooth = 5;
paramSmooth.inputFeatureRate = side_info.CRP.featureRate;
[f_CRPSmoothed, featureRateSmoothed] = ...
    smoothDownsampleFeature(f_CRP, paramSmooth);
parameterVis.featureRate = featureRateSmoothed;
visualizeCRP(f_CRPSmoothed, parameterVis);

