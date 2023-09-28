function sigma_stim = findSigmaStim(DSetSpec)

sigma_stim = sqrt(2) * DSetSpec.DotsSd * sqrt(DSetSpec.Fps);